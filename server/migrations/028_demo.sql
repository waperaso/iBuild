-- Demo world: companies, users and applications that belong to the read-only demo
-- are flagged, so real people never see them and demo never sees real data.
ALTER TABLE companies ADD COLUMN is_demo boolean NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN is_demo boolean NOT NULL DEFAULT false;
ALTER TABLE applications ADD COLUMN is_demo boolean NOT NULL DEFAULT false;
