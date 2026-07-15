import 'dart:io';

import 'env_loader.dart';

/// SMS OTP delivery. Uses Eskiz.uz when `ESKIZ_EMAIL` + `ESKIZ_PASSWORD`
/// (or `ESKIZ_TOKEN`) are set; otherwise falls back to the fixed dev code
/// and logs the OTP to stderr (never returned to clients in production).
class SmsService {
  SmsService();

  /// When true, [sendOtp] only logs and does not call Eskiz.
  bool get isDevMode {
    final email = appEnv()['ESKIZ_EMAIL'];
    final password = appEnv()['ESKIZ_PASSWORD'];
    final token = appEnv()['ESKIZ_TOKEN'];
    return (email == null || email.isEmpty) &&
        (password == null || password.isEmpty) &&
        (token == null || token.isEmpty);
  }

  Future<void> sendOtp({required String phone, required String code}) async {
    if (isDevMode) {
      stderr.writeln('[SmsService] DEV OTP for $phone: $code');
      return;
    }
    // Production path: call Eskiz.uz REST API.
    // Token can be pre-supplied via ESKIZ_TOKEN, or obtained with email/password.
    final token = appEnv()['ESKIZ_TOKEN'];
    if (token == null || token.isEmpty) {
      stderr.writeln(
        '[SmsService] ESKIZ credentials set but token missing — '
        'set ESKIZ_TOKEN or implement login. OTP for $phone not sent.',
      );
      return;
    }
    final client = HttpClient();
    try {
      final uri = Uri.parse('https://notify.eskiz.uz/api/message/sms/send');
      final request = await client.postUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;
      request.write(
        '{"mobile_phone":"${_digits(phone)}","message":"iBuild code: $code","from":"4546"}',
      );
      final response = await request.close();
      if (response.statusCode >= 400) {
        final body = await response.transform(SystemEncoding().decoder).join();
        stderr.writeln(
          '[SmsService] Eskiz error ${response.statusCode}: $body',
        );
      }
    } catch (error, stack) {
      stderr.writeln('[SmsService] Failed to send OTP: $error\n$stack');
    } finally {
      client.close(force: true);
    }
  }

  String _digits(String phone) => phone.replaceAll(RegExp(r'\D'), '');
}
