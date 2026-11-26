# INTER-03-C — Assainissement technique final d'Inventory V2

**Date :** 25 novembre 2026  
**Nature :** nettoyage ciblé autorisé (liste fermée INTER-03)  
**Compilation / install / commit :** aucun  
**Verdict :** **ASSAINISSEMENT TERMINÉ**

---

## 1. Résumé exécutif

Les résidus techniques démontrés par INTER-03 (R-01 à R-05), plus `NeedStatus` (R-08) et le texte d’aide `helpBrowseBody`, ont été traités sans modifier les parcours métier, le DnD actuel, la fiche unifiée ni la valorisation active.

`dart analyze lib` : **identique** à INTER-03 — 1 warning préexistant `unnecessary_null_comparison` (hors périmètre).

Gel fonctionnel respecté. Plan directeur non modifié (report livraison).

---

## 2. Liste exhaustive des fichiers et symboles supprimés

### Fichiers retirés

| Fichier |
|---|
| `lib/app/persistence_check_screen.dart` |
| `lib/app/persistence_check_controller.dart` |
| `lib/app/inventory_advanced_section.dart` |

### Symboles / membres retirés

| Emplacement | Symbole |
|---|---|
| `inventory_ui.dart` | classe `InventoryValuationBanner` |
| `inventory_tree_controller.dart` | `isSameParentDrop` |
| `inventory_tree_controller.dart` | `moveSibling` |
| `inventory_tree_controller.dart` | `relocateNode` |
| `inventory_tree_controller.dart` | `listSiblings` |
| `purchase_models.dart` | enum `NeedStatus` (+ `fromNodeStatus`) |
| `app_strings.dart` | `valuationChangeNotice` |
| `app_strings.dart` | `chooseDestination` |
| `app_strings.dart` | `currentDestination` |
| `app_strings.dart` | `noMoveDestinations` |
| `app_strings.dart` | `noChildDestinations` |
| `app_strings.dart` | `destinationReadError` |
| `app_strings.dart` | `moveHere` |
| `app_strings.dart` | `moving` |
| `app_strings.dart` | `confirmMove` |
| `app_strings.dart` | `moveWithContents` |
| `app_strings.dart` | `chooseInside` |
| `app_strings.dart` | `moveTo` |

### Chaînes de déplacement **préservées** (DnD / messages actifs)

`move`, `destination`, `inventoryRoot`, `parentLevel`, `moveSuccess`, `moveError`, `invalidDestination`, `cyclicDestination`, `dropToRoot`, `organizeReorderSuccess`, `organizeReorderError`, `nodeUnavailable`.

### API organisation **préservées**

`resolveOrganizeDrop`, `canAcceptReorder`, `canAcceptDrop`, `reorderSiblings`, `placeSiblingBefore`, `placeSiblingAfter`, `moveNode`.

---

## 3. Justification des suppressions

| ID | Preuve d’absence de consommateurs | Effet attendu |
|---|---|---|
| R-01 | Aucun import / route / test | Diagnostic DEV hors produit |
| R-02 | Orphelin depuis UX-CORR-04 ; fiche unifiée seule référence | Évite second layout avancé |
| R-03 | Aucune construction UI | Valorisation via `InventoryValuationField` intacte |
| R-04 | Aucun appel hors définitions | DnD vivant inchangé |
| R-05 | Scan `AppStrings.*` = 0 hors `app_strings.dart` | Ancien sélecteur « Déplacer vers… » |

---

## 4. Décision concernant `NeedStatus` (R-08)

| Vérification | Résultat |
|---|---|
| Références Dart | Uniquement dans `purchase_models.dart` |
| Sérialisation / Drift / backup | Utilise `NodeStatus` (`active` / `acquired` / `abandoned`), pas `NeedStatus` |
| Tests | Importent `purchase_models.dart` pour d’autres types ; **aucun** usage de `NeedStatus` |
| Persistance / compat | Aucune colonne ni payload dédié |
| Relation `NodeStatus` | Miroir redondant sans contrat |

**Décision :** **suppression effectuée.**  
Les besoins À acheter restent représentés par `NodeStatus` + événements `PurchaseEventType`.

---

## 5. Actualisation de l’aide intégrée

Comportement vérifié dans `inventory_tree_screen.dart` :

- Chevron → `_toggleChildren` (emplacements et biens-contenants).
- Tap ligne emplacement → `_toggleChildren`.
- Tap ligne bien (simple ou contenant) → `_toggleInfo` (détails indépendants des enfants).

`helpBrowseBody` réécrit en conséquence.  
`helpMoveBody` **inchangé** (déjà conforme au glisser-déposer).

---

## 6. Analyse statique avant / après

| Moment | Résultat |
|---|---|
| Avant | 1 warning : `inventory_tree_screen.dart:1220` `unnecessary_null_comparison` |
| Après | **Identique** — même warning unique |
| Nouvelles erreurs | **Aucune** |

---

## 7. Synthèse du diff

```
7 files changed, 5 insertions(+), 398 deletions(-)
 lib/app/app_strings.dart                  |  24 ++-----
 lib/app/inventory_advanced_section.dart   |  41 ------------  (deleted)
 lib/app/inventory_tree_controller.dart    | 101 ------------------------------
 lib/app/inventory_ui.dart                 |  39 ------------
 lib/app/persistence_check_controller.dart |  91 ---------------------------  (deleted)
 lib/app/persistence_check_screen.dart     |  89 --------------------------  (deleted)
 lib/core/domain/purchase_models.dart      |  18 ------
```

Insertions = nouveau texte `helpBrowseBody` uniquement (hors reformulations mineures de suppression).

---

## 8. Confirmation du gel fonctionnel

- Aucune règle métier / migration / média / backup modifiée.
- Aucune interaction arbre ou formulaire modifiée (hors libellé d’aide).
- Aucune compilation, install, effacement Motorola, commit ou push.
- Note utilisateur : autorisation future d’effacement Motorola **documentée**, **non exercée** ici.

---

## 9. Réserves résiduelles

| Réserve | Statut |
|---|---|
| Warning `unnecessary_null_comparison` | Hors périmètre — conservé |
| Plan directeur (Organiser / phases) | Reporté au mandat livraison / clôture doc |
| Thème FAB sans FAB | Conservé (E, INTER-03) |
| Autres chaînes `AppStrings` peu référencées | Hors liste autorisée — non touchées |

---

## Verdict

**ASSAINISSEMENT TERMINÉ**

Nettoyage conforme à la liste autorisée ; références résiduelles des symboles retirés absentes ; analyse stable ; gel fonctionnel intact.

**STOP** — aucun mandat suivant engagé.
