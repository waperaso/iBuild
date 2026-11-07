-- Bank cabinet. A bank is its own company. Staff keep their existing
-- project role so the developer flow still recognizes the observer.
-- Access to a construction site comes from project_facilities.

CREATE TABLE bank_profiles (
  company_id uuid PRIMARY KEY REFERENCES companies (id),
  department text NOT NULL DEFAULT ''
);

CREATE TABLE bank_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id uuid NOT NULL REFERENCES companies (id),
  user_id uuid NOT NULL UNIQUE REFERENCES users (id),
  role text NOT NULL CHECK (
    role IN ('specialist', 'expert', 'head', 'committee', 'risk', 'audit', 'admin')
  ),
  title text NOT NULL DEFAULT '',
  branch text NOT NULL DEFAULT '',
  on_leave_until date,
  active boolean NOT NULL DEFAULT true
);

CREATE TABLE bank_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id uuid NOT NULL REFERENCES companies (id),
  code text NOT NULL,
  name text NOT NULL,
  required_approvals integer NOT NULL CHECK (required_approvals > 0),
  UNIQUE (bank_id, code)
);

CREATE TABLE bank_group_members (
  group_id uuid NOT NULL REFERENCES bank_groups (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users (id),
  title text NOT NULL DEFAULT '',
  branch text NOT NULL DEFAULT '',
  PRIMARY KEY (group_id, user_id)
);

CREATE TABLE project_facilities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  bank_id uuid NOT NULL REFERENCES companies (id),
  developer_name text NOT NULL DEFAULT '',
  credit_limit numeric(18, 2) NOT NULL CHECK (credit_limit >= 0),
  issued_amount numeric(18, 2) NOT NULL DEFAULT 0 CHECK (issued_amount >= 0),
  utilize_until date,
  branch text NOT NULL DEFAULT '',
  UNIQUE (project_id, bank_id)
);

CREATE TABLE bank_rule_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id uuid NOT NULL REFERENCES companies (id),
  version integer NOT NULL CHECK (version > 0),
  effective_from date NOT NULL,
  snapshot jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bank_id, version)
);

CREATE TABLE bank_tranches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  bank_id uuid NOT NULL REFERENCES companies (id),
  rules_version_id uuid NOT NULL REFERENCES bank_rule_versions (id),
  tranche_no integer NOT NULL CHECK (tranche_no > 0),
  stage text NOT NULL CHECK (
    stage IN ('submitted', 'docs', 'inspection', 'specialist', 'approval', 'payout')
  ),
  stage_label text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  holder_user_id uuid REFERENCES users (id),
  holder_label text NOT NULL DEFAULT '',
  waiting_developer boolean NOT NULL DEFAULT false,
  elapsed_days integer NOT NULL DEFAULT 0 CHECK (elapsed_days >= 0),
  elapsed_hours integer NOT NULL DEFAULT 0 CHECK (elapsed_hours >= 0 AND elapsed_hours < 24),
  sla_days integer NOT NULL CHECK (sla_days > 0),
  problems_label text NOT NULL DEFAULT '',
  signal text NOT NULL DEFAULT 'none' CHECK (
    signal IN ('none', 'block', 'warning', 'inspection', 'developer')
  ),
  requested_amount numeric(18, 2) NOT NULL DEFAULT 0,
  confirmed_amount numeric(18, 2) NOT NULL DEFAULT 0,
  blocked_amount numeric(18, 2) NOT NULL DEFAULT 0,
  issue_amount numeric(18, 2) NOT NULL DEFAULT 0,
  submitted_at timestamptz NOT NULL DEFAULT now(),
  stage_entered_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (project_id, bank_id, tranche_no)
);

CREATE INDEX bank_tranches_bank_idx ON bank_tranches (bank_id, sort_order);

CREATE TABLE bank_tranche_clock (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tranche_id uuid NOT NULL REFERENCES bank_tranches (id) ON DELETE CASCADE,
  stage text NOT NULL,
  started_at timestamptz NOT NULL,
  ended_at timestamptz,
  paused boolean NOT NULL DEFAULT false
);

CREATE TABLE bank_checks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tranche_id uuid NOT NULL REFERENCES bank_tranches (id) ON DELETE CASCADE,
  code text NOT NULL,
  level text NOT NULL CHECK (level IN ('block', 'warning', 'signal', 'reminder')),
  basis text NOT NULL,
  title text NOT NULL,
  detail text NOT NULL DEFAULT '',
  passed boolean NOT NULL DEFAULT false,
  UNIQUE (tranche_id, code)
);

CREATE TABLE bank_tranche_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tranche_id uuid NOT NULL REFERENCES bank_tranches (id) ON DELETE CASCADE,
  budget_item_id uuid REFERENCES budget_items (id),
  title text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  issued_before numeric(18, 2) NOT NULL DEFAULT 0,
  requested numeric(18, 2) NOT NULL DEFAULT 0,
  readiness_percent numeric(5, 2),
  readiness_note text NOT NULL DEFAULT '',
  confirmed numeric(18, 2) NOT NULL DEFAULT 0,
  to_issue numeric(18, 2) NOT NULL DEFAULT 0,
  choice text NOT NULL DEFAULT 'confirmed' CHECK (
    choice IN ('confirmed', 'requested', 'withhold')
  )
);

CREATE TABLE bank_approval_steps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tranche_id uuid NOT NULL REFERENCES bank_tranches (id) ON DELETE CASCADE,
  code text NOT NULL,
  position integer NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'done', 'skipped', 'waiting')
  ),
  required_approvals integer NOT NULL DEFAULT 1 CHECK (required_approvals > 0),
  note text NOT NULL DEFAULT '',
  UNIQUE (tranche_id, code)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON
  bank_profiles, bank_staff, bank_groups, bank_group_members,
  project_facilities, bank_rule_versions, bank_tranches, bank_tranche_clock,
  bank_checks, bank_tranche_lines, bank_approval_steps
TO ibuild_app;

CREATE OR REPLACE FUNCTION app_bank_id() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT bank_id FROM bank_staff WHERE user_id = app_uid() AND active LIMIT 1
$$;

REVOKE ALL ON FUNCTION app_bank_id() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_bank_id() TO ibuild_app;

CREATE POLICY company_bank_read ON companies
  FOR SELECT
  USING (id = app_bank_id());

CREATE POLICY project_bank_read ON projects
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM project_facilities f
      WHERE f.project_id = projects.id AND f.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_profiles FORCE ROW LEVEL SECURITY;
CREATE POLICY bank_profile_read ON bank_profiles
  FOR SELECT
  USING (company_id = app_bank_id());

ALTER TABLE bank_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_staff FORCE ROW LEVEL SECURITY;
CREATE POLICY bank_staff_read ON bank_staff
  FOR SELECT
  USING (user_id = app_uid() OR bank_id = app_bank_id());

ALTER TABLE bank_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_groups FORCE ROW LEVEL SECURITY;
CREATE POLICY bank_group_read ON bank_groups
  FOR SELECT
  USING (bank_id = app_bank_id());

ALTER TABLE bank_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_group_members FORCE ROW LEVEL SECURITY;
CREATE POLICY bank_group_member_read ON bank_group_members
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_groups g
      WHERE g.id = group_id AND g.bank_id = app_bank_id()
    )
  );

ALTER TABLE project_facilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_facilities FORCE ROW LEVEL SECURITY;
CREATE POLICY facility_read ON project_facilities
  FOR SELECT
  USING (bank_id = app_bank_id());

ALTER TABLE bank_rule_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_rule_versions FORCE ROW LEVEL SECURITY;
CREATE POLICY rules_read ON bank_rule_versions
  FOR SELECT
  USING (bank_id = app_bank_id());

ALTER TABLE bank_tranches ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_tranches FORCE ROW LEVEL SECURITY;
CREATE POLICY tranche_read ON bank_tranches
  FOR SELECT
  USING (bank_id = app_bank_id());

ALTER TABLE bank_tranche_clock ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_tranche_clock FORCE ROW LEVEL SECURITY;
CREATE POLICY clock_read ON bank_tranche_clock
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_checks FORCE ROW LEVEL SECURITY;
CREATE POLICY check_read ON bank_checks
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_tranche_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_tranche_lines FORCE ROW LEVEL SECURITY;
CREATE POLICY line_read ON bank_tranche_lines
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );

ALTER TABLE bank_approval_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_approval_steps FORCE ROW LEVEL SECURITY;
CREATE POLICY step_read ON bank_approval_steps
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bank_tranches t
      WHERE t.id = tranche_id AND t.bank_id = app_bank_id()
    )
  );
