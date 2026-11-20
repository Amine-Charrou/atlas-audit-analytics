SELECT
    e.employee_number,
    e.first_name,
    e.last_name,
    u.username,
    u.status AS account_status,
    e.termination_at,
    u.deactivated_at,
    e.termination_at + INTERVAL '24 hours' AS sla_deadline,

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
    END AS compliance_status,

    CASE
        WHEN u.deactivated_at IS NOT NULL
            THEN u.deactivated_at - e.termination_at
        ELSE NULL
    END AS deactivation_delay

FROM employees e
INNER JOIN users u
    ON e.employee_id = u.employee_id
WHERE e.termination_at IS NOT NULL
ORDER BY e.termination_at;