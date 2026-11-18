# Rapport DEV-23 — Fiches intégrées + correction DnD

## Verdict

| État | Statut |
|---|---|
| Implémenté | Oui |
| Compilé | Oui (`1.0.6+7`) |
| Observé sur émulateur | Oui (fiches + édition + DnD via geste tactile simulé) |
| DnD souris Windows → émulateur | **Non vérifié manuellement** (fenêtres superposées / drag desktop ≠ long-press) |
| Installé Moto | Non |
| Validé physique | **En attente** |

**ARRÊT — attendre le retour du propriétaire.**

---

## 1. Causes du glisser-déposer fiable

1. **Course critique** : `onDragEnd` vidait `_dragging` avant `onAccept`, donc le dépôt lisait parfois `null` et abandonnait silencieusement. Les injections ADB « lentes » masquaient le problème ; un relâchement manuel plus rapide échouait souvent.
2. Concurrence geste / défilement / fiche : le draggable englobait trop de surface utile.

## 2. Corrections DnD

- Dépôt basé sur **`details.data`**, plus sur l’état `_dragging`.
- `LongPressDraggable` uniquement sur **l’en-tête** de ligne (pas le formulaire déplié).
- Délai long-press **280 ms**, `pointerDragAnchorStrategy`, feedback plus visible.
- Édition active → `maxSimultaneousDrags: 0` sur la ligne.

## 3. Fiches dépliables

- Appui court sur le corps → ouvre / ferme `InventoryInlineSheet` sous la ligne.
- Chevron → enfants uniquement (`toggle` / `expand`).
- Consultation compacte : type, position, quantité / sentimental si absents de la ligne.
- **Pas** de double prix, **pas** de double nom, **pas** de « Aucune valorisation ».
- Retrait / suppression via menu ⋮ de la fiche.

## 4. Modification mutualisée

- Même ordre DEV-21 : Position → Quantité → Valorisation `$`/`♡` → Nom → Annuler | Enregistrer.
- Composants : `InventoryParentField`, `InventoryValuationField`, `InventoryActionBar`.
- Après save : retour consultation + snackbar haut.
- Abandon protégé (`confirmDiscardChanges`).

## 5. Anciennes pages

- Navigation arbre → `NodeDetailsScreen` / `NodeEditScreen` **retirée**.
- Fichiers page détail / édition / contrôleur associé **supprimés**.
- Recherche → `revealNode` + `openDetailFor` dans l’arbre.
- Création et historique (retirés) inchangés.

## 6. Fichiers

**Ajouté :** `inventory_inline_sheet.dart`

**Modifiés :** `inventory_tree_screen.dart`, `inventory_tree_controller.dart`, `main_navigation_screen.dart`, `inventory_valuation_field.dart`, `pubspec.yaml`

**Supprimés :** `node_details_screen.dart`, `node_edit_screen.dart`, `node_details_controller.dart`

---

## 7. Compilation

- `flutter analyze lib/app` : OK
- `flutter run -d emulator-5554` : OK

---

## 8. Parcours observés (émulateur)

| # | Parcours | Statut |
|---|---|---|
| 1 | Appui court → fiche | **Observé** |
| 2 | 2ᵉ appui → fermeture | **Observé** |
| 3 | Chevron ≠ fiche | **Observé** (enfants vs sheet) |
| 4 | Bien / prix non répété | **Observé** (Ess 28 $ hors sheet) |
| 5 | Emplacement adapté | **Observé** (type + position) |
| 6 | Contenant + enfants | **Observé** (Ess2 avec enfants) |
| 7 | Modifier in-line | **Observé** |
| 8 | Enregistrer (Ess→Ess2) | **Observé** + snackbar |
| 9 | Annuler | **Observé** |
| 10 | DnD Dest→Ess2 | **Observé** (`motionevent` long-press) |
| 11 | Dépôt invalide | Non rejoué ce mandat (logique inchangée + data-driven) |
| 12 | Liste courte bas | **Observé** |
| 13 | Recherche → arbre | Implémenté (non rejoué UI ce tour) |
| 14 | Plus de page détail | **Observé** |

**DnD souris sur fenêtre émulateur :** tentative desktop interceptée (VLC/Chrome) ; outil de drag desktop sans vrai long-press → **Non vérifié manuellement**.

---

## 9. Limites

- Validation DnD « au doigt » réelle = Moto.
- Expand-au-survol / auto-scroll : non rejoués ici.
- Un appui mal cadré peut encore ouvrir Modifier si la sheet est déjà visible (zones proches).

---

## 10. À confirmer sur Moto

1. Long-press + glisser au doigt.
2. Fiches / édition au pouce.
3. Recherche → dépliage.
4. Données réelles préservées.
