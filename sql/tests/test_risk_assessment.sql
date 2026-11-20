
-- ============================================================
-- ATLAS AUDIT ANALYTICS
-- TEST: AUDIT FINDINGS & RISK ASSESSMENT
-- ============================================================

BEGIN;

DO $$

DECLARE
    v_user_id INTEGER;
    v_finding_id INTEGER;
    v_assessment_id INTEGER;
    v_recommendation_id INTEGER;

    v_risk_score INTEGER;
    v_risk_level VARCHAR(10);

BEGIN

    -- --------------------------------------------------------
    -- T01: Retrieve an existing test user
    -- --------------------------------------------------------

    SELECT user_id
    INTO v_user_id
    FROM users
    WHERE username = 'nadia.benali';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION
            'T01 failed: test user nadia.benali not found';
    END IF;


    -- --------------------------------------------------------
    -- T02: Create an audit finding
    -- --------------------------------------------------------

    INSERT INTO audit_findings (
        control_code,
        exception_type,
        title,
        description,
        affected_user_id
    )
    VALUES (
        'AC-05',
        'SOD_CONFLICT_DETECTED',
        'Conflicting user permissions',
        'User has both CREATE_USERS and ASSIGN_ROLES permissions.',
        v_user_id
    )
    RETURNING finding_id INTO v_finding_id;

    IF v_finding_id IS NULL THEN
        RAISE EXCEPTION
            'T02 failed: audit finding not created';
    END IF;


    -- --------------------------------------------------------
    -- T03: Create a risk assessment
    -- Impact = 5
    -- Likelihood = 4
    -- Expected score = 20
    -- Expected level = Critical
    -- --------------------------------------------------------

    INSERT INTO risk_assessments (
        finding_id,
        impact_score,
        likelihood_score,
        assessment_rationale,
        assessed_by
    )
    VALUES (
        v_finding_id,
        5,
        4,
        'A user can create accounts and assign roles, creating a potential access control conflict.',
        'Audit Team'
    )
    RETURNING assessment_id INTO v_assessment_id;


    SELECT risk_score, risk_level
    INTO v_risk_score, v_risk_level
    FROM risk_assessments
    WHERE assessment_id = v_assessment_id;


    IF v_risk_score <> 20 THEN
        RAISE EXCEPTION
            'T03 failed: expected score 20, got %',
            v_risk_score;
    END IF;

    IF v_risk_level <> 'Critical' THEN
        RAISE EXCEPTION
            'T03 failed: expected Critical, got %',
            v_risk_level;
    END IF;


    -- --------------------------------------------------------
    -- T04: Create a corrective recommendation
    -- --------------------------------------------------------

    INSERT INTO audit_recommendations (
        finding_id,
        title,
        description,
        priority,
        assigned_to,
        due_date
    )
    VALUES (
        v_finding_id,
        'Review conflicting permissions',
        'Separate user creation and role assignment responsibilities.',
        'Critical',
        'IT Security Team',
        CURRENT_DATE + 30
    )
    RETURNING recommendation_id INTO v_recommendation_id;


    IF v_recommendation_id IS NULL THEN
        RAISE EXCEPTION
            'T04 failed: recommendation not created';
    END IF;


    -- --------------------------------------------------------
    -- SUCCESS
    -- --------------------------------------------------------

    RAISE NOTICE 'T01 PASS: Existing user retrieved.';
    RAISE NOTICE 'T02 PASS: Audit finding created.';
    RAISE NOTICE 'T03 PASS: Risk score and level calculated correctly.';
    RAISE NOTICE 'T04 PASS: Recommendation created.';

    RAISE NOTICE 'Risk Assessment Model: All 4 tests passed.';

END $$;


-- Display generated test data before rollback

SELECT
    f.finding_id,
    f.control_code,
    f.title,
    u.username,
    ra.impact_score,
    ra.likelihood_score,
    ra.risk_score,
    ra.risk_level,
    ar.title AS recommendation,
    ar.priority

FROM audit_findings f

INNER JOIN users u
    ON f.affected_user_id = u.user_id

INNER JOIN risk_assessments ra
    ON f.finding_id = ra.finding_id

INNER JOIN audit_recommendations ar
    ON f.finding_id = ar.finding_id

WHERE f.title = 'Conflicting user permissions';


-- Remove all test records

ROLLBACK;

-- ============================================================
-- END OF TEST
-- ============================================================
