# SQL

- `schema.sql` : schéma PostgreSQL minimal.
- `sample_data.sql` : petit jeu fictif pour les exercices.
- `controls/001_unconfirmed_active_admins.sql` : contrôle AC-01.

Depuis `psql`, avec une base locale déjà créée :

```sql
\i sql/schema.sql
\i sql/sample_data.sql
\i sql/controls/001_unconfirmed_active_admins.sql
```

Le projet n'inclut pas encore de configuration de connexion ni de mot de passe. Ne stockez jamais de secret dans Git.