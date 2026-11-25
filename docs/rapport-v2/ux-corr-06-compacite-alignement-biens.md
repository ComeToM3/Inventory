# UX-CORR-06 — Compacité et alignement fiche Biens

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` — versionCode **6038** (build Flutter **4038**, arm64 debug)  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION VISUELLE UTILISATEUR**

---

## Harmonisation graphique

### Composants réutilisés

| Composant | Usage |
|---|---|
| `InventorySquareIconButton` | `$`, cœur, `+` position, − / + quantité (chrome unique, coins 12, 48×48) |
| `inventoryGoodsOutlinedStyle` | Galerie / Caméra / Reçus + Objectif Aucun / Vendre / Réparer |

### Modifications

1. **Boutons icône** — forme circulaire quantité / `filledTonal` position remplacés par le carré arrondi des chips de valorisation.
2. **Objectif** — `SegmentedButton` remplacé par trois `OutlinedButton` indépendants (sélection exclusive, fond `mintSoft` + bordure petroleum si actif).
3. **Médias** — titre unique « Photo et document » ; bouton « Reçus » (types de fichiers inchangés).

Hauteurs de rangée **conservées** (48 dp / 84 px).

### Preuves Motorola (6038)

| Contrôle | Taille observée |
|---|---|
| `+` position / − / + / `$` / cœur | **84×84** |
| Aucun / Vendre / Réparer | h=**84** |
| Galerie / Caméra / Reçus | h=**84** |
| Titre | « Photo et document » présent ; anciens titres absents |

Capture : `_ux-corr-06/apres-harmonisation-graphique.png`

### Install

`adb -s ZT322P23HJ install -r …arm64…` — Success. Données conservées.

---

## Verdict

**EN ATTENTE DE VALIDATION VISUELLE UTILISATEUR**

Inventory au premier plan (`6038`). Aucun commit / push. **STOP.**
