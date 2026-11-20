
-- ============================================================
-- ATLAS AUDIT ANALYTICS
-- PHASE 4.1: AUDIT FINDINGS & RISK ASSESSMENT
-- PostgreSQL 18
-- ============================================================

-- ------------------------------------------------------------
-- 1. AUDIT FINDINGS
-- Stores exceptions identified by audit controls.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS audit_findings (

    finding_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    control_code VARCHAR(10) NOT NULL,

    exception_type VARCHAR(100) NOT NULL,

    title VARCHAR(200) NOT NULL,

    description TEXT NOT NULL,

    affected_user_id INTEGER,

    status VARCHAR(20) NOT NULL DEFAULT 'Open',

    detected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    resolved_at TIMESTAMPTZ,

    resolution_notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_finding_user
        FOREIGN KEY (affected_user_id)
        REFERENCES users(user_id),

    CONSTRAINT chk_finding_control_code
        CHECK (
            control_code IN (
                'AC-01',
                'AC-02',
                'AC-03',
                'AC-04',
                'AC-05'
            )
        ),

    CONSTRAINT chk_finding_status
        CHECK (
            status IN (
                'Open',
                'In Progress',
                'Resolved'
            )
        ),

    CONSTRAINT chk_finding_resolution
        CHECK (
            (status = 'Resolved') = (resolved_at IS NOT NULL)
        )
);


-- ------------------------------------------------------------
-- 2. RISK ASSESSMENTS
-- Stores risk evaluations and preserves reassessment history.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS risk_assessments (

    assessment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    finding_id INTEGER NOT NULL,

    impact_score INTEGER NOT NULL,

    likelihood_score INTEGER NOT NULL,

    risk_score INTEGER GENERATED ALWAYS AS (
        impact_score * likelihood_score
    ) STORED,

    risk_level VARCHAR(10) GENERATED ALWAYS AS (
        CASE
            WHEN impact_score * likelihood_score BETWEEN 1 AND 4
                THEN 'Low'

            WHEN impact_score * likelihood_score BETWEEN 5 AND 9
                THEN 'Medium'

            WHEN impact_score * likelihood_score BETWEEN 10 AND 16
                THEN 'High'

            ELSE 'Critical'
        END
    ) STORED,

    assessment_rationale TEXT NOT NULL,

    assessed_by VARCHAR(100),

    assessed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_assessment_finding
        FOREIGN KEY (finding_id)
        REFERENCES audit_findings(finding_id),

    CONSTRAINT chk_impact_score
        CHECK (impact_score BETWEEN 1 AND 5),

    CONSTRAINT chk_likelihood_score
        CHECK (likelihood_score BETWEEN 1 AND 5)

);


-- ------------------------------------------------------------
-- 3. AUDIT RECOMMENDATIONS
-- Stores corrective actions linked to audit findings.
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS audit_recommendations (

    recommendation_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    finding_id INTEGER NOT NULL,

    title VARCHAR(200) NOT NULL,

    description TEXT NOT NULL,

    priority VARCHAR(10) NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'Open',

    assigned_to VARCHAR(100),

    due_date DATE,

    completed_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_recommendation_finding
        FOREIGN KEY (finding_id)
        REFERENCES audit_findings(finding_id),

    CONSTRAINT chk_recommendation_priority
        CHECK (
            priority IN (
                'Low',
                'Medium',
                'High',
                'Critical'
            )
        ),

    CONSTRAINT chk_recommendation_status
        CHECK (
            status IN (
                'Open',
                'In Progress',
                'Implemented',
                'Rejected'
            )
        ),

    CONSTRAINT chk_recommendation_completion
        CHECK (
            (status = 'Implemented') = (completed_at IS NOT NULL)
        )
);


-- ------------------------------------------------------------
-- 4. INDEXES
-- Improve query performance for audit reporting.
-- ------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_findings_control_code
    ON audit_findings(control_code);

CREATE INDEX IF NOT EXISTS idx_findings_status
    ON audit_findings(status);

CREATE INDEX IF NOT EXISTS idx_findings_affected_user
    ON audit_findings(affected_user_id);

CREATE INDEX IF NOT EXISTS idx_assessments_finding
    ON risk_assessments(finding_id);

CREATE INDEX IF NOT EXISTS idx_assessments_risk_level
    ON risk_assessments(risk_level);

CREATE INDEX IF NOT EXISTS idx_recommendations_finding
    ON audit_recommendations(finding_id);

CREATE INDEX IF NOT EXISTS idx_recommendations_status
    ON audit_recommendations(status);


-- ------------------------------------------------------------
-- 5. VALIDATION
-- ------------------------------------------------------------

SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
      'audit_findings',
      'risk_assessments',
      'audit_recommendations'
  )
ORDER BY table_name;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
