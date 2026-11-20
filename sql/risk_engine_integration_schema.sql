
-- ============================================================
-- ATLAS AUDIT ANALYTICS
-- JALON 4.3 - INTEGRATION SCHEMA
-- ============================================================

BEGIN;

-- 1. Audit execution history
CREATE TABLE IF NOT EXISTS audit_runs (
    run_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'Running',
    triggered_by VARCHAR(100) DEFAULT 'system',
    CONSTRAINT chk_audit_run_status
        CHECK (status IN (
            'Running',
            'Completed',
            'Completed_With_Errors',
            'Failed'
        )),
    CONSTRAINT chk_audit_run_dates
        CHECK (
            completed_at IS NULL
            OR completed_at >= started_at
        )
);

-- 2. Individual control execution history
CREATE TABLE IF NOT EXISTS control_executions (
    execution_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    run_id INTEGER NOT NULL
        REFERENCES audit_runs(run_id),
    control_code VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Running',
    findings_count INTEGER NOT NULL DEFAULT 0,
    error_message TEXT,
    started_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,

    CONSTRAINT uq_control_execution
        UNIQUE (run_id, control_code),

    CONSTRAINT chk_control_execution_code
        CHECK (control_code IN (
            'AC-01', 'AC-02', 'AC-03', 'AC-04', 'AC-05'
        )),

    CONSTRAINT chk_control_execution_status
        CHECK (status IN ('Running', 'Completed', 'Failed')),

    CONSTRAINT chk_findings_count
        CHECK (findings_count >= 0)
);

-- 3. Extend the existing findings table
ALTER TABLE audit_findings
    ADD COLUMN IF NOT EXISTS source_key VARCHAR(255);

ALTER TABLE audit_findings
    ADD COLUMN IF NOT EXISTS last_seen_at TIMESTAMPTZ;

ALTER TABLE audit_findings
    ADD COLUMN IF NOT EXISTS detection_count INTEGER
    NOT NULL DEFAULT 1;

ALTER TABLE audit_findings
    ADD COLUMN IF NOT EXISTS last_seen_run_id INTEGER;

-- Preserve existing findings if any
UPDATE audit_findings
SET
    source_key = COALESCE(
        source_key,
        'legacy-' || finding_id::VARCHAR
    ),
    last_seen_at = COALESCE(last_seen_at, detected_at)
WHERE source_key IS NULL
   OR last_seen_at IS NULL;

-- Enforce mandatory source identification
ALTER TABLE audit_findings
    ALTER COLUMN source_key SET NOT NULL;

ALTER TABLE audit_findings
    ALTER COLUMN last_seen_at SET NOT NULL;

-- Link the latest detection to its audit execution
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_finding_last_seen_run'
    ) THEN
        ALTER TABLE audit_findings
            ADD CONSTRAINT fk_finding_last_seen_run
            FOREIGN KEY (last_seen_run_id)
            REFERENCES audit_runs(run_id);
    END IF;
END $$;

-- 4. Prevent duplicate active findings.
-- A resolved finding can be detected again as a new record.
CREATE UNIQUE INDEX IF NOT EXISTS uq_active_finding_source
    ON audit_findings(control_code, source_key)
    WHERE status <> 'Resolved';

-- 5. Performance indexes
CREATE INDEX IF NOT EXISTS idx_audit_runs_started_at
    ON audit_runs(started_at);

CREATE INDEX IF NOT EXISTS idx_control_executions_run
    ON control_executions(run_id);

CREATE INDEX IF NOT EXISTS idx_findings_last_seen
    ON audit_findings(last_seen_at);

CREATE INDEX IF NOT EXISTS idx_findings_last_seen_run
    ON audit_findings(last_seen_run_id);

COMMIT;
 

