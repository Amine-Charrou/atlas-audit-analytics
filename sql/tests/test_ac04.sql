BEGIN;

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
    VALUES ('TAC04-01'), ('TAC04-02'), ('TAC04-03')
) AS v(employee_number)
CROSS JOIN departments d
WHERE d.department_name = 'IT';

INSERT INTO users (
    employee_id,
    username,
    status,
    created_at
)
SELECT
    employee_id,
    CASE employee_number
        WHEN 'TAC04-01' THEN 'tac04_approved'
        WHEN 'TAC04-02' THEN 'tac04_missing'
        WHEN 'TAC04-03' THEN 'tac04_self_approved'
    END,
    'Active',
    CURRENT_TIMESTAMP
FROM employees
WHERE employee_number LIKE 'TAC04-%';

-- Attribution avec approbation complète
INSERT INTO user_roles (
    user_id,
    role_id,
    authorized,
    assigned_at,
    assigned_by_employee_id,
    approved_at,
    approved_by_employee_id,
    approval_reference
)
SELECT
    u.user_id,
    r.role_id,
    TRUE,
    CURRENT_TIMESTAMP,
    e.employee_id,
    CURRENT_TIMESTAMP,
    approver.employee_id,
    'TEST-APPROVAL-001'
FROM users u
INNER JOIN employees e ON u.employee_id = e.employee_id
INNER JOIN roles r ON r.role_name = 'VIEWER'
INNER JOIN employees approver
    ON approver.employee_number = 'E001'
WHERE u.username = 'tac04_approved';

-- Attribution sans preuve d'approbation
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
INNER JOIN employees e ON u.employee_id = e.employee_id
INNER JOIN roles r ON r.role_name = 'VIEWER'
WHERE u.username = 'tac04_missing';

-- Attribution approuvée par la même personne qui l'a effectuée
INSERT INTO user_roles (
    user_id,
    role_id,
    authorized,
    assigned_at,
    assigned_by_employee_id,
    approved_at,
    approved_by_employee_id,
    approval_reference
)
SELECT
    u.user_id,
    r.role_id,
    TRUE,
    CURRENT_TIMESTAMP,
    e.employee_id,
    CURRENT_TIMESTAMP,
    e.employee_id,
    'TEST-SELF-APPROVAL'
FROM users u
INNER JOIN employees e ON u.employee_id = e.employee_id
INNER JOIN roles r ON r.role_name = 'VIEWER'
WHERE u.username = 'tac04_self_approved';

CREATE TEMP TABLE ac04_test_results AS
SELECT
    u.username,
    CASE
        WHEN ur.approved_at IS NULL
          OR ur.approved_by_employee_id IS NULL
          OR ur.approval_reference IS NULL
            THEN 'MISSING_APPROVAL_EVIDENCE'
        WHEN ur.assigned_by_employee_id = ur.approved_by_employee_id
            THEN 'SELF_APPROVED_ASSIGNMENT'
    END AS exception_type
FROM user_roles ur
INNER JOIN users u ON ur.user_id = u.user_id
WHERE u.username LIKE 'tac04\_%'
  AND ur.revoked_at IS NULL
  AND (
        ur.approved_at IS NULL
        OR ur.approved_by_employee_id IS NULL
        OR ur.approval_reference IS NULL
        OR ur.assigned_by_employee_id = ur.approved_by_employee_id
      );

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM ac04_test_results
        WHERE username = 'tac04_approved'
    ) THEN RAISE EXCEPTION 'T01 failed: approved assignment detected'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ac04_test_results
        WHERE username = 'tac04_missing'
          AND exception_type = 'MISSING_APPROVAL_EVIDENCE'
    ) THEN RAISE EXCEPTION 'T02 failed'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ac04_test_results
        WHERE username = 'tac04_self_approved'
          AND exception_type = 'SELF_APPROVED_ASSIGNMENT'
    ) THEN RAISE EXCEPTION 'T03 failed'; END IF;

    RAISE NOTICE 'AC-04: All 3 tests passed.';
END $$;

SELECT * FROM ac04_test_results ORDER BY username;

ROLLBACK;


