BEGIN;

-- Création des employés de test
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
    v.employee_number,
    d.department_id,
    DATE '2020-01-01',
    v.termination_at
FROM (
    VALUES
        ('TAC03-01', CURRENT_TIMESTAMP - INTERVAL '30 hours'),
        ('TAC03-02', CURRENT_TIMESTAMP - INTERVAL '30 hours'),
        ('TAC03-03', CURRENT_TIMESTAMP - INTERVAL '30 hours'),
        ('TAC03-04', CURRENT_TIMESTAMP - INTERVAL '30 hours'),
        ('TAC03-05', CURRENT_TIMESTAMP - INTERVAL '1 hour'),
        ('TAC03-06', CURRENT_TIMESTAMP - INTERVAL '30 hours')
) AS v(employee_number, termination_at)
CROSS JOIN departments d
WHERE d.department_name = 'IT';

-- Création des comptes associés
INSERT INTO users (
    employee_id,
    username,
    status,
    created_at,
    deactivated_at
)
SELECT
    e.employee_id,
    CASE e.employee_number
        WHEN 'TAC03-01' THEN 'tac03_compliant_23h'
        WHEN 'TAC03-02' THEN 'tac03_compliant_24h'
        WHEN 'TAC03-03' THEN 'tac03_late_26h'
        WHEN 'TAC03-04' THEN 'tac03_overdue'
        WHEN 'TAC03-05' THEN 'tac03_within_sla'
        WHEN 'TAC03-06' THEN 'tac03_before_termination'
    END,
    CASE
        WHEN e.employee_number IN ('TAC03-04', 'TAC03-05')
            THEN 'Active'
        ELSE 'Disabled'
    END,
    CURRENT_TIMESTAMP,
    CASE e.employee_number
        WHEN 'TAC03-01' THEN e.termination_at + INTERVAL '23 hours 15 minutes'
        WHEN 'TAC03-02' THEN e.termination_at + INTERVAL '24 hours'
        WHEN 'TAC03-03' THEN e.termination_at + INTERVAL '26 hours'
        WHEN 'TAC03-06' THEN e.termination_at - INTERVAL '1 hour'
        ELSE NULL
    END
FROM employees e
WHERE e.employee_number LIKE 'TAC03-%';

-- Reproduction de la logique AC-03 sur les données de test
CREATE TEMP TABLE ac03_test_results AS
SELECT
    e.employee_number,
    u.username,
    CASE
        WHEN u.status = 'Disabled'
             AND u.deactivated_at < e.termination_at
            THEN 'DEACTIVATED_BEFORE_TERMINATION'
        WHEN u.status = 'Disabled'
             AND u.deactivated_at <= e.termination_at + INTERVAL '24 hours'
            THEN 'COMPLIANT'
        WHEN u.status = 'Disabled'
             AND u.deactivated_at > e.termination_at + INTERVAL '24 hours'
            THEN 'NON_COMPLIANT'
        WHEN u.status = 'Active'
             AND CURRENT_TIMESTAMP > e.termination_at + INTERVAL '24 hours'
            THEN 'PENDING_OVERDUE'
        WHEN u.status = 'Active'
            THEN 'PENDING_WITHIN_SLA'
    END AS compliance_status
FROM employees e
INNER JOIN users u ON e.employee_id = u.employee_id
WHERE e.employee_number LIKE 'TAC03-%';

-- Vérification des résultats
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM ac03_test_results
        WHERE username = 'tac03_compliant_23h'
          AND compliance_status = 'COMPLIANT'
    ) THEN RAISE EXCEPTION 'T01 failed'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ac03_test_results
        WHERE username = 'tac03_compliant_24h'
          AND compliance_status = 'COMPLIANT'
    ) THEN RAISE EXCEPTION 'T02 failed'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ac03_test_results
        WHERE username = 'tac03_late_26h'
          AND compliance_status = 'NON_COMPLIANT'
    ) THEN RAISE EXCEPTION 'T03 failed'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ac03_test_results
        WHERE username = 'tac03_overdue'
          AND compliance_status = 'PENDING_OVERDUE'
    ) THEN RAISE EXCEPTION 'T04 failed'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ac03_test_results
        WHERE username = 'tac03_within_sla'
          AND compliance_status = 'PENDING_WITHIN_SLA'
    ) THEN RAISE EXCEPTION 'T05 failed'; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM ac03_test_results
        WHERE username = 'tac03_before_termination'
          AND compliance_status = 'DEACTIVATED_BEFORE_TERMINATION'
    ) THEN RAISE EXCEPTION 'T06 failed'; END IF;

    RAISE NOTICE 'AC-03: All 6 tests passed.';
END $$;

SELECT * FROM ac03_test_results ORDER BY username;

ROLLBACK;