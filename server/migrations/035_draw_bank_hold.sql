-- What stops the money on a draw, told to the developer side, which cannot read
-- the bank's own tables: 'returned' (the bank sent the whole tranche back),
-- 'paused' (the bank suspended the financing), 'control' (a control inspection
-- is planned), or '' when the draw simply waits for the bank.
CREATE OR REPLACE FUNCTION draw_bank_hold(request uuid) RETURNS text
  LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT COALESCE((
    SELECT CASE d.kind
             WHEN 'suspend' THEN 'paused'
             WHEN 'control_measure' THEN 'control'
             WHEN 'return_all' THEN 'returned'
             ELSE ''
           END
    FROM bank_tranches t
    JOIN LATERAL (
      SELECT x.kind FROM bank_decisions x
      WHERE x.tranche_id = t.id
        AND x.kind IN ('return_all', 'suspend', 'control_measure', 'resume', 'partial')
      ORDER BY x.created_at DESC LIMIT 1
    ) d ON true
    WHERE t.request_id = request AND t.outcome IS NULL
      AND (t.waiting_developer OR (d.kind = 'control_measure' AND t.stage = 'inspection'))
    LIMIT 1
  ), '')
$$;
REVOKE ALL ON FUNCTION draw_bank_hold(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION draw_bank_hold(uuid) TO ibuild_app;
