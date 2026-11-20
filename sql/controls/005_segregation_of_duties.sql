WITH sod_conflict_rules AS (
    SELECT
        'CREATE_USERS'::VARCHAR AS permission_1,
        'ASSIGN_ROLES'::VARCHAR AS permission_2,
        'USER_CREATION_AND_ROLE_ASSIGNMENT'::VARCHAR AS conflict_name
),

user_permissions AS (
    SELECT DISTINCT
        ur.user_id,
        u.username,
        e.employee_number,
        e.first_name,
        e.last_name,
        p.permission_name,
        r.role_name

    FROM user_roles ur
    INNER JOIN users u
        ON ur.user_id = u.user_id
    INNER JOIN employees e
        ON u.employee_id = e.employee_id
    INNER JOIN role_permissions rp
        ON ur.role_id = rp.role_id
    INNER JOIN permissions p
        ON rp.permission_id = p.permission_id
    INNER JOIN roles r
        ON ur.role_id = r.role_id

    WHERE ur.revoked_at IS NULL
      AND u.status = 'Active'
),

detected_conflicts AS (
    SELECT
        p1.user_id,
        p1.username,
        p1.employee_number,
        p1.first_name,
        p1.last_name,
        rules.conflict_name,
        rules.permission_1,
        rules.permission_2

    FROM sod_conflict_rules rules

    INNER JOIN user_permissions p1
        ON p1.permission_name = rules.permission_1

    INNER JOIN user_permissions p2
        ON p1.user_id = p2.user_id
       AND p2.permission_name = rules.permission_2
)

SELECT
    user_id,
    username,
    employee_number,
    first_name,
    last_name,
    conflict_name,
    permission_1,
    permission_2,
    'SOD_CONFLICT_DETECTED' AS exception_type

FROM detected_conflicts
ORDER BY username;