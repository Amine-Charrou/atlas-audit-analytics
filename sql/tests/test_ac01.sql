
-- =====================================================
-- ATLAS AUDIT ANALYTICS
-- TEST SUITE: AC-01
-- Active Privileged Accounts Without Confirmed Authorization
--
-- IMPORTANT:
-- Test records are inserted inside a transaction.
-- ROLLBACK at the end removes all test records.
-- =====================================================

BEGIN;

-- =====================================================
-- TEST FIXTURES: 6 SCENARIOS
-- =====================================================

-- Create test employees

INSERT INTO employees (
    employee_number,
    first_name,
    last_name,
    department_id,
    hire_date
)
SELECT
    v.employee_number,
    'Audit Test',
    v.username,
    d.department_id,
    DATE '2020-01-01'
FROM (
    VALUES
        ('TAC01', 'test_ac01_t01'),
        ('TAC02', 'test_ac01_t02'),
        ('TAC03', 'test_ac01_t03'),
        ('TAC04', 'test_ac01_t04'),
        ('TAC05', 'test_ac01_t05'),
        ('TAC06', 'test_ac01_t06')
) AS v(employee_number, username)
JOIN departments d
    ON d.department_name = 'IT';


-- Create test users

INSERT INTO users (
    employee_id,
    username,
    status,
    created_at,
    deactivated_at
)
SELECT
    e.employee_id,
    v.username,
    v.status,
    CURRENT_TIMESTAMP,
    CASE
        WHEN v.status = 'Disabled'
            THEN CURRENT_TIMESTAMP
        ELSE NULL
    END
FROM (
    VALUES
        ('TAC01', 'test_ac01_t01', 'Active'),
        ('TAC02', 'test_ac01_t02', 'Active'),
        ('TAC03', 'test_ac01_t03', 'Active'),
        ('TAC04', 'test_ac01_t04', 'Disabled'),
        ('TAC05', 'test_ac01_t05', 'Active'),
        ('TAC06', 'test_ac01_t06', 'Active')
) AS v(employee_number, username, status)
JOIN employees e
    ON e.employee_number = v.employee_number;


-- Create test role assignments

INSERT INTO user_roles (
    user_id,
    role_id,
    authorized,
    assigned_at,
    revoked_at
)
SELECT
    u.user_id,
    r.role_id,
    v.authorized,
    TIMESTAMPTZ '2025-01-01 09:00:00+00',
    v.revoked_at
FROM (
    VALUES
        ('test_ac01_t01', 'ADMIN',
         TRUE, NULL::TIMESTAMPTZ),

        ('test_ac01_t02', 'ADMIN',
         FALSE, NULL::TIMESTAMPTZ),

        ('test_ac01_t03', 'ADMIN',
         NULL::BOOLEAN, NULL::TIMESTAMPTZ),

        ('test_ac01_t04', 'ADMIN',
         FALSE, NULL::TIMESTAMPTZ),

        ('test_ac01_t05', 'ADMIN',
         FALSE, TIMESTAMPTZ '2025-01-02 09:00:00+00'),

        ('test_ac01_t06', 'VIEWER',
         FALSE, NULL::TIMESTAMPTZ)
) AS v(username, role_name, authorized, revoked_at)
JOIN users u
    ON u.username = v.username
JOIN roles r
    ON r.role_name = v.role_name;


-- =====================================================
-- TEST EXECUTION
-- =====================================================

WITH expected_results AS (
    SELECT *
    FROM (
        VALUES
            ('test_ac01_t01', FALSE, 'T01 - Authorized admin'),
            ('test_ac01_t02', TRUE,  'T02 - Unauthorized admin'),
            ('test_ac01_t03', TRUE,  'T03 - Unknown authorization'),
            ('test_ac01_t04', FALSE, 'T04 - Disabled account'),
            ('test_ac01_t05', FALSE, 'T05 - Revoked role'),
            ('test_ac01_t06', FALSE, 'T06 - Low privilege role')
    ) AS v(username, expected_detection, test_description)
),

detected_exceptions AS (
    SELECT DISTINCT
        u.username
    FROM users u
    INNER JOIN user_roles ur
        ON u.user_id = ur.user_id
    INNER JOIN roles r
        ON ur.role_id = r.role_id
    WHERE u.status = 'Active'
      AND ur.revoked_at IS NULL
      AND r.privilege_level IN ('High', 'Critical')
      AND ur.authorized IS NOT TRUE
)

SELECT
    e.test_description,
    e.username,
    e.expected_detection,

    (d.username IS NOT NULL) AS actual_detection,

    CASE
        WHEN e.expected_detection = (d.username IS NOT NULL)
            THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result

FROM expected_results e
LEFT JOIN detected_exceptions d
    ON e.username = d.username
ORDER BY e.username;


-- =====================================================
-- CLEANUP
-- =====================================================

ROLLBACK;
