# UX-CORR-04 — Fiche Biens unifiée

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` — versionCode **6025** (build Flutter **4025**, arm64 debug)  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION UTILISATEUR**

---

## Synthèse

Disposition Biens réordonnée en **cinq lignes** sur la fiche création/modification. Section « Informations avancées » (ExpansionTile) retirée de l’UI. Composants, styles et comportements réutilisés tels quels.

---

## Composants existants réutilisés (déplacés uniquement)

| Ligne | Composants |
|---|---|
| 1 | `TextFormField` nom (+ icône) · `Switch` « Est un contenant » |
| 2 | `InventoryParentField` (Position + `+` rapide) |
| 3 | `InventoryQuantityStepper` · `SegmentedButton` Objectif |
| 4 | Libellé valorisation · `InventoryValuationField` |
| 5 | `GoodsMainPhotoField` · `GoodsDocumentsField` |

Retiré de l’UI seulement : `InventoryAdvancedSection` / dépliage (fichier conservé, plus référencé).

Stock / À acheter / emplacements : **inchangés**.

---

## Fichiers

**Modifié :** `lib/app/inventory_creation_screen.dart`  
**Non modifiés :** schéma SQLite, backup, médias, organisation, Stock/À acheter.

### Adaptations dimensionnelles strictement nécessaires

- Objectif à droite de la quantité : la quantité n’est plus dans un `Expanded` (évite overflow ~4 px observé).
- Espacement horizontal quantité/objectif : 8 px.

Aucun nouveau style, carte, séparateur ou champ.

---

## Captures Motorola

| | Fichier |
|---|---|
| Avant (6023, section avancée dépliée) | `docs/rapport-v2/_ux-corr-04/avant.png` |
| Après — lignes hautes | `docs/rapport-v2/_ux-corr-04/apres-haut.png` |
| Après — valorisation + médias | `docs/rapport-v2/_ux-corr-04/apres.png` |

**Observé (uiautomator + captures) :**

- Ordre L1→L5 respecté.
- « Informations avancées » **absent**.
- Galerie / Caméra / Document sur une ligne.
- Apparence des contrôles inchangée (mêmes widgets).

**Non déclaré comme validation utilisateur :** création/modification bout-en-bout au doigt, focus nom (autofocus code conservé).

---

## Préservation

- Contrôleurs, validations, persistance photo/docs/objectif/quantité/valorisation : inchangés.
- Colonnes SQLite / `.invbackup` : inchangés.
- Préférence globale « avancées par défaut » : non modifiée (hors périmètre ; sans effet UI sur la fiche Biens unifiée).

---

## Limitations

1. Contenu long : L4–L5 sous le pli si IME ouvert — défilement naturel du formulaire.
2. Validation tactile/fonctionnelle complète : **à confirmer par l’utilisateur**.

---

## Verdict

**EN ATTENTE DE VALIDATION UTILISATEUR**

Inventory au premier plan sur Motorola, données conservées. **STOP.**
