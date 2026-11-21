# Atlas Audit Analytics

**Plateforme pédagogique d'IT Audit & Data Analytics** — un projet *learning by doing* pour apprendre à transformer des données fictives en contrôles auditables, constats documentés et analyses utiles.

> Projet éducatif indépendant. L'entreprise et les exemples de données sont fictifs. Aucun lien d'affiliation avec Forvis Mazars.

## Objectifs

- Comprendre les contrôles d'accès et le cycle de vie des comptes.
- Interroger et structurer des données avec PostgreSQL et SQL.
- Analyser les résultats avec Python et Pandas.
- Présenter les risques et anomalies avec Streamlit.
- Apprendre à distinguer une exception à investiguer d'une fraude avérée.

## Technologies

Python · PostgreSQL · SQL · Pandas · Streamlit · Plotly

## Démarrage rapide

Prérequis : Python 3.10 ou supérieur. L'application de départ utilise des données synthétiques en mémoire ; PostgreSQL sera intégré dans une étape suivante.

```bash
python -m venv .venv
source .venv/bin/activate        # Windows : .venv\Scripts\activate
pip install -r requirements.txt

# macOS / Linux
export ATLAS_DATABASE_URL="postgresql://utilisateur:mot_de_passe@localhost:5432/atlas_audit"
streamlit run app/Home.py
```

### Configuration PostgreSQL

Définissez `ATLAS_DATABASE_URL` dans l’environnement avant de lancer Streamlit. Vous pouvez aussi la placer dans `.streamlit/secrets.toml` (ne jamais committer ce fichier) :

```toml
ATLAS_DATABASE_URL = "postgresql://utilisateur:mot_de_passe@localhost:5432/atlas_audit"
```

Le dashboard propose les vues **Executive Overview**, **Risk Analytics** (matrice Impact × Likelihood), **Findings Explorer**, **Recommendations Tracker** et **Audit Execution History**. Il lit `audit_findings`, `risk_assessments`, `audit_recommendations`, `audit_runs` et `control_executions`, ajoutés par les scripts de schéma correspondants sous `sql/`. Il ne modifie pas la base.

Sans URL valide ou en cas d’indisponibilité, l’interface affiche un message de configuration/connexion et ne bascule pas vers des données fictives.

## Structure

```text
app/                 Interface Streamlit
data/sample/         Emplacement des jeux synthétiques (aucune donnée réelle)
docs/                Cadrage, parcours et catalogue de contrôles
sql/                 Schéma et requêtes d'audit
src/atlas_audit/     Logique métier réutilisable
```

## Contrôle initial : comptes privilégiés non confirmés

La première analyse repère les comptes actifs avec le rôle `Admin` dont l'autorisation n'est pas confirmée. En SQL, `IS NOT TRUE` inclut les valeurs `FALSE` et `NULL`. Un résultat est un signal à investiguer, pas une preuve de fraude.

Le schéma et les données de démonstration sont dans [sql/](sql/). Le cadrage détaillé est dans [docs/PROJECT_CHARTER.md](docs/PROJECT_CHARTER.md) et le parcours dans [docs/LEARNING_PATH.md](docs/LEARNING_PATH.md).

## Sécurité et données

- N'ajoutez jamais de secrets, mots de passe, jetons, données client ou données personnelles réelles.
- Les fichiers locaux `.env` et les données de travail sont ignorés par Git.
- Utilisez uniquement des données synthétiques ou anonymisées avec autorisation.

## Feuille de route

1. Modéliser les comptes utilisateurs et charger des données fictives.
2. Écrire des contrôles SQL explicables et documenter les critères.
3. Comparer les résultats SQL avec une analyse Pandas.
4. Ajouter filtres, indicateurs et fiches de constats dans Streamlit.
5. Produire un rapport d'audit reproductible.

## Contribution pédagogique

Chaque contrôle doit expliquer son objectif, ses critères, ses limites, les éléments probants à demander et la façon de valider une exception. Voir [le catalogue de contrôles](docs/CONTROLS_CATALOG.md).
