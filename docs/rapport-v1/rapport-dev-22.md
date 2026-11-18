# Rapport DEV-22 — Anciens types + glisser-déposer

## Verdict

| État | Statut |
|---|---|
| Implémenté | Oui |
| Compilé | Oui (`1.0.5+6`, debug sur émulateur) |
| Observé sur émulateur | Partiel (DnD valide démontré ; certains gestes non vérifiés) |
| Installé Moto | Non — non autorisé |
| Validé physique | **En attente** |

**ARRÊT — attendre le retour du propriétaire.**

---

## 1. Traces de l’ancien système supprimées

| Trace | Action |
|---|---|
| Filtre recherche « Contenants » | Remplacé par **Biens-contenants** |
| Chip « Biens » ambigu | **Biens simples** + **Biens-contenants** distincts |
| Texte « catégories » (filtres / backup) | Reformulé sans catégories |
| Message `searchCategoryUnavailable` | Retiré de l’UI |
| Sélecteur de types | Vérifié : Emplacement / Bien simple / Bien-contenant uniquement |

Structures SQLite historiques (catégories, etc.) **non touchées**.

---

## 2. Interfaces de déplacement retirées

- Bouton **Déplacer** retiré de la fiche de consultation.
- `node_move_screen.dart` et `node_move_controller.dart` **supprimés**.
- Paramètre `revealMovedNode` retiré.
- Le sélecteur **Position** des formulaires (DEV-21) est conservé (dropdown, pas l’ancien écran Move).

---

## 3. Fonctionnement du glisser-déposer

1. **Appui court** → ouvre la fiche.
2. **Appui long** → saisie (`LongPressDraggable`) + feedback.
3. **Survol** d’un emplacement / bien-contenant valide → surbrillance.
4. **Survol prolongé** (~650 ms) d’une branche fermée → `expand` (sans commit).
5. **Bords** de la liste → auto-scroll pendant le glissement.
6. **Dépôt valide** → `InventoryTreeController.moveNode` → snackbar haut « Élément déplacé. ».
7. **Même parent** → no-op.
8. **Dépôt invalide / hors cible** → aucune écriture.
9. **Racine** → cible « Racine de l’inventaire » si `canBeRoot`.

---

## 4. Composants réutilisés / adaptés

- `InventoryTreeController.moveNode` (moteur existant)
- `canAcceptDrop` / `expand` / `findCachedNode` (UI)
- `showInventoryMessage` (confirmation haut)
- `InventoryTreeScreen` (geste + cibles + scroll)

---

## 5. Fichiers

**Modifiés :** `inventory_tree_screen.dart`, `inventory_tree_controller.dart`, `node_details_screen.dart`, `main_navigation_screen.dart`, `inventory_search_screen.dart`, `app_strings.dart`, `pubspec.yaml`

**Supprimés :** `node_move_screen.dart`, `node_move_controller.dart`

**Version :** `1.0.5+6`

---

## 6. Compilation

- `flutter analyze lib/app` : OK
- `flutter run -d emulator-5554` : OK (debug)

---

## 7. Parcours réellement effectués sur émulateur

Gestes via `adb shell input motionevent` (appui long + déplacement).

| # | Parcours | Résultat |
|---|---|---|
| 1 | Appui court → fiche | **Observé** (Livre → fiche, bouton Modifier seul) |
| 2 | Appui long saisit | **Observé** (prérequis des dépôts réussis) |
| 3 | Dépôt dans emplacement (Livre → Dest) | **Observé** + snackbar « Élément déplacé. » |
| 4 | Dépôt dans bien-contenant (Livre → Boite) | **Observé** + snackbar |
| 5 | Bien simple non destinataire | **Observé** (Livre sur Ray : pas de déplacement) |
| 6 | Cycle soi / descendant | **Non vérifié** (geste non abouti clairement) |
| 7 | Dépôt invalide / annulation | **Observé** (relâche hors cible : structure inchangée) |
| 8 | Ouverture branche au survol | **Non vérifié** (Boite restée repliée après essai) |
| 9 | Auto-scroll pendant glissement | **Non vérifié** (liste trop courte) |
| 10 | Arbre à jour après move | **Observé** (compteurs Dest/Ess/Boite) |
| 11 | Ancien Move inaccessible | **Observé** (pas de Déplacer sur fiche) |
| 12 | Anciens types / libellés | **Observé** (picker + filtres recherche) |

---

## 8. Non vérifiés

- Ouverture automatique de branche pendant le glissement.
- Auto-scroll en longue liste.
- Interdiction visuelle explicite cycle parent→descendant (moteur toujours garant).
- Gestes tactiles « humains » hors injection `motionevent` (souris Windows / `swipe` adb seuls insuffisants pour le long-press Flutter).

---

## 9. Problèmes / limites

- `adb input swipe` / `draganddrop` **ne déclenchent pas** le `LongPressDraggable` Flutter ; seuls `motionevent DOWN` + pause + `MOVE`/`UP` ont fonctionné.
- Données de test créées sur l’émulateur (Dest, Livre, Boite) — ne pas confondre avec validation Moto.
- Liste courte : bas d’écran conservé (DEV-20).

---

## 10. À confirmer sur Moto G24 Power

1. Long-press + glisser-déposer au doigt (ressenti tactile).
2. Expand au survol sur branche fermée.
3. Auto-scroll sur inventaire long.
4. Refus cycle / descendant au doigt.
5. Absence totale de l’ancien parcours Déplacer.
6. Données réelles préservées après quelques déplacements.

Ne pas installer sans autorisation explicite.
