import 'package:flutter_test/flutter_test.dart';

import 'package:ibuild_client/core/network/ws_client.dart';

void main() {
  group('WsClient auth gating', () {
    test('connect without a token does not throw and stays idle', () async {
      final client = WsClient(
        'ws://127.0.0.1:9/v1/ws',
        tokenProvider: () => null,
      );
      addTearDown(client.dispose);

      final stream = client.connect();
      // Give any accidental dial a moment — there should be none.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(stream.isBroadcast, isTrue);
    });

    test('onAuthChanged with null token is safe before any dial', () async {
      final client = WsClient(
        'ws://127.0.0.1:9/v1/ws',
        tokenProvider: () => null,
      );
      addTearDown(client.dispose);

      client.connect();
      client.onAuthChanged();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
