-- A demo session is the one started from the "Demo cabinet" buttons on the
-- sign-in page. Being read-only belongs to that session, not to the account:
-- the seeded pilot logins are ordinary accounts that sign in with a password.
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS demo boolean NOT NULL DEFAULT false;
