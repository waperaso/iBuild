import 'dart:io';

import 'package:ibuild_server/src/mail.dart';
import 'package:test/test.dart';

void main() {
  test('an address needs a name, a host and a dot', () {
    expect(isMailAddress('me@example.com'), isTrue);
    expect(isMailAddress('not-an-address'), isFalse);
    expect(isMailAddress('a@b'), isFalse);
    expect(isMailAddress(''), isFalse);
    expect(isMailAddress('me @example.com'), isFalse);
    expect(bareMailAddress('iBuild <no-reply@example.com>'), 'no-reply@example.com');
  });

  test('smtp stays off until host, from, and a password for a user are set', () {
    expect(MailConfig.fromEnvironment(const {}).ready, isFalse);
    expect(MailConfig.fromEnvironment(const {'SMTP_HOST': 'smtp.example.com'}).ready, isFalse);
    expect(
      MailConfig.fromEnvironment(const {
        'SMTP_HOST': 'smtp.example.com',
        'SMTP_FROM': 'iBuild <no-reply@example.com>',
        'SMTP_USER': 'mailbox',
      }).ready,
      isFalse,
    );
    final openRelay = MailConfig.fromEnvironment(const {
      'SMTP_HOST': 'smtp.example.com',
      'SMTP_FROM': 'no-reply@example.com',
    });
    expect(openRelay.ready, isTrue);
    expect(openRelay.password, isEmpty);
    expect(
      MailConfig.fromEnvironment(const {
        'SMTP_HOST': 'smtp.example.com',
        'SMTP_FROM': 'no-reply@example.com',
        'SMTP_USER': 'mailbox',
        'SMTP_PASSWORD': 'secret',
      }).ready,
      isTrue,
    );
  });

  test('the smtp password is read from a file without its trailing newline', () {
    final dir = Directory.systemTemp.createTempSync('ibuild-smtp-');
    try {
      File('${dir.path}/smtp').writeAsStringSync('secret\n');
      final config = MailConfig.fromEnvironment({
        'SMTP_HOST': 'smtp.example.com',
        'SMTP_FROM': 'no-reply@example.com',
        'SMTP_USER': 'mailbox',
        'SMTP_PASSWORD_FILE': '${dir.path}/smtp',
      });
      expect(config.password, 'secret');
      expect(config.ready, isTrue);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
