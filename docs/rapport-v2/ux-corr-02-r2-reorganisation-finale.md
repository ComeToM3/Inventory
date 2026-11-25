# UX-CORR-02-R2 — Finalisation glisser-déposer unique

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ`  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION TACTILE UTILISATEUR**

---

## Version installée

| Champ | Valeur |
|---|---|
| Avant | `1.0.15` / versionCode **6022** (build 4022) |
| Après | `1.0.15` / versionCode **6023** (build **4023**, arm64 debug) |
| Install | `adb -s ZT322P23HJ install -r app-arm64-v8a-debug.apk` |
| Données | conservées |

---

## Cause réelle de l’échec du réordonnancement

1. **Ambiguïté nest vs ordre** — `resolveOrganizeDrop` préférait `nest` dès que la cible pouvait contenir. Déposer un bien sur un frère « contenant », ou viser le parent ouvert, ne changeait pas l’ordre (souvent no-op si déjà enfant).
2. **Une seule sémantique « avant »** — déposer sur une ligne = toujours `placeSiblingBefore`. Impossible de placer **après** le dernier (scénario B : A après C).
3. **Pas de zones d’insertion** — aucune distinction visuelle / spatiale entre « entre deux lignes » et « dans un contenant ».

Le changement de parent fonctionnait car le centre d’une cible `canContain` menait clairement à `nest`.

---

## Correction apportée

- Résolution selon la **position verticale** sur la ligne :
  - frères non nestables : moitié haute = avant, moitié basse = après ;
  - frères nestables : bandes haut/bas = réordre, centre = nest ;
  - nest sur le parent actuel = rejeté (plus de faux succès).
- `placeSiblingAfter` + indicateur d’insertion (barre mint avant/après la ligne).
- Même geste : appui long → maintenir → glisser → relâcher.
- Paramètres tactiles UX-CORR-02-R (arming scroll / touchSlop) **conservés**.

---

## Ancien système retiré

| Élément | Action |
|---|---|
| Menu ⋯ **Organiser** / **Terminer** / bannière mode | **Supprimés** (seul système parallèle encore exposé) |
| État `_organizing` / prop `organizing` | **Supprimés** |
| Chaînes `organize`, `organizeDone`, `organizeBanner` | **Supprimées** |
| Écran / route Paramètres dédiée « organisation » | **Aucune trouvée** (Paramètres : Aide, À propos, avancées, backup) — rien à supprimer là |

**Conservé (partagé / métier) :** `reorderSiblings`, `placeSiblingBefore` / `After`, `moveSibling`, `relocateNode`, `sibling_order`, moteur SQLite, backup.

Aide « Déplacement » mise à jour (ordre + parent).

---

## Fichiers

**Modifiés**

- `lib/app/inventory_tree_controller.dart`
- `lib/app/inventory_tree_screen.dart`
- `lib/app/main_navigation_screen.dart`
- `lib/app/app_strings.dart`

**Supprimés :** aucun fichier dédié (pas d’écran d’organisation séparé).

---

## Scénarios A–G

| # | Attendu | Preuve agent |
|---|---|---|
| A–D réordre | avant / après / entre / dans contenant | **À confirmer au doigt** sur Motorola |
| E parent | Salon ↔ Chambre, boîtes | Non régressé côté code ; **à confirmer au doigt** |
| F persistance | fermer / rouvrir | **À confirmer** |
| G ancien système | pas d’Organiser dans ⋯ ; Paramètres sans org | Code retiré ; **à constater** dans l’UI |

Aucune simulation ADB présentée comme validation tactile.

---

## Verdict

**EN ATTENTE DE VALIDATION TACTILE UTILISATEUR**

Inventory ouvert au premier plan sur le Motorola. **STOP.**
