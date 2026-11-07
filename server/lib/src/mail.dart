import 'dart:async';
import 'dart:io';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:postgres/postgres.dart';

import 'db.dart';
import 'http_util.dart';
import 'vault.dart';

/// Mail of the platform. Every letter is written to `mail_outbox` first. With
/// SMTP_HOST set the letter is sent at once and marked sent or failed; without
/// it the letter stays "queued" so nothing is lost and the admin can see it.
class MailConfig {
  const MailConfig({this.host = '', this.port = 587, this.user = '', this.password = '', this.from = '', this.ssl = false});

  factory MailConfig.fromEnvironment([Map<String, String>? env]) {
    final values = env ?? Platform.environment;
    return MailConfig(
      host: values['SMTP_HOST'] ?? '',
      port: int.tryParse(values['SMTP_PORT'] ?? '') ?? 587,
      user: values['SMTP_USER'] ?? '',
      password: readSecret(values, 'SMTP_PASSWORD').value,
      from: values['SMTP_FROM'] ?? values['SMTP_USER'] ?? '',
      ssl: values['SMTP_SSL'] == 'true',
    );
  }

  final String host;
  final int port;
  final String user;
  final String password;
  final String from;
  final bool ssl;

  /// Connected only when there is a host, a real From address, and a password
  /// whenever a username is set. An incomplete setup stays "not connected":
  /// letters remain queued instead of failing at the SMTP server.
  bool get ready {
    if (host.trim().isEmpty) return false;
    if (!isMailAddress(bareMailAddress(from))) return false;
    if (user.trim().isNotEmpty && password.isEmpty) return false;
    return true;
  }
}

/// `Name <user@host>` and a plain address both yield the address.
String bareMailAddress(String value) {
  final trimmed = value.trim();
  final wrapped = RegExp(r'<([^>]+)>').firstMatch(trimmed);
  return (wrapped?.group(1) ?? trimmed).trim();
}

MailConfig mailConfig = MailConfig.fromEnvironment();

final _address = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isMailAddress(String value) => _address.hasMatch(value);

class Attachment {
  const Attachment(this.name, this.type, this.bytes);

  final String name;
  final String type;
  final List<int> bytes;
}

/// Writes the letter and, when SMTP is connected, sends it. Returns its status.
Future<String> sendMail(
  AppDatabase db, {
  required String to,
  required String subject,
  required String body,
  String kind = '',
  String? bankId,
  Attachment? attachment,
}) async {
  final stored = await db.owner.execute(
    Sql.named('''
      INSERT INTO mail_outbox (kind, to_email, subject, body, attachment_name, bank_id)
      VALUES (@kind, @to, @subject, @body, @attachment, @bank::uuid)
      RETURNING id::text
    '''),
    parameters: {
      'kind': kind,
      'to': to,
      'subject': await Vault.seal(subject),
      'body': await Vault.seal(body),
      'attachment': attachment?.name ?? '',
      'bank': bankId,
    },
  );
  final id = stored.first[0]! as String;
  if (!mailConfig.ready) return 'queued';
  return deliver(db, id, to, subject, body, attachment);
}

Future<String> deliver(AppDatabase db, String id, String to, String subject, String body, Attachment? attachment) async {
  final config = mailConfig;
  try {
    final server = SmtpServer(
      config.host,
      port: config.port,
      ssl: config.ssl,
      username: config.user.isEmpty ? null : config.user,
      password: config.user.isEmpty ? null : config.password,
    );
    final message = Message()
      ..from = Address(config.from, 'iBuild')
      ..recipients.add(to)
      ..subject = subject
      ..text = body;
    if (attachment != null) {
      message.attachments.add(StreamAttachment(Stream.value(attachment.bytes), attachment.type, fileName: attachment.name));
    }
    await send(message, server, timeout: const Duration(seconds: 20));
    await db.owner.execute(
      Sql.named("UPDATE mail_outbox SET status = 'sent', error = '', sent_at = now() WHERE id = @id::uuid"),
      parameters: {'id': id},
    );
    return 'sent';
  } catch (error) {
    final text = error.toString();
    await db.owner.execute(
      Sql.named("UPDATE mail_outbox SET status = 'failed', error = @error WHERE id = @id::uuid"),
      parameters: {'id': id, 'error': text.length > 400 ? text.substring(0, 400) : text},
    );
    return 'failed';
  }
}

/// Seals letters written before the vault existed. Safe to run on every start.
Future<int> sealLegacyMail(AppDatabase db) async {
  final rows = await db.owner.execute(
    "SELECT id::text, subject, body FROM mail_outbox WHERE subject NOT LIKE 'v1.%' OR body NOT LIKE 'v1.%'",
  );
  for (final row in rows) {
    await db.owner.execute(
      Sql.named('UPDATE mail_outbox SET subject = @subject, body = @body WHERE id = @id::uuid'),
      parameters: {
        'id': row[0],
        'subject': Vault.isSealed(row[1]! as String) ? row[1] : await Vault.seal(row[1]! as String),
        'body': Vault.isSealed(row[2]! as String) ? row[2] : await Vault.seal(row[2]! as String),
      },
    );
  }
  return rows.length;
}
