DROP POLICY IF EXISTS inspection_access ON inspections;

CREATE POLICY inspection_read ON inspections
  FOR SELECT
  USING (app_member_role(project_id) IS NOT NULL);

CREATE POLICY inspection_insert ON inspections
  FOR INSERT
  WITH CHECK (
    author_user_id = app_uid()
    AND app_member_role(project_id) IN ('observer', 'director', 'developer', 'tech')
  );

CREATE POLICY inspection_update ON inspections
  FOR UPDATE
  USING (app_member_role(project_id) IN ('director', 'developer', 'tech', 'observer'))
  WITH CHECK (app_member_role(project_id) IN ('director', 'developer', 'tech', 'observer'));
