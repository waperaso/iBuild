ALTER TABLE projects
  ADD COLUMN funding_paused boolean NOT NULL DEFAULT false;

ALTER TABLE funding_requests
  ADD COLUMN tranche_no integer,
  ADD COLUMN confirmed_amount numeric(18,2),
  ADD COLUMN decision text;

WITH numbered AS (
  SELECT id, row_number() OVER (PARTITION BY project_id ORDER BY created_at, id) AS n
  FROM funding_requests
  WHERE status <> 'draft'
)
UPDATE funding_requests AS fr
SET tranche_no = numbered.n
FROM numbered
WHERE fr.id = numbered.id
  AND fr.tranche_no IS NULL;

CREATE UNIQUE INDEX funding_requests_project_tranche
  ON funding_requests (project_id, tranche_no)
  WHERE tranche_no IS NOT NULL;

ALTER TABLE request_files DROP CONSTRAINT request_files_purpose_check;

ALTER TABLE request_files
  ADD CONSTRAINT request_files_purpose_check
  CHECK (purpose IN ('material', 'payment', 'act', 'invoice'));
