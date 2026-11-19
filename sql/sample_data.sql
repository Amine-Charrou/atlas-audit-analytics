
-- =====================================================
-- ATLAS AUDIT ANALYTICS
-- Synthetic Dataset v1.0
-- Module: User Access Audit
-- All records are fictional.
-- Execute only once on an empty dataset.
-- =====================================================

BEGIN;

-- =====================================================
-- 1. DEPARTMENTS
-- =====================================================

INSERT INTO departments (department_name, description)
VALUES
    ('Finance', 'Financial operations and accounting'),
    ('IT', 'Information technology and systems'),
    ('Operations', 'Business operations'),
    ('Human Resources', 'Human resources management');

-- =====================================================
-- 2. EMPLOYEES
-- =====================================================

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
    v.first_name,
    v.last_name,
    d.department_id,
    v.hire_date,
    v.termination_at
FROM (
    VALUES
        ('E001', 'Nadia', 'Benali', 'Finance',
         DATE '2021-04-12', NULL::TIMESTAMPTZ),

        ('E002', 'Yassine', 'Amrani', 'IT',
         DATE '2020-09-01', NULL::TIMESTAMPTZ),

        ('E003', 'Sara', 'El Idrissi', 'Operations',
         DATE '2022-01-10', NULL::TIMESTAMPTZ),

        ('E004', 'Omar', 'Tazi', 'Human Resources',
         DATE '2019-06-03', NULL::TIMESTAMPTZ),

        ('E005', 'Lina', 'Alaoui', 'Finance',
         DATE '2021-03-15', TIMESTAMPTZ '2026-10-01 09:00:00+00'),

        ('E006', 'Karim', 'Bennis', 'IT',
         DATE '2020-11-20', TIMESTAMPTZ '2026-10-10 09:30:00+00'),

        ('E007', 'Salma', 'Rami', 'Finance',
         DATE '2023-02-01', NULL::TIMESTAMPTZ),

        ('E008', 'Hamza', 'Idrissi', 'IT',
         DATE '2022-07-18', NULL::TIMESTAMPTZ),

        ('E009', 'Mehdi', 'Ziani', 'Operations',
         DATE '2024-01-08', NULL::TIMESTAMPTZ)
) AS v (
    employee_number,
    first_name,
    last_name,
    department_name,
    hire_date,
    termination_at
)
JOIN departments d
    ON d.department_name = v.department_name;

-- =====================================================
-- 3. USERS
-- =====================================================

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
    v.created_at,
    v.deactivated_at
FROM (
    VALUES
        ('E001', 'nadia.benali', 'Active',
         TIMESTAMPTZ '2021-04-13 08:00:00+00', NULL::TIMESTAMPTZ),

        ('E002', 'yassine.amrani', 'Active',
         TIMESTAMPTZ '2020-09-02 08:00:00+00', NULL::TIMESTAMPTZ),

        ('E003', 'sara.elidrissi', 'Active',
         TIMESTAMPTZ '2022-01-11 08:00:00+00', NULL::TIMESTAMPTZ),

        ('E004', 'omar.tazi', 'Disabled',
         TIMESTAMPTZ '2019-06-04 08:00:00+00',
         TIMESTAMPTZ '2025-08-16 10:00:00+00'),

        ('E005', 'lina.alaoui', 'Active',
         TIMESTAMPTZ '2021-03-16 08:00:00+00', NULL::TIMESTAMPTZ),

        ('E006', 'karim.bennis', 'Disabled',
         TIMESTAMPTZ '2020-11-21 08:00:00+00',
         TIMESTAMPTZ '2026-10-11 08:45:00+00'),

        ('E007', 'salma.rami', 'Active',
         TIMESTAMPTZ '2023-02-02 08:00:00+00', NULL::TIMESTAMPTZ),

        ('E008', 'hamza.idrissi', 'Active',
         TIMESTAMPTZ '2022-07-19 08:00:00+00', NULL::TIMESTAMPTZ),

        ('E009', 'mehdi.ziani', 'Active',
         TIMESTAMPTZ '2024-01-09 08:00:00+00', NULL::TIMESTAMPTZ)
) AS v (
    employee_number,
    username,
    status,
    created_at,
    deactivated_at
)
JOIN employees e
    ON e.employee_number = v.employee_number;

-- =====================================================
-- 4. ROLES
-- =====================================================

INSERT INTO roles (role_name, privilege_level, description)
VALUES
    ('ADMIN', 'Critical', 'Full administrative access'),
    ('IT_MANAGER', 'High', 'IT infrastructure and user management'),
    ('ANALYST', 'Medium', 'Data analysis and reporting'),
    ('VIEWER', 'Low', 'Read-only access');

-- =====================================================
-- 5. PERMISSIONS
-- =====================================================

INSERT INTO permissions (
    permission_name,
    resource,
    action,
    description
)
VALUES
    ('VIEW_USERS', 'Users', 'READ', 'View user accounts'),
    ('CREATE_USERS', 'Users', 'CREATE', 'Create user accounts'),
    ('UPDATE_USERS', 'Users', 'UPDATE', 'Modify user accounts'),
    ('DISABLE_USERS', 'Users', 'DISABLE', 'Disable user accounts'),
    ('ASSIGN_ROLES', 'Roles', 'ASSIGN', 'Assign roles to users'),
    ('VIEW_REPORTS', 'Reports', 'READ', 'View audit reports'),
    ('EXPORT_FINANCE', 'Finance', 'EXPORT', 'Export financial data'),
    ('VIEW_EMPLOYEES', 'Employees', 'READ', 'View employee records');

-- =====================================================
-- 6. USER_ROLES
-- =====================================================

WITH assignment_data (
    username,
    role_name,
    authorized,
    assigned_at,
    assigned_by_number,
    approved_at,
    approved_by_number,
    approval_reference,
    revoked_at
) AS (
    VALUES
        ('nadia.benali', 'ANALYST', TRUE,
         TIMESTAMPTZ '2024-01-15 09:00:00+00',
         'E002',
         TIMESTAMPTZ '2024-01-15 10:00:00+00',
         'E004',
         'APR-001',
         NULL::TIMESTAMPTZ),

        ('yassine.amrani', 'ADMIN', TRUE,
         TIMESTAMPTZ '2023-05-10 09:00:00+00',
         'E004',
         TIMESTAMPTZ '2023-05-10 10:00:00+00',
         'E004',
         'APR-002',
         NULL::TIMESTAMPTZ),

        ('sara.elidrissi', 'VIEWER', TRUE,
         TIMESTAMPTZ '2024-03-01 09:00:00+00',
         'E002',
         TIMESTAMPTZ '2024-03-01 10:00:00+00',
         'E004',
         'APR-003',
         NULL::TIMESTAMPTZ),

        ('omar.tazi', 'VIEWER', TRUE,
         TIMESTAMPTZ '2022-06-01 09:00:00+00',
         'E002',
         TIMESTAMPTZ '2022-06-01 10:00:00+00',
         'E004',
         'APR-004',
         TIMESTAMPTZ '2025-08-16 10:00:00+00'),

        ('lina.alaoui', 'ADMIN', NULL,
         TIMESTAMPTZ '2023-09-01 09:00:00+00',
         'E002',
         NULL::TIMESTAMPTZ,
         NULL,
         NULL,
         NULL::TIMESTAMPTZ),

        ('karim.bennis', 'IT_MANAGER', TRUE,
         TIMESTAMPTZ '2024-02-01 09:00:00+00',
         'E002',
         TIMESTAMPTZ '2024-02-01 10:00:00+00',
         'E004',
         'APR-005',
         TIMESTAMPTZ '2026-10-10 10:00:00+00'),

        ('salma.rami', 'ADMIN', FALSE,
         TIMESTAMPTZ '2025-01-15 09:00:00+00',
         'E002',
         NULL::TIMESTAMPTZ,
         NULL,
         NULL,
         NULL::TIMESTAMPTZ),

        ('hamza.idrissi', 'IT_MANAGER', TRUE,
         TIMESTAMPTZ '2024-06-01 09:00:00+00',
         'E004',
         TIMESTAMPTZ '2024-06-01 10:00:00+00',
         'E004',
         'APR-006',
         NULL::TIMESTAMPTZ),

        ('mehdi.ziani', 'ANALYST', TRUE,
         TIMESTAMPTZ '2025-02-01 09:00:00+00',
         'E002',
         TIMESTAMPTZ '2025-02-01 10:00:00+00',
         'E004',
         'APR-007',
         NULL::TIMESTAMPTZ)
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
    a.authorized,
    a.assigned_at,
    assigner.employee_id,
    a.approved_at,
    approver.employee_id,
    a.approval_reference,
    a.revoked_at
FROM assignment_data a
JOIN users u
    ON u.username = a.username
JOIN roles r
    ON r.role_name = a.role_name
LEFT JOIN employees assigner
    ON assigner.employee_number = a.assigned_by_number
LEFT JOIN employees approver
    ON approver.employee_number = a.approved_by_number;

-- =====================================================
-- 7. ROLE_PERMISSIONS
-- =====================================================

WITH role_permission_data (role_name, permission_name) AS (
    VALUES
        ('ADMIN', 'VIEW_USERS'),
        ('ADMIN', 'CREATE_USERS'),
        ('ADMIN', 'UPDATE_USERS'),
        ('ADMIN', 'DISABLE_USERS'),
        ('ADMIN', 'ASSIGN_ROLES'),
        ('ADMIN', 'VIEW_REPORTS'),
        ('ADMIN', 'EXPORT_FINANCE'),
        ('ADMIN', 'VIEW_EMPLOYEES'),

        ('IT_MANAGER', 'VIEW_USERS'),
        ('IT_MANAGER', 'CREATE_USERS'),
        ('IT_MANAGER', 'UPDATE_USERS'),
        ('IT_MANAGER', 'DISABLE_USERS'),
        ('IT_MANAGER', 'ASSIGN_ROLES'),
        ('IT_MANAGER', 'VIEW_REPORTS'),
        ('IT_MANAGER', 'VIEW_EMPLOYEES'),

        ('ANALYST', 'VIEW_REPORTS'),
        ('ANALYST', 'EXPORT_FINANCE'),
        ('ANALYST', 'VIEW_EMPLOYEES'),

        ('VIEWER', 'VIEW_REPORTS')
)
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    r.role_id,
    p.permission_id
FROM role_permission_data rp
JOIN roles r
    ON r.role_name = rp.role_name
JOIN permissions p
    ON p.permission_name = rp.permission_name;

COMMIT;

