# UX-CONV-02 — Convergence ergonomique et modulaire

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` — versionCode **6039** (build Flutter **4039**, arm64 debug)  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION UTILISATEUR**

---

## 1. Résumé des interventions

Propagation des conventions Biens (48 dp, titres externes, boutons carrés, roulette position, outlined exclusifs, sobriété) vers :

- Fiches création / modification **Stock**
- Fiches création / modification **À acheter**
- Formulaire **d’acquisition**

Biens : **inchangé** visuellement (même chrome ; paramètre `compact` retiré car devenu le seul mode).

---

## 2. Composants existants réutilisés

| Composant | Usage |
|---|---|
| `InventorySquareIconButton` | Quantité + niveau de stock |
| `inventoryGoodsOutlinedStyle` | Destination Biens / Stock (achat) |
| `InventoryCompactRoulette` via `InventoryParentField(compactRoulette: true)` | Position Stock, À acheter, acquisition |
| `InventoryQuantityStepper` | À acheter + acquisition (chrome carré unique) |
| `InventoryStockLevelStepper` | Stock — quarts, chrome carré |
| `InventoryValuationField` | Acquisition → Biens (inchangé) |
| `valuationControlHeight` / `compactRouletteHeight` | Hauteur 48 |

---

## 3. Modifications Stock

- **Nom** : titre `labelLarge` + champ h=48 (réutilise `_buildGoodsNameField`) ; autofocus création conservé.
- **Position** : `compactRoulette: true` ; quick-add et règles parent inchangés.
- **Niveau restant** : boutons carrés ; incréments par quarts inchangés.
- **Quantité de référence** : titre externe + h=48 ; saisie entière facultative ; helper retiré.
- **Contenant / Objectif / valorisation / médias** : non importés.

---

## 4. Modifications À acheter

- **Nom** : même coquille Biens ; libellé « Article à acheter ».
- **Position** : roulette compacte.
- **Quantité** : stepper carré h=48.
- **Prix cible** : saisie décimale précise conservée ; titre + h=48 ; helper retiré.

---

## 5. Modifications acquisition

- **Quantité** : stepper carré h=48.
- **Destination** : deux `OutlinedButton` exclusifs (style Biens) à la place du `SegmentedButton`.
- **Position** : roulette lorsque création nouvelle destination.
- **Prix payé** : précision clavier conservée ; titre + h=48 ; helper retiré.
- **Valorisation / liaisons Stock** : inchangées.

---

## 6. Conventions graphiques appliquées

| Propriété | Valeur |
|---|---|
| Hauteur contrôles | 48 dp |
| Rayon boutons carrés / outlined | 12 |
| Icônes | 22 |
| Gap rangées | 12 |
| Gap titre → contrôle | 6 |
| Titres | `labelLarge` au-dessus |

---

## 7. Anciennes variantes supprimées

- Chrome circulaire `_StepButton` et icônes 32 `_CompactStepIcon` (steppers).
- Paramètre `compact` des steppers (un seul chrome).
- Helpers : `stockReferenceHint`, `targetPriceHint`, `paidPriceHint`.
- `SegmentedButton` destination (écran achat).

`InventoryParentField` conserve encore le mode Dropdown (`compactRoulette: false`) ; tous les call-sites passent désormais `true`. Pas de suppression du mode Dropdown dans ce mandat (composant partagé Biens).

---

## 8. Différences métier préservées

- Stock : niveau en quarts, référence quantitative, pas de valorisation/médias/objectif.
- À acheter : quantité désirée, prix cible optionnel précis.
- Acquisition : destinations, modes de liaison Stock, prix payé, valuation si Biens.
- **Contenant** : volontairement **goods-only** (`_supportsItemKind` exclut Stock / À acheter). Pas de contradiction bloquante ; capacité non retirée ailleurs.

---

## 9. Fichiers modifiés

- `lib/app/inventory_ui.dart`
- `lib/app/inventory_creation_screen.dart`
- `lib/app/purchase_acquire_screen.dart`
- `lib/app/app_strings.dart`
- `docs/rapport-v2/ux-conv-02-convergence-ergonomique-modulaire.md` (ce fichier)

---

## 10. Captures

| Fichier | Contenu |
|---|---|
| `_ux-conv-02/motorola-premier-plan.png` | Premier plan après install / launch |

Captures comparatives détaillées des trois formulaires : **à valider visuellement sur Motorola** par le propriétaire (navigation manuelle).

---

## 11. Résultats observables et limites

| Critère | État |
|---|---|
| Code implémenté | Oui |
| `dart analyze` (fichiers touchés) | Aucun problème |
| Compilation ARM64 debug | OK (4039) |
| Install `adb -s ZT322P23HJ install -r` | Success — versionCode **6039** |
| Données | Conservées (pas de uninstall) |
| Validation tactile / parcours métier | **À faire par l’utilisateur** |
| Non-régression Biens | Structure goods inchangée ; chrome steppers identique (carré) |

ADB ne remplace pas la validation tactile des roulettes ni les parcours d’enregistrement.

---

## 12. Arbitrages éventuels

Aucun arbitrage bloquant pour clôturer ce mandat.  
Option ultérieure (hors scope) : retirer le chemin Dropdown de `InventoryParentField` si le mode non-roulette reste durablement inutilisé.

---

## 13. Version Motorola

| Élément | Valeur |
|---|---|
| Appareil | `ZT322P23HJ` |
| versionName | `1.0.15` |
| versionCode | **6039** |
| APK | `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` |

**STOP — EN ATTENTE DE VALIDATION UTILISATEUR.**
