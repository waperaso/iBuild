-- Internal mailbox. Subject and body are stored sealed (AES-256-GCM, see vault.dart).
CREATE TABLE messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL,
  sender_id uuid NOT NULL REFERENCES users (id),
  subject text NOT NULL,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  sender_deleted_at timestamptz
);

CREATE INDEX messages_thread_idx ON messages (thread_id, created_at);
CREATE INDEX messages_sender_idx ON messages (sender_id, created_at DESC);

CREATE TABLE message_recipients (
  message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users (id),
  read_at timestamptz,
  deleted_at timestamptz,
  PRIMARY KEY (message_id, user_id)
);

CREATE INDEX message_recipients_user_idx ON message_recipients (user_id, deleted_at, read_at);
