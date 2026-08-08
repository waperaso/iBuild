import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/auth/auth.dart';
import '../api_client.dart';
import '../env.dart';

/// Real-time events from `/v1/ws`.
enum WsEventType {
  unitStatusChanged,
  unitPriceChanged,
  leadCreated,
  leadStatusChanged,
  leadOwnerChanged,
  newOffer,
  constructionProgress,
  adminNotification,
  unknown;

  static WsEventType parse(String? raw) => WsEventType.values.firstWhere(
    (e) => e.name == raw,
    orElse: () => WsEventType.unknown,
  );
}

class WsEvent {
  const WsEvent({required this.type, required this.payload});

  final WsEventType type;
  final Map<String, dynamic> payload;

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
    type: WsEventType.parse(json['event'] as String?),
    payload: (json['data'] as Map<String, dynamic>?) ?? const {},
  );
}

/// Admin WebSocket client (unit/lead pushes; reconnect with backoff).
class WsClient {
  // A private field can't be a named initializing formal, so assign it in the
  // initializer list instead.
  // ignore: prefer_initializing_formals
  WsClient(
    this._url, {
    bool enabled = true,
    String? Function()? tokenProvider,
  }) : _enabled = enabled, // ignore: prefer_initializing_formals
       _tokenProvider = tokenProvider ?? (() => accessTokenCache);

  final String _url;
  final bool _enabled;
  final String? Function() _tokenProvider;

  WebSocketChannel? _channel;
  StreamController<WsEvent>? _controller;
  StreamSubscription<dynamic>? _channelSub;

  /// Projects currently subscribed, so a reconnect can restore them.
  final Set<String> _subscribedProjects = {};

  bool _connecting = false;
  bool _disposed = false;
  bool _wantConnection = false;
  bool _sawFrame = false;
  bool _handlingClose = false;
  int _reconnectAttempts = 0;
  int _handshakeFailures = 0;
  Timer? _reconnectTimer;

  /// Backoff is capped so a long-lived, repeatedly-failing connection retries
  /// at most every 30s instead of drifting toward minutes.
  static const int _maxBackoffSeconds = 30;

  /// After this many consecutive failed handshakes (no frame received), stop
  /// retrying until auth changes — typically a 401 / missing token case.
  static const int _maxHandshakeFailures = 3;

  String? get _token {
    final value = _tokenProvider();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  /// URL with `access_token` query param (browsers can't set WS headers).
  String _authenticatedUrl(String token) {
    final uri = Uri.parse(_url);
    final query = Map<String, String>.from(uri.queryParameters)
      ..['access_token'] = token;
    return uri.replace(queryParameters: query).toString();
  }

  /// Idempotent: returns the single shared event stream, opening the socket
  /// on the first call when a token is available. Safe to call from
  /// multiple screens — later callers just receive the same broadcast
  /// stream.
  ///
  /// Does **not** bypass an in-flight backoff timer (that was flooding
  /// `/v1/ws` with unauthenticated 401s every second).
  Stream<WsEvent> connect() {
    final controller = _controller ??= StreamController<WsEvent>.broadcast();
    _wantConnection = true;
    _tryOpen();
    return controller.stream;
  }

  /// Call when the access token is set, cleared, or rotated so the socket can
  /// start, stop, or retry with the new credentials.
  void onAuthChanged() {
    if (_disposed) return;
    _handshakeFailures = 0;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_token == null) {
      _tearDownChannel();
      return;
    }
    if (_wantConnection) {
      _tryOpen(force: true);
    }
  }

  void _tryOpen({bool force = false}) {
    if (!_enabled || _disposed || !_wantConnection) return;
    if (_channel != null || _connecting) return;
    if (!force && _reconnectTimer != null) return;
    if (_token == null) return;
    if (_handshakeFailures >= _maxHandshakeFailures) return;
    _openChannel();
  }

  void _openChannel() {
    if (!_enabled || _disposed) return;
    final token = _token;
    if (token == null) return;

    _connecting = true;
    _sawFrame = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _tearDownChannel();

    try {
      final channel = WebSocketChannel.connect(
        Uri.parse(_authenticatedUrl(token)),
      );
      _channel = channel;
      _channelSub = channel.stream.listen(
        (raw) {
          _sawFrame = true;
          _reconnectAttempts = 0;
          _handshakeFailures = 0;
          try {
            final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
            _controller?.add(WsEvent.fromJson(decoded));
          } catch (_) {
            // Ignore malformed frames.
          }
        },
        onError: (_) => _onChannelClosed(),
        onDone: _onChannelClosed,
        cancelOnError: true,
      );
      _connecting = false;
      for (final id in _subscribedProjects) {
        _send({'action': 'subscribeProject', 'projectId': id});
      }
    } catch (_) {
      _connecting = false;
      _channel = null;
      _onChannelClosed();
    }
  }

  void _onChannelClosed() {
    if (_handlingClose) return;
    _handlingClose = true;
    final hadFrame = _sawFrame;
    _tearDownChannel();
    _connecting = false;
    _handlingClose = false;
    if (!_enabled || _disposed || !_wantConnection) return;

    if (_token == null) return;

    if (!hadFrame) {
      _handshakeFailures += 1;
      if (_handshakeFailures >= _maxHandshakeFailures) {
        // Likely 401 / rejected handshake — stop the reconnect storm until
        // the user signs in again or the token is refreshed.
        return;
      }
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_enabled || _disposed || !_wantConnection) return;
    if (_reconnectTimer != null) return;
    if (_token == null) return;
    if (_handshakeFailures >= _maxHandshakeFailures) return;

    _reconnectAttempts += 1;
    final seconds = (1 << (_reconnectAttempts - 1)).clamp(1, _maxBackoffSeconds);
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      _tryOpen();
    });
  }

  void _tearDownChannel() {
    _channelSub?.cancel();
    _channelSub = null;
    _channel?.sink.close();
    _channel = null;
  }

  void subscribeProject(String projectId) {
    _subscribedProjects.add(projectId);
    _send({'action': 'subscribeProject', 'projectId': projectId});
  }

  void unsubscribeProject(String projectId) {
    _subscribedProjects.remove(projectId);
    _send({'action': 'unsubscribeProject', 'projectId': projectId});
  }

  void _send(Map<String, dynamic> message) {
    if (!_enabled) return;
    _channel?.sink.add(jsonEncode(message));
  }

  Future<void> dispose() async {
    _disposed = true;
    _wantConnection = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _channelSub?.cancel();
    await _channel?.sink.close();
    await _controller?.close();
  }
}

final wsClientProvider = Provider<WsClient>((ref) {
  final client = WsClient(Env.wsUrl);
  final unsubscribe = addAccessTokenListener((_) => client.onAuthChanged());
  ref.listen(authControllerProvider, (previous, next) {
    client.onAuthChanged();
  });
  ref.onDispose(() {
    unsubscribe();
    client.dispose();
  });
  return client;
});
