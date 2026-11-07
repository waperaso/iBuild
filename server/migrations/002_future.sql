-- Requests, files, and audit stay unused until later weeks.
-- Budget lines are written from week 2. Amounts are numeric(18,2).

CREATE TABLE budget_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  title text NOT NULL,
  planned_amount numeric(18, 2) NOT NULL,
  contractor_company_id uuid REFERENCES companies (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE funding_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  budget_item_id uuid NOT NULL REFERENCES budget_items (id),
  contractor_user_id uuid NOT NULL REFERENCES users (id),
  author_user_id uuid NOT NULL REFERENCES users (id),
  amount numeric(18, 2) NOT NULL,
  description text NOT NULL DEFAULT '',
  status text NOT NULL CHECK (
    status IN (
      'draft',
      'submitted',
      'tech_approved',
      'approved',
      'paid',
      'rejected',
      'cancelled'
    )
  ),
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE request_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES funding_requests (id),
  storage_path text NOT NULL,
  content_type text NOT NULL,
  size_bytes integer NOT NULL,
  author_user_id uuid NOT NULL REFERENCES users (id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid REFERENCES projects (id),
  request_id uuid REFERENCES funding_requests (id),
  action text NOT NULL,
  old_status text,
  new_status text,
  author_user_id uuid REFERENCES users (id),
  reason text,
  amount numeric(18, 2),
  created_at timestamptz NOT NULL DEFAULT now()
);
