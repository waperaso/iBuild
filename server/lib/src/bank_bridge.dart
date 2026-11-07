import 'dart:io';

import 'package:postgres/postgres.dart';

import 'bank_common.dart';
import 'bank_rules.dart';
import 'bank_rules_api.dart' show ensureBankDefaults;
import 'db.dart';

/// The bridge between the draw of the developer and the tranche of the bank.
///
/// A draw that is submitted becomes a tranche of the bank, with lines taken from
/// the draw, checks produced by the rules of the bank and the clock started on
/// the real moment. It runs after the developer's own transaction has been
/// committed, as the system (owner connection), and never breaks the developer's
/// action: a failure is written to the log and the next change repairs it.

const _openStages = ['submitted', 'docs', 'inspection', 'specialist'];

/// Brings the bank tranche of one draw in line with the draw. Safe to call as
/// often as needed.
Future<void> bankSyncRequest(AppDatabase db, String requestId) async {
  try {
    await db.owner.runTx((tx) => _sync(tx, requestId));
  } catch (error, stack) {
    stderr.writeln('bank bridge failed for draw $requestId: $error\n$stack');
  }
}

/// Every draw that waits for the bank. Used on start and after changes that
/// touch many draws at once.
Future<void> bankReconcile(AppDatabase db) async {
  try {
    final rows = await db.owner.execute(
      Sql.named('''
        SELECT fr.id::text
        FROM funding_requests fr
        JOIN project_facilities f ON f.project_id = fr.project_id
        WHERE fr.status IN ('submitted', 'tech_approved')
           OR (fr.id IN (SELECT request_id FROM bank_tranches WHERE request_id IS NOT NULL)
               AND fr.status IN ('approved', 'paid'))
        ORDER BY fr.created_at
      '''),
    );
    for (final row in rows) {
      await bankSyncRequest(db, row[0]! as String);
    }
  } catch (error, stack) {
    stderr.writeln('bank reconcile failed: $error\n$stack');
  }
}

String _money(Object? value) => (value ?? '0.00').toString();

Future<void> _sync(Session tx, String requestId) async {
  final draw = await tx.execute(
    Sql.named('''
      SELECT fr.id::text AS id,
             fr.project_id::text AS project_id,
             fr.status AS status,
             fr.tranche_no AS tranche_no,
             COALESCE(
               (SELECT min(a.created_at) FROM audit_events a
                WHERE a.request_id = fr.id AND a.action = 'submitted'),
               fr.created_at
             ) AS submitted_at,
             fr.requested_amount AS requested_amount
      FROM funding_requests fr
      WHERE fr.id = @id::uuid
    '''),
    parameters: {'id': requestId},
  );
  if (draw.isEmpty) return;
  final head = draw.first.toColumnMap();
  final status = head['status'] as String;
  final projectId = head['project_id'] as String;

  final facilityRows = await tx.execute(
    Sql.named('''
      SELECT bank_id::text AS bank_id,
             to_char(credit_limit - issued_amount, $bankMoneyFormat) AS limit_left,
             funding_paused
      FROM project_facilities WHERE project_id = @project::uuid
      ORDER BY bank_id LIMIT 1
    '''),
    parameters: {'project': projectId},
  );
  if (facilityRows.isEmpty) return;
  final facility = facilityRows.first.toColumnMap();
  final bankId = facility['bank_id'] as String;

  final existing = await tx.execute(
    Sql.named('''
      SELECT id::text AS id, stage, waiting_developer, outcome, rules_version_id::text AS rules
      FROM bank_tranches WHERE request_id = @id::uuid FOR UPDATE
    '''),
    parameters: {'id': requestId},
  );

  final bool created;
  final String trancheId;
  if (existing.isEmpty) {
    if (status != 'submitted' && status != 'tech_approved') return;
    trancheId = await _create(tx, head, bankId);
    created = true;
  } else {
    final row = existing.first.toColumnMap();
    trancheId = row['id'] as String;
    created = false;
    final frozen = row['outcome'] != null ||
        row['waiting_developer'] == true ||
        !_openStages.contains(row['stage']);
    if (frozen) return;
  }

  final rulesRows = await tx.execute(
    Sql.named('''
      SELECT v.snapshot AS snapshot
      FROM bank_tranches t JOIN bank_rule_versions v ON v.id = t.rules_version_id
      WHERE t.id = @id::uuid
    '''),
    parameters: {'id': trancheId},
  );
  final rules = Map<String, Object?>.from(rulesRows.first[0]! as Map);

  final lines = await _syncLines(tx, trancheId, requestId);
  final inspected = lines.any((line) => line.inspected);

  // The check list is produced from the real data of the draw.
  final requirements = <String, String>{};
  final requirementRows = await tx.execute(
    Sql.named('''
      SELECT c.code, r.status
      FROM draw_requirements r JOIN checklist_items c ON c.id = r.item_id
      WHERE r.request_id = @id::uuid
    '''),
    parameters: {'id': requestId},
  );
  for (final row in requirementRows) {
    requirements[row[0]! as String] = row[1]! as String;
  }
  final payables = <RulePayable>[];
  final payableRows = await tx.execute(
    Sql.named('SELECT number, waiver FROM payables WHERE request_id = @id::uuid ORDER BY created_at'),
    parameters: {'id': requestId},
  );
  for (final row in payableRows) {
    payables.add(RulePayable(number: row[0]! as String, signed: row[1] == 'signed'));
  }

  var confirmedCents = BigInt.zero;
  for (final line in lines) {
    confirmedCents += bankCentsOf(line.confirmed ?? '0.00');
  }
  final confirmedText = _centsText(confirmedCents);
  final results = evaluateBankRules(RuleInput(
    today: DateTime.now().toUtc(),
    rules: rules,
    lines: lines,
    payables: payables,
    requirements: requirements,
    limitLeft: _money(facility['limit_left']),
    issue: confirmedText,
    fundingPaused: facility['funding_paused'] == true,
    inspected: inspected,
  ));
  await _writeChecks(tx, trancheId, results);

  await tx.execute(
    Sql.named('''
      UPDATE bank_tranche_lines l
      SET block_check_id = (
        SELECT c.id FROM bank_checks c
        WHERE c.tranche_id = l.tranche_id AND c.code = @code
      )
      WHERE l.tranche_id = @id::uuid AND l.budget_item_id = ANY(@items::uuid[])
    '''),
    parameters: {
      'id': trancheId,
      'code': 'certificate',
      'items': [
        for (final result in results)
          if (result.code == 'certificate') ...result.lineIds,
      ],
    },
  );
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranche_lines
      SET block_check_id = NULL
      WHERE tranche_id = @id::uuid AND block_check_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM bank_checks c WHERE c.id = block_check_id)
    '''),
    parameters: {'id': trancheId},
  );

  final techDate = status == 'tech_approved' ? 'COALESCE(tech_confirmed_on, current_date)' : 'tech_confirmed_on';
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET requested_amount = COALESCE((
            SELECT SUM(requested) FROM bank_tranche_lines WHERE tranche_id = @id::uuid
          ), 0),
          tech_confirmed_on = $techDate
      WHERE id = @id::uuid
    '''),
    parameters: {'id': trancheId},
  );

  // Moves from the wait for inspection to the work of the specialist.
  final moved = await _advance(tx, trancheId, bankId, inspected);
  await bankRecompute(tx, trancheId);
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET signal = CASE WHEN signal = 'none' THEN 'inspection' ELSE signal END,
          problems_label = CASE WHEN problems_label = '' THEN 'Ждёт осмотра' ELSE problems_label END
      WHERE id = @id::uuid AND stage = 'inspection'
    '''),
    parameters: {'id': trancheId},
  );

  if (created) {
    await bankAudit(
      tx,
      bankId: bankId,
      trancheId: trancheId,
      actorLabel: 'Система',
      action: 'tranche_created',
      detail: {'source': 'developer_draw', 'checks': results.where((r) => !r.passed).length},
    );
  }
  if (moved) {
    await bankAudit(
      tx,
      bankId: bankId,
      trancheId: trancheId,
      actorLabel: 'Система',
      action: 'inspection_reported',
      detail: {'stage': 'specialist'},
    );
  }
}

BigInt bankCentsOf(String amount) {
  final parts = amount.split('.');
  final fraction = (parts.length == 2 ? parts[1] : '').padRight(2, '0').substring(0, 2);
  return BigInt.parse('${parts[0]}$fraction');
}

String _centsText(BigInt cents) {
  final text = cents.toString().padLeft(3, '0');
  return '${text.substring(0, text.length - 2)}.${text.substring(text.length - 2)}';
}

Future<String> _create(Session tx, Map<String, Object?> head, String bankId) async {
  final requestId = head['id']! as String;
  final projectId = head['project_id']! as String;
  final inspectedRows = await tx.execute(
    Sql.named('''
      SELECT EXISTS (
        SELECT 1 FROM draw_lines
        WHERE request_id = @id::uuid AND inspector_percent IS NOT NULL
      )
    '''),
    parameters: {'id': requestId},
  );
  final inspected = inspectedRows.first[0] == true;
  final stage = inspected ? 'specialist' : 'inspection';
  final role = inspected ? 'specialist' : 'expert';
  final holder = await tx.execute(
    Sql.named('''
      SELECT s.user_id::text, u.name
      FROM bank_staff s JOIN users u ON u.id = s.user_id
      WHERE s.bank_id = @bank::uuid AND s.role = @role AND s.active
      ORDER BY (
        SELECT count(*) FROM bank_tranches t
        WHERE t.holder_user_id = s.user_id AND t.outcome IS NULL
      ), u.name
      LIMIT 1
    '''),
    parameters: {'bank': bankId, 'role': role},
  );
  final holderId = holder.isEmpty ? null : holder.first[0] as String;
  final holderName = holder.isEmpty ? '' : holder.first[1]! as String;
  await ensureBankDefaults(tx, bankId);
  final rulesRows = await tx.execute(
    Sql.named('''
      SELECT id::text FROM bank_rule_versions
      WHERE bank_id = @bank::uuid AND effective_from <= current_date
      ORDER BY version DESC LIMIT 1
    '''),
    parameters: {'bank': bankId},
  );
  if (rulesRows.isEmpty) throw StateError('the bank has no rule version');
  final rulesId = rulesRows.first[0]! as String;
  final number = await tx.execute(
    Sql.named('''
      SELECT COALESCE(MAX(tranche_no), 0) + 1
      FROM bank_tranches WHERE project_id = @project::uuid AND bank_id = @bank::uuid
    '''),
    parameters: {'project': projectId, 'bank': bankId},
  );
  var trancheNo = (head['tranche_no'] as int?) ?? 0;
  final taken = await tx.execute(
    Sql.named('''
      SELECT 1 FROM bank_tranches
      WHERE project_id = @project::uuid AND bank_id = @bank::uuid AND tranche_no = @no
    '''),
    parameters: {'project': projectId, 'bank': bankId, 'no': trancheNo},
  );
  if (trancheNo <= 0 || taken.isNotEmpty) trancheNo = (number.first[0]! as int);
  final order = await tx.execute(
    Sql.named('SELECT COALESCE(MAX(sort_order), 0) + 1 FROM bank_tranches WHERE bank_id = @bank::uuid'),
    parameters: {'bank': bankId},
  );
  final submitted = head['submitted_at'] as DateTime;
  final label = inspected ? 'Решение специалиста' : 'Осмотр эксперта';
  final holderLabel = holderName.isEmpty
      ? ''
      : (inspected ? '$holderName, кредитный специалист' : '$holderName, эксперт');
  final rows = await tx.execute(
    Sql.named('''
      INSERT INTO bank_tranches (
        project_id, bank_id, rules_version_id, tranche_no, stage, stage_label, sort_order,
        holder_user_id, holder_label, sla_days, submitted_at, stage_entered_at, request_id
      ) VALUES (
        @project::uuid, @bank::uuid, @rules::uuid, @no, @stage, @label, @sort,
        @holder::uuid, @holderLabel, bank_stage_days(@rules::uuid, @stage, 3),
        @submitted, now(), @request::uuid
      )
      RETURNING id::text
    '''),
    parameters: {
      'project': projectId,
      'bank': bankId,
      'rules': rulesId,
      'no': trancheNo,
      'stage': stage,
      'label': label,
      'sort': order.first[0]! as int,
      'holder': holderId,
      'holderLabel': holderLabel,
      'submitted': submitted,
      'request': requestId,
    },
  );
  final id = rows.first[0]! as String;
  await tx.execute(
    Sql.named('''
      INSERT INTO bank_tranche_clock (tranche_id, stage, started_at, paused)
      VALUES (@id::uuid, @stage, now(), false)
    '''),
    parameters: {'id': id, 'stage': stage},
  );
  await tx.execute(
    Sql.named('''
      INSERT INTO bank_approval_steps (tranche_id, code, position, status, required_approvals, note)
      VALUES
        (@id::uuid, 'expert', 1, 'pending', 1, ''),
        (@id::uuid, 'specialist', 2, 'pending', 1, ''),
        (@id::uuid, 'head', 3, 'pending', 1, ''),
        (@id::uuid, 'committee', 4, 'skipped', 1, ''),
        (@id::uuid, 'sign', 5, 'pending', 1, ''),
        (@id::uuid, 'payment', 6, 'pending', 1, '')
    '''),
    parameters: {'id': id},
  );
  return id;
}

/// The inspection of the expert came in: the tranche goes to the specialist.
Future<bool> _advance(Session tx, String id, String bankId, bool inspected) async {
  if (!inspected) return false;
  final rows = await tx.execute(
    Sql.named('SELECT stage FROM bank_tranches WHERE id = @id::uuid'),
    parameters: {'id': id},
  );
  if (rows.first[0] != 'inspection') return false;
  final holder = await tx.execute(
    Sql.named('''
      SELECT s.user_id::text, u.name
      FROM bank_staff s JOIN users u ON u.id = s.user_id
      WHERE s.bank_id = @bank::uuid AND s.role = 'specialist' AND s.active
      ORDER BY (
        SELECT count(*) FROM bank_tranches t
        WHERE t.holder_user_id = s.user_id AND t.outcome IS NULL
      ), u.name
      LIMIT 1
    '''),
    parameters: {'bank': bankId},
  );
  await tx.execute(
    Sql.named('''
      UPDATE bank_approval_steps
      SET status = 'done', decided_at = now(), actor_label = 'Осмотр зафиксирован'
      WHERE tranche_id = @id::uuid AND code = 'expert' AND status = 'pending'
    '''),
    parameters: {'id': id},
  );
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranches
      SET stage = 'specialist',
          stage_label = 'Решение специалиста',
          holder_user_id = @holder::uuid,
          holder_label = @label,
          sla_days = bank_stage_days(rules_version_id, 'specialist', sla_days),
          elapsed_days = 0,
          elapsed_hours = 0
      WHERE id = @id::uuid
    '''),
    parameters: {
      'id': id,
      'holder': holder.isEmpty ? null : holder.first[0],
      'label': holder.isEmpty ? '' : '${holder.first[1]}, кредитный специалист',
    },
  );
  await bankMoveClock(tx, id, 'specialist');
  return true;
}

Future<List<RuleLine>> _syncLines(Session tx, String trancheId, String requestId) async {
  final rows = await tx.execute(
    Sql.named('''
      SELECT dl.budget_item_id::text AS item_id,
             bi.title AS title,
             to_char(dl.requested - dl.retainage_withheld + dl.retainage_released, $bankMoneyFormat) AS net,
             to_char(dl.stored_materials, $bankMoneyFormat) AS stored,
             dl.inspector_percent AS percent,
             to_char(dl.inspector_recommend, $bankMoneyFormat) AS recommend,
             dl.inspector_risk AS risk,
             dl.inspector_comment AS note,
             CASE WHEN bi.plan_set THEN to_char(bi.planned_amount, $bankMoneyFormat) END AS plan,
             cf.name AS firm,
             cf.license_until AS license_until,
             cf.insurance_until AS insurance_until,
             to_char(COALESCE((
               SELECT SUM(COALESCE(o.approved_amount,
                                   o.requested - o.retainage_withheld + o.retainage_released))
               FROM draw_lines o JOIN funding_requests f ON f.id = o.request_id
               WHERE o.budget_item_id = dl.budget_item_id
                 AND f.id <> dl.request_id AND f.status IN ('approved', 'paid')
             ), 0), $bankMoneyFormat) AS issued_before,
             (SELECT il.percent FROM inspection_lines il
              JOIN inspections i ON i.id = il.inspection_id
              WHERE il.budget_item_id = dl.budget_item_id
                AND i.status = 'reported'
                AND i.request_id IS DISTINCT FROM dl.request_id
              ORDER BY i.created_at DESC LIMIT 1) AS previous_percent,
             (SELECT u.name FROM inspections i JOIN users u ON u.id = i.author_user_id
              WHERE i.request_id = dl.request_id AND i.status = 'reported'
              ORDER BY i.created_at DESC LIMIT 1) AS expert_name,
             (SELECT i.created_at::date FROM inspections i
              WHERE i.request_id = dl.request_id AND i.status = 'reported'
              ORDER BY i.created_at DESC LIMIT 1) AS expert_date,
             (SELECT to_char(SUM(p.amount), $bankMoneyFormat) FROM payables p
              WHERE p.request_id = dl.request_id AND p.budget_item_id = dl.budget_item_id) AS payables_sum
      FROM (
        SELECT request_id, budget_item_id, requested, retainage_withheld, retainage_released,
               stored_materials, inspector_percent, inspector_recommend, inspector_risk,
               inspector_comment
        FROM draw_lines WHERE request_id = @id::uuid
        UNION ALL
        -- A draw of the first kind has one line and no list of lines.
        SELECT fr.id, fr.budget_item_id, fr.amount, 0, 0, 0, NULL::numeric, NULL::numeric, '', ''
        FROM funding_requests fr
        WHERE fr.id = @id::uuid
          AND NOT EXISTS (SELECT 1 FROM draw_lines WHERE request_id = fr.id)
      ) dl
      JOIN budget_items bi ON bi.id = dl.budget_item_id
      LEFT JOIN contractor_firms cf ON cf.id = bi.contractor_company_id
      WHERE dl.request_id = @id::uuid
        AND (dl.requested - dl.retainage_withheld + dl.retainage_released > 0 OR dl.stored_materials > 0)
      ORDER BY bi.title
    '''),
    parameters: {'id': requestId},
  );

  final result = <RuleLine>[];
  final kept = <String>[];
  var order = 0;
  for (final row in rows) {
    final map = row.toColumnMap();
    order += 1;
    final itemId = map['item_id']! as String;
    kept.add(itemId);
    final net = _money(map['net']);
    final percent = map['percent'];
    final inspected = percent != null;
    String? confirmed;
    if (inspected) {
      final recommend = map['recommend'] == null ? '0.00' : _money(map['recommend']);
      confirmed = bankCentsOf(recommend) < bankCentsOf(net) ? recommend : net;
    }
    final percentValue = inspected ? double.parse(percent.toString()) : null;
    final previous = map['previous_percent'];
    final note = inspected && previous != null
        ? '${_delta(percentValue!, double.parse(previous.toString()))} с прошлого осмотра'
        : '';
    final plan = map['plan'] as String?;
    String? remaining;
    if (inspected && plan != null && bankCentsOf(plan) > BigInt.zero) {
      final left = bankCentsOf(plan) * BigInt.from(((100 - percentValue!) * 100).round()) ~/ BigInt.from(10000);
      remaining = _centsText(left);
    }
    final stored = _money(map['stored']);
    await tx.execute(
      Sql.named('''
        INSERT INTO bank_tranche_lines (
          tranche_id, budget_item_id, title, sort_order, issued_before, requested,
          readiness_percent, readiness_note, confirmed, plan_amount, previous_percent,
          expert_name, expert_signed_on, expert_note, remaining_to_build, recommended, risk_flag
        ) VALUES (
          @tranche::uuid, @item::uuid, @title, @order, @before::numeric, @requested::numeric,
          @percent::numeric, @note, @confirmed::numeric, @plan::numeric, @previous::numeric,
          @expert, @signed::date, @expertNote, @remaining::numeric, @recommend::numeric, @risk
        )
        ON CONFLICT (tranche_id, budget_item_id) WHERE budget_item_id IS NOT NULL
        DO UPDATE SET title = EXCLUDED.title,
          sort_order = EXCLUDED.sort_order,
          issued_before = EXCLUDED.issued_before,
          requested = EXCLUDED.requested,
          readiness_percent = EXCLUDED.readiness_percent,
          readiness_note = EXCLUDED.readiness_note,
          confirmed = EXCLUDED.confirmed,
          plan_amount = EXCLUDED.plan_amount,
          previous_percent = EXCLUDED.previous_percent,
          expert_name = EXCLUDED.expert_name,
          expert_signed_on = EXCLUDED.expert_signed_on,
          expert_note = EXCLUDED.expert_note,
          remaining_to_build = EXCLUDED.remaining_to_build,
          recommended = EXCLUDED.recommended,
          risk_flag = EXCLUDED.risk_flag
      '''),
      parameters: {
        'tranche': trancheId,
        'item': itemId,
        'title': map['title'],
        'order': order,
        'before': _money(map['issued_before']),
        'requested': net,
        'percent': percentValue?.toStringAsFixed(2),
        'note': note,
        'confirmed': confirmed ?? '0.00',
        'plan': plan,
        'previous': previous?.toString(),
        'expert': inspected ? (map['expert_name'] as String? ?? '') : '',
        'signed': inspected ? (map['expert_date'] as DateTime?)?.toIso8601String().substring(0, 10) : null,
        'expertNote': inspected ? (map['note'] as String? ?? '') : '',
        'remaining': remaining,
        'recommend': inspected ? (map['recommend'] as String?) : null,
        'risk': map['risk'] == 'high',
      },
    );
    result.add(RuleLine(
      itemId: itemId,
      title: map['title']! as String,
      requested: net,
      confirmed: confirmed,
      storedMaterials: stored,
      inspected: inspected,
      firmName: map['firm'] as String?,
      firmLicenseUntil: map['license_until'] as DateTime?,
      firmInsuranceUntil: map['insurance_until'] as DateTime?,
    ));
  }

  await tx.execute(
    Sql.named('''
      DELETE FROM bank_tranche_lines
      WHERE tranche_id = @tranche::uuid AND NOT (budget_item_id = ANY(@kept::uuid[]))
    '''),
    parameters: {'tranche': trancheId, 'kept': kept},
  );
  await _syncLineDetails(tx, trancheId, requestId);
  return result;
}

String _delta(double now, double before) {
  final diff = now - before;
  final text = diff == diff.roundToDouble() ? diff.round().toString() : diff.toStringAsFixed(1);
  return '${diff >= 0 ? '+' : ''}$text%';
}

/// Documents and paid history of every line come from the same real data.
Future<void> _syncLineDetails(Session tx, String trancheId, String requestId) async {
  await tx.execute(
    Sql.named('''
      DELETE FROM bank_line_documents WHERE line_id IN (
        SELECT id FROM bank_tranche_lines WHERE tranche_id = @tranche::uuid)
    '''),
    parameters: {'tranche': trancheId},
  );
  await tx.execute(
    Sql.named('''
      INSERT INTO bank_line_documents (line_id, title, state, sort_order)
      SELECT l.id,
             'Отказ от претензий, счёт ' || p.number,
             CASE WHEN p.waiver = 'signed' THEN 'ok' ELSE 'missing' END,
             row_number() OVER (PARTITION BY l.id ORDER BY p.created_at)
      FROM payables p
      JOIN bank_tranche_lines l
        ON l.budget_item_id = p.budget_item_id AND l.tranche_id = @tranche::uuid
      WHERE p.request_id = @request::uuid
    '''),
    parameters: {'tranche': trancheId, 'request': requestId},
  );
  await tx.execute(
    Sql.named('''
      INSERT INTO bank_line_documents (line_id, title, state, sort_order)
      SELECT l.id,
             'Ведомость материалов на площадке',
             CASE WHEN COALESCE((
               SELECT r.status FROM draw_requirements r
               JOIN checklist_items c ON c.id = r.item_id
               WHERE r.request_id = @request::uuid AND c.code = 'stored_log'
             ), 'missing') = 'missing' THEN 'missing' ELSE 'ok' END,
             0
      FROM bank_tranche_lines l
      JOIN draw_lines dl ON dl.budget_item_id = l.budget_item_id AND dl.request_id = @request::uuid
      WHERE l.tranche_id = @tranche::uuid AND dl.stored_materials > 0
    '''),
    parameters: {'tranche': trancheId, 'request': requestId},
  );
  await tx.execute(
    Sql.named('''
      DELETE FROM bank_line_payments WHERE line_id IN (
        SELECT id FROM bank_tranche_lines WHERE tranche_id = @tranche::uuid)
    '''),
    parameters: {'tranche': trancheId},
  );
  await tx.execute(
    Sql.named('''
      INSERT INTO bank_line_payments (line_id, label, paid_on, amount)
      SELECT l.id,
             'Транш №' || COALESCE(f.tranche_no::text, '?'),
             COALESCE(f.paid_on, f.updated_at::date),
             COALESCE(o.approved_amount, o.requested - o.retainage_withheld + o.retainage_released)
      FROM bank_tranche_lines l
      JOIN draw_lines o ON o.budget_item_id = l.budget_item_id
      JOIN funding_requests f ON f.id = o.request_id
      WHERE l.tranche_id = @tranche::uuid
        AND f.id <> @request::uuid
        AND f.status IN ('approved', 'paid')
        AND COALESCE(o.approved_amount, o.requested - o.retainage_withheld + o.retainage_released) > 0
    '''),
    parameters: {'tranche': trancheId, 'request': requestId},
  );
}

Future<void> _writeChecks(Session tx, String trancheId, List<RuleResult> results) async {
  for (final result in results) {
    await tx.execute(
      Sql.named('''
        INSERT INTO bank_checks (tranche_id, code, level, basis, title, detail, passed, sort_order)
        VALUES (@id::uuid, @code, @level, @basis, @title, @detail, @passed, @sort)
        ON CONFLICT (tranche_id, code) DO UPDATE
        SET level = EXCLUDED.level, basis = EXCLUDED.basis, title = EXCLUDED.title,
            detail = EXCLUDED.detail, passed = EXCLUDED.passed, sort_order = EXCLUDED.sort_order
      '''),
      parameters: {
        'id': trancheId,
        'code': result.code,
        'level': result.level,
        'basis': result.basis,
        'title': result.title,
        'detail': result.detail,
        'passed': result.passed,
        'sort': result.sort,
      },
    );
  }
  await tx.execute(
    Sql.named('''
      UPDATE bank_tranche_lines SET block_check_id = NULL
      WHERE tranche_id = @id::uuid AND block_check_id IN (
        SELECT id FROM bank_checks WHERE tranche_id = @id::uuid AND NOT (code = ANY(@codes))
      )
    '''),
    parameters: {'id': trancheId, 'codes': [for (final r in results) r.code]},
  );
  await tx.execute(
    Sql.named('DELETE FROM bank_checks WHERE tranche_id = @id::uuid AND NOT (code = ANY(@codes))'),
    parameters: {'id': trancheId, 'codes': [for (final r in results) r.code]},
  );
}

/// What the bank decided goes back to the developer: comments on the lines that
/// were returned, and the stop of financing. Only tranches that came from a real
/// draw are touched. Never breaks the bank's own action.
Future<void> bankWriteBack(AppDatabase db, String trancheId) async {
  try {
    await db.owner.runTx((tx) async {
      final head = await tx.execute(
        Sql.named('''
          SELECT t.request_id::text, t.project_id::text, t.bank_id::text
          FROM bank_tranches t WHERE t.id = @id::uuid AND t.request_id IS NOT NULL
        '''),
        parameters: {'id': trancheId},
      );
      if (head.isEmpty) return;
      final requestId = head.first[0]! as String;
      final projectId = head.first[1]! as String;
      final bankId = head.first[2]! as String;

      await tx.execute(
        Sql.named('''
          UPDATE projects
          SET funding_paused = (
            SELECT funding_paused FROM project_facilities
            WHERE project_id = @project::uuid AND bank_id = @bank::uuid
          )
          WHERE id = @project::uuid
        '''),
        parameters: {'project': projectId, 'bank': bankId},
      );

      final decisions = await tx.execute(
        Sql.named('''
          SELECT d.id::text, d.kind, d.user_id::text, d.note, d.return_lines,
                 to_char(d.returned_amount, $bankMoneyFormat), to_char(d.issue_amount, $bankMoneyFormat)
          FROM bank_decisions d
          WHERE d.tranche_id = @id::uuid AND NOT d.written_back
            AND d.kind IN ('partial', 'return_all')
          ORDER BY d.created_at
        '''),
        parameters: {'id': trancheId},
      );
      for (final row in decisions) {
        final kind = row[1]! as String;
        final note = (row[3] as String? ?? '').trim();
        final returned = bankMillions(bankCentsOf(_money(row[5])));
        final issued = bankMillions(bankCentsOf(_money(row[6])));
        final summary = kind == 'return_all'
            ? 'Банк вернул транш целиком.'
            : 'Банк согласовал $issued млн, на доработку вернул $returned млн.';
        await tx.execute(
          Sql.named('''
            INSERT INTO draw_comments (request_id, author_user_id, body)
            VALUES (@request::uuid, @user::uuid, @body)
          '''),
          parameters: {
            'request': requestId,
            'user': row[2],
            'body': note.isEmpty ? summary : '$summary $note',
          },
        );
        final lines = row[4];
        if (lines is List) {
          for (final raw in lines) {
            if (raw is! Map) continue;
            final lineId = raw['lineId'] ?? raw['line_id'];
            if (lineId is! String) continue;
            final reason = (raw['reason'] ?? raw['note'] ?? '').toString().trim();
            await tx.execute(
              Sql.named('''
                INSERT INTO draw_comments (request_id, budget_item_id, author_user_id, body)
                SELECT @request::uuid, l.budget_item_id, @user::uuid, @body
                FROM bank_tranche_lines l
                WHERE l.id::text = @line AND l.budget_item_id IS NOT NULL
              '''),
              parameters: {
                'request': requestId,
                'user': row[2],
                'line': lineId,
                'body': reason.isEmpty ? 'Банк вернул эту статью на доработку.' : 'Банк: $reason',
              },
            );
          }
        }
        await tx.execute(
          Sql.named('UPDATE bank_decisions SET written_back = true WHERE id = @id::uuid'),
          parameters: {'id': row[0]},
        );
      }
    });
  } catch (error, stack) {
    stderr.writeln('bank write-back failed for tranche $trancheId: $error\n$stack');
  }
}
