-- The bank cabinet now follows the real tranche of the developer: a draw that is
-- submitted becomes a bank tranche, its lines and checks come from real data.
-- Also the journal of the bank and the working calendar of the bank clock.

ALTER TABLE bank_tranches
  ADD COLUMN request_id uuid UNIQUE REFERENCES funding_requests (id);

CREATE UNIQUE INDEX bank_checks_tranche_code ON bank_checks (tranche_id, code);
CREATE UNIQUE INDEX bank_lines_tranche_item ON bank_tranche_lines (tranche_id, budget_item_id)
  WHERE budget_item_id IS NOT NULL;

CREATE TABLE bank_holidays (
  day date PRIMARY KEY,
  label text NOT NULL DEFAULT ''
);

INSERT INTO bank_holidays (day, label) VALUES
  (DATE '2026-01-01', 'Новый год'),
  (DATE '2026-03-09', 'Международный женский день (перенос)'),
  (DATE '2026-03-20', 'Рамазан хайит'),
  (DATE '2026-03-21', 'Навруз'),
  (DATE '2026-05-09', 'День памяти и почестей'),
  (DATE '2026-05-27', 'Курбан хайит'),
  (DATE '2026-09-01', 'День независимости'),
  (DATE '2026-10-01', 'День учителя'),
  (DATE '2026-12-08', 'День Конституции'),
  (DATE '2027-01-01', 'Новый год'),
  (DATE '2027-03-08', 'Международный женский день'),
  (DATE '2027-03-21', 'Навруз');

CREATE TABLE bank_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id uuid NOT NULL REFERENCES companies (id),
  tranche_id uuid REFERENCES bank_tranches (id) ON DELETE SET NULL,
  project_id uuid REFERENCES projects (id),
  user_id uuid REFERENCES users (id),
  actor_label text NOT NULL DEFAULT '',
  action text NOT NULL,
  detail jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX bank_audit_tranche_idx ON bank_audit_events (tranche_id, created_at);
CREATE INDEX bank_audit_bank_idx ON bank_audit_events (bank_id, created_at DESC);

GRANT SELECT ON bank_holidays TO ibuild_app;
GRANT SELECT, INSERT ON bank_audit_events TO ibuild_app;

ALTER TABLE bank_audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_audit_events FORCE ROW LEVEL SECURITY;

CREATE POLICY audit_read ON bank_audit_events
  FOR SELECT
  USING (bank_id = app_bank_id());

CREATE POLICY audit_insert ON bank_audit_events
  FOR INSERT
  WITH CHECK (bank_id = app_bank_id() AND user_id = app_uid());

-- Days the rules of this version give to a stage.
CREATE FUNCTION bank_stage_days(p_rules uuid, p_stage text, p_fallback integer)
RETURNS integer
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE((
    SELECT (item ->> 'days')::integer
    FROM bank_rule_versions v, jsonb_array_elements(v.snapshot -> 'stages') AS item
    WHERE v.id = p_rules AND item ->> 'code' = p_stage
    LIMIT 1
  ), p_fallback)
$$;

GRANT EXECUTE ON FUNCTION bank_stage_days(uuid, text, integer) TO ibuild_app;

-- Comments to the developer are written once per decision.
ALTER TABLE bank_decisions
  ADD COLUMN written_back boolean NOT NULL DEFAULT false;
