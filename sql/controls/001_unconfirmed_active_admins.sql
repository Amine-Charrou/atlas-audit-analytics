
-- =====================================================
-- ATLAS AUDIT ANALYTICS
-- CONTROL: AC-01
-- Active Privileged Accounts Without Confirmed Authorization
-- =====================================================

SELECT
    u.user_id,
    u.username,

    e.employee_number,
    e.first_name,
    e.last_name,

    d.department_name,

    r.role_name,
    r.privilege_level,

    ur.authorized,

    CASE
        WHEN ur.authorized IS FALSE
            THEN 'NOT_AUTHORIZED'
        WHEN ur.authorized IS NULL
            THEN 'UNKNOWN_AUTHORIZATION'
    END AS exception_type,

    ur.assigned_at,
    ur.approval_reference

FROM users u

INNER JOIN employees e
    ON u.employee_id = e.employee_id

INNER JOIN departments d
    ON e.department_id = d.department_id

INNER JOIN user_roles ur
    ON u.user_id = ur.user_id

INNER JOIN roles r
    ON ur.role_id = r.role_id

WHERE
    u.status = 'Active'

    AND ur.revoked_at IS NULL

    AND r.privilege_level IN ('High', 'Critical')

    AND ur.authorized IS NOT TRUE

ORDER BY
    r.privilege_level DESC,
    u.username;


