# UX-ARB-02 — Dissociation des expansions et simplification des détails

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` — versionCode **6047** (build Flutter **4047**, arm64 debug)  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION UTILISATEUR**

---

## 1. Diagnostic

| Problème | Cause | Correction |
|---|---|---|
| Cycle 3 clics couplant enfants / détails | `_RowPhase` unique | États séparés `_expanded` / `_infoOpenIds` |
| Arbre tout ouvert au démarrage | `_expandAllContainingInitial` | Supprimé — démarrage **replié** |
| Objectif Vendre affiché à tort | `sell` déjà en base + taps accidentels qty | Défaut Aucun, rangée séparée, reset ponctuel |
| Chevron vs ligne (contenants) | GestureDetector imbriqué fragile | `IconButton` chevron (enfants seuls) |

---

## 2. Comportements (6046)

| Nœud | Chevron | Ligne / nom |
|---|---|---|
| Emplacement | Enfants | Enfants |
| Bien-contenant | Enfants **uniquement** | Détails **uniquement** |
| Bien simple | — | Détails |

Quatre combinaisons possibles pour un bien-contenant (enfants × détails).  
Objectif / photo / docs / valorisation **n’influencent pas** l’expansion des enfants.  
Sous-ligne sous la ligne principale, **avant** les enfants dans la liste plate.

État initial (6047) : **emplacements** déroulés par défaut ; **biens-contenants** restent repliés (exploration manuelle).

---

## 3. Sous-ligne

Photo (si présente) → Documents (si présents) → Vendre/Réparer (si renseigné) → crayon (colonne actions).  
Absents omis.

---

## 4. Objectif

- Défaut création / réparation : **Aucun**
- `sell` accidentels corrigés une fois (`ux_arb_02_objective_none_repair`)
- Objectif pleine largeur (plus collé à ± quantité)

---

## 5. Fichiers (cumul)

- `lib/app/inventory_tree_controller.dart` — plus d’expand-all initial  
- `lib/app/inventory_tree_screen.dart` — chevron IconButton / états indépendants  
- `lib/app/inventory_inline_sheet.dart`  
- `lib/app/inventory_creation_screen.dart` / `inventory_ui.dart` / `app_strings.dart`  
- `lib/core/domain/*` / `inventory_database.dart` (objectif)

---

## 6. Livraison

| Élément | Valeur |
|---|---|
| Install | Success `adb -s ZT322P23HJ install -r` |
| versionCode | **6047** |
| Captures | `_ux-arb-02/motorola-branches-repliees.png` (6046) |

Validation utilisateur : 4 combinaisons contenant + hiérarchies imbriquées + détails visibles avec enfants repliés.

**STOP — EN ATTENTE DE VALIDATION UTILISATEUR.**
