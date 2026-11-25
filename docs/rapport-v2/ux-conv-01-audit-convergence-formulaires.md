# UX-CONV-01 — Audit de convergence formulaires Biens / Stock / À acheter

**Date :** 24 novembre 2026  
**Nature :** analyse et recommandation uniquement — aucun code modifié  
**Référentiel :** fiche Biens post UX-CORR-04…06 (Motorola `6038`)  
**Statut :** **AUDIT TERMINÉ — EN ATTENTE D'ARBITRAGE**

---

## 1. Résumé exécutif et verdict

La fiche Biens dispose désormais d’un socle **partagé et réutilisable** (`InventorySquareIconButton`, `inventoryGoodsOutlinedStyle`, `InventoryCompactRoulette`, `valuationControlHeight` / `compactRouletteHeight` = 48, `InventoryQuantityStepper(compact:)`, `InventoryParentField(compactRoulette:)`).

Stock et À acheter passent déjà par le **même** `InventoryCreationScreen`, mais empruntent la branche « non-Biens » : dropdown parent, steppers circulaires, champs prix/référence au clavier avec `helperText`, titres flottants, espacements 14.

**Verdict :** une convergence **proportionnée** est possible sans refonte — principalement en **branchant les flags/composants existants** et en harmonisant la coquille de formulaire. Les écarts métier (niveau de stock, prix cible, acquisition) doivent rester **préservés**.

---

## 2. Acquis ergonomiques et modulaires de Biens

### Conventions (code)

| Domaine | Convention Biens | Source |
|---|---|---|
| Hauteur contrôle | **48 dp** | `compactRouletteHeight` / `valuationControlHeight` |
| Gap titre → contrôle | **6** | `_goodsLabelControlGap` |
| Gap entre rangées | **12** | `inventory_creation_screen` branche goods |
| Titres | `labelLarge` **au-dessus** du contrôle (pas de `labelText` flottant sur Nom) | fiche goods |
| Bouton icône | Carré coins **12**, mintSoft / petroleum sélectionné, icône 22 | `InventorySquareIconButton` |
| Bouton texte | `OutlinedButton` h=48, style partagé, sélection mintSoft | `inventoryGoodsOutlinedStyle` |
| Quantité | Stepper `compact: true` → boutons carrés | `InventoryQuantityStepper` |
| Position | Roulette `compactRoulette: true` + `+` carré | `InventoryParentField` + `InventoryCompactRoulette` |
| Valorisation | Chips carrés + roulette $5 / cœurs | `InventoryValuationField` |
| Médias | Titre unique « Photo et document » ; Galerie / Caméra / Reçus | `GoodsMainPhotoField` |
| Sobriété | Pas de `helperText` permanent ; pas de légende docs vide | UX-CORR-06 |

### Fichiers clés

- `lib/app/inventory_creation_screen.dart` (`_isGoodsItemForm`)
- `lib/app/inventory_ui.dart` (boutons / steppers / style outlined)
- `lib/app/inventory_compact_roulette.dart`
- `lib/app/inventory_parent_field.dart`
- `lib/app/inventory_valuation_field.dart`
- `lib/app/goods_main_photo_field.dart`

*Constats : inspection code. Comportement tactile Biens validé sur Motorola dans UX-CORR-06 ; Stock / À acheter non re-mesurés sur appareil dans cet audit.*

---

## 3. État réel de la réutilisation

| Composant | Partagé ? | Biens | Stock / À acheter / Achats | Blocage métier |
|---|---|---|---|---|
| `InventorySquareIconButton` | Oui | Oui | Non utilisé (sauf via éventuel compact) | Non |
| `inventoryGoodsOutlinedStyle` | Oui | Objectif + médias | Non | Non |
| `InventoryCompactRoulette` | Oui | Finance + position | Non branché | Non |
| `InventoryParentField` | Oui | `compactRoulette: true` | `false` → **DropdownMenu** | Non |
| `InventoryQuantityStepper` | Oui | `compact: true` | `compact: false` → **cercles 40** | Non |
| `InventoryStockLevelStepper` | Oui | — | Stock : cercles / compact 32px | Spécifique Stock |
| `InventoryValuationField` | Oui | Fiche Biens | Achats (`purchase_acquire`) si destination Biens | Valorisation biens seulement |
| `GoodsMainPhotoField` | Oui (goods) | Oui | Absent | Médias goods-only (validé M4) |
| Hauteur 48 / titres externes | Pattern local goods | Oui | Non (labels flottants, h libres) | Non |

**Doublons de style :** chrome circulaire `_StepButton` encore vivant pour steppers non-compact ; `SegmentedButton` encore utilisé (destination achat) alors que Biens a basculé vers outlined indépendants.

---

## 4. Écarts constatés dans Stock

Branche `else` de `inventory_creation_screen` lorsque `_isStockProduct`.

| Élément | Biens | Stock | Nature |
|---|---|---|---|
| Position | Roulette + `+` carré | DropdownMenu (+ quick add) | Graphique / interaction |
| Quantité conceptuelle | — | `TextField` + clavier + **helperText** | Interaction + sobriété |
| Niveau restant | — | `InventoryStockLevelStepper` cercles | Graphique (métier à garder) |
| Nom | Titre + champ h=48 | `labelText` flottant, h libre | Graphique |
| Contenant / Objectif / Valorisation / Médias | Présents | Absents | **Métier — préserver** |
| Espacements | 12 | 14 | Mineur |

---

## 5. Écarts constatés dans À acheter

### Fiche besoin (`_isToBuyNeed`)

| Élément | Biens | À acheter | Nature |
|---|---|---|---|
| Position | Roulette | DropdownMenu | Graphique / interaction |
| Quantité désirée | Stepper carré compact | Stepper **circulaire** | Graphique (composant déjà prêt) |
| Prix cible | Roulette $ (Biens) | `TextField` + helper | Interaction — **arbitrage** |
| Nom | Titre externe h=48 | Label flottant | Graphique |
| Médias / Objectif / Contenant | Présents | Absents | **Métier — préserver** |

### Écran Achats (`purchase_acquire_screen.dart`)

| Élément | Écart vs conventions Biens |
|---|---|
| Quantité | Stepper non-compact (cercles) |
| Destination Biens/Stock | `SegmentedButton` (≠ trio outlined Biens) |
| Position | `InventoryParentField` sans roulette |
| Valorisation à l’achat | **Déjà** `InventoryValuationField` — conforme composant |
| Prix payé | `TextField` + helper | 

---

## 6. Matrice de convergence

| Réf. Biens | Stock | À acheter / Achats | Écart | Partagé dispo. | Action | Impact / risque | Priorité |
|---|---|---|---|---|---|---|---|
| Stepper `compact: true` | Cercles 40 | Cercles 40 (besoin + achat) | Chrome | `InventoryQuantityStepper` | **RÉUTILISER** `compact: true` | Faible | P1 |
| `InventorySquareIconButton` | Stock level cercles | — | Chrome | Oui + stepper stock | **HARMONISER** stock level via carrés / `compact` | Faible | P2 |
| Parent `compactRoulette` | Dropdown | Dropdown (+ achat) | Interaction | `InventoryParentField` | **RÉUTILISER** flag | Moyen (habitudes) | P1 |
| Titre + champ h=48 | Label flottant | Label flottant | Layout | Pattern goods | **HARMONISER** coquille nom | Faible | P2 |
| Gaps 12 / label gap 6 | 14 / 6 | 14 / 6 | Espacement | Constantes | **HARMONISER** | Trivial | P3 |
| Outlined exclusifs | — | `SegmentedButton` destination | Famille boutons | `inventoryGoodsOutlinedStyle` | **HARMONISER** ou **PRÉSERVER** | Moyen UX | P2 / arbitrage |
| Roulette finance | — | Prix cible / payé en clavier | Saisie | `InventoryValuationField` / roulette | **À ARBITRER** | Métier + clavier | P2 |
| Sans helper permanent | `stockReferenceHint` | `targetPriceHint` / `paidPriceHint` | Sobriété | — | **SIMPLIFIER** ou **PRÉSERVER** | Info utile ? | Arbitrage |
| Médias / Objectif / Contenant | Absents | Absents | — | — | **PRÉSERVER** | N/A | — |
| Valorisation fiche | Absente Stock/À acheter | Présente à l’achat→Biens | — | `InventoryValuationField` | **CONFORME** (achat) / **PRÉSERVER** (fiches) | — | — |
| `GoodsMainPhotoField` | Non | Non | — | Goods-only | **PRÉSERVER** | Hors Stock/À acheter | — |

---

## 7. Différences métier à préserver

- **Stock :** niveau restant (quarts), référence quantitative conceptuelle, pas de valorisation ni médias ni Contenant/Objectif.
- **À acheter :** quantité désirée / restante, prix cible optionnel, pas de médias goods.
- **Achats :** destination Biens vs Stock, modes de liaison stock, prix payé, valuation seulement si destination Biens.
- Ne **pas** importer Objectif, Contenant, Photo/Reçus ou valorisation unitaire dans les fiches Stock / besoin.

---

## 8. Risques et arbitrages produit

| # | Question | Options |
|---|---|---|
| A | Remplacer les `helperText` (référence stock, prix cible, prix payé) ? | SIMPLIFIER (aligné Biens) vs PRÉSERVER (aide champs optionnels) |
| B | Prix cible / prix payé → roulette financière Biens ? | Réduit clavier mais sémantique ≠ valorisation d’un bien ; champs facultatifs |
| C | Destination achat : trio outlined vs SegmentedButton ? | Cohérence visuelle vs contrôle segmenté déjà clair à 2 options |
| D | Roulette position partout (Stock, besoin, achat) ? | Oui pour cohérence tactile ; vérifier listes courtes / `allowRoot` |

---

## 9. Trajectoire recommandée

**Principe :** Biens reste figé sauf nécessité technique autorisée. Interventions groupées, pas de microcorrectifs isolés.

### Vague 1 — Réutilisation immédiate (P1, bas risque)

1. Activer `compact: true` sur `InventoryQuantityStepper` (fiche besoin, écran achat).
2. Activer `compactRoulette: true` sur `InventoryParentField` (Stock, À acheter, achat quand position affichée) ; conserver règles `allowRoot` / exclusion existantes.
3. Option liée : aligner `InventoryStockLevelStepper` sur les boutons carrés (même chrome).

### Vague 2 — Coquille formulaire (P2)

4. Harmoniser Nom (titre `labelLarge` + champ h=48) sur Stock / À acheter — sans changer les libellés métier (`stockProductType`, `needType`).
5. Uniformiser gaps 12 / 6.
6. Selon arbitrage **C** : destination achat en boutons outlined.

### Vague 3 — Sobriété & saisie (après arbitrage A/B)

7. Retrait ou conservation des helpers.
8. Décision roulette vs clavier pour prix cible / payé (si oui : réutiliser mécanismes existants, pas un nouveau système).

### Ne pas faire

- Refonte design system globale.
- Forcer champs Biens dans Stock / À acheter.
- Abstraction « FormShell » tant que 2–3 écrans suffisent avec flags existants.

---

## Classification des suites

| Type | Contenu |
|---|---|
| **Nécessaire (si convergence validée)** | Vague 1 (compact stepper + roulette parent) |
| **Utile** | Vague 2 (nom h=48, gaps, stock level carré) |
| **Facultatif / arbitrage** | Helpers, roulette prix, outlined destination |

**STOP — aucune implémentation.** Attendre arbitrage de la trajectoire (vagues + questions A–D).
