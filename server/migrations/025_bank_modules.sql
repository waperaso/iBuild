-- Portfolio, objects, inspections, developers, reports, rules and the admin panel.
-- Everything here is read and written by the server as the system, after it has
-- checked who the person is and which bank the person belongs to.

ALTER TABLE bank_inspections
  ADD COLUMN note text NOT NULL DEFAULT '',
  ADD COLUMN completed_on date,
  ADD COLUMN risk text NOT NULL DEFAULT '' CHECK (risk IN ('', 'ok', 'watch', 'high')),
  ADD COLUMN expected_finish date,
  ADD COLUMN recommendation text NOT NULL DEFAULT '' CHECK (recommendation IN ('', 'issue', 'withhold'));

CREATE TABLE bank_filings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_id uuid NOT NULL REFERENCES companies (id),
  project_id uuid NOT NULL REFERENCES projects (id),
  kind text NOT NULL CHECK (kind IN ('sales', 'quarterly')),
  period text NOT NULL,
  filed_on date NOT NULL,
  user_id uuid NOT NULL REFERENCES users (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (project_id, kind, period)
);

CREATE TABLE bank_report_schedules (
  bank_id uuid NOT NULL REFERENCES companies (id),
  code text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  recipients text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (bank_id, code)
);

ALTER TABLE bank_rule_versions
  ADD COLUMN author_id uuid REFERENCES users (id),
  ADD COLUMN note text NOT NULL DEFAULT '';

CREATE TABLE admin_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users (id),
  actor_label text NOT NULL DEFAULT '',
  action text NOT NULL,
  target text NOT NULL DEFAULT '',
  detail jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX admin_events_time_idx ON admin_events (created_at DESC);
