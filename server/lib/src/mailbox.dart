import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'bank_common.dart';
import 'bank_data.dart';
import 'db.dart';
import 'http_util.dart';
import 'vault.dart';

/// The mailbox inside the application: every person has an inbox and a sent
/// folder and writes to the people they work with. Subject and body are sealed
/// in the database (see vault.dart); who wrote to whom and when stays readable,
/// because the lists need it. Everything runs as the database owner after the
/// session is known, and every query is bound to the person who asked.

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

void mountMailbox(Router router, AppDatabase db) {
  router
    ..get('/api/mail/unread', (Request r) => _unread(r, db))
    ..get('/api/mail/contacts', (Request r) => _contacts(r, db))
    ..get('/api/mail/messages', (Request r) => _list(r, db))
    ..get('/api/mail/messages/<id>', (Request r, String id) => _read(r, db, id))
    ..post('/api/mail/messages', (Request r) => _send(r, db))
    ..post('/api/mail/messages/<id>/delete', (Request r, String id) => _delete(r, db, id));
}

/// Who a person may write to: the people of their own company, the iBuild
/// administrators, and across the contract the staff of the bank that finances
/// their objects, or the developers whose objects the bank finances. The demo
/// world and the real one never meet.
const _contactsSql = '''
  WITH me AS (
    SELECT u.id, u.company_id, u.is_demo, u.platform_admin,
           (SELECT s.bank_id FROM bank_staff s WHERE s.user_id = u.id AND s.active) AS bank_id
    FROM users u WHERE u.id = @me::uuid
  )
  SELECT u.id::text AS id, u.name AS name, c.name AS company, COALESCE(s.title, '') AS title,
         u.platform_admin AS admin
  FROM users u
  JOIN companies c ON c.id = u.company_id
  LEFT JOIN bank_staff s ON s.user_id = u.id AND s.active
  CROSS JOIN me
  WHERE u.active AND u.id <> me.id AND u.is_demo = me.is_demo AND (
    me.platform_admin
    OR u.platform_admin
    OR u.company_id = me.company_id
    OR (me.bank_id IS NOT NULL AND u.company_id IN (
          SELECT p.company_id FROM project_facilities f JOIN projects p ON p.id = f.project_id
          WHERE f.bank_id = me.bank_id))
    OR (s.bank_id IS NOT NULL AND s.bank_id IN (
          SELECT f.bank_id FROM project_facilities f JOIN projects p ON p.id = f.project_id
          WHERE p.company_id = me.company_id))
  )
  ORDER BY c.name, u.name
''';

Future<Object> _open(Request request, AppDatabase db, {bool mutating = false}) async {
  return mutating ? bankMutating(request, db) : bankSession(request, db);
}

Future<List<Map<String, Object?>>> _contactRows(AppDatabase db, String me) =>
    bankRows(db, _contactsSql, {'me': me});

Future<Response> _contacts(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final me = (opened as SessionLookup).user!.id;
  return bankOk({'items': await _contactRows(db, me)});
}

Future<Response> _unread(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final me = (opened as SessionLookup).user!.id;
  final rows = await bankRows(
    db,
    'SELECT count(*) AS n FROM message_recipients WHERE user_id = @me::uuid AND read_at IS NULL AND deleted_at IS NULL',
    {'me': me},
  );
  return bankOk({'count': bankInt(rows.first['n'])});
}

Future<Response> _list(Request request, AppDatabase db) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final me = (opened as SessionLookup).user!.id;
  final sent = request.url.queryParameters['folder'] == 'sent';
  final rows = await bankRows(
    db,
    sent
        ? '''
          SELECT m.id::text AS id, m.thread_id::text AS thread_id, m.subject AS subject, m.created_at AS at,
                 false AS unread,
                 COALESCE((SELECT string_agg(u.name, ', ' ORDER BY u.name)
                           FROM message_recipients r JOIN users u ON u.id = r.user_id
                           WHERE r.message_id = m.id), '') AS people
          FROM messages m
          WHERE m.sender_id = @me::uuid AND m.sender_deleted_at IS NULL
          ORDER BY m.created_at DESC LIMIT 200
        '''
        : '''
          SELECT m.id::text AS id, m.thread_id::text AS thread_id, m.subject AS subject, m.created_at AS at,
                 r.read_at IS NULL AS unread, u.name AS people
          FROM message_recipients r
          JOIN messages m ON m.id = r.message_id
          JOIN users u ON u.id = m.sender_id
          WHERE r.user_id = @me::uuid AND r.deleted_at IS NULL
          ORDER BY m.created_at DESC LIMIT 200
        ''',
    {'me': me},
  );
  final items = [
    for (final row in rows) {...row, 'subject': await _unseal(row['subject']! as String)},
  ];
  return bankOk({'folder': sent ? 'sent' : 'inbox', 'items': items});
}

/// A value that cannot be opened (a lost key) does not break the whole list.
Future<String> _unseal(String value) async {
  try {
    return await Vault.open(value);
  } catch (_) {
    return '[не удалось расшифровать]';
  }
}

Future<Response> _read(Request request, AppDatabase db, String id) async {
  final opened = await _open(request, db);
  if (opened is Response) return opened;
  final me = (opened as SessionLookup).user!.id;
  if (!_uuid.hasMatch(id)) return jsonError(404, 'not_found', 'Письмо не найдено');
  final head = await _visible(db, me, id);
  if (head.isEmpty) return jsonError(404, 'not_found', 'Письмо не найдено');
  final thread = head.first['thread_id']! as String;
  final rows = await bankRows(
    db,
    '''
      SELECT m.id::text AS id, m.sender_id::text AS sender_id, s.name AS sender, m.subject AS subject,
             m.body AS body, m.created_at AS at,
             COALESCE((SELECT string_agg(u.name, ', ' ORDER BY u.name)
                       FROM message_recipients r JOIN users u ON u.id = r.user_id
                       WHERE r.message_id = m.id), '') AS people,
             COALESCE(mine.read_at IS NULL AND mine.user_id IS NOT NULL, false) AS unread
      FROM messages m
      JOIN users s ON s.id = m.sender_id
      LEFT JOIN message_recipients mine ON mine.message_id = m.id AND mine.user_id = @me::uuid
      WHERE m.thread_id = @thread::uuid AND (
        (m.sender_id = @me::uuid AND m.sender_deleted_at IS NULL)
        OR (mine.user_id IS NOT NULL AND mine.deleted_at IS NULL))
      ORDER BY m.created_at
    ''',
    {'me': me, 'thread': thread},
  );
  await db.owner.execute(
    Sql.named('''
      UPDATE message_recipients SET read_at = now()
      WHERE user_id = @me::uuid AND read_at IS NULL
        AND message_id IN (SELECT id FROM messages WHERE thread_id = @thread::uuid)
    '''),
    parameters: {'me': me, 'thread': thread},
  );
  final addressed = await bankRows(
    db,
    'SELECT r.message_id::text AS message_id, r.user_id::text AS user_id FROM message_recipients r JOIN messages m ON m.id = r.message_id WHERE m.thread_id = @thread::uuid',
    {'thread': thread},
  );
  final messages = [
    for (final row in rows)
      {
        ...row,
        'subject': await _unseal(row['subject']! as String),
        'body': await _unseal(row['body']! as String),
        'mine': row['sender_id'] == me,
        'recipient_ids': [
          for (final entry in addressed)
            if (entry['message_id'] == row['id']) entry['user_id'],
        ],
      },
  ];
  return bankOk({'id': id, 'threadId': thread, 'subject': messages.isEmpty ? '' : messages.first['subject'], 'messages': messages});
}

/// The letter, when this person wrote it or received it and has not deleted it.
Future<List<Map<String, Object?>>> _visible(AppDatabase db, String me, String id) {
  return bankRows(
    db,
    '''
      SELECT m.thread_id::text AS thread_id FROM messages m
      LEFT JOIN message_recipients r ON r.message_id = m.id AND r.user_id = @me::uuid
      WHERE m.id = @id::uuid AND (
        (m.sender_id = @me::uuid AND m.sender_deleted_at IS NULL)
        OR (r.user_id IS NOT NULL AND r.deleted_at IS NULL))
    ''',
    {'me': me, 'id': id},
  );
}

Future<Response> _send(Request request, AppDatabase db) async {
  final opened = await _open(request, db, mutating: true);
  if (opened is Response) return opened;
  final me = (opened as SessionLookup).user!.id;
  final body = await bankBody(request);
  if (body == null) return jsonError(400, 'validation', 'Не удалось прочитать письмо');
  final subject = (body['subject'] as String? ?? '').trim();
  final text = (body['body'] as String? ?? '').trim();
  final to = body['to'];
  final threadInput = body['threadId'];
  if (to is! List || to.isEmpty || to.length > 20 || to.any((id) => id is! String || !_uuid.hasMatch(id))) {
    return jsonError(400, 'validation', 'Выберите получателей: от 1 до 20');
  }
  if (subject.isEmpty || subject.length > 200) return jsonError(400, 'validation', 'Напишите тему письма, до 200 знаков');
  if (text.isEmpty || text.length > 10000) return jsonError(400, 'validation', 'Напишите текст письма, до 10 000 знаков');
  if (threadInput != null && (threadInput is! String || !_uuid.hasMatch(threadInput))) {
    return jsonError(400, 'validation', 'Не удалось найти переписку');
  }

  final recent = await bankRows(
    db,
    "SELECT count(*) AS n FROM messages WHERE sender_id = @me::uuid AND created_at > now() - interval '1 hour'",
    {'me': me},
  );
  if (bankInt(recent.first['n']) >= 60) {
    return jsonError(429, 'rate_limited', 'Слишком много писем за час. Подождите немного');
  }

  final allowed = {for (final row in await _contactRows(db, me)) row['id']! as String};
  String? thread;
  if (threadInput is String) {
    // A reply goes to the people of the conversation even when they are no
    // longer among the contacts.
    final known = await bankRows(
      db,
      '''
        SELECT DISTINCT p AS id FROM (
          SELECT m.sender_id::text AS p FROM messages m WHERE m.thread_id = @thread::uuid
          UNION
          SELECT r.user_id::text FROM messages m JOIN message_recipients r ON r.message_id = m.id
          WHERE m.thread_id = @thread::uuid) x
        WHERE EXISTS (
          SELECT 1 FROM messages m LEFT JOIN message_recipients r ON r.message_id = m.id
          WHERE m.thread_id = @thread::uuid AND (m.sender_id = @me::uuid OR r.user_id = @me::uuid))
      ''',
      {'thread': threadInput, 'me': me},
    );
    if (known.isEmpty) return jsonError(404, 'not_found', 'Переписка не найдена');
    thread = threadInput;
    allowed.addAll(known.map((row) => row['id']! as String));
  }
  final recipients = to.cast<String>().toSet();
  if (recipients.contains(me)) return jsonError(400, 'validation', 'Нельзя написать самому себе');
  if (!recipients.every(allowed.contains)) {
    return jsonError(403, 'forbidden', 'Одному из получателей нельзя написать');
  }

  final id = await deliverInternal(db, senderId: me, recipientIds: recipients.toList(), subject: subject, body: text, threadId: thread);
  return bankOk({'ok': true, 'id': id});
}

/// Writes a letter into the mailboxes of [recipientIds]. Used by people through
/// the screen and by the platform itself for reminders. Returns the letter id.
Future<String> deliverInternal(
  AppDatabase db, {
  required String senderId,
  required List<String> recipientIds,
  required String subject,
  required String body,
  String? threadId,
}) async {
  final sealedSubject = await Vault.seal(subject);
  final sealedBody = await Vault.seal(body);
  return db.owner.runTx((session) async {
    final inserted = await session.execute(
      Sql.named('''
        INSERT INTO messages (thread_id, sender_id, subject, body)
        VALUES (COALESCE(@thread::uuid, gen_random_uuid()), @sender::uuid, @subject, @body)
        RETURNING id::text, thread_id::text
      '''),
      parameters: {'thread': threadId, 'sender': senderId, 'subject': sealedSubject, 'body': sealedBody},
    );
    final id = inserted.first[0]! as String;
    if (threadId == null) {
      await session.execute(
        Sql.named('UPDATE messages SET thread_id = id WHERE id = @id::uuid'),
        parameters: {'id': id},
      );
    }
    for (final recipient in recipientIds) {
      await session.execute(
        Sql.named('INSERT INTO message_recipients (message_id, user_id) VALUES (@id::uuid, @user::uuid) ON CONFLICT DO NOTHING'),
        parameters: {'id': id, 'user': recipient},
      );
    }
    return id;
  });
}

Future<Response> _delete(Request request, AppDatabase db, String id) async {
  final opened = await _open(request, db, mutating: true);
  if (opened is Response) return opened;
  final me = (opened as SessionLookup).user!.id;
  if (!_uuid.hasMatch(id)) return jsonError(404, 'not_found', 'Письмо не найдено');
  final head = await _visible(db, me, id);
  if (head.isEmpty) return jsonError(404, 'not_found', 'Письмо не найдено');
  await db.owner.execute(
    Sql.named('UPDATE message_recipients SET deleted_at = now() WHERE message_id = @id::uuid AND user_id = @me::uuid'),
    parameters: {'id': id, 'me': me},
  );
  await db.owner.execute(
    Sql.named('UPDATE messages SET sender_deleted_at = now() WHERE id = @id::uuid AND sender_id = @me::uuid'),
    parameters: {'id': id, 'me': me},
  );
  return bankOk({'ok': true});
}
