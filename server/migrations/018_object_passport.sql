-- Passport of a construction object: description, map point, financing bank, documents.

ALTER TABLE projects
  ADD COLUMN description text NOT NULL DEFAULT '',
  ADD COLUMN latitude numeric(9, 6),
  ADD COLUMN longitude numeric(9, 6),
  ADD COLUMN bank_name text NOT NULL DEFAULT '';

CREATE TABLE project_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  title text NOT NULL,
  doc_number text NOT NULL DEFAULT '',
  issued_on date,
  note text NOT NULL DEFAULT ''
);

GRANT SELECT, INSERT, UPDATE, DELETE ON project_documents TO ibuild_app;

ALTER TABLE project_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_documents FORCE ROW LEVEL SECURITY;

CREATE POLICY document_read ON project_documents
  FOR SELECT
  USING (
    app_is_platform_admin()
    OR app_member_role(project_id) IS NOT NULL
  );
