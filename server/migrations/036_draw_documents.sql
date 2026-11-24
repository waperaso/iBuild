-- The papers of a tranche are files, not marks. A required paper (the act of
-- work done, the invoice, the waiver) counts as attached only when a file is
-- there, and the bank opens the same file.
CREATE TABLE draw_requirement_files (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL REFERENCES funding_requests (id),
  item_id uuid NOT NULL REFERENCES checklist_items (id),
  storage_path text NOT NULL,
  file_name text NOT NULL,
  content_type text NOT NULL,
  size_bytes integer NOT NULL CHECK (size_bytes > 0),
  author_user_id uuid NOT NULL REFERENCES users (id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX draw_requirement_files_request_idx ON draw_requirement_files (request_id, item_id);

-- Marks made before files existed stay valid for the draws that carry them.
ALTER TABLE draw_requirements ADD COLUMN attached_before_files boolean NOT NULL DEFAULT false;
UPDATE draw_requirements SET attached_before_files = true WHERE status = 'attached';

-- What the bank's own expert measured on site, line by line. When present it
-- is what the bank pays against, ahead of the developer's site inspector.
CREATE TABLE bank_inspection_lines (
  inspection_id uuid NOT NULL REFERENCES bank_inspections (id) ON DELETE CASCADE,
  budget_item_id uuid NOT NULL REFERENCES budget_items (id),
  percent numeric(5, 2) NOT NULL CHECK (percent >= 0 AND percent <= 100),
  recommend numeric(18, 2) NOT NULL CHECK (recommend >= 0),
  comment text NOT NULL DEFAULT '',
  PRIMARY KEY (inspection_id, budget_item_id)
);
