CREATE OR REPLACE FUNCTION line_hold(item uuid, kinds text[])
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE((
    SELECT SUM(
      CASE
        WHEN fr.status IN ('approved', 'paid') AND dl.approved_amount IS NOT NULL
          THEN dl.approved_amount
        ELSE dl.requested - dl.retainage_withheld + dl.retainage_released
      END
    )
    FROM draw_lines dl
    JOIN funding_requests fr ON fr.id = dl.request_id
    WHERE dl.budget_item_id = item
      AND fr.status = ANY(kinds)
  ), 0) + COALESCE((
    SELECT SUM(fr.amount)
    FROM funding_requests fr
    WHERE fr.budget_item_id = item
      AND fr.status = ANY(kinds)
      AND NOT EXISTS (SELECT 1 FROM draw_lines dl WHERE dl.request_id = fr.id)
  ), 0);
$$;

REVOKE ALL ON FUNCTION line_hold(uuid, text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION line_hold(uuid, text[]) TO ibuild_app;
