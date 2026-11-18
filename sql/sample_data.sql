-- Jeu de démonstration entièrement synthétique.
INSERT INTO users (user_id, department, role, authorized, status) VALUES
    ('U101', 'Finance', 'Admin', FALSE, 'Active'),
    ('U102', 'IT', 'Admin', TRUE, 'Active'),
    ('U103', 'Operations', 'Viewer', TRUE, 'Active'),
    ('U104', 'Finance', 'Editor', TRUE, 'Active'),
    ('U105', 'Human Resources', 'Viewer', TRUE, 'Inactive'),
    ('U106', 'Finance', 'Admin', NULL, 'Active')
ON CONFLICT (user_id) DO UPDATE SET
    department = EXCLUDED.department,
    role = EXCLUDED.role,
    authorized = EXCLUDED.authorized,
    status = EXCLUDED.status;