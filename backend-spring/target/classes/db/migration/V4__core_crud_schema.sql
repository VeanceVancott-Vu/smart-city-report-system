CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
          AND column_name = 'display_name'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'users'
          AND column_name = 'full_name'
    ) THEN
        ALTER TABLE users RENAME COLUMN display_name TO full_name;
    END IF;
END $$;

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS full_name VARCHAR(120),
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255),
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

UPDATE users
SET full_name = email
WHERE full_name IS NULL;

ALTER TABLE users
    ALTER COLUMN full_name SET NOT NULL,
    DROP CONSTRAINT IF EXISTS users_role_check,
    ADD CONSTRAINT users_role_check CHECK (role IN ('CITIZEN', 'STAFF', 'OVERSEER'));

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'reports'
          AND column_name = 'created_by'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'reports'
          AND column_name = 'created_by_user_id'
    ) THEN
        ALTER TABLE reports RENAME COLUMN created_by TO created_by_user_id;
    END IF;
END $$;

ALTER TABLE reports
    ADD COLUMN IF NOT EXISTS address_text VARCHAR(255),
    ADD COLUMN IF NOT EXISTS before_photo_url VARCHAR(2048),
    ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS upvote_count INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS priority_score INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS linked_task_id UUID,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE reports
    DROP CONSTRAINT IF EXISTS reports_status_check,
    DROP CONSTRAINT IF EXISTS reports_category_check;

UPDATE reports
SET category = CASE UPPER(category)
    WHEN 'ROAD' THEN 'ROAD_DAMAGE'
    WHEN 'ROAD_DAMAGE' THEN 'ROAD_DAMAGE'
    WHEN 'LIGHTING' THEN 'STREET_LIGHT'
    WHEN 'STREET_LIGHT' THEN 'STREET_LIGHT'
    WHEN 'GARBAGE' THEN 'GARBAGE'
    WHEN 'WATER_LEAK' THEN 'WATER_LEAK'
    WHEN 'DRAINAGE' THEN 'DRAINAGE'
    WHEN 'TRAFFIC_SIGN' THEN 'TRAFFIC_SIGN'
    WHEN 'TREE_BLOCKAGE' THEN 'TREE_BLOCKAGE'
    ELSE 'OTHER'
END;

UPDATE reports
SET status = CASE status
    WHEN 'RESOLVED' THEN 'FIXED'
    WHEN 'APPROVED' THEN 'FIXED'
    WHEN 'CLOSED' THEN 'FIXED'
    WHEN 'REJECTED' THEN 'CANCELLED'
    WHEN 'CANCELLED' THEN 'CANCELLED'
    ELSE 'SUBMITTED'
END
WHERE status NOT IN ('SUBMITTED', 'FIXED', 'CANCELLED');

ALTER TABLE reports
    ALTER COLUMN category TYPE VARCHAR(40),
    DROP CONSTRAINT IF EXISTS reports_upvote_count_check,
    DROP CONSTRAINT IF EXISTS reports_priority_score_check,
    ADD CONSTRAINT reports_status_check CHECK (status IN ('SUBMITTED', 'FIXED', 'CANCELLED')),
    ADD CONSTRAINT reports_category_check CHECK (category IN (
        'ROAD_DAMAGE',
        'STREET_LIGHT',
        'GARBAGE',
        'WATER_LEAK',
        'DRAINAGE',
        'TRAFFIC_SIGN',
        'TREE_BLOCKAGE',
        'OTHER'
    )),
    ADD CONSTRAINT reports_upvote_count_check CHECK (upvote_count >= 0),
    ADD CONSTRAINT reports_priority_score_check CHECK (priority_score >= 0);

ALTER TABLE reports
    DROP CONSTRAINT IF EXISTS reports_created_by_fkey,
    DROP CONSTRAINT IF EXISTS reports_created_by_user_id_fkey,
    ADD CONSTRAINT reports_created_by_user_id_fkey
        FOREIGN KEY (created_by_user_id) REFERENCES users(id);

ALTER TABLE reports
    ADD COLUMN IF NOT EXISTS location GEOMETRY(Point, 4326)
    GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED;

CREATE INDEX IF NOT EXISTS idx_reports_created_by_user_id ON reports(created_by_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_location ON reports USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_priority_score ON reports(priority_score DESC);

CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(40) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'NEW',
    latitude DOUBLE PRECISION NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
    longitude DOUBLE PRECISION NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
    address_text VARCHAR(255),
    priority_score INTEGER NOT NULL DEFAULT 0 CHECK (priority_score >= 0),
    assigned_staff_id UUID REFERENCES users(id),
    created_by_overseer_id UUID REFERENCES users(id),
    before_photo_url VARCHAR(2048),
    after_photo_url VARCHAR(2048),
    staff_note TEXT,
    ai_confidence_score DOUBLE PRECISION CHECK (
        ai_confidence_score IS NULL OR (ai_confidence_score >= 0 AND ai_confidence_score <= 1)
    ),
    ai_decision VARCHAR(120),
    started_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ,
    closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    location GEOMETRY(Point, 4326)
        GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    CONSTRAINT tasks_category_check CHECK (category IN (
        'ROAD_DAMAGE',
        'STREET_LIGHT',
        'GARBAGE',
        'WATER_LEAK',
        'DRAINAGE',
        'TRAFFIC_SIGN',
        'TREE_BLOCKAGE',
        'OTHER'
    )),
    CONSTRAINT tasks_status_check CHECK (status IN (
        'NEW',
        'ASSIGNED',
        'IN_PROGRESS',
        'DONE',
        'PENDING_REVIEW',
        'APPROVED',
        'CLOSED',
        'CANCELLED'
    ))
);

CREATE INDEX IF NOT EXISTS idx_tasks_assigned_staff_id ON tasks(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by_overseer_id ON tasks(created_by_overseer_id);
CREATE INDEX IF NOT EXISTS idx_tasks_location ON tasks USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority_score ON tasks(priority_score DESC);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'reports_linked_task_id_fkey'
    ) THEN
        ALTER TABLE reports
            ADD CONSTRAINT reports_linked_task_id_fkey
            FOREIGN KEY (linked_task_id) REFERENCES tasks(id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reports_linked_task_id ON reports(linked_task_id);

CREATE TABLE IF NOT EXISTS report_upvotes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT report_upvotes_report_user_unique UNIQUE (report_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_report_upvotes_report_id ON report_upvotes(report_id);
CREATE INDEX IF NOT EXISTS idx_report_upvotes_user_id ON report_upvotes(user_id);

CREATE TABLE IF NOT EXISTS task_reports (
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
    PRIMARY KEY (task_id, report_id)
);

CREATE INDEX IF NOT EXISTS idx_task_reports_report_id ON task_reports(report_id);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_users_updated_at ON users;
CREATE TRIGGER set_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_reports_updated_at ON reports;
CREATE TRIGGER set_reports_updated_at
    BEFORE UPDATE ON reports
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS set_tasks_updated_at ON tasks;
CREATE TRIGGER set_tasks_updated_at
    BEFORE UPDATE ON tasks
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();

COMMENT ON COLUMN tasks.ai_confidence_score IS 'Reserved for future AI verification; not used during the core CRUD-first phase.';
COMMENT ON COLUMN tasks.ai_decision IS 'Reserved for future AI verification; not used during the core CRUD-first phase.';
