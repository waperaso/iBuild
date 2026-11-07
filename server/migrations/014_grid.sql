ALTER TABLE budget_items
  ADD COLUMN retainage_percent numeric(5, 2) NOT NULL DEFAULT 0
    CHECK (retainage_percent >= 0 AND retainage_percent <= 100);

ALTER TABLE inspection_lines
  ADD COLUMN risk text NOT NULL DEFAULT ''
    CHECK (risk IN ('', 'ok', 'watch', 'high'));

ALTER TABLE draw_lines
  ADD COLUMN inspector_risk text NOT NULL DEFAULT ''
    CHECK (inspector_risk IN ('', 'ok', 'watch', 'high')),
  ADD COLUMN inspector_comment text NOT NULL DEFAULT '';

CREATE OR REPLACE FUNCTION line_adjust(item uuid)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(dl.adjustment), 0)
  FROM draw_lines dl
  JOIN funding_requests fr ON fr.id = dl.request_id
  WHERE dl.budget_item_id = item
    AND fr.status <> 'draft';
$$;

CREATE OR REPLACE FUNCTION line_retainage(item uuid)
RETURNS numeric
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(SUM(dl.retainage_withheld - dl.retainage_released), 0)
  FROM draw_lines dl
  JOIN funding_requests fr ON fr.id = dl.request_id
  WHERE dl.budget_item_id = item
    AND fr.status <> 'draft';
$$;

REVOKE ALL ON FUNCTION line_adjust(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION line_retainage(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION line_adjust(uuid) TO ibuild_app;
GRANT EXECUTE ON FUNCTION line_retainage(uuid) TO ibuild_app;
