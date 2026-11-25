-- Photo forensics metadata for tranche requests and draw documents:
-- SHA-256 checksum, capture source (camera vs gallery upload), device geolocation,
-- parsed EXIF camera/timestamp/GPS tags, distance to object coordinates, and
-- integrity/duplicate verification flags.

ALTER TABLE request_files
  ADD COLUMN sha256 text NOT NULL DEFAULT '',
  ADD COLUMN capture_source text NOT NULL DEFAULT 'upload' CHECK (capture_source IN ('camera', 'upload')),
  ADD COLUMN captured_at timestamptz,
  ADD COLUMN gps_lat numeric(9, 6),
  ADD COLUMN gps_lon numeric(9, 6),
  ADD COLUMN gps_accuracy numeric(8, 2),
  ADD COLUMN gps_heading numeric(6, 2),
  ADD COLUMN exif_lat numeric(9, 6),
  ADD COLUMN exif_lon numeric(9, 6),
  ADD COLUMN exif_taken_at timestamptz,
  ADD COLUMN exif_heading numeric(6, 2),
  ADD COLUMN camera_make text NOT NULL DEFAULT '',
  ADD COLUMN camera_model text NOT NULL DEFAULT '',
  ADD COLUMN exif_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN distance_m integer,
  ADD COLUMN verify_status text NOT NULL DEFAULT 'unverified' CHECK (verify_status IN ('verified', 'warning', 'alert', 'unverified')),
  ADD COLUMN verify_flags jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN duplicate_of_file_id uuid;

CREATE INDEX request_files_sha256_idx ON request_files (sha256) WHERE sha256 <> '';

ALTER TABLE draw_requirement_files
  ADD COLUMN sha256 text NOT NULL DEFAULT '',
  ADD COLUMN capture_source text NOT NULL DEFAULT 'upload' CHECK (capture_source IN ('camera', 'upload')),
  ADD COLUMN captured_at timestamptz,
  ADD COLUMN gps_lat numeric(9, 6),
  ADD COLUMN gps_lon numeric(9, 6),
  ADD COLUMN gps_accuracy numeric(8, 2),
  ADD COLUMN gps_heading numeric(6, 2),
  ADD COLUMN exif_lat numeric(9, 6),
  ADD COLUMN exif_lon numeric(9, 6),
  ADD COLUMN exif_taken_at timestamptz,
  ADD COLUMN exif_heading numeric(6, 2),
  ADD COLUMN camera_make text NOT NULL DEFAULT '',
  ADD COLUMN camera_model text NOT NULL DEFAULT '',
  ADD COLUMN exif_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN distance_m integer,
  ADD COLUMN verify_status text NOT NULL DEFAULT 'unverified' CHECK (verify_status IN ('verified', 'warning', 'alert', 'unverified')),
  ADD COLUMN verify_flags jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN duplicate_of_file_id uuid;

CREATE INDEX draw_requirement_files_sha256_idx ON draw_requirement_files (sha256) WHERE sha256 <> '';
