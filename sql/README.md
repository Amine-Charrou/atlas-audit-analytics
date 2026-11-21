# SQL

- `schema.sql` : schéma PostgreSQL minimal.
- `sample_data.sql` : petit jeu fictif initial pour les exercices.
- `sample_data_extended.sql` : 120 comptes synthétiques supplémentaires, avec scénarios de test ciblés pour AC-01 à AC-05. Le script est relançable sans doublonner ses comptes.
- `risk_assessment_schema.sql` : tables de constats, évaluations de risque et recommandations.
- `risk_engine_integration_schema.sql` : exécutions, historique et clés d’intégration des constats.
- `recommendation_engine_schema.sql` : index de suivi des recommandations.
- `controls/` : contrôles SQL AC-01 à AC-05.
- `tests/` : requêtes SQL de validation manuelle.

Sur une base PostgreSQL **vide**, depuis la racine du dépôt, initialisez les scripts dans l’ordre :

```bash
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/sample_data.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/risk_assessment_schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/risk_engine_integration_schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/recommendation_engine_schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/sample_data_extended.sql
```

Les scripts `schema.sql` et `sample_data.sql` initialisent une base vide et ne sont pas conçus pour être relancés. Le jeu étendu est relançable et n’utilise que les identifiants synthétiques `TST-*` et `atlas.test.*`. Configurez `ATLAS_DATABASE_URL` dans l’environnement et ne stockez jamais de secret dans Git.

Le jeu étendu suppose que tous les scripts de schéma puis le petit jeu de base ont déjà été exécutés. Il n’efface et ne met à jour aucune donnée existante ; il insère 120 employés, comptes et attributions dans l’espace réservé `TST-*` / `atlas.test.*`. Les cas ciblés sont indiqués en commentaire dans le script. Les moteurs d’intégration, de risque et de recommandations peuvent ensuite être exécutés pour alimenter le dashboard.
