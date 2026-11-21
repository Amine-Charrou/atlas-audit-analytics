
-- ============================================================
-- ATLAS AUDIT ANALYTICS
-- JALON 4.5 - RECOMMENDATION ENGINE
-- ============================================================

BEGIN;

-- One active recommendation per finding.
-- Historical recommendations with status Implemented or
-- Rejected remain preserved.

CREATE UNIQUE INDEX IF NOT EXISTS uq_active_recommendation_finding
    ON audit_recommendations(finding_id)
    WHERE status IN ('Open', 'In Progress');

CREATE INDEX IF NOT EXISTS idx_recommendations_priority
    ON audit_recommendations(priority);

CREATE INDEX IF NOT EXISTS idx_recommendations_due_date
    ON audit_recommendations(due_date);

COMMIT;

