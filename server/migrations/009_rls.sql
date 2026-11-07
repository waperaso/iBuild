-- Tenant isolation in the database. The API connects as ibuild_app.
-- The table owner (ibuild) is a superuser and is used only for login,
-- sessions, migrations, and seed. ibuild_app has no BYPASSRLS.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ibuild_app') THEN
    CREATE ROLE ibuild_app
      LOGIN
      NOSUPERUSER
      NOBYPASSRLS
      NOCREATEDB
      NOCREATEROLE;
  END IF;
END $$;

DO $$
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO ibuild_app', current_database());
END $$;

GRANT USAGE ON SCHEMA public TO ibuild_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ibuild_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ibuild_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ibuild_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT USAGE, SELECT ON SEQUENCES TO ibuild_app;

REVOKE SELECT (password_hash) ON users FROM ibuild_app;

CREATE OR REPLACE FUNCTION app_uid() RETURNS uuid
LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.user_id', true), '')::uuid
$$;

CREATE OR REPLACE FUNCTION app_company() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT company_id FROM users WHERE id = app_uid()
$$;

CREATE OR REPLACE FUNCTION app_member_role(pid uuid) RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT role FROM project_members
  WHERE project_id = pid AND user_id = app_uid()
$$;

CREATE OR REPLACE FUNCTION app_member_firm(pid uuid) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT contractor_company_id FROM project_members
  WHERE project_id = pid AND user_id = app_uid()
$$;

CREATE OR REPLACE FUNCTION app_line_firm(item uuid) RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT contractor_company_id FROM budget_items WHERE id = item
$$;

CREATE OR REPLACE FUNCTION app_is_company_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1
    FROM project_members m
    JOIN projects p ON p.id = m.project_id
    WHERE m.user_id = app_uid()
      AND p.company_id = app_company()
      AND m.role IN ('director', 'developer')
  )
$$;

REVOKE ALL ON FUNCTION app_uid() FROM PUBLIC;
REVOKE ALL ON FUNCTION app_company() FROM PUBLIC;
REVOKE ALL ON FUNCTION app_member_role(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_member_firm(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_line_firm(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION app_is_company_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_uid() TO ibuild_app;
GRANT EXECUTE ON FUNCTION app_company() TO ibuild_app;
GRANT EXECUTE ON FUNCTION app_member_role(uuid) TO ibuild_app;
GRANT EXECUTE ON FUNCTION app_member_firm(uuid) TO ibuild_app;
GRANT EXECUTE ON FUNCTION app_line_firm(uuid) TO ibuild_app;
GRANT EXECUTE ON FUNCTION app_is_company_admin() TO ibuild_app;

ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS company_tenant ON companies;
CREATE POLICY company_tenant ON companies
  FOR ALL
  USING (id = app_company())
  WITH CHECK (id = app_company());

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_tenant ON users;
CREATE POLICY user_tenant ON users
  FOR SELECT
  USING (company_id = app_company());

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS project_member_read ON projects;
CREATE POLICY project_member_read ON projects
  FOR SELECT
  USING (
    app_member_role(id) IS NOT NULL
    OR (company_id = app_company() AND app_is_company_admin())
  );
DROP POLICY IF EXISTS project_director_write ON projects;
CREATE POLICY project_director_write ON projects
  FOR INSERT
  WITH CHECK (company_id = app_company() AND app_is_company_admin());
DROP POLICY IF EXISTS project_director_update ON projects;
CREATE POLICY project_director_update ON projects
  FOR UPDATE
  USING (app_member_role(id) IN ('director', 'developer'))
  WITH CHECK (
    company_id = app_company()
    AND app_member_role(id) IN ('director', 'developer')
  );

ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS member_read ON project_members;
CREATE POLICY member_read ON project_members
  FOR SELECT
  USING (app_member_role(project_id) IS NOT NULL);
DROP POLICY IF EXISTS member_write ON project_members;
CREATE POLICY member_write ON project_members
  FOR INSERT
  WITH CHECK (
    app_member_role(project_id) IN ('director', 'developer')
    OR (
      user_id = app_uid()
      AND role IN ('director', 'developer')
      AND app_is_company_admin()
    )
  );
DROP POLICY IF EXISTS member_delete ON project_members;
CREATE POLICY member_delete ON project_members
  FOR DELETE
  USING (app_member_role(project_id) IN ('director', 'developer'));

ALTER TABLE contractor_firms ENABLE ROW LEVEL SECURITY;
ALTER TABLE contractor_firms FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS firm_read ON contractor_firms;
CREATE POLICY firm_read ON contractor_firms
  FOR SELECT
  USING (owner_company_id = app_company());
DROP POLICY IF EXISTS firm_write ON contractor_firms;
CREATE POLICY firm_write ON contractor_firms
  FOR INSERT
  WITH CHECK (owner_company_id = app_company() AND app_is_company_admin());

ALTER TABLE budget_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_items FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS budget_read ON budget_items;
CREATE POLICY budget_read ON budget_items
  FOR SELECT
  USING (
    app_member_role(project_id) IS NOT NULL
    AND (
      app_member_role(project_id) <> 'contractor'
      OR contractor_company_id IS NOT DISTINCT FROM app_member_firm(project_id)
    )
  );
DROP POLICY IF EXISTS budget_write ON budget_items;
CREATE POLICY budget_write ON budget_items
  FOR ALL
  USING (app_member_role(project_id) IN ('director', 'developer'))
  WITH CHECK (app_member_role(project_id) IN ('director', 'developer'));

ALTER TABLE funding_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_requests FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS request_read ON funding_requests;
CREATE POLICY request_read ON funding_requests
  FOR SELECT
  USING (
    app_member_role(project_id) = 'developer'
    OR contractor_user_id = app_uid()
    OR (
      app_member_role(project_id) = 'contractor'
      AND status <> 'draft'
      AND app_line_firm(budget_item_id) IS NOT DISTINCT FROM app_member_firm(project_id)
    )
    OR (
      app_member_role(project_id) IN ('director', 'tech', 'observer')
      AND status <> 'draft'
    )
  );
DROP POLICY IF EXISTS request_insert ON funding_requests;
CREATE POLICY request_insert ON funding_requests
  FOR INSERT
  WITH CHECK (
    author_user_id = app_uid()
    AND contractor_user_id = app_uid()
    AND app_member_role(project_id) IN ('contractor', 'director', 'developer')
  );
DROP POLICY IF EXISTS request_update ON funding_requests;
CREATE POLICY request_update ON funding_requests
  FOR UPDATE
  USING (
    app_member_role(project_id) = 'developer'
    OR contractor_user_id = app_uid()
    OR (
      app_member_role(project_id) = 'contractor'
      AND status <> 'draft'
      AND app_line_firm(budget_item_id) IS NOT DISTINCT FROM app_member_firm(project_id)
    )
    OR (
      app_member_role(project_id) IN ('director', 'tech', 'observer')
      AND status <> 'draft'
    )
  )
  WITH CHECK (
    app_member_role(project_id) = 'developer'
    OR contractor_user_id = app_uid()
    OR (
      app_member_role(project_id) IN ('director', 'tech', 'observer')
      AND status <> 'draft'
    )
  );

ALTER TABLE request_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE request_files FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS file_read ON request_files;
CREATE POLICY file_read ON request_files
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM funding_requests fr WHERE fr.id = request_id
    )
  );
DROP POLICY IF EXISTS file_write ON request_files;
CREATE POLICY file_write ON request_files
  FOR ALL
  USING (
    author_user_id = app_uid()
    AND EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id)
  )
  WITH CHECK (
    author_user_id = app_uid()
    AND EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id)
  );

ALTER TABLE audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_events FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS audit_read ON audit_events;
CREATE POLICY audit_read ON audit_events
  FOR SELECT
  USING (
    project_id IS NOT NULL
    AND app_member_role(project_id) IS NOT NULL
    AND (
      app_member_role(project_id) <> 'contractor'
      OR request_id IS NULL
      OR EXISTS (SELECT 1 FROM funding_requests fr WHERE fr.id = request_id)
    )
  );
DROP POLICY IF EXISTS audit_insert ON audit_events;
CREATE POLICY audit_insert ON audit_events
  FOR INSERT
  WITH CHECK (
    project_id IS NOT NULL
    AND app_member_role(project_id) IS NOT NULL
    AND author_user_id = app_uid()
  );

ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_keys FORCE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS idempotency_own ON idempotency_keys;
CREATE POLICY idempotency_own ON idempotency_keys
  FOR ALL
  USING (user_id = app_uid())
  WITH CHECK (user_id = app_uid());

ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions FORCE ROW LEVEL SECURITY;
ALTER TABLE login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_attempts FORCE ROW LEVEL SECURITY;
ALTER TABLE schema_migrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE schema_migrations FORCE ROW LEVEL SECURITY;
