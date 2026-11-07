-- Contractor firms belong to a developer company. They are not a second tenant.

CREATE TABLE contractor_firms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_company_id uuid NOT NULL REFERENCES companies (id),
  name text NOT NULL,
  inn text NOT NULL,
  contact text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (owner_company_id, inn)
);

ALTER TABLE project_members
  DROP CONSTRAINT project_members_contractor_company_id_fkey;

ALTER TABLE project_members
  ADD CONSTRAINT project_members_contractor_company_id_fkey
  FOREIGN KEY (contractor_company_id) REFERENCES contractor_firms (id);

ALTER TABLE budget_items
  DROP CONSTRAINT budget_items_contractor_company_id_fkey;

ALTER TABLE budget_items
  ADD CONSTRAINT budget_items_contractor_company_id_fkey
  FOREIGN KEY (contractor_company_id) REFERENCES contractor_firms (id);

ALTER TABLE budget_items
  ADD CONSTRAINT budget_items_planned_amount_positive
  CHECK (planned_amount > 0);
