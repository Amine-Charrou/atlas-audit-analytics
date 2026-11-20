
-- =====================================================
-- TEST SUITE: AC-02
-- Former Employees with Active Accounts
-- =====================================================

BEGIN;

-- Create test employees

INSERT INTO employees (
    employee_number,
    first_name,
    last_name,
    department_id,
    hire_date,
    termination_at
)
SELECT
    v.employee_number,
    'Test',
    v.username,
    d.department_id,
    DATE '2020-01-01',
    v.termination_at
FROM (
    VALUES
        ('TAC021', 'test_ac02_t01', NULL::TIMESTAMPTZ),
        ('TAC022', 'test_ac02_t02',
         TIMESTAMPTZ '2026-10-01 09:00:00+00'),
        ('TAC023', 'test_ac02_t03',
         TIMESTAMPTZ '2026-10-01 09:00:00+00'),
        ('TAC024', 'test_ac02_t04', NULL::TIMESTAMPTZ)
) AS v(employee_number, username, termination_at)
JOIN departments d
    ON d.department_name = 'IT';


-- Create test accounts

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
        ('TAC021', 'test_ac02_t01', 'Active'),
        ('TAC022', 'test_ac02_t02', 'Active'),
        ('TAC023', 'test_ac02_t03', 'Disabled'),
        ('TAC024', 'test_ac02_t04', 'Active')
) AS v(employee_number, username, status)
JOIN employees e
    ON e.employee_number = v.employee_number;


-- Expected results

WITH expected_results AS (
    SELECT *
    FROM (
        VALUES
            ('test_ac02_t01', FALSE, 'T01 - Current employee'),
            ('test_ac02_t02', TRUE, 'T02 - Former employee with active account'),
            ('test_ac02_t03', FALSE, 'T03 - Former employee with disabled account'),
            ('test_ac02_t04', FALSE, 'T04 - Missing termination date')
    ) AS v(username, expected_detection, test_description)
),

detected_exceptions AS (
    SELECT
        u.username
    FROM employees e
    JOIN users u
        ON e.employee_id = u.employee_id
    WHERE e.termination_at IS NOT NULL
      AND u.status = 'Active'
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

ROLLBACK;
