-- Tranches created before the expert step was closed at inspection time can
-- still show "pending" after the bank has already moved on. This closes only
-- that stuck step. Amounts, decisions, payments, the tranche stage and any
-- route that is still waiting for the expert stay as they are.
-- Calling the function again updates nothing and does not write a second journal line.

CREATE OR REPLACE FUNCTION close_stuck_expert_steps()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  closed integer;
BEGIN
  WITH candidates AS (
    SELECT
      s.id AS step_id,
      t.id AS tranche_id,
      t.bank_id,
      t.project_id,
      COALESCE(
        (
          SELECT c.ended_at
          FROM bank_tranche_clock c
          WHERE c.tranche_id = t.id
            AND c.stage = 'inspection'
            AND c.ended_at IS NOT NULL
          ORDER BY c.ended_at DESC
          LIMIT 1
        ),
        CASE
          WHEN t.stage IN ('specialist', 'approval', 'payout') THEN t.stage_entered_at
        END,
        fr.updated_at,
        now()
      ) AS decided_at
    FROM bank_approval_steps s
    JOIN bank_tranches t ON t.id = s.tranche_id
    LEFT JOIN funding_requests fr ON fr.id = t.request_id
    WHERE s.code = 'expert'
      AND s.status = 'pending'
      AND (
        t.stage IN ('specialist', 'approval', 'payout')
        OR t.outcome IS NOT NULL
        OR fr.status IN ('tech_approved', 'approved', 'paid')
      )
  ),
  updated AS (
    UPDATE bank_approval_steps s
    SET status = 'done',
        decided_at = c.decided_at,
        actor_label = CASE
          WHEN btrim(s.actor_label) = '' THEN 'Осмотр зафиксирован'
          ELSE s.actor_label
        END
    FROM candidates c
    WHERE s.id = c.step_id
      AND s.status = 'pending'
    RETURNING s.id, c.tranche_id, c.bank_id, c.project_id
  ),
  logged AS (
    INSERT INTO bank_audit_events (
      bank_id, tranche_id, project_id, user_id, actor_label, action, detail
    )
    SELECT
      u.bank_id,
      u.tranche_id,
      u.project_id,
      NULL,
      'Система',
      'expert_step_closed',
      jsonb_build_object(
        'step', 'expert',
        'reason', 'backfill',
        'previous', 'pending',
        'status', 'done'
      )
    FROM updated u
    WHERE NOT EXISTS (
      SELECT 1
      FROM bank_audit_events e
      WHERE e.tranche_id = u.tranche_id
        AND e.action = 'expert_step_closed'
        AND COALESCE(e.detail ->> 'reason', '') = 'backfill'
    )
    RETURNING id
  )
  SELECT count(*)::integer INTO closed FROM updated;
  RETURN closed;
END;
$$;

SELECT close_stuck_expert_steps();
