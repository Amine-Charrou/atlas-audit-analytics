# Catalogue initial de contrôles

## AC-01 — Administrateurs actifs sans autorisation confirmée

**Objectif :** identifier les comptes actifs de rôle `Admin` pour lesquels l'autorisation n'est pas explicitement confirmée.
**Critères :** `role = 'Admin'`, `status = 'Active'`, `authorized IS NOT TRUE`.
**Interprétation :** les valeurs `FALSE` et `NULL` sont signalées. `NULL` signifie que l'information est absente ou inconnue ; cela ne prouve pas à lui seul que l'accès est illégitime.
**Risque potentiel :** des privilèges élevés non justifiés ou non documentés peuvent permettre des actions incompatibles avec les responsabilités de l'utilisateur.
**Éléments à demander :** demande d'accès, approbation du responsable, responsabilités actuelles, historique des changements et preuve de revue périodique.
**Limites :** le jeu de données peut être incomplet ; le rôle seul ne décrit pas toutes les permissions ; l'approbation peut être conservée dans un autre système.
**Suivi recommandé :** confirmer les preuves, évaluer la nécessité du rôle et, si besoin, faire approuver une modification par le propriétaire habilité.

## AC-02 — Comptes actifs d'anciens employés (à réaliser)

**Objectif :** rechercher des comptes actifs liés à des départs confirmés.
**Données nécessaires :** statut du compte, statut d'emploi et dates effectives de départ/désactivation.
**Prudence :** vérifier la qualité et la date de mise à jour des données RH et IAM avant de conclure.

## AC-03 — Transactions potentiellement dupliquées (à réaliser)

**Objectif :** repérer des transactions partageant des attributs définis (par exemple référence, montant et date).
**Prudence :** des doublons peuvent être légitimes ; examiner les règles métier, annulations et paiements fractionnés.