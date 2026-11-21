# SQL

- `schema.sql` : schéma PostgreSQL minimal.
- `sample_data.sql` : petit jeu fictif initial pour les exercices.
- `sample_data_extended.sql` : 120 comptes synthétiques supplémentaires, avec scénarios de test ciblés pour AC-01 à AC-05. Le script est relançable sans doublonner ses comptes.
- `controls/001_unconfirmed_active_admins.sql` : contrôle AC-01.

Depuis `psql`, avec une base locale déjà créée :

```sql
\i sql/schema.sql
\i sql/sample_data.sql
\i sql/sample_data_extended.sql
\i sql/controls/001_unconfirmed_active_admins.sql
```

Le projet n'inclut pas encore de configuration de connexion ni de mot de passe. Ne stockez jamais de secret dans Git.

Le jeu étendu suppose que `schema.sql` puis `sample_data.sql` ont déjà été exécutés. Il n’efface et ne met à jour aucune donnée existante ; il insère 120 employés, comptes et attributions dans l’espace réservé `TST-*` / `atlas.test.*`. Les cas ciblés sont indiqués en commentaire dans le script. Les moteurs d’intégration, de risque et de recommandations peuvent ensuite être exécutés pour alimenter le dashboard.
