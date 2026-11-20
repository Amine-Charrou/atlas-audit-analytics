SELECT
    u.username,
    e.employee_number,
    e.first_name,
    e.last_name,
    r.role_name,
    r.privilege_level,

    ur.assigned_at,
    assigner.employee_number AS assigned_by,
    ur.approved_at,
    approver.employee_number AS approved_by,
    ur.approval_reference,

    CASE
        WHEN ur.approved_at IS NULL
          OR ur.approved_by_employee_id IS NULL
          OR ur.approval_reference IS NULL
            THEN 'MISSING_APPROVAL_EVIDENCE'

        WHEN ur.assigned_by_employee_id = ur.approved_by_employee_id
            THEN 'SELF_APPROVED_ASSIGNMENT'
    END AS exception_type

FROM user_roles ur
INNER JOIN users u
    ON ur.user_id = u.user_id
INNER JOIN employees e
    ON u.employee_id = e.employee_id
INNER JOIN roles r
    ON ur.role_id = r.role_id

LEFT JOIN employees assigner
    ON ur.assigned_by_employee_id = assigner.employee_id

LEFT JOIN employees approver
    ON ur.approved_by_employee_id = approver.employee_id

WHERE ur.revoked_at IS NULL
  AND (
        ur.approved_at IS NULL
        OR ur.approved_by_employee_id IS NULL
        OR ur.approval_reference IS NULL
        OR ur.assigned_by_employee_id = ur.approved_by_employee_id
      )

ORDER BY r.privilege_level DESC, u.username;