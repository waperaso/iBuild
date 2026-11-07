import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import 'bank_common.dart';
import 'db.dart';
import 'http_util.dart';

/// Shared parts of the screens of the bank that read across tranches: who is
/// asking, which bank, and a plain way to read rows as JSON.
///
/// These reads run as the system after the person and the bank are known, and
/// every query is filtered by the bank of the person. That keeps the portfolio
/// queries simple; the data of other banks is never selected.

const bankToday = "(now() AT TIME ZONE 'Asia/Tashkent')::date";
const bankMoney = "'FM999999999999990.00'";

class BankCtx {
  const BankCtx(this.session, this.actor);

  final SessionLookup session;
  final BankActor actor;

  String get bankId => actor.bankId;
}

/// A person of a bank, or the answer to send back. [roles] limits who may ask.
Future<Object> bankContext(
  Request request,
  AppDatabase db, {
  bool mutating = false,
  Set<String>? roles,
}) async {
  final opened = mutating ? await bankMutating(request, db) : await bankSession(request, db);
  if (opened is Response) return opened;
  final session = opened as SessionLookup;
  final actor = await bankActor(db, session.user!);
  if (actor == null) return jsonError(404, 'not_found', 'Не найдено');
  if (roles != null && !roles.contains(actor.role)) {
    return jsonError(403, 'forbidden', 'У вашей роли нет доступа к этому разделу');
  }
  return BankCtx(session, actor);
}

Object? bankJson(Object? value) {
  if (value is DateTime) return value.toUtc().toIso8601String();
  if (value is BigInt) return value.toInt();
  if (value is Map) return value.map((key, item) => MapEntry(key.toString(), bankJson(item)));
  if (value is List) return [for (final item in value) bankJson(item)];
  if (value == null || value is num || value is bool || value is String) return value;
  return value.toString();
}

/// A calendar day as "YYYY-MM-DD", or null.
String? bankDay(Object? value) {
  if (value is! DateTime) return null;
  final day = value.toUtc();
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

Future<List<Map<String, Object?>>> bankRows(
  AppDatabase db,
  String sql, [
  Map<String, Object?> params = const {},
]) async {
  // The driver refuses parameters that the query does not use; the filters are shared.
  final used = {for (final m in RegExp(r'@([a-zA-Z_][a-zA-Z0-9_]*)').allMatches(sql)) m.group(1)!};
  final rows = await db.owner.execute(
    Sql.named(sql),
    parameters: {for (final e in params.entries) if (used.contains(e.key)) e.key: e.value},
  );
  return [
    for (final row in rows)
      row.toColumnMap().map((key, value) => MapEntry(key, value)),
  ];
}

Response bankOk(Map<String, Object?> body) =>
    jsonResponse(200, bankJson(body)! as Map<String, Object?>);

Future<Map<String, Object?>?> bankBody(Request request) async {
  final limited = await readAtMost(request.read(), 1024 * 1024);
  if (limited.overflow) throw const BodyTooLarge();
  final text = utf8.decode(limited.bytes);
  if (text.isEmpty) return const {};
  try {
    final decoded = jsonDecode(text);
    if (decoded is! Map) return null;
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  } catch (_) {
    return null;
  }
}

/// A calendar date from the user as "YYYY-MM-DD", or null when it is not a real
/// day. The text is kept as written: parsing it as a local midnight and then
/// converting to UTC moves the day for anyone east of UTC.
String? bankDateInput(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final parts = value.split('-');
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  final check = DateTime.utc(year, month, day);
  if (check.year != year || check.month != month || check.day != day) return null;
  return value;
}

Future<void> bankEvent(
  AppDatabase db,
  BankCtx ctx,
  String action, {
  String? trancheId,
  String? projectId,
  Map<String, Object?> detail = const {},
}) async {
  await db.owner.execute(
    Sql.named('''
      INSERT INTO bank_audit_events (bank_id, tranche_id, project_id, user_id, actor_label, action, detail)
      VALUES (@bank::uuid, @tranche::uuid, @project::uuid, @user::uuid, @label, @action, @detail::jsonb)
    '''),
    parameters: {
      'bank': ctx.bankId,
      'tranche': trancheId,
      'project': projectId,
      'user': ctx.actor.userId,
      'label': ctx.actor.name,
      'action': action,
      'detail': jsonEncode(detail),
    },
  );
}
