ALTER TABLE tasks
    DROP CONSTRAINT IF EXISTS tasks_status_check,
    ADD CONSTRAINT tasks_status_check CHECK (status IN (
        'NEW',
        'ASSIGNED',
        'IN_PROGRESS',
        'DONE',
        'PENDING_REVIEW',
        'DENIED',
        'APPROVED',
        'CLOSED',
        'CANCELLED'
    ));
