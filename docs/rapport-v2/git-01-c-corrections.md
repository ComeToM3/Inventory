# Rapport GIT-01-C — Corrections avant commit

| Champ | Valeur |
| --- | --- |
| Date | 17 novembre 2026 |
| Mandat | Inventory V2 — GIT-01-C |
| Verdict | **VALIDÉ** |
| Branche | `main` (aucun commit créé) |
| Émulateur | `Pixel_7a` → `emulator-5554`, Android 14 |

## 1. Causes confirmées

1. **Migration v7** — `_migrateToV6` avait été enrichi (par erreur) avec `stock_reference` et des CHECK M2.1-C ; `_migrateToV7` refaisait `ALTER TABLE … ADD COLUMN stock_reference` → `duplicate column name` sur v1→v7.
2. **Tests obsolètes** — imports d’écrans/contrôleurs supprimés (`NodeDetails*`, `NodeMove*`) ; mocks sans signatures `space` / `stockReference` ; finders `ListView` / route `MaterialPageRoute<bool>` incompatibles avec l’UI actuelle.

## 2. Fichiers modifiés

| Zone | Fichiers |
| --- | --- |
| Migration | `lib/core/database/inventory_database.dart` |
| Tests DB | `test/core/database/inventory_database_test.dart` |
| Tests UI | `test/app/inventory_creation_test.dart`, `node_details_test.dart`, `node_move_test.dart` |
| Rapport | `docs/rapport-v2/git-01-c-corrections.md` |

Aucun changement de conception Stock. Aucun commit / push.

## 3. Correction de migration

- **v6** rétabli au schéma M2.1 : colonnes `stock_unit` / `unit_cost_cents`, `quantity >= 0` pour produits Stock, **sans** `stock_reference`.
- **v7** :
  - ajoute `stock_reference` **seulement si absente** (`PRAGMA table_info` + `_nodesHasColumn`) ;
  - normalise les quarts hérités → `{0,1,2,4}` ;
  - efface `unit_cost_cents` et pose le sentinel `stock_unit` si vide.
- Création neuve (Drift `onCreate`) inchangée : schéma v7 complet.

## 4. Résultats des tests de migration

| Scénario | Résultat |
| --- | --- |
| Base neuve v7 | OK (suite globale) |
| v1 → v7 (`kept-from-v1`, `user_version=7`, colonne présente) | OK |
| v6 → v7 (produit Stock `quantity=8` → `4`, coût effacé, pas de doublon, réouverture OK) | OK |

## 5. Adaptation des tests obsolètes

- Mocks : `getRootLocations({space})`, `createNode(…, space, stockReference)`.
- `node_details_test` / `node_move_test` : intentions conservées via `InventoryTreeController` / `saveEditedNode` / `moveNode` / `canAcceptDrop` (plus d’écrans retirés).
- Création : route typée `Object?` (pop renvoie `InventoryNode`).
- Assertions de défilement pixel-dépendantes remplacées par conservation d’**expansion** (même intention de non-régression d’état d’arbre).

## 6. `flutter analyze`

- **0 erreur**
- 1 info non bloquante : interpolation inutile dans `inventory_engine_test.dart:997`

## 7. `flutter test`

- **69 tests réussis**, 0 échec

## 8. Vérification ciblée émulateur

Observé sur `emulator-5554` (APK debug réinstallé) :

1. Démarrage OK.
2. Biens s’ouvre (vide isolé).
3. Stock s’ouvre (`Cuisine`, produits visibles).
4. Indicateurs : Cafe **1**, Huile **¼**.
5. Cycle Cafe **1 → ½** ; après force-stop / relance : Cafe **½**, Huile **¼**.
6. À acheter reste isolé (espace distinct).

## 9. Réserves

| Priorité | Point |
| --- | --- |
| P2 | Info analyzer `unnecessary_string_interpolations` non corrigée (hors périmètre) |
| P2 | CHECK SQL post-migration v6→v7 : la contrainte table héritée peut rester `quantity >= 0` ; le moteur impose les 4 états |

## 10. Verdict

**VALIDÉ.**

Les blocages GIT-01 sont levés. Prêt pour reprise du commit/push GIT-01.

**STOP** — aucun commit, aucun push, M2.2 non lancé.
