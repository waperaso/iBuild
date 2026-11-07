-- Colleagues of the same bank see each other's names: control measures name
-- the expert, the route names who approved.
CREATE POLICY user_bank_colleague_read ON users
  FOR SELECT
  USING (
    app_bank_id() IS NOT NULL
    AND id IN (SELECT user_id FROM bank_staff WHERE bank_id = app_bank_id())
  );
