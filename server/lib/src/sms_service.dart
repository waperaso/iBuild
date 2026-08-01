import 'dart:convert';
import 'dart:io';

import 'env_loader.dart';

/// SMS OTP delivery. Uses Eskiz.uz when `ESKIZ_EMAIL` + `ESKIZ_PASSWORD`
/// (or `ESKIZ_TOKEN`) are set; otherwise falls back to the fixed dev code
/// and logs the OTP to stderr (never returned to clients in production).
class SmsService {
  SmsService();

  static final Uri _sendUri = Uri.parse(
    'https://notify.eskiz.uz/api/message/sms/send',
  );
  static final Uri _loginUri = Uri.parse(
    'https://notify.eskiz.uz/api/auth/login',
  );

  /// Token obtained from [_loginUri] with `ESKIZ_EMAIL`/`ESKIZ_PASSWORD`.
  /// Eskiz tokens expire (~30 days), so a 401 from the send endpoint clears
  /// this and the next send re-authenticates.
  String? _sessionToken;

  /// When true, [sendOtp] only logs and does not call Eskiz.
  bool get isDevMode {
    final env = appEnv();
    final email = env['ESKIZ_EMAIL'];
    final password = env['ESKIZ_PASSWORD'];
    final token = env['ESKIZ_TOKEN'];
    return (email == null || email.isEmpty) &&
        (password == null || password.isEmpty) &&
        (token == null || token.isEmpty);
  }

  /// Sender ID registered with Eskiz. `4546` is Eskiz's shared test sender,
  /// which only delivers to numbers allow-listed in your Eskiz account —
  /// production accounts must set `ESKIZ_FROM` to their approved alphanumeric
  /// sender or real messages are silently dropped by the provider.
  String get _from => appEnv()['ESKIZ_FROM']?.trim().isNotEmpty == true
      ? appEnv()['ESKIZ_FROM']!.trim()
      : '4546';

  Future<void> sendOtp({required String phone, required String code}) async {
    if (isDevMode) {
      stderr.writeln('[SmsService] DEV OTP for $phone: $code');
      return;
    }
    final client = HttpClient();
    try {
      var token = await _resolveToken(client);
      if (token == null) {
        stderr.writeln(
          '[SmsService] Could not obtain an Eskiz token — OTP for $phone '
          'NOT sent. Check ESKIZ_TOKEN, or ESKIZ_EMAIL + ESKIZ_PASSWORD.',
        );
        return;
      }
      var status = await _postSms(client, token, phone, code);
      // An expired session token is the common failure after ~30 days: drop
      // it and retry once with a freshly minted one.
      if (status == 401 && appEnv()['ESKIZ_TOKEN']?.isNotEmpty != true) {
        _sessionToken = null;
        token = await _resolveToken(client);
        if (token != null) {
          status = await _postSms(client, token, phone, code);
        }
      }
      if (status >= 400) {
        stderr.writeln('[SmsService] Eskiz send failed with status $status');
      }
    } catch (error, stack) {
      stderr.writeln('[SmsService] Failed to send OTP: $error\n$stack');
    } finally {
      client.close(force: true);
    }
  }

  /// A static `ESKIZ_TOKEN` wins; otherwise logs in with email/password and
  /// caches the resulting token for the process lifetime.
  Future<String?> _resolveToken(HttpClient client) async {
    final configured = appEnv()['ESKIZ_TOKEN']?.trim();
    if (configured != null && configured.isNotEmpty) return configured;
    final cached = _sessionToken;
    if (cached != null) return cached;

    final email = appEnv()['ESKIZ_EMAIL']?.trim();
    final password = appEnv()['ESKIZ_PASSWORD'];
    if (email == null || email.isEmpty || password == null || password.isEmpty) {
      return null;
    }
    try {
      final request = await client.postUrl(_loginUri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'email': email, 'password': password}));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode >= 400) {
        // Never log the body verbatim — it can echo back credentials.
        stderr.writeln(
          '[SmsService] Eskiz login failed with status ${response.statusCode}',
        );
        return null;
      }
      final decoded = jsonDecode(body);
      final token =
          (decoded is Map && decoded['data'] is Map)
          ? (decoded['data'] as Map)['token'] as String?
          : null;
      if (token == null || token.isEmpty) {
        stderr.writeln('[SmsService] Eskiz login returned no token');
        return null;
      }
      _sessionToken = token;
      return token;
    } catch (error) {
      stderr.writeln('[SmsService] Eskiz login error: $error');
      return null;
    }
  }

  Future<int> _postSms(
    HttpClient client,
    String token,
    String phone,
    String code,
  ) async {
    final request = await client.postUrl(_sendUri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'mobile_phone': _digits(phone),
        'message': 'iBuild code: $code',
        'from': _from,
      }),
    );
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 400) {
      stderr.writeln('[SmsService] Eskiz error ${response.statusCode}: $body');
    }
    return response.statusCode;
  }

  String _digits(String phone) => phone.replaceAll(RegExp(r'\D'), '');
}
