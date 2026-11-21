# Atlas Audit Analytics

**Plateforme pédagogique d'IT Audit & Data Analytics** — un projet *learning by doing* pour apprendre à transformer des données fictives en contrôles auditables, constats documentés et analyses utiles.

> Projet éducatif indépendant basé sur des exemples fictifs.

![Croquis de l’objectif et du parcours d’Atlas Audit Analytics](docs/assets/atlas-audit-objective.png)

## Objectifs

- Comprendre les contrôles d'accès et le cycle de vie des comptes.
- Interroger et structurer des données avec PostgreSQL et SQL.
- Analyser les résultats avec Python et Pandas.
- Présenter les risques et anomalies avec Streamlit.
- Apprendre à distinguer une exception à investiguer d'une fraude avérée.

## Technologies

Python · PostgreSQL · SQL · Pandas · Streamlit · Plotly

## Démarrage rapide

Prérequis : Python 3.10 ou supérieur et une base PostgreSQL.

```bash
python -m venv .venv
# macOS / Linux
source .venv/bin/activate
pip install -r requirements.txt

export ATLAS_DATABASE_URL="postgresql://utilisateur:mot_de_passe@localhost:5432/atlas_audit"
streamlit run app/Home.py
```

Sous Windows PowerShell, activez l’environnement avec `.venv\Scripts\Activate.ps1`.

Pour installer aussi les outils de développement et lancer les tests, utilisez `pip install -e ".[dev]"` après avoir activé l’environnement virtuel.

Lancez ensuite la suite de tests avec `python -m pytest -q`.

### Initialisation de la base

Sur une base PostgreSQL vide, exécutez les scripts dans cet ordre depuis la racine du dépôt :

```bash
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/sample_data.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/risk_assessment_schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/risk_engine_integration_schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/recommendation_engine_schema.sql
psql "$ATLAS_DATABASE_URL" -v ON_ERROR_STOP=1 -f sql/sample_data_extended.sql
```

Les deux premiers scripts sont destinés à une base vide et ne doivent pas être relancés sur une base déjà initialisée. Le jeu étendu ajoute 120 comptes synthétiques et peut être relancé sans doublonner ces comptes.

Après initialisation, les moteurs s’exécutent depuis la racine du dépôt :

```bash
python -m atlas_audit.integrations.runner
python -m atlas_audit.risk.assessor
python -m atlas_audit.recommendations.engine
```

### Configuration PostgreSQL

Définissez `ATLAS_DATABASE_URL` dans l’environnement avant de lancer Streamlit. Vous pouvez aussi la placer dans `.streamlit/secrets.toml` (ne jamais committer ce fichier) :

```toml
ATLAS_DATABASE_URL = "postgresql://utilisateur:mot_de_passe@localhost:5432/atlas_audit"
```

Le dashboard propose les vues **Executive Overview**, **Risk Analytics** (matrice Impact × Likelihood), **Findings Explorer**, **Recommendations Tracker**, **Audit Execution History** et **Audit Report** (exports CSV/JSON). Il lit les tables de résultats et fonctionne en lecture seule. La logique SQL est isolée dans `src/atlas_audit/dashboard/repository.py` ; l’interface Streamlit est dans `app/Home.py`.

Sans URL valide ou en cas d’indisponibilité, l’interface affiche un message de configuration/connexion et ne bascule pas vers des données fictives.

## Structure

```text
app/                         Application Streamlit
pyproject.toml               Configuration du paquet et des outils Python
src/atlas_audit/dashboard/    Accès PostgreSQL en lecture seule
src/atlas_audit/integrations/ Exécution des contrôles et persistance
src/atlas_audit/risk/         Évaluation du risque
src/atlas_audit/recommendations/ Recommandations
sql/                         Schémas, contrôles et jeux synthétiques
tests/                       Tests unitaires Python
docs/                        Cadrage et parcours
```

## Contrôle initial : comptes privilégiés non confirmés

La première analyse repère les comptes actifs avec le rôle `Admin` dont l'autorisation n'est pas confirmée. En SQL, `IS NOT TRUE` inclut les valeurs `FALSE` et `NULL`. Un résultat est un signal à investiguer, pas une preuve de fraude.

Le schéma et les données de démonstration sont dans [sql/](sql/). Le cadrage détaillé est dans [docs/PROJECT_CHARTER.md](docs/PROJECT_CHARTER.md) et le parcours dans [docs/LEARNING_PATH.md](docs/LEARNING_PATH.md).

## Sécurité et données

- N'ajoutez jamais de secrets, mots de passe, jetons, données client ou données personnelles réelles.
- Les fichiers locaux `.env` et les données de travail sont ignorés par Git.
- Utilisez uniquement des données synthétiques ou anonymisées avec autorisation.

## Feuille de route

Les contrôles AC-01 à AC-05, la persistance des constats, l’évaluation des risques, les recommandations et le dashboard sont implémentés. Le jeu synthétique étendu fournit 120 comptes pour les essais. La prochaine extension fonctionnelle peut porter sur un nouveau domaine de données ou de contrôles, après validation des résultats du jeu étendu.

## Contribution pédagogique

Chaque contrôle doit expliquer son objectif, ses critères, ses limites, les éléments probants à demander et la façon de valider une exception. Voir [le catalogue de contrôles](docs/CONTROLS_CATALOG.md).
