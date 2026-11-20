
-- =====================================================
-- ATLAS AUDIT ANALYTICS
-- CONTROL: AC-02
-- Former Employees with Active Accounts
-- =====================================================

SELECT
    e.employee_id,
    e.employee_number,

    e.first_name,
    e.last_name,

    d.department_name,

    u.user_id,
    u.username,
    u.status,

    e.termination_at,
    u.created_at,
    u.deactivated_at,

    CURRENT_TIMESTAMP - e.termination_at
        AS time_since_termination,

    'FORMER_EMPLOYEE_ACTIVE_ACCOUNT'
        AS exception_type

FROM employees e

INNER JOIN departments d
    ON e.department_id = d.department_id

INNER JOIN users u
    ON e.employee_id = u.employee_id

WHERE
    e.termination_at IS NOT NULL
    AND u.status = 'Active'

ORDER BY
    e.termination_at;
