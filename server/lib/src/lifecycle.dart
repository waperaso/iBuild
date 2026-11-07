import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'db.dart';

class LifeReply {
  LifeReply(this.status, this.body);

  final int status;
  final String body;
}

class KeyReused implements Exception {}

const changedMessage = 'Транш уже изменили. Обновите страницу.';
const overLimitMessage = 'Сумма больше, чем можно запросить.';
const photoMessage = 'Добавьте хотя бы одно фото работы.';
const reasonMessage = 'Напишите причину.';
const techFirstMessage = 'Сначала транш должен проверить технадзор.';
const cancelMessage = 'Транш можно отозвать, пока банк не принял решение.';
const paymentFieldsMessage = 'Укажите дату и номер платежа.';
const paymentProofMessage = 'Добавьте подтверждение платежа.';
const paymentStatusMessage = 'Отметить выплату можно после одобрения банка.';
const paymentReadyMessage = 'Подтверждение можно добавить, когда банк одобрил транш.';
const paymentAttachedMessage = 'Подтверждение уже добавлено.';
const withdrawMessage = 'Одобрение можно отменить, пока выплата не отмечена.';
const unpaidConfirmMessage = 'Подтвердите, что платёж ещё не ушёл.';
const addresseeRoleMessage = 'Транш можно отправить технадзору или в банк.';
const bankEarlyMessage = 'В банк транш отправляет застройщик после одобрения.';
const bankAgainMessage = 'Транш уже отправлен в банк.';
const bankRoleMessage = 'В банк транш получает сотрудник банка с этого объекта.';
const forwardMessage = 'Транш можно передать технадзору или застройщику.';
const forwardStatusMessage = 'Передать транш можно, пока он на проверке или одобрен.';
const forwardSelfMessage = 'Выберите другого человека.';
const copyStatusMessage = 'Новый транш можно создать только на основе отклонённого.';

Future<LifeReply?> replay(AppDatabase db, String userId, String key, String fingerprint) async {
  final rows = await db.pool.execute(
    Sql.named('''
      SELECT fingerprint, status_code, body
      FROM idempotency_keys
      WHERE user_id = @userId::uuid AND idempotency_key = @key
    '''),
    parameters: {'userId': userId, 'key': key},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  if (map['fingerprint'] != fingerprint) throw KeyReused();
  return LifeReply(_asInt(map['status_code']), map['body'] as String);
}

Future<LifeReply> submitRequest(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
  String addresseeUserId = '',
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'contractor',
    allow: const {'contractor', 'director'},
    work: (session) => _submit(
      session,
      userId,
      requestId,
      version,
      key,
      fingerprint,
      addresseeUserId,
    ),
  );
}

Future<LifeReply> deliverRequest(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
  required String addresseeUserId,
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'director',
    allow: const {'director', 'tech'},
    work: (session) => _deliver(
      session,
      userId: userId,
      requestId: requestId,
      version: version,
      key: key,
      fingerprint: fingerprint,
      addresseeUserId: addresseeUserId,
    ),
  );
}

Future<LifeReply> cancelRequest(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'contractor',
    allow: const {'contractor', 'director'},
    work: (session) => _move(
      session,
      userId: userId,
      requestId: requestId,
      version: version,
      key: key,
      fingerprint: fingerprint,
      role: 'contractor',
      from: 'submitted',
      to: 'cancelled',
      action: 'cancelled',
      ownerOnly: true,
      wrongStatus: cancelMessage,
    ),
  );
}

Future<LifeReply> techDecision(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String decision,
  required String reason,
  required String key,
  required String fingerprint,
}) {
  final approve = decision == 'approve';
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'tech',
    work: (session) async {
      if (!approve && reason.trim().isEmpty) {
        return _fail(400, 'validation', reasonMessage);
      }
      return _move(
        session,
        userId: userId,
        requestId: requestId,
        version: version,
        key: key,
        fingerprint: fingerprint,
        role: 'tech',
        from: 'submitted',
        to: approve ? 'tech_approved' : 'rejected',
        action: approve ? 'tech_approved' : 'rejected',
        reason: reason.trim(),
        ownerOnly: false,
        wrongStatus: changedMessage,
      );
    },
  );
}

Future<LifeReply> directorApprove(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'observer',
    work: (session) => _move(
        session,
        userId: userId,
        requestId: requestId,
        version: version,
        key: key,
        fingerprint: fingerprint,
        role: 'observer',
        from: 'submitted',
        acceptFrom: const ['submitted', 'tech_approved'],
        to: 'approved',
        action: 'approved',
        ownerOnly: false,
        wrongStatus: changedMessage,
        mark: 'full',
      ),
  );
}

Future<LifeReply> directorReject(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String reason,
  required String key,
  required String fingerprint,
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'observer',
    work: (session) async {
      if (reason.trim().isEmpty) return _fail(400, 'validation', reasonMessage);
      return _move(
        session,
        userId: userId,
        requestId: requestId,
        version: version,
        key: key,
        fingerprint: fingerprint,
        role: 'observer',
        from: 'submitted',
        acceptFrom: const ['submitted', 'tech_approved'],
        to: 'rejected',
        action: 'director_rejected',
        ownerOnly: false,
        wrongStatus: changedMessage,
        reason: reason.trim(),
      );
    },
  );
}

Future<LifeReply> recordPayment(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String paidOn,
  required String paymentNumber,
  required String key,
  required String fingerprint,
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'observer',
    work: (session) => _pay(
      session,
      userId: userId,
      requestId: requestId,
      version: version,
      paidOn: paidOn,
      paymentNumber: paymentNumber,
      key: key,
      fingerprint: fingerprint,
    ),
  );
}

Future<LifeReply> withdrawApproval(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String reason,
  required bool unpaidConfirmed,
  required String key,
  required String fingerprint,
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'observer',
    work: (session) async {
      final current = await _lockedRequest(session, requestId);
      if (current == null) return _fail(404, 'not_found', 'Транш не найден.');
      if (current.version != version || current.status != 'approved') {
        return _fail(409, 'conflict', withdrawMessage);
      }
      if (reason.trim().isEmpty) return _fail(400, 'validation', reasonMessage);
      if (!unpaidConfirmed) return _fail(400, 'validation', unpaidConfirmMessage);
      return _move(
        session,
        userId: userId,
        requestId: requestId,
        version: version,
        key: key,
        fingerprint: fingerprint,
        role: 'observer',
        from: 'approved',
        to: 'cancelled',
        action: 'approval_withdrawn',
        ownerOnly: false,
        wrongStatus: withdrawMessage,
        reason: reason.trim(),
      );
    },
  );
}

Future<LifeReply> copyRejected(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
}) {
  return _run(
    db,
    userId: userId,
    requestId: requestId,
    key: key,
    fingerprint: fingerprint,
    role: 'contractor',
    allow: const {'contractor', 'director'},
    work: (session) => _copy(
      session,
      userId: userId,
      requestId: requestId,
      version: version,
      key: key,
      fingerprint: fingerprint,
    ),
  );
}

typedef _Work = Future<LifeReply> Function(Session session);

Future<LifeReply> _run(
  AppDatabase db, {
  required String userId,
  required String requestId,
  required String key,
  required String fingerprint,
  required String role,
  Set<String>? allow,
  required _Work work,
}) async {
  final seen = await replay(db, userId, key, fingerprint);
  if (seen != null) return seen;
  try {
    return await db.pool.runTx((session) async {
      final again = await _readKey(session, userId, key);
      if (again != null) {
        if (again.fingerprint != fingerprint) throw KeyReused();
        return again.reply;
      }
      final access = await _role(session, userId, requestId);
      if (access == null) return _fail(404, 'not_found', 'Транш не найден.');
      final allowed = allow ?? {role};
      if (access != 'developer' && !allowed.contains(access)) {
        if (access == 'contractor') return _fail(404, 'not_found', 'Транш не найден.');
        return _fail(403, 'forbidden', 'У вас нет прав на это действие.');
      }
      await _lockLine(session, requestId);
      return work(session);
    });
  } on ServerException catch (error) {
    if (error.code != '23505') rethrow;
    final stored = await replay(db, userId, key, fingerprint);
    if (stored != null) return stored;
    throw KeyReused();
  }
}

Future<LifeReply> _submit(
  Session session,
  String userId,
  String requestId,
  int version,
  String key,
  String fingerprint,
  String addresseeUserId,
) async {
  final current = await _lockedRequest(session, requestId);
  if (current == null) return _fail(404, 'not_found', 'Транш не найден.');
  if (current.status != 'draft' || current.version != version) {
    return _fail(409, 'conflict', changedMessage);
  }
  final access = await _role(session, userId, requestId);
  if (current.ownerId != userId && access != 'developer') {
    return _fail(403, 'forbidden', 'У вас нет прав на это действие.');
  }
  var forBank = false;
  var auditReason = '';
  if (addresseeUserId.isNotEmpty) {
    final person = await _member(session, requestId, addresseeUserId);
    if (person == null) return _fail(404, 'not_found', 'Транш не найден.');
    if (person.role != 'tech' && person.role != 'observer') {
      return _fail(400, 'validation', addresseeRoleMessage);
    }
    forBank = person.role == 'observer';
    auditReason = forBank ? 'В банк: ${person.name}' : person.name;
  }
  final photos = await session.execute(
    Sql.named('''
      SELECT COUNT(*) FROM request_files
      WHERE request_id = @requestId::uuid
        AND purpose = 'material'
        AND content_type LIKE 'image/%'
    '''),
    parameters: {'requestId': requestId},
  );
  if (_asInt(photos.first[0]) < 1) return _fail(400, 'validation', photoMessage);
  final room = await session.execute(
    Sql.named('''
      SELECT
        (CASE WHEN bi.plan_set THEN bi.planned_amount ELSE 0 END
          - COALESCE((
              SELECT SUM(fr.amount) FROM funding_requests fr
              WHERE fr.budget_item_id = bi.id
                AND fr.status IN ('submitted', 'tech_approved', 'approved')
            ), 0)
          - COALESCE((
              SELECT SUM(fr.amount) FROM funding_requests fr
              WHERE fr.budget_item_id = bi.id AND fr.status = 'paid'
            ), 0)
        ) >= @amount::numeric AS fits,
        to_char(
          CASE WHEN bi.plan_set THEN bi.planned_amount ELSE 0 END
            - COALESCE((
                SELECT SUM(fr.amount) FROM funding_requests fr
                WHERE fr.budget_item_id = bi.id
                  AND fr.status IN ('submitted', 'tech_approved', 'approved')
              ), 0)
            - COALESCE((
                SELECT SUM(fr.amount) FROM funding_requests fr
                WHERE fr.budget_item_id = bi.id AND fr.status = 'paid'
              ), 0),
          'FM999999999999990.00'
        ) AS available
      FROM budget_items bi
      WHERE bi.id = @itemId::uuid
    '''),
    parameters: {'amount': current.amount, 'itemId': current.itemId},
  );
  final fit = room.first.toColumnMap();
  if (!_asBool(fit['fits'])) {
    final reply = _fail(409, 'over_limit', overLimitMessage, available: fit['available'] as String);
    await _remember(session, userId, key, fingerprint, reply);
    return reply;
  }
  final updated = await session.execute(
    Sql.named('''
      UPDATE funding_requests
      SET status = 'submitted',
          version = version + 1,
          updated_at = now(),
          addressee_user_id = NULLIF(@addressee, '')::uuid,
          for_bank = @forBank,
          tranche_no = COALESCE(funding_requests.tranche_no, next_tranche_no(funding_requests.project_id))
      WHERE id = @requestId::uuid AND status = 'draft' AND version = @version
      RETURNING id::text
    '''),
    parameters: {
      'requestId': requestId,
      'version': version,
      'addressee': addresseeUserId,
      'forBank': forBank,
    },
  );
  if (updated.isEmpty) return _fail(409, 'conflict', changedMessage);
  await _audit(
    session,
    projectId: current.projectId,
    requestId: requestId,
    userId: userId,
    action: 'submitted',
    oldStatus: 'draft',
    newStatus: 'submitted',
    amount: current.amount,
    reason: auditReason,
  );
  final reply = LifeReply(200, jsonEncode(await _snapshot(session, userId, requestId)));
  await _remember(session, userId, key, fingerprint, reply);
  return reply;
}

Future<LifeReply> _deliver(
  Session session, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
  required String addresseeUserId,
}) async {
  final current = await _lockedRequest(session, requestId);
  if (current == null) return _fail(404, 'not_found', 'Транш не найден.');
  const open = {'submitted', 'tech_approved', 'approved'};
  if (!open.contains(current.status) || current.version != version) {
    return _fail(409, 'conflict', forwardStatusMessage);
  }
  final person = await _member(session, requestId, addresseeUserId);
  if (person == null) return _fail(404, 'not_found', 'Транш не найден.');
  final access = await _role(session, userId, requestId);
  if (person.role == 'observer') {
    if (access != 'director' && access != 'developer') {
      return _fail(403, 'forbidden', 'У вас нет прав на это действие.');
    }
    if (current.status != 'approved') return _fail(400, 'validation', bankEarlyMessage);
    final sent = await session.execute(
      Sql.named('SELECT bank_sent_at IS NOT NULL FROM funding_requests WHERE id = @requestId::uuid'),
      parameters: {'requestId': requestId},
    );
    if (_asBool(sent.first[0])) return _fail(409, 'conflict', bankAgainMessage);
    final updated = await session.execute(
      Sql.named('''
        UPDATE funding_requests
        SET addressee_user_id = @addressee::uuid,
            for_bank = true,
            bank_sent_at = now(),
            version = version + 1,
            updated_at = now()
        WHERE id = @requestId::uuid AND status = 'approved' AND version = @version
        RETURNING id::text
      '''),
      parameters: {'requestId': requestId, 'addressee': addresseeUserId, 'version': version},
    );
    if (updated.isEmpty) return _fail(409, 'conflict', changedMessage);
    await _audit(
      session,
      projectId: current.projectId,
      requestId: requestId,
      userId: userId,
      action: 'sent_to_bank',
      oldStatus: 'approved',
      newStatus: 'approved',
      amount: current.amount,
      reason: person.name,
    );
  } else if (person.role == 'tech' || person.role == 'director') {
    if (addresseeUserId == userId) return _fail(400, 'validation', forwardSelfMessage);
    final updated = await session.execute(
      Sql.named('''
        UPDATE funding_requests
        SET addressee_user_id = @addressee::uuid,
            version = version + 1,
            updated_at = now()
        WHERE id = @requestId::uuid AND status = @status AND version = @version
        RETURNING id::text
      '''),
      parameters: {
        'requestId': requestId,
        'addressee': addresseeUserId,
        'status': current.status,
        'version': version,
      },
    );
    if (updated.isEmpty) return _fail(409, 'conflict', changedMessage);
    await _audit(
      session,
      projectId: current.projectId,
      requestId: requestId,
      userId: userId,
      action: 'forwarded',
      oldStatus: current.status,
      newStatus: current.status,
      amount: current.amount,
      reason: person.name,
    );
  } else {
    return _fail(400, 'validation', person.role == 'observer' ? bankRoleMessage : forwardMessage);
  }
  final reply = LifeReply(200, jsonEncode(await _snapshot(session, userId, requestId)));
  await _remember(session, userId, key, fingerprint, reply);
  return reply;
}

class _Person {
  _Person(this.role, this.name);
  final String role;
  final String name;
}

Future<_Person?> _member(Session session, String requestId, String userId) async {
  final rows = await session.execute(
    Sql.named('''
      SELECT m.role, u.name
      FROM project_members m
      JOIN users u ON u.id = m.user_id
      JOIN funding_requests fr ON fr.project_id = m.project_id
      WHERE fr.id = @requestId::uuid AND m.user_id = @userId::uuid
    '''),
    parameters: {'requestId': requestId, 'userId': userId},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  return _Person(map['role'] as String, map['name'] as String);
}

Future<LifeReply> _move(
  Session session, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
  required String role,
  required String from,
  List<String>? acceptFrom,
  required String to,
  required String action,
  required bool ownerOnly,
  required String wrongStatus,
  String? reason,
  String? submittedMeans,
  String mark = '',
}) async {
  final current = await _lockedRequest(session, requestId);
  if (current == null) return _fail(404, 'not_found', 'Транш не найден.');
  final access = await _role(session, userId, requestId);
  if (ownerOnly && current.ownerId != userId && access != 'developer') {
    return _fail(404, 'not_found', 'Транш не найден.');
  }
  final sources = acceptFrom ?? [from];
  if (current.version != version || !sources.contains(current.status)) {
    final message = current.status == 'submitted' && submittedMeans != null
        ? submittedMeans
        : wrongStatus;
    if (current.version != version && sources.contains(current.status)) {
      return _fail(409, 'conflict', changedMessage);
    }
    return _fail(409, 'conflict', message);
  }
  final updated = await session.execute(
    Sql.named('''
      UPDATE funding_requests
      SET status = @to,
          version = version + 1,
          updated_at = now(),
          decision = CASE WHEN @mark = '' THEN decision ELSE @mark END,
          amount = CASE
            WHEN @to = 'approved' THEN COALESCE(confirmed_amount, amount)
            ELSE amount
          END
      WHERE id = @requestId::uuid AND status = @from AND version = @version
      RETURNING id::text
    '''),
    parameters: {
      'requestId': requestId,
      'to': to,
      'from': current.status,
      'version': version,
      'mark': mark,
    },
  );
  if (updated.isEmpty) return _fail(409, 'conflict', changedMessage);
  await _audit(
    session,
    projectId: current.projectId,
    requestId: requestId,
    userId: userId,
    action: action,
    oldStatus: current.status,
    newStatus: to,
    amount: current.amount,
    reason: reason ?? '',
  );
  final reply = LifeReply(200, jsonEncode(await _snapshot(session, userId, requestId)));
  await _remember(session, userId, key, fingerprint, reply);
  return reply;
}

Future<LifeReply> _pay(
  Session session, {
  required String userId,
  required String requestId,
  required int version,
  required String paidOn,
  required String paymentNumber,
  required String key,
  required String fingerprint,
}) async {
  final current = await _lockedRequest(session, requestId);
  if (current == null) return _fail(404, 'not_found', 'Транш не найден.');
  if (current.version != version || current.status != 'approved') {
    final message = current.status == 'approved' ? changedMessage : paymentStatusMessage;
    return _fail(409, 'conflict', message);
  }
  final number = paymentNumber.trim();
  if (!_realDate(paidOn) || number.isEmpty || number.length > 40) {
    return _fail(400, 'validation', paymentFieldsMessage);
  }
  final proofs = await session.execute(
    Sql.named('''
      SELECT COUNT(*) FROM request_files
      WHERE request_id = @requestId::uuid AND purpose = 'payment'
    '''),
    parameters: {'requestId': requestId},
  );
  if (_asInt(proofs.first[0]) < 1) return _fail(400, 'validation', paymentProofMessage);
  final updated = await session.execute(
    Sql.named('''
      UPDATE funding_requests
      SET status = 'paid',
          version = version + 1,
          paid_on = @paidOn::date,
          payment_number = @number,
          updated_at = now()
      WHERE id = @requestId::uuid AND status = 'approved' AND version = @version
      RETURNING id::text
    '''),
    parameters: {
      'requestId': requestId,
      'version': version,
      'paidOn': paidOn,
      'number': number,
    },
  );
  if (updated.isEmpty) return _fail(409, 'conflict', changedMessage);
  await _audit(
    session,
    projectId: current.projectId,
    requestId: requestId,
    userId: userId,
    action: 'paid',
    oldStatus: 'approved',
    newStatus: 'paid',
    amount: current.amount,
    reason: number,
  );
  final reply = LifeReply(200, jsonEncode(await _snapshot(session, userId, requestId)));
  await _remember(session, userId, key, fingerprint, reply);
  return reply;
}

Future<LifeReply> _copy(
  Session session, {
  required String userId,
  required String requestId,
  required int version,
  required String key,
  required String fingerprint,
}) async {
  final current = await _lockedRequest(session, requestId);
  final access = await _role(session, userId, requestId);
  if (current == null || (current.ownerId != userId && access != 'developer')) {
    return _fail(404, 'not_found', 'Транш не найден.');
  }
  if (current.version != version || current.status != 'rejected') {
    return _fail(409, 'conflict', copyStatusMessage);
  }
  final inserted = await session.execute(
    Sql.named('''
      INSERT INTO funding_requests (
        project_id, budget_item_id, contractor_user_id, author_user_id,
        amount, description, status, source_request_id
      )
      SELECT project_id, budget_item_id, @userId::uuid, @userId::uuid,
             amount, description, 'draft', id
      FROM funding_requests
      WHERE id = @requestId::uuid
        AND status = 'rejected'
      RETURNING id::text, project_id::text, amount::text
    '''),
    parameters: {'requestId': requestId, 'userId': userId},
  );
  if (inserted.isEmpty) return _fail(409, 'conflict', copyStatusMessage);
  final created = inserted.first.toColumnMap();
  final newId = created['id'] as String;
  await _audit(
    session,
    projectId: '${created['project_id']}',
    requestId: newId,
    userId: userId,
    action: 'draft_saved',
    oldStatus: '',
    newStatus: 'draft',
    amount: '${created['amount']}',
  );
  final reply = LifeReply(201, jsonEncode(await _snapshot(session, userId, newId)));
  await _remember(session, userId, key, fingerprint, reply);
  return reply;
}

bool _realDate(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return false;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (year < 2020 || year > 2100) return false;
  final parsed = DateTime.utc(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day;
}

Future<void> _lockLine(Session session, String requestId) {
  return session.execute(
    Sql.named('''
      SELECT bi.id
      FROM budget_items bi
      JOIN funding_requests fr ON fr.budget_item_id = bi.id
      WHERE fr.id = @requestId::uuid
      FOR UPDATE OF bi
    '''),
    parameters: {'requestId': requestId},
  );
}

Future<String?> _role(Session session, String userId, String requestId) async {
  final rows = await session.execute(
    Sql.named('''
      SELECT m.role
      FROM funding_requests fr
      JOIN project_members m
        ON m.project_id = fr.project_id AND m.user_id = @userId::uuid
      WHERE fr.id = @requestId::uuid
    '''),
    parameters: {'userId': userId, 'requestId': requestId},
  );
  if (rows.isEmpty) return null;
  return rows.first[0]! as String;
}

class _Held {
  _Held({
    required this.status,
    required this.version,
    required this.amount,
    required this.projectId,
    required this.itemId,
    required this.ownerId,
  });

  final String status;
  final int version;
  final String amount;
  final String projectId;
  final String itemId;
  final String ownerId;
}

Future<_Held?> _lockedRequest(Session session, String requestId) async {
  final rows = await session.execute(
    Sql.named('''
      SELECT status,
             version,
             to_char(amount, 'FM999999999999990.00') AS amount,
             project_id::text AS project_id,
             budget_item_id::text AS budget_item_id,
             contractor_user_id::text AS owner_id
      FROM funding_requests
      WHERE id = @requestId::uuid
      FOR UPDATE
    '''),
    parameters: {'requestId': requestId},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  return _Held(
    status: map['status'] as String,
    version: _asInt(map['version']),
    amount: map['amount'] as String,
    projectId: map['project_id'] as String,
    itemId: map['budget_item_id'] as String,
    ownerId: map['owner_id'] as String,
  );
}

Future<Map<String, Object?>> _snapshot(Session session, String userId, String requestId) async {
  final rows = await session.execute(
    Sql.named('''
      SELECT fr.id::text AS id,
             fr.project_id::text AS project_id,
             p.name AS project_name,
             fr.budget_item_id::text AS budget_item_id,
             bi.title AS line_title,
             to_char(fr.amount, 'FM999999999999990.00') AS amount,
             fr.description AS description,
             fr.status AS status,
             fr.version AS version,
             to_char(fr.paid_on, 'YYYY-MM-DD') AS paid_on,
             fr.payment_number AS payment_number,
             fr.contractor_user_id::text AS owner_id,
             fr.addressee_user_id::text AS addressee_user_id,
             fr.for_bank AS for_bank,
             (fr.bank_sent_at IS NOT NULL) AS bank_sent,
             COALESCE((SELECT u.name FROM users u WHERE u.id = fr.addressee_user_id), '') AS addressee_name,
             COALESCE((
               SELECT pm.role FROM project_members pm
               WHERE pm.project_id = fr.project_id AND pm.user_id = fr.addressee_user_id
             ), '') AS addressee_role,
             $requestTrancheColumns
      FROM funding_requests fr
      JOIN projects p ON p.id = fr.project_id
      JOIN budget_items bi ON bi.id = fr.budget_item_id
      WHERE fr.id = @requestId::uuid
    '''),
    parameters: {'requestId': requestId},
  );
  final map = rows.first.toColumnMap();
  final files = await session.execute(
    Sql.named('''
      SELECT id::text AS id, content_type, size_bytes, purpose
      FROM request_files
      WHERE request_id = @requestId::uuid
      ORDER BY created_at
    '''),
    parameters: {'requestId': requestId},
  );
  final events = await session.execute(
    Sql.named('''
      SELECT ae.action AS action,
             ae.old_status AS old_status,
             ae.new_status AS new_status,
             COALESCE(ae.reason, '') AS reason,
             to_char(ae.amount, 'FM999999999999990.00') AS amount,
             ae.created_at AS created_at,
             COALESCE(u.name, '') AS author_name
      FROM audit_events ae
      LEFT JOIN users u ON u.id = ae.author_user_id
      WHERE ae.request_id = @requestId::uuid
      ORDER BY ae.created_at, ae.id
    '''),
    parameters: {'requestId': requestId},
  );
  return {
    'id': map['id'],
    'projectId': map['project_id'],
    'projectName': map['project_name'],
    'budgetItemId': map['budget_item_id'],
    'lineTitle': map['line_title'],
    'amount': map['amount'],
    'description': map['description'] ?? '',
    'status': map['status'],
    'mine': map['owner_id'] == userId,
    'version': _asInt(map['version']),
    'paidOn': map['paid_on'],
    'paymentNumber': map['payment_number'],
    'addresseeUserId': map['addressee_user_id'],
    'addresseeName': (map['addressee_name'] as String?)?.isEmpty == true
        ? null
        : map['addressee_name'],
    'addresseeRole': (map['addressee_role'] as String?)?.isEmpty == true
        ? null
        : map['addressee_role'],
    'forBank': _asBool(map['for_bank']),
    'bankSent': _asBool(map['bank_sent']),
    'trancheNo': map['tranche_no'] == null ? null : _asInt(map['tranche_no']),
    'confirmedAmount': map['confirmed_amount'],
    'decision': (map['decision'] as String?)?.isEmpty == true ? null : map['decision'],
    'fundingPaused': _asBool(map['funding_paused']),
    'linePlan': map['line_plan'],
    'lineReserved': map['line_reserved'],
    'linePaid': map['line_paid'],
    'lineAvailable': map['line_available'],
    'hasAct': _asBool(map['has_act']),
    'hasInvoice': _asBool(map['has_invoice']),
    'files': [
      for (final row in files)
        () {
          final file = row.toColumnMap();
          final type = file['content_type'] as String;
          return {
            'id': file['id'],
            'contentType': type,
            'sizeBytes': _asInt(file['size_bytes']),
            'kind': type == 'application/pdf' ? 'pdf' : 'photo',
            'purpose': file['purpose'] ?? 'material',
          };
        }(),
    ],
    'events': [
      for (final row in events) RequestEventRecord.fromMap(row.toColumnMap()).toJson(),
    ],
  };
}

Future<void> _audit(
  Session session, {
  required String projectId,
  required String requestId,
  required String userId,
  required String action,
  required String oldStatus,
  required String newStatus,
  required String amount,
  String reason = '',
}) {
  return session.execute(
    Sql.named('''
      INSERT INTO audit_events (
        project_id, request_id, action, old_status, new_status,
        author_user_id, reason, amount
      ) VALUES (
        @projectId::uuid, @requestId::uuid, @action, @oldStatus, @newStatus,
        @userId::uuid, @reason, @amount::numeric
      )
    '''),
    parameters: {
      'projectId': projectId,
      'requestId': requestId,
      'action': action,
      'oldStatus': oldStatus,
      'newStatus': newStatus,
      'userId': userId,
      'reason': reason,
      'amount': amount,
    },
  );
}

class _Stored {
  _Stored(this.fingerprint, this.reply);

  final String fingerprint;
  final LifeReply reply;
}

Future<_Stored?> _readKey(Session session, String userId, String key) async {
  final rows = await session.execute(
    Sql.named('''
      SELECT fingerprint, status_code, body
      FROM idempotency_keys
      WHERE user_id = @userId::uuid AND idempotency_key = @key
    '''),
    parameters: {'userId': userId, 'key': key},
  );
  if (rows.isEmpty) return null;
  final map = rows.first.toColumnMap();
  return _Stored(
    map['fingerprint'] as String,
    LifeReply(_asInt(map['status_code']), map['body'] as String),
  );
}

Future<void> _remember(
  Session session,
  String userId,
  String key,
  String fingerprint,
  LifeReply reply,
) {
  return session.execute(
    Sql.named('''
      INSERT INTO idempotency_keys (user_id, idempotency_key, fingerprint, status_code, body)
      VALUES (@userId::uuid, @key, @fingerprint, @status, @body)
    '''),
    parameters: {
      'userId': userId,
      'key': key,
      'fingerprint': fingerprint,
      'status': reply.status,
      'body': reply.body,
    },
  );
}

LifeReply _fail(int status, String error, String message, {String? available}) {
  return LifeReply(
    status,
    jsonEncode({
      'error': error,
      'message': message,
      if (available != null) 'available': available,
    }),
  );
}

int _asInt(Object? value) {
  if (value is int) return value;
  return int.parse(value.toString());
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  final text = value.toString().toLowerCase();
  return text == 'true' || text == 't';
}
