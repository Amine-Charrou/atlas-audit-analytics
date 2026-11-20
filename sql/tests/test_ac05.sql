
BEGIN;

-- ============================================================
-- AC-05: SEGREGATION OF DUTIES (SoD)
-- Test scenarios:
-- T01: User with conflicting permissions must be detected.
-- T02: User without conflicting permissions must not be detected.
-- ============================================================


-- 1. CREATE TEST EMPLOYEES

INSERT INTO employees (
    employee_number,
    first_name,
    last_name,
    department_id,
    hire_date
)
SELECT
    v.employee_number,
    'Test',
    v.employee_number,
    d.department_id,
    DATE '2020-01-01'
FROM (
    VALUES
        ('TAC05-01'),
        ('TAC05-02')
) AS v(employee_number)
CROSS JOIN departments d
WHERE d.department_name = 'IT';


-- 2. CREATE TEST USER ACCOUNTS

INSERT INTO users (
    employee_id,
    username,
    status,
    created_at
)
SELECT
    employee_id,
    CASE employee_number
        WHEN 'TAC05-01' THEN 'tac05_conflicting'
        WHEN 'TAC05-02' THEN 'tac05_non_conflicting'
    END,
    'Active',
    CURRENT_TIMESTAMP
FROM employees
WHERE employee_number IN ('TAC05-01', 'TAC05-02');


-- 3. ASSIGN IT_MANAGER TO THE CONFLICTING USER
-- IT_MANAGER has CREATE_USERS and ASSIGN_ROLES.

INSERT INTO user_roles (
    user_id,
    role_id,
    authorized,
    assigned_at,
    assigned_by_employee_id
)
SELECT
    u.user_id,
    r.role_id,
    TRUE,
    CURRENT_TIMESTAMP,
    e.employee_id
FROM users u
INNER JOIN employees e
    ON u.employee_id = e.employee_id
INNER JOIN roles r
    ON r.role_name = 'IT_MANAGER'
WHERE u.username = 'tac05_conflicting';


-- 4. ASSIGN VIEWER TO THE NON-CONFLICTING USER

INSERT INTO user_roles (
    user_id,
    role_id,
    authorized,
    assigned_at,
    assigned_by_employee_id
)
SELECT
    u.user_id,
    r.role_id,
    TRUE,
    CURRENT_TIMESTAMP,
    e.employee_id
FROM users u
INNER JOIN employees e
    ON u.employee_id = e.employee_id
INNER JOIN roles r
    ON r.role_name = 'VIEWER'
WHERE u.username = 'tac05_non_conflicting';


-- 5. DETECT SEGREGATION OF DUTIES CONFLICTS

CREATE TEMP TABLE ac05_test_results AS

WITH user_permissions AS (

    SELECT DISTINCT
        ur.user_id,
        u.username,
        p.permission_name

    FROM user_roles ur

    INNER JOIN users u
        ON ur.user_id = u.user_id

    INNER JOIN role_permissions rp
        ON ur.role_id = rp.role_id

    INNER JOIN permissions p
        ON rp.permission_id = p.permission_id

    WHERE ur.revoked_at IS NULL
      AND u.status = 'Active'
)

SELECT DISTINCT
    p1.username,
    'USER_CREATION_AND_ROLE_ASSIGNMENT' AS conflict_name

FROM user_permissions p1

INNER JOIN user_permissions p2
    ON p1.user_id = p2.user_id

WHERE p1.permission_name = 'CREATE_USERS'
  AND p2.permission_name = 'ASSIGN_ROLES'
  AND p1.username IN (
      'tac05_conflicting',
      'tac05_non_conflicting'
  );


-- 6. VALIDATE TEST RESULTS

DO $$
BEGIN

    -- T01: Conflicting user must be detected.

    IF NOT EXISTS (
        SELECT 1
        FROM ac05_test_results
        WHERE username = 'tac05_conflicting'
    ) THEN
        RAISE EXCEPTION
            'T01 failed: conflicting permissions not detected';
    END IF;


    -- T02: Non-conflicting user must not be detected.

    IF EXISTS (
        SELECT 1
        FROM ac05_test_results
        WHERE username = 'tac05_non_conflicting'
    ) THEN
        RAISE EXCEPTION
            'T02 failed: non-conflicting user incorrectly detected';
    END IF;


    RAISE NOTICE 'AC-05: All 2 tests passed.';

END $$;


-- 7. DISPLAY RESULTS

SELECT *
FROM ac05_test_results
ORDER BY username;


-- 8. ROLLBACK TEST DATA

ROLLBACK;
