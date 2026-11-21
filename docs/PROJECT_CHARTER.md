# Cadrage du projet

## Vision

Atlas Audit Analytics est une plateforme éducative qui illustre un cycle simple d'analyse d'audit SI : définir un objectif de contrôle, sélectionner des données, appliquer des critères explicites, examiner les exceptions et communiquer les résultats.

> Projet éducatif indépendant. L'entreprise et les exemples de données sont fictifs. Aucun lien d'affiliation avec Forvis Mazars.

## Contexte fictif

Atlas Distribution Group est une entreprise fictive utilisant des comptes utilisateurs pour ses opérations. L'équipe d'audit interne souhaite analyser la gestion des accès et, dans les étapes suivantes, des transactions simulées.

## Périmètre initial

Le premier module porte sur la revue des accès : comptes actifs et inactifs, rôles attribués, statut de confirmation de l'autorisation et identification des comptes administrateurs actifs dont l'autorisation n'est pas confirmée.

## Utilisateurs visés

Étudiants et personnes en apprentissage de l'IT Audit, du SQL et de l'analyse de données. L'application sert de support pédagogique et ne remplace pas le jugement d'un auditeur.

## Principes de conception

1. **Learning by doing** : chaque module associe une question métier, une requête, un résultat et une explication.
2. **Traçabilité** : les critères et limites de chaque contrôle sont documentés.
3. **Prudence** : une exception est une piste d'investigation, jamais une conclusion automatique de fraude.
4. **Données sûres** : seules des données fictives ou autorisées sont utilisées.
5. **Simplicité** : commencer par un petit périmètre testable avant d'ajouter de la complexité.

## Architecture cible

- **PostgreSQL** : stockage relationnel et exécution des contrôles SQL.
- **Python / Pandas** : préparation et comparaison des résultats.
- **Streamlit** : interface interactive de consultation.
- **SQL** : définition des tables et règles d'analyse.

## Architecture actuelle

- `app/Home.py` : navigation et présentation Streamlit.
- `src/atlas_audit/dashboard/repository.py` : requêtes de lecture seule et chargement des jeux du dashboard.
- `src/atlas_audit/integrations/` : exécution des contrôles et centralisation des constats.
- `src/atlas_audit/risk/` : calcul, classification et persistance des évaluations de risque.
- `src/atlas_audit/recommendations/` : catalogue et génération des recommandations.
- `sql/` : schéma, migrations, contrôles et jeux de données synthétiques.

Le paquet Python est configuré dans `pyproject.toml`. `requirements.txt` reste le point d’installation simple pour l’application ; les dépendances de développement sont dans l’extra `dev`.

## Hors périmètre initial

Connexion à des systèmes de production, décision automatisée sur des personnes, preuve de fraude, authentification multi-utilisateur et déploiement public.

## Critères de réussite du premier jalon

- Le dépôt explique comment installer et lancer l'application.
- Le schéma SQL et les critères de contrôle sont lisibles.
- L'application présente un jeu synthétique et les exceptions correspondantes.
- Les limites d'interprétation sont visibles.
