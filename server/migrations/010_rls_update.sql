-- SELECT FOR UPDATE uses the UPDATE policy. Reviewers must still see a
-- request after they have finished with it, so the application can answer
-- "already changed" instead of pretending the row does not exist.
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
