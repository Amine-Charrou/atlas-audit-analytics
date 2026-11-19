
-- =====================================================
-- ATLAS AUDIT ANALYTICS
-- Database Schema v1.0
-- Module: User Access Audit
-- Database: PostgreSQL
-- =====================================================

BEGIN;

-- =====================================================
-- 1. DEPARTMENTS
-- =====================================================

CREATE TABLE departments (
    department_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

-- =====================================================
-- 2. EMPLOYEES
-- =====================================================

CREATE TABLE employees (
    employee_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_number VARCHAR(30) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    department_id INTEGER NOT NULL,
    hire_date DATE NOT NULL,
    termination_at TIMESTAMPTZ,

    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id),

    CONSTRAINT chk_employment_dates
    CHECK (
        termination_at IS NULL
        OR termination_at >= (hire_date::timestamp AT TIME ZONE 'UTC')
    )
);

-- =====================================================
-- 3. USERS
-- =====================================================

CREATE TABLE users (
    user_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    username VARCHAR(100) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deactivated_at TIMESTAMPTZ,

    CONSTRAINT fk_user_employee
        FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id),

    CONSTRAINT chk_user_status
        CHECK (status IN ('Active', 'Disabled')),

    CONSTRAINT chk_user_deactivation
        CHECK (
            (status = 'Active' AND deactivated_at IS NULL)
            OR
            (status = 'Disabled' AND deactivated_at IS NOT NULL)
        )
);

-- =====================================================
-- 4. ROLES
-- =====================================================

CREATE TABLE roles (
    role_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_name VARCHAR(100) NOT NULL UNIQUE,
    privilege_level VARCHAR(20) NOT NULL,
    description TEXT,

    CONSTRAINT chk_privilege_level
        CHECK (
            privilege_level IN ('Low', 'Medium', 'High', 'Critical')
        )
);

-- =====================================================
-- 5. PERMISSIONS
-- =====================================================

CREATE TABLE permissions (
    permission_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT
);

-- =====================================================
-- 6. USER_ROLES
-- =====================================================

CREATE TABLE user_roles (
    user_role_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,

    authorized BOOLEAN,

    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by_employee_id INTEGER,

    approved_at TIMESTAMPTZ,
    approved_by_employee_id INTEGER,
    approval_reference VARCHAR(150),

    revoked_at TIMESTAMPTZ,

    CONSTRAINT fk_user_role_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id),

    CONSTRAINT fk_user_role_role
        FOREIGN KEY (role_id)
        REFERENCES roles(role_id),

    CONSTRAINT fk_user_role_assigned_by
        FOREIGN KEY (assigned_by_employee_id)
        REFERENCES employees(employee_id),

    CONSTRAINT fk_user_role_approved_by
        FOREIGN KEY (approved_by_employee_id)
        REFERENCES employees(employee_id),

    CONSTRAINT chk_role_assignment_dates
        CHECK (
            revoked_at IS NULL
            OR revoked_at >= assigned_at
        )
);

-- Prevent duplicate active role assignments.
-- Revoked assignments remain available for historical audits.

CREATE UNIQUE INDEX uq_active_user_role
    ON user_roles(user_id, role_id)
    WHERE revoked_at IS NULL;

-- =====================================================
-- 7. ROLE_PERMISSIONS
-- =====================================================

CREATE TABLE role_permissions (
    role_id INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,

    PRIMARY KEY (role_id, permission_id),

    CONSTRAINT fk_role_permission_role
        FOREIGN KEY (role_id)
        REFERENCES roles(role_id),

    CONSTRAINT fk_role_permission_permission
        FOREIGN KEY (permission_id)
        REFERENCES permissions(permission_id)
);

-- =====================================================
-- 8. PERFORMANCE INDEXES
-- =====================================================

CREATE INDEX idx_employees_department
    ON employees(department_id);

CREATE INDEX idx_users_employee
    ON users(employee_id);

CREATE INDEX idx_users_status
    ON users(status);

CREATE INDEX idx_user_roles_user
    ON user_roles(user_id);

CREATE INDEX idx_user_roles_role
    ON user_roles(role_id);

COMMIT;

