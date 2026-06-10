ALTER TABLE reports
    DROP CONSTRAINT IF EXISTS reports_status_check;

ALTER TABLE reports
    ADD CONSTRAINT reports_status_check
    CHECK (status IN (
        'SUBMITTED',
        'IN_REVIEW',
        'IN_PROGRESS',
        'RESOLVED',
        'REJECTED',
        'APPROVED',
        'CLOSED',
        'PENDING_REVIEW'
    ));
