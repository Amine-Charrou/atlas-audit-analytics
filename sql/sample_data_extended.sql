-- ============================================================
-- ATLAS AUDIT ANALYTICS
-- Extended synthetic dataset for AC-01 through AC-05
-- Creates 120 test employees, accounts and role assignments.
-- Fictional records only. Safe to run more than once.
-- ============================================================

BEGIN;

-- This seed expects sql/schema.sql and sql/sample_data.sql to have
-- already created departments, roles, permissions and their base data.
-- It only inserts rows in the synthetic fixture namespace TST-* / atlas.test.*.

WITH generated AS (
    SELECT n
    FROM generate_series(1, 120) AS series(n)
), employee_rows AS (
    SELECT
        'TST-' || lpad(n::text, 3, '0') AS employee_number,
        'Synthetic'::varchar AS first_name,
        'User ' || lpad(n::text, 3, '0') AS last_name,
        CASE WHEN n IN (1, 2, 3, 4, 8)
            THEN CASE n
                WHEN 1 THEN CURRENT_TIMESTAMP - INTERVAL '30 days'
                WHEN 2 THEN CURRENT_TIMESTAMP - INTERVAL '30 days'
                WHEN 3 THEN CURRENT_TIMESTAMP - INTERVAL '20 days'
                WHEN 4 THEN CURRENT_TIMESTAMP - INTERVAL '10 days'
                WHEN 8 THEN CURRENT_TIMESTAMP - INTERVAL '2 hours'
            END
            ELSE NULL
        END AS termination_at,
        CASE ((n - 1) % 4)
            WHEN 0 THEN 'Finance'
            WHEN 1 THEN 'IT'
            WHEN 2 THEN 'Operations'
            ELSE 'Human Resources'
        END AS department_name
    FROM generated
)
INSERT INTO employees (
    employee_number, first_name, last_name, department_id, hire_date, termination_at
)
SELECT
    er.employee_number,
    er.first_name,
    er.last_name,
    d.department_id,
    DATE '2023-01-01',
    er.termination_at
FROM employee_rows er
JOIN departments d ON d.department_name = er.department_name
ON CONFLICT (employee_number) DO NOTHING;

WITH generated AS (
    SELECT n
    FROM generate_series(1, 120) AS series(n)
), account_rows AS (
    SELECT
        'TST-' || lpad(n::text, 3, '0') AS employee_number,
        'atlas.test.' || lpad(n::text, 3, '0') AS username,
        CASE WHEN n IN (2, 3, 4) THEN 'Disabled' ELSE 'Active' END AS status,
        CASE n
            WHEN 2 THEN CURRENT_TIMESTAMP - INTERVAL '30 days' + INTERVAL '36 hours'
            WHEN 3 THEN CURRENT_TIMESTAMP - INTERVAL '20 days' + INTERVAL '12 hours'
            WHEN 4 THEN CURRENT_TIMESTAMP - INTERVAL '10 days' - INTERVAL '2 hours'
            ELSE NULL
        END AS deactivated_at
    FROM generated
)
INSERT INTO users (employee_id, username, status, created_at, deactivated_at)
SELECT e.employee_id, ar.username, ar.status, TIMESTAMPTZ '2023-01-02 08:00:00+00', ar.deactivated_at
FROM account_rows ar
JOIN employees e ON e.employee_number = ar.employee_number
ON CONFLICT (username) DO NOTHING;

WITH generated AS (
    SELECT n
    FROM generate_series(1, 120) AS series(n)
), assignment_rows AS (
    SELECT
        'atlas.test.' || lpad(n::text, 3, '0') AS username,
        CASE n
            WHEN 5 THEN 'ADMIN'
            WHEN 6 THEN 'IT_MANAGER'
            WHEN 7 THEN 'ADMIN'
            WHEN 8 THEN 'ANALYST'
            ELSE CASE WHEN n % 2 = 0 THEN 'VIEWER' ELSE 'ANALYST' END
        END AS role_name,
        CASE WHEN n = 5 THEN FALSE ELSE TRUE END AS authorized,
        n
    FROM generated
)
INSERT INTO user_roles (
    user_id,
    role_id,
    authorized,
    assigned_at,
    assigned_by_employee_id,
    approved_at,
    approved_by_employee_id,
    approval_reference,
    revoked_at
)
SELECT
    u.user_id,
    r.role_id,
    ar.authorized,
    TIMESTAMPTZ '2025-01-15 09:00:00+00',
    assigner.employee_id,
    CASE WHEN ar.n IN (5, 6) THEN NULL ELSE TIMESTAMPTZ '2025-01-15 10:00:00+00' END,
    CASE
        WHEN ar.n IN (5, 6) THEN NULL
        WHEN ar.n = 7 THEN subject.employee_id
        ELSE approver.employee_id
    END,
    CASE
        WHEN ar.n IN (5, 6) THEN NULL
        WHEN ar.n = 7 THEN 'SYNTHETIC-SELF-APPROVAL-007'
        ELSE 'SYNTHETIC-APPROVAL-' || lpad(ar.n::text, 3, '0')
    END,
    NULL
FROM assignment_rows ar
JOIN users u ON u.username = ar.username
JOIN employees subject ON subject.employee_id = u.employee_id
JOIN roles r ON r.role_name = ar.role_name
LEFT JOIN employees assigner
    ON assigner.employee_number = CASE WHEN ar.n = 7 THEN 'TST-007' ELSE 'TST-009' END
LEFT JOIN employees approver
    ON approver.employee_number = 'TST-010'
ON CONFLICT (user_id, role_id) WHERE revoked_at IS NULL DO NOTHING;

COMMIT;

-- Expected fixture size (after the baseline dataset is loaded):
-- SELECT COUNT(*) FROM users WHERE username LIKE 'atlas.test.%';
-- Expected result: 120.
--
-- Coverage notes:
-- AC-01: atlas.test.005, active ADMIN with authorized = FALSE.
-- AC-02: atlas.test.001 and atlas.test.008, former employees with active accounts.
-- AC-03: atlas.test.001 pending overdue; .002 disabled after 24h; .003 within SLA;
--        .004 disabled before termination; .008 still within the 24h window.
-- AC-04: .005 and .006 missing approval evidence; .007 self-approved.
-- AC-05: .006 (IT_MANAGER) and .007 (ADMIN) have conflicting permissions.
-- All remaining generated assignments are approved and do not create SOD conflicts.
