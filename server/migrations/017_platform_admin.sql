-- Platform administrator and moderated edits of a construction object.
-- The admin is not a member of every project: a flag on the user opens read
-- access. Live name, address, and photo change only when that admin accepts.

ALTER TABLE users
  ADD COLUMN platform_admin boolean NOT NULL DEFAULT false;

ALTER TABLE projects
  ADD COLUMN photo_path text;

CREATE TABLE project_changes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects (id),
  author_user_id uuid NOT NULL REFERENCES users (id),
  name text NOT NULL,
  address text NOT NULL,
  photo_path text,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  review_note text NOT NULL DEFAULT '',
  reviewer_user_id uuid REFERENCES users (id),
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX project_changes_one_pending
  ON project_changes (project_id)
  WHERE status = 'pending';

GRANT SELECT, INSERT, UPDATE, DELETE ON project_changes TO ibuild_app;

CREATE OR REPLACE FUNCTION app_is_platform_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE(
    (SELECT platform_admin FROM users WHERE id = app_uid()),
    false
  )
$$;

REVOKE ALL ON FUNCTION app_is_platform_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_is_platform_admin() TO ibuild_app;

DO $$
DECLARE
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'companies',
    'users',
    'projects',
    'project_members',
    'contractor_firms',
    'budget_items',
    'funding_requests',
    'request_files',
    'audit_events',
    'funding_sources',
    'draw_lines',
    'draw_source_uses',
    'checklist_items',
    'draw_requirements',
    'inspections',
    'inspection_lines',
    'draw_comments',
    'payables',
    'budget_templates',
    'budget_template_lines'
  ]
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS platform_admin_read ON %I', tbl);
    EXECUTE format(
      'CREATE POLICY platform_admin_read ON %I FOR SELECT USING (app_is_platform_admin())',
      tbl
    );
  END LOOP;
END $$;

DROP POLICY IF EXISTS platform_admin_update ON projects;
CREATE POLICY platform_admin_update ON projects
  FOR UPDATE
  USING (app_is_platform_admin())
  WITH CHECK (app_is_platform_admin());

DROP POLICY IF EXISTS platform_admin_checklist_insert ON checklist_items;
CREATE POLICY platform_admin_checklist_insert ON checklist_items
  FOR INSERT
  WITH CHECK (app_is_platform_admin());

ALTER TABLE project_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_changes FORCE ROW LEVEL SECURITY;

CREATE POLICY change_read ON project_changes
  FOR SELECT
  USING (
    app_is_platform_admin()
    OR app_member_role(project_id) IS NOT NULL
  );

CREATE POLICY change_insert ON project_changes
  FOR INSERT
  WITH CHECK (
    author_user_id = app_uid()
    AND status = 'pending'
    AND app_member_role(project_id) = 'director'
  );

CREATE POLICY change_review ON project_changes
  FOR UPDATE
  USING (app_is_platform_admin())
  WITH CHECK (app_is_platform_admin());
