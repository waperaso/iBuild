ALTER TABLE funding_requests
  ADD COLUMN paid_on date,
  ADD COLUMN payment_number text,
  ADD COLUMN source_request_id uuid REFERENCES funding_requests (id);

ALTER TABLE request_files
  ADD COLUMN purpose text NOT NULL DEFAULT 'material';

ALTER TABLE request_files
  ADD CONSTRAINT request_files_purpose_check
  CHECK (purpose IN ('material', 'payment'));
