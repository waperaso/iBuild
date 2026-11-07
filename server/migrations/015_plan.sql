ALTER TABLE budget_items
  ADD COLUMN plan_set boolean NOT NULL DEFAULT false;

ALTER TABLE budget_items
  DROP CONSTRAINT budget_items_planned_amount_positive;

ALTER TABLE budget_items
  ADD CONSTRAINT budget_items_planned_amount_positive
  CHECK (planned_amount >= 0);

CREATE OR REPLACE FUNCTION budget_item_guard() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF app_member_role(NEW.project_id) IN ('director', 'developer', 'observer') THEN
    RETURN NEW;
  END IF;
  IF NEW.planned_amount IS DISTINCT FROM OLD.planned_amount
     OR NEW.title IS DISTINCT FROM OLD.title
     OR NEW.contractor_company_id IS DISTINCT FROM OLD.contractor_company_id
     OR NEW.project_id IS DISTINCT FROM OLD.project_id
     OR NEW.plan_set IS DISTINCT FROM OLD.plan_set THEN
    RAISE EXCEPTION 'budget change denied' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END $$;

DROP POLICY IF EXISTS budget_bank_insert ON budget_items;
CREATE POLICY budget_bank_insert ON budget_items
  FOR INSERT
  WITH CHECK (app_member_role(project_id) = 'observer');

DROP POLICY IF EXISTS budget_bank_update ON budget_items;
CREATE POLICY budget_bank_update ON budget_items
  FOR UPDATE
  USING (app_member_role(project_id) = 'observer')
  WITH CHECK (app_member_role(project_id) = 'observer');
