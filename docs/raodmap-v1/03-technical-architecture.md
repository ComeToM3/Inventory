# 03 — Architecture technique minimale

Statut des informations : **Confirmé** = décidé dans le blueprint · **Recommandation** = proposition à valider · **Ouvert** = à trancher.

Ce document décrit uniquement les composants indispensables au fonctionnement de la V1.

**Recentrage V1 :** l'application est **Android exclusivement**, locale et hors ligne. Les composants réseau, de synchronisation et d'appairage décrits dans une version antérieure de ce document sont retirés du périmètre V1 (voir [blueprint.md](blueprint.md), section 6, pour l'historique). Les anciennes décisions D03 (causalité), D04 (appairage) et D05 (restauration/ré-appairage) ne s'appliquent plus : D03 et D04 sont sans objet en l'absence de synchronisation ; D05 est remplacée par une politique de restauration simplifiée (section 5).

## 1. Choix technologiques confirmés

| Couche | Technologie |
| --- | --- |
| Plateforme | Android exclusivement |
| Interface | Flutter, Material 3 |
| Langage | Dart |
| Gestion d'état | Riverpod |
| Navigation | go_router |
| Persistance | Drift + SQLite |
| Identifiants | UUID |
| Sauvegarde | Archive locale exportable |

Aucun backend, aucune base de données serveur, aucun service cloud, aucun transport réseau et aucun mécanisme de synchronisation ne sont utilisés. *(Confirmé)*

## 2. Composants principaux et responsabilités

| Composant | Responsabilité |
| --- | --- |
| Interface (UI Flutter) | Affiche l'inventaire, les formulaires, la recherche et les valeurs des biens. Ne modifie jamais directement la base de données. |
| Couche domaine | Applique les règles métier (hiérarchie, catégories, quantités, valeurs, validations de déplacement). Utilisée par l'interface, point de passage unique pour toute modification des nœuds. |
| Persistance locale (Drift/SQLite) | Stocke les nœuds, catégories et leurs valeurs, avec transactions pour garantir la cohérence. |
| Module de sauvegarde | Exporte et restaure une archive locale complète de l'inventaire. |

## 3. Schéma de données (aperçu)

| Table | Rôle |
| --- | --- |
| `inventories` | Identité de l'inventaire local |
| `nodes` | Biens, emplacements et contenants (inclut le mode de valorisation et le statut actif/retiré) |
| `categories` / `node_categories` | Classification des biens |

Les définitions exactes des champs, contraintes et relations sont celles du [modèle de données actuel](04-data-domain-model.md). Les anciens aperçus ne doivent pas être utilisés comme schéma :

- `can_contain` n'est pas listé comme colonne; le modèle recommande de déduire la capacité de `node_type`. Cette représentation reste une recommandation technique à confirmer au schéma.
- `financial_value` n'est pas le nom de champ du modèle actuel, qui recommande `financial_value_cents` en cents CAD; cette précision est une recommandation technique du modèle.
- `financial_value_is_total` est omis; le total d'un lot est calculé avec la quantité et le montant unitaire.
- `deleted_at` est omis; la suppression définitive supprime la ligne, tandis qu'un retrait conserve le bien avec `status`, `withdrawal_reason` et `withdrawn_at`.
- Les photos et la table `attachments` ne font pas partie du modèle ni du périmètre V1.

La valorisation utilise `value_mode` (`financial` ou `sentimental`) avec une seule valeur active : `financial_value_cents` ou `sentimental_value`. Les identifiants sont des UUID. Les horodatages ne servent qu'à l'affichage et au diagnostic. *(Confirmé)*

## 4. Risques techniques principaux

| Risque | Importance | Mesure prévue |
| --- | --- | --- |
| Perte de données | Élevée | Transactions et sauvegardes locales |
| Boucles hiérarchiques | Élevée | Validation systématique avant tout déplacement |
| Confusion entre valeur financière et valeur sentimentale | Moyenne | Modes mutuellement exclusifs, jamais convertis l'un en l'autre |
| Perte accidentelle d'un bien retiré | Faible | Historique minimal conservé hors de l'inventaire actif |
| Complexité excessive | Moyenne | Périmètre V1 strict, aucun composant réseau ou distribué |

## 5. Politique de sauvegarde et de restauration (D05 révisée)

**Décision :** une restauration remplace entièrement les données actives de l'appareil par le contenu de la sauvegarde, après validation de son intégrité. *(Confirmé)*

Il n'y a plus de notion d'appareils appairés ou de curseurs de synchronisation à gérer : la V1 étant mono-appareil, la restauration ne concerne que la cohérence interne de la base restaurée (biens, catégories, contenants, valeurs) par rapport à l'archive exportée.

## Points nécessitant une décision

Aucun point ouvert restant pour ce document.
