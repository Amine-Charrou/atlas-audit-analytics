# Parcours d'apprentissage

Le parcours suit une approche progressive. À chaque étape, formule d'abord ta propre hypothèse, exécute le travail, puis compare le résultat avec les attentes.

## Étape 1 — Comprendre le contrôle d'accès

**Question :** quels comptes administrateurs actifs n'ont pas une autorisation confirmée ?
- Identifier les champs nécessaires : identifiant fictif, département, rôle, autorisation et statut.
- Définir le risque sans conclure à une fraude.
- Expliquer pourquoi les comptes inactifs ne répondent pas au même critère.
**Livrable :** une définition de contrôle claire et ses limites.

## Étape 2 — SQL et PostgreSQL

- Créer le schéma depuis `sql/schema.sql`.
- Charger les exemples synthétiques depuis `sql/sample_data.sql`.
- Exécuter et commenter `sql/controls/001_unconfirmed_active_admins.sql`.
- Comparer `authorized = FALSE` à `authorized IS NOT TRUE`.
**Livrable :** une requête reproductible et un résultat attendu documenté.

## Étape 3 — Python et Pandas

- Lire le même jeu de données avec Pandas.
- Réimplémenter le filtre du contrôle.
- Comparer les lignes sélectionnées par SQL et Pandas.
- Traiter explicitement les valeurs manquantes.
**Livrable :** une analyse reproductible qui concorde avec SQL.

## Étape 4 — Restitution avec Streamlit

- Afficher les volumes analysés et les exceptions.
- Ajouter des filtres par rôle, statut et département.
- Présenter les critères, la date d'analyse et les limites.
- Structurer un constat : condition, risque, preuve à obtenir, recommandation.
**Livrable :** un tableau de bord explicable.

## Étape 5 — Étendre le périmètre

Choisir un nouveau contrôle (comptes d'anciens employés, accès incompatibles, doublons de transactions) et répéter le cycle complet.

## Questions de réflexion

1. Une valeur `NULL` dans l'autorisation signifie-t-elle que l'accès est nécessairement non autorisé ?
2. Quelles preuves permettraient de confirmer ou d'écarter une exception ?
3. Quels faux positifs cette règle peut-elle produire ?
4. Quelle personne ou fonction devrait valider la remédiation ?