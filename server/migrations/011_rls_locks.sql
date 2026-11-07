-- Contractors lock their own budget line while a tranche is submitted.
-- They still cannot change the line itself.
DROP POLICY IF EXISTS budget_write ON budget_items;
CREATE POLICY budget_insert ON budget_items
  FOR INSERT
  WITH CHECK (app_member_role(project_id) IN ('director', 'developer'));
CREATE POLICY budget_delete ON budget_items
  FOR DELETE
  USING (app_member_role(project_id) IN ('director', 'developer'));
CREATE POLICY budget_update ON budget_items
  FOR UPDATE
  USING (
    app_member_role(project_id) IN ('director', 'developer')
    OR (
      app_member_role(project_id) = 'contractor'
      AND contractor_company_id IS NOT DISTINCT FROM app_member_firm(project_id)
    )
  )
  WITH CHECK (
    app_member_role(project_id) IN ('director', 'developer')
    OR (
      app_member_role(project_id) = 'contractor'
      AND contractor_company_id IS NOT DISTINCT FROM app_member_firm(project_id)
    )
  );

CREATE OR REPLACE FUNCTION budget_item_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF app_member_role(NEW.project_id) IN ('director', 'developer') THEN
    RETURN NEW;
  END IF;
  IF NEW.planned_amount IS DISTINCT FROM OLD.planned_amount
     OR NEW.title IS DISTINCT FROM OLD.title
     OR NEW.contractor_company_id IS DISTINCT FROM OLD.contractor_company_id
     OR NEW.project_id IS DISTINCT FROM OLD.project_id THEN
    RAISE EXCEPTION 'budget change denied' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS budget_item_guard ON budget_items;
CREATE TRIGGER budget_item_guard
  BEFORE UPDATE ON budget_items
  FOR EACH ROW
  EXECUTE FUNCTION budget_item_guard();

CREATE OR REPLACE FUNCTION next_tranche_no(pid uuid) RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  n integer;
BEGIN
  PERFORM 1 FROM projects WHERE id = pid FOR UPDATE;
  SELECT COALESCE(MAX(tranche_no), 0) + 1 INTO n
  FROM funding_requests
  WHERE project_id = pid AND tranche_no IS NOT NULL;
  RETURN n;
END $$;

REVOKE ALL ON FUNCTION budget_item_guard() FROM PUBLIC;
REVOKE ALL ON FUNCTION next_tranche_no(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION next_tranche_no(uuid) TO ibuild_app;
