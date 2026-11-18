-- Schéma pédagogique minimal. Toutes les identités sont fictives.
CREATE TABLE IF NOT EXISTS users (
    user_id TEXT PRIMARY KEY,
    department TEXT NOT NULL,
    role TEXT NOT NULL,
    authorized BOOLEAN,
    status TEXT NOT NULL CHECK (status IN ('Active', 'Inactive'))
);