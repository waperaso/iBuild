ALTER TABLE budget_items
  ADD COLUMN cost_code text NOT NULL DEFAULT '',
  ADD COLUMN cost_kind text NOT NULL DEFAULT 'hard',
  ADD COLUMN budget_side text NOT NULL DEFAULT 'use';

ALTER TABLE budget_items
  ADD CONSTRAINT budget_items_kind_check
  CHECK (cost_kind IN ('hard', 'soft', 'contingency'));

ALTER TABLE budget_items
  ADD CONSTRAINT budget_items_side_check
  CHECK (budget_side IN ('use', 'source'));

ALTER TABLE funding_requests
  ADD COLUMN draw_name text NOT NULL DEFAULT '',
  ADD COLUMN final_draw boolean NOT NULL DEFAULT false,
  ADD COLUMN requested_amount numeric(18, 2),
  ADD COLUMN signed_name text NOT NULL DEFAULT '',
  ADD COLUMN signed_at timestamptz;

ALTER TABLE contractor_firms
  ADD COLUMN insurance_until date,
  ADD COLUMN license_until date;

CREATE TABLE funding_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  name text NOT NULL,
  kind text NOT NULL CHECK (kind IN ('loan', 'equity', 'escrow')),
  amount numeric(18, 2) NOT NULL CHECK (amount > 0),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE draw_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES funding_requests (id),
  budget_item_id uuid NOT NULL REFERENCES budget_items (id),
  requested numeric(18, 2) NOT NULL DEFAULT 0,
  adjustment numeric(18, 2) NOT NULL DEFAULT 0,
  retainage_withheld numeric(18, 2) NOT NULL DEFAULT 0,
  retainage_released numeric(18, 2) NOT NULL DEFAULT 0,
  stored_materials numeric(18, 2) NOT NULL DEFAULT 0,
  inspector_percent numeric(5, 2),
  inspector_recommend numeric(18, 2),
  approved_amount numeric(18, 2),
  comment text NOT NULL DEFAULT '',
  UNIQUE (request_id, budget_item_id)
);

CREATE TABLE draw_source_uses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES funding_requests (id),
  source_id uuid NOT NULL REFERENCES funding_sources (id),
  amount numeric(18, 2) NOT NULL DEFAULT 0,
  UNIQUE (request_id, source_id)
);

CREATE TABLE checklist_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  code text NOT NULL,
  title text NOT NULL,
  required boolean NOT NULL DEFAULT true,
  UNIQUE (project_id, code)
);

CREATE TABLE draw_requirements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES funding_requests (id),
  item_id uuid NOT NULL REFERENCES checklist_items (id),
  status text NOT NULL DEFAULT 'missing'
    CHECK (status IN ('missing', 'attached', 'na', 'resolved')),
  note text NOT NULL DEFAULT '',
  UNIQUE (request_id, item_id)
);

CREATE TABLE inspections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  request_id uuid REFERENCES funding_requests (id),
  scheduled_on date,
  gate_code text NOT NULL DEFAULT '',
  note text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'requested'
    CHECK (status IN ('requested', 'reported')),
  author_user_id uuid NOT NULL REFERENCES users (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE inspection_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES inspections (id),
  budget_item_id uuid NOT NULL REFERENCES budget_items (id),
  percent numeric(5, 2) NOT NULL DEFAULT 0,
  recommend numeric(18, 2) NOT NULL DEFAULT 0,
  comment text NOT NULL DEFAULT '',
  UNIQUE (inspection_id, budget_item_id)
);

CREATE TABLE draw_comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES funding_requests (id),
  budget_item_id uuid REFERENCES budget_items (id),
  author_user_id uuid NOT NULL REFERENCES users (id),
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE payables (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES funding_requests (id),
  budget_item_id uuid NOT NULL REFERENCES budget_items (id),
  firm_id uuid NOT NULL REFERENCES contractor_firms (id),
  number text NOT NULL,
  amount numeric(18, 2) NOT NULL CHECK (amount > 0),
  waiver text NOT NULL DEFAULT 'missing'
    CHECK (waiver IN ('missing', 'signed')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE budget_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid NOT NULL REFERENCES companies (id),
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE budget_template_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id uuid NOT NULL REFERENCES budget_templates (id),
  cost_code text NOT NULL DEFAULT '',
  title text NOT NULL,
  cost_kind text NOT NULL DEFAULT 'hard',
  budget_side text NOT NULL DEFAULT 'use',
  amount numeric(18, 2) NOT NULL CHECK (amount > 0)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON
  funding_sources, draw_lines, draw_source_uses, checklist_items,
  draw_requirements, inspections, inspection_lines, draw_comments,
  payables, budget_templates, budget_template_lines
TO ibuild_app;

ALTER TABLE funding_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_sources FORCE ROW LEVEL SECURITY;
CREATE POLICY source_access ON funding_sources
  FOR ALL
  USING (app_member_role(project_id) IS NOT NULL)
  WITH CHECK (app_member_role(project_id) IS NOT NULL);

ALTER TABLE draw_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_lines FORCE ROW LEVEL SECURITY;
CREATE POLICY draw_line_access ON draw_lines
  FOR ALL
  USING (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id))
  WITH CHECK (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id));

ALTER TABLE draw_source_uses ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_source_uses FORCE ROW LEVEL SECURITY;
CREATE POLICY draw_source_access ON draw_source_uses
  FOR ALL
  USING (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id))
  WITH CHECK (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id));

ALTER TABLE checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE checklist_items FORCE ROW LEVEL SECURITY;
CREATE POLICY checklist_access ON checklist_items
  FOR ALL
  USING (app_member_role(project_id) IS NOT NULL)
  WITH CHECK (app_member_role(project_id) IS NOT NULL);

ALTER TABLE draw_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_requirements FORCE ROW LEVEL SECURITY;
CREATE POLICY requirement_access ON draw_requirements
  FOR ALL
  USING (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id))
  WITH CHECK (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id));

ALTER TABLE inspections ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspections FORCE ROW LEVEL SECURITY;
CREATE POLICY inspection_access ON inspections
  FOR ALL
  USING (app_member_role(project_id) IS NOT NULL)
  WITH CHECK (
    app_member_role(project_id) IN ('tech', 'developer', 'director')
    AND author_user_id = app_uid()
  );

ALTER TABLE inspection_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE inspection_lines FORCE ROW LEVEL SECURITY;
CREATE POLICY inspection_line_access ON inspection_lines
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM inspections i
      WHERE i.id = inspection_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM inspections i
      WHERE i.id = inspection_id
    )
  );

ALTER TABLE draw_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE draw_comments FORCE ROW LEVEL SECURITY;
CREATE POLICY comment_access ON draw_comments
  FOR ALL
  USING (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id))
  WITH CHECK (
    author_user_id = app_uid()
    AND EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id)
  );

ALTER TABLE payables ENABLE ROW LEVEL SECURITY;
ALTER TABLE payables FORCE ROW LEVEL SECURITY;
CREATE POLICY payable_access ON payables
  FOR ALL
  USING (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id))
  WITH CHECK (EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id));

ALTER TABLE budget_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_templates FORCE ROW LEVEL SECURITY;
CREATE POLICY template_access ON budget_templates
  FOR ALL
  USING (company_id = app_company())
  WITH CHECK (company_id = app_company() AND app_is_company_admin());

CREATE POLICY firm_compliance ON contractor_firms
  FOR UPDATE
  USING (owner_company_id = app_company() AND app_is_company_admin())
  WITH CHECK (owner_company_id = app_company() AND app_is_company_admin());

ALTER TABLE budget_template_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_template_lines FORCE ROW LEVEL SECURITY;
CREATE POLICY template_line_access ON budget_template_lines
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM budget_templates t
      WHERE t.id = template_id
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM budget_templates t
      WHERE t.id = template_id
    )
  );
