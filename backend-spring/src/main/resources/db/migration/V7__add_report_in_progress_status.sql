ALTER TABLE reports
    DROP CONSTRAINT IF EXISTS reports_status_check,
    ADD CONSTRAINT reports_status_check CHECK (status IN ('SUBMITTED', 'IN_PROGRESS', 'FIXED', 'CANCELLED'));
