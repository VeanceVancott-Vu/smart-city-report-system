CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE reports
    ADD COLUMN IF NOT EXISTS location GEOMETRY(Point, 4326)
    GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED;

ALTER TABLE reports
    ALTER COLUMN location SET NOT NULL;

CREATE INDEX IF NOT EXISTS idx_reports_location ON reports USING GIST (location);

COMMENT ON COLUMN reports.location IS 'Generated PostGIS point from longitude/latitude in SRID 4326 for map bounding-box queries.';
