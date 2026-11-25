# UX-ARB-01 — Emplacement racine permanent et ajout contextuel

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` — versionCode **6041** (build Flutter **4041**, arm64 debug)  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION UTILISATEUR**

---

## 1. Décisions appliquées

| Décision | Application |
|---|---|
| Suppression du FAB global | Oui — ajout via `+` contextuel et menu ⋯ → Ajouter |
| Emplacement racine permanent | Oui — `NodeType.location`, nom défaut « Inventaire » |
| Nouveau type métier | Non — réutilisation de `location` |
| Migration schéma SQLite | **Non** — IDs stables + ensure idempotent |

---

## 2. Mécanisme

### Architecture réutilisée

- Racines déjà = `parentId IS NULL` + `NodeType.location` (`getRootLocations`).
- Contenant / `+` contextuel déjà sur tout nœud `canContain`.

### Racine permanente

Fichier : `lib/core/domain/permanent_roots.dart`

| Espace | ID stable |
|---|---|
| Biens | `…000010` |
| Stock | `…000011` |
| À acheter | `…000012` |

`InventoryEngine.ensurePermanentRoot(space)` :

1. Crée la location si absente (nom « Inventaire »).
2. Garantit `parentId = null`, type location, statut actif.
3. **Réparente** les autres racines orphelines sous cette racine (ids descendants inchangés).
4. Idempotent — pas de doublon aux démarrages suivants.
5. **Ne renomme pas** une racine déjà présente (renommage manuel possible).

Appelé au chargement des racines (`InventoryTreeController.loadRoots`).

### Protections

- Suppression → `permanentRootProtected`
- Déplacement → idem (`_writeMove`)
- DnD : `maxSimultaneousDrags = 0` sur la racine
- Fiche : pas de champ Position / pas de bouton Supprimer
- `createNode` : `parentId` obligatoire (plus de nouvelle racine libre)

Déplacement vers « racine » (zone DnD / `null`) → nest sous la racine permanente.

---

## 3. Autres corrections UX-ARB-01

- FAB retiré (`main_navigation_screen`).
- Encerclements des `+` et cœurs retirés (`_TrailingCircleButton` sans cercle/bordure).
- Menu ⋯ → Ajouter conserve un accès, parent = racine permanente.
- Ajout d’emplacement dans les fiches (quick-add position) **conservé**.

---

## 4. Inventaires existants (observé Motorola)

Avant : « appartement Papineau » était racine.  
Après ensure : **Inventaire (1)** → appartement Papineau (et suite) en enfants.

- Identifiants des nœuds existants : conservés.
- Médias / valorisations / historique : non touchés (seul `parentId` / `siblingOrder` des anciennes racines).
- Sauvegardes : la racine est un nœud location normal ; restore puis `ensure` répare les orphelins.

---

## 5. Cohérence des espaces

Même principe Biens / Stock / À acheter (IDs distincts).  
Indépendance métier préservée.

---

## 6. Fichiers modifiés

- `lib/core/domain/permanent_roots.dart` *(nouveau)*
- `lib/core/domain/inventory_engine.dart`
- `lib/core/domain/inventory_exception.dart`
- `lib/app/inventory_tree_controller.dart`
- `lib/app/inventory_creation_screen.dart`
- `lib/app/inventory_tree_screen.dart`
- `lib/app/main_navigation_screen.dart`
- `lib/app/app_strings.dart`
- `docs/rapport-v2/ux-arb-01-emplacement-racine-permanent.md`

---

## 7. Affinement graphique et colonnes (suite)

| Élément | Changement |
|---|---|
| `+` | Trait CustomPaint **2.2** (taille 18 conservée) |
| Cœur | Contour **2.2** (était 1.5) ; remplissage progressif inchangé |
| Colonne valorisation | Largeur **56** ; cœur / montant / niveau **centrés** sur le même axe |
| Colonne actions | Largeur **40** ; `+` et crayon **centrés** (même `_TrailingCircleButton`) |
| Compacité | Espace rendu aux noms ; pas d’encerclement réintroduit |
| Typo montants / hauteurs / indent | Inchangés |

Fichiers : `inventory_tree_screen.dart`, `inventory_ui.dart` (stroke cœur).

---

## 8. Preuves Motorola

| Élément | Résultat |
|---|---|
| Install racine permanente | Success — **6040** |
| Install affinement colonnes | Success — **6041** |
| UI dump | `Inventaire (1)` + `Ajouter dans Inventaire` ; `0 $` visible |
| Captures | `_ux-arb-01/motorola-biens-apres.png` ; `_ux-arb-01/motorola-alignement-colonnes.png` |

---

## 9. Validation restante (utilisateur)

- Alignement colonnes valorisation / actions (œil + tactile).
- Lisibilité montants sans débordement.
- Épaisseur `+` / contour cœur vs montants.
- Parcours racine permanente déjà listés (ajout, non-suppression, persistance).

**STOP — EN ATTENTE DE VALIDATION UTILISATEUR.**
