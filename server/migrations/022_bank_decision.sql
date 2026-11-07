-- Days 4 and 5 of the bank cabinet: expert evidence per budget line, waivers,
-- the specialist decision, the approval route with votes, control measures.
-- The demo tranche of Bank Navoi is filled in for a database that already has
-- it. A fresh database gets the same values from the seed.

ALTER TABLE bank_tranche_lines
  ADD COLUMN plan_amount numeric(18, 2),
  ADD COLUMN previous_percent numeric(5, 2),
  ADD COLUMN expert_name text NOT NULL DEFAULT '',
  ADD COLUMN expert_signed_on date,
  ADD COLUMN expert_note text NOT NULL DEFAULT '',
  ADD COLUMN remaining_to_build numeric(18, 2),
  ADD COLUMN recommended numeric(18, 2),
  ADD COLUMN risk_flag boolean NOT NULL DEFAULT false,
  ADD COLUMN block_check_id uuid REFERENCES bank_checks (id);

ALTER TABLE bank_checks
  ADD COLUMN requested_kind text CHECK (requested_kind IN ('document', 'schedule')),
  ADD COLUMN requested_at timestamptz;

ALTER TABLE bank_tranches
  ADD COLUMN approval_round integer NOT NULL DEFAULT 1,
  ADD COLUMN outcome text CHECK (outcome IN ('rejected'));

ALTER TABLE project_facilities
  ADD COLUMN funding_paused boolean NOT NULL DEFAULT false;

ALTER TABLE bank_approval_steps
  ADD COLUMN actor_user_id uuid REFERENCES users (id),
  ADD COLUMN actor_label text NOT NULL DEFAULT '',
  ADD COLUMN decided_at timestamptz,
  ADD COLUMN reason text NOT NULL DEFAULT '';

CREATE TABLE bank_line_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  line_id uuid NOT NULL REFERENCES bank_tranche_lines (id) ON DELETE CASCADE,
  caption text NOT NULL,
  meta text NOT NULL DEFAULT '',
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE bank_line_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  line_id uuid NOT NULL REFERENCES bank_tranche_lines (id) ON DELETE CASCADE,
  title text NOT NULL,
  state text NOT NULL CHECK (state IN ('ok', 'missing')),
  sort_order integer NOT NULL DEFAULT 0
);

CREATE TABLE bank_line_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  line_id uuid NOT NULL REFERENCES bank_tranche_lines (id) ON DELETE CASCADE,
  label text NOT NULL,
  paid_on date NOT NULL,
  amount numeric(18, 2) NOT NULL
);

CREATE TABLE bank_check_waivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  check_id uuid NOT NULL UNIQUE REFERENCES bank_checks (id) ON DELETE CASCADE,
  tranche_id uuid NOT NULL REFERENCES bank_tranches (id) ON DELETE CASCADE,
  reason text NOT NULL CHECK (
    reason IN ('outside_system', 'fixed_elsewhere', 'approved_exception', 'other')
  ),
  comment text NOT NULL,
  user_id uuid NOT NULL REFERENCES users (id),
  actor_label text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE bank_decisions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tranche_id uuid NOT NULL REFERENCES bank_tranches (id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (
    kind IN ('partial', 'return_all', 'control_measure', 'suspend', 'resume')
  ),
  round integer NOT NULL DEFAULT 1,
  issue_amount numeric(18, 2) NOT NULL DEFAULT 0,
  returned_amount numeric(18, 2) NOT NULL DEFAULT 0,
  waived_count integer NOT NULL DEFAULT 0,
  return_lines jsonb NOT NULL DEFAULT '[]'::jsonb,
  note text NOT NULL DEFAULT '',
  user_id uuid NOT NULL REFERENCES users (id),
  actor_label text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX bank_decisions_tranche_idx ON bank_decisions (tranche_id, created_at);

CREATE TABLE bank_approval_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  step_id uuid NOT NULL REFERENCES bank_approval_steps (id) ON DELETE CASCADE,
  round integer NOT NULL,
  user_id uuid NOT NULL REFERENCES users (id),
  actor_label text NOT NULL,
  vote text NOT NULL CHECK (vote IN ('approve', 'return', 'reject')),
  comment text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (step_id, round, user_id)
);

CREATE TABLE bank_inspections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tranche_id uuid REFERENCES bank_tranches (id) ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES projects (id),
  bank_id uuid NOT NULL REFERENCES companies (id),
  kind text NOT NULL DEFAULT 'control' CHECK (kind IN ('control', 'regular')),
  status text NOT NULL DEFAULT 'planned' CHECK (status IN ('planned', 'done', 'overdue')),
  scheduled_on date NOT NULL,
  expert_user_id uuid REFERENCES users (id),
  expert_label text NOT NULL DEFAULT '',
  created_by uuid NOT NULL REFERENCES users (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON
  bank_line_photos, bank_line_documents, bank_line_payments,
  bank_check_waivers, bank_decisions, bank_approval_votes, bank_inspections
TO ibuild_app;

-- Reading follows the bank of the tranche, like the tables of day 1.
ALTER TABLE bank_line_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_line_photos FORCE ROW LEVEL SECURITY;
CREATE POLICY line_photo_read ON bank_line_photos
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranche_lines l
      JOIN bank_tranches t ON t.id = l.tranche_id
      WHERE l.id = line_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_line_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_line_documents FORCE ROW LEVEL SECURITY;
CREATE POLICY line_document_read ON bank_line_documents
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranche_lines l
      JOIN bank_tranches t ON t.id = l.tranche_id
      WHERE l.id = line_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_line_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_line_payments FORCE ROW LEVEL SECURITY;
CREATE POLICY line_payment_read ON bank_line_payments
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranche_lines l
      JOIN bank_tranches t ON t.id = l.tranche_id
      WHERE l.id = line_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_check_waivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_check_waivers FORCE ROW LEVEL SECURITY;
CREATE POLICY waiver_read ON bank_check_waivers
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );
CREATE POLICY waiver_insert ON bank_check_waivers
  FOR INSERT
  WITH CHECK (
    user_id = app_uid()
    AND EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_decisions FORCE ROW LEVEL SECURITY;
CREATE POLICY decision_read ON bank_decisions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );
CREATE POLICY decision_insert ON bank_decisions
  FOR INSERT
  WITH CHECK (
    user_id = app_uid()
    AND EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_approval_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_approval_votes FORCE ROW LEVEL SECURITY;
CREATE POLICY vote_read ON bank_approval_votes
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_approval_steps s
      JOIN bank_tranches t ON t.id = s.tranche_id
      WHERE s.id = step_id AND t.bank_id = app_bank_id()
    )
  );
CREATE POLICY vote_insert ON bank_approval_votes
  FOR INSERT
  WITH CHECK (
    user_id = app_uid()
    AND EXISTS (
      SELECT 1 FROM bank_approval_steps s
      JOIN bank_tranches t ON t.id = s.tranche_id
      WHERE s.id = step_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_inspections FORCE ROW LEVEL SECURITY;
CREATE POLICY inspection_read ON bank_inspections
  FOR SELECT
  USING (bank_id = app_bank_id());
CREATE POLICY inspection_insert ON bank_inspections
  FOR INSERT
  WITH CHECK (bank_id = app_bank_id() AND created_by = app_uid());

-- Writing into the tables of day 1: only rows of the bank of the signed-in
-- person. Which role may do what is decided in the API.
CREATE POLICY tranche_update ON bank_tranches
  FOR UPDATE
  USING (bank_id = app_bank_id())
  WITH CHECK (bank_id = app_bank_id());

CREATE POLICY line_update ON bank_tranche_lines
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

CREATE POLICY check_update ON bank_checks
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

CREATE POLICY clock_write ON bank_tranche_clock
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

CREATE POLICY step_update ON bank_approval_steps
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

CREATE POLICY facility_update ON project_facilities
  FOR UPDATE
  USING (bank_id = app_bank_id())
  WITH CHECK (bank_id = app_bank_id());
