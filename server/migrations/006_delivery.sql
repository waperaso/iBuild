ALTER TABLE funding_requests
  ADD COLUMN addressee_user_id uuid REFERENCES users (id),
  ADD COLUMN for_bank boolean NOT NULL DEFAULT false,
  ADD COLUMN bank_sent_at timestamptz;
