-- Registration of new companies: developers and banks apply from the public
-- sign-in page, the platform admin calls them, checks the papers and decides.
--
-- These tables hold personal data (passport, PINFL), so the app role gets no
-- access at all. Only the API running as the database owner touches them, and
-- every admin route checks platform_admin first.

CREATE TABLE applications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seq bigserial NOT NULL UNIQUE,
  kind text NOT NULL CHECK (kind IN ('developer', 'bank')),
  status text NOT NULL DEFAULT 'new'
    CHECK (status IN ('new', 'calling', 'docs_requested', 'in_review', 'approved', 'rejected')),
  org_name text NOT NULL,
  inn text NOT NULL,
  contact_name text NOT NULL,
  phone text NOT NULL,
  email text NOT NULL,
  region text NOT NULL DEFAULT '',
  data jsonb NOT NULL,
  token_hash text NOT NULL UNIQUE,
  consent_at timestamptz NOT NULL,
  consent_version text NOT NULL,
  checks jsonb NOT NULL DEFAULT '{}'::jsonb,
  docs_request_note text NOT NULL DEFAULT '',
  decision_note text NOT NULL DEFAULT '',
  next_call_on date,
  decided_by uuid REFERENCES users(id),
  decided_at timestamptz,
  company_id uuid REFERENCES companies(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- One open application per organisation. A rejected one can be sent again.
CREATE UNIQUE INDEX applications_one_open_per_inn
  ON applications (kind, inn)
  WHERE status NOT IN ('rejected', 'approved');

CREATE INDEX applications_status_idx ON applications (status, created_at DESC);

CREATE TABLE application_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  doc_type text NOT NULL,
  file_name text NOT NULL,
  content_type text NOT NULL,
  size_bytes integer NOT NULL CHECK (size_bytes > 0),
  storage_path text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX application_documents_app_idx ON application_documents (application_id);

CREATE TABLE application_events (
  id bigserial PRIMARY KEY,
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  author_user_id uuid REFERENCES users(id),
  kind text NOT NULL
    CHECK (kind IN ('created', 'status', 'call', 'note', 'check', 'document', 'approved')),
  outcome text NOT NULL DEFAULT '',
  body text NOT NULL DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX application_events_app_idx ON application_events (application_id, created_at);

REVOKE ALL ON applications, application_documents, application_events FROM ibuild_app;
REVOKE ALL ON SEQUENCE applications_seq_seq, application_events_id_seq FROM ibuild_app;
