CREATE TABLE idempotency_keys (
  user_id uuid NOT NULL REFERENCES users (id),
  idempotency_key text NOT NULL,
  fingerprint text NOT NULL,
  status_code integer NOT NULL,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, idempotency_key)
);

CREATE INDEX funding_requests_item_status
  ON funding_requests (budget_item_id, status);

CREATE INDEX funding_requests_project_status
  ON funding_requests (project_id, status);

CREATE INDEX audit_events_request
  ON audit_events (request_id, created_at);
