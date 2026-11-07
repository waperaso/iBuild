ALTER TABLE users ADD COLUMN must_change_password boolean NOT NULL DEFAULT false;

CREATE TABLE mail_outbox (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind text NOT NULL DEFAULT '',
  to_email text NOT NULL,
  subject text NOT NULL,
  body text NOT NULL,
  attachment_name text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'failed')),
  error text NOT NULL DEFAULT '',
  bank_id uuid REFERENCES companies (id),
  created_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz
);

CREATE INDEX mail_outbox_time_idx ON mail_outbox (created_at DESC);
