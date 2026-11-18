# Rapport DEV-34 — Alignement cartésien des montants et des actions

## 1. Cause du décalage

Dans `_TreeItem` (`inventory_tree_screen.dart`), la ligne était construite ainsi :

1. `LongPressDraggable` contenant un `Row` avec le prix **en fin de zone flexible** (après le nom).
2. Le bouton `+` était ajouté **uniquement** si `node.type.canContain`, **à l’extérieur** du `Expanded` qui enveloppe le draggable.

Conséquences :

- Avec `+` : le montant s’arrêtait avant la colonne d’action.
- Sans `+` : le montant occupait jusqu’au bord droit de l’écran.
- L’indentation enveloppait toute la ligne, donc les colonnes prix/actions se déplaçaient aussi selon la profondeur.

Aucune largeur réservée n’existait pour les actions absentes.

## 2. Composants concernés

| Fichier | Rôle |
|---|---|
| `lib/app/inventory_tree_screen.dart` | Ligne d’arbre `_TreeItem` — seule modification UI |
| `lib/app/inventory_inline_sheet.dart` | Sous-ligne consultation + Modifier (inchangé fonctionnellement) |
| `lib/app/inventory_ui.dart` | `inventoryListPrice` (inchangé) |
| `test/app/dev34_tree_alignment_test.dart` | Assertion géométrique (bord droit des montants) |
| `integration_test/dev34_alignment_smoke_test.dart` | Smoke émulateur + captures PNG |

Aucun modèle SQLite, calcul de totaux, tri, DnD, recherche ni navigation modifié.

## 3. Structure des colonnes retenue

Grille unique par ligne, **indépendante du type de nœud** :

| Zone | Contenu | Contrainte |
|---|---|---|
| **A** | Indentation + chevron + icône + nom (+ sous-titre / total sous-arbre) | `Expanded` — seule zone indentée |
| **B** | Montant propre (`inventoryListPrice`) | Largeur fixe, `TextAlign.end` |
| **C** | Bouton `+` ou emplacement vide | Largeur fixe toujours réservée |

Le `+` reste **hors** du `LongPressDraggable` (évite de voler le long-press).  
Le bouton **Modifier** reste dans la sous-ligne de consultation (DEV-24/25) ; son affichage ne déplace pas la zone B.

## 4. Largeurs et contraintes appliquées

```dart
const _priceColumnWidth = 72.0;   // Zone B — ex. « 1 000 $ »
const _actionColumnWidth = 40.0;  // Zone C — IconButton compact
```

- Zone B : `MediaQuery.textScalerOf(context).scale(72)` pour respecter la taille système.
- Zone C : 40 px logiques stables (pas de shrinkage si `+` absent).
- Indentation DEV-33 conservée : `_indentPerLevel = 8`, `_maxVisualIndent = 48`, **appliquée uniquement en Zone A**.
- Pas de `0 $` inventé ; prix vide → Zone B vide mais réservée.
- Pas de défilement horizontal de l’arbre.

## 5. Résultats des tests

| Test | Cible | Résultat |
|---|---|---|
| `test/app/dev34_tree_alignment_test.dart` | Widget — écart ≤ 1 px entre bords droits des montants (avec/sans `+`, 3 niveaux, `1 000 $`, nom long, largeur 320 + textScaler 1.3) | **OK** (exécuté avant verrou `sqlite3.dll` Windows) |
| `integration_test/dev34_alignment_smoke_test.dart` | `emulator-5554` — même assertion ≤ 1,5 px + écriture PNG | **OK** (`All tests passed!`) |
| `dart analyze lib/app/inventory_tree_screen.dart` | Analyse | **No issues found** |

Scénario seed émulateur : Maison (sans valeur propre) → Bureau 120 $ (`+`) → Ampoule 15 $ / Clavier 5 $ / Moniteur 250 $ (sans `+`) → Boîte 10 $ (`+`) → Câble 1 000 $ ; nom long tronqué ; info Moniteur + Modifier.

## 6. Captures avant / après

Dossier : [`docs/rapport/_dev34_shots/`](_dev34_shots/)

| Fichier | Contenu |
|---|---|
| `01_before_dev32.png` | Référence antérieure (DEV-32) — ligne avec `+` vs biens sans grille réservée |
| `02_after_align.png` | Après correction — montants + `+` / emplacements vides |
| `03_info_modifier.png` | Consultation ouverte (Moniteur) + bouton Modifier en sous-ligne |

Captures produites sur `emulator-5554` via `RepaintBoundary.toImage` + `adb run-as` pull (pas d’installation Moto).

## 7. Comportement des noms longs

Conservé : `maxLines: 1` + `TextOverflow.ellipsis` en Zone A.  
La Zone A cède l’espace aux colonnes B/C ; le nom ne chevauche pas le montant.

## 8. Vérification des sous-totaux

Inchangés : sous-titre gris sous le nom = total sous-arbre (`inventorySubtreeTotalLabel`) ; trailing Zone B = valeur propre uniquement.  
Exemple observé : Bureau — sous-titre `1 400 $`, trailing `120 $`.

## 9. Régressions éventuelles

| Point | Statut |
|---|---|
| Boutons `+` utilisables | OK |
| Long-press / DnD | Non modifié ( `+` hors draggable) |
| Consultation / Modifier | OK (sous-ligne) |
| Indentation compacte | OK (Zone A seulement) |
| Métier / SQLite / totaux | Aucun changement |
| Installation Moto | **Non effectuée** (interdit ; appareil vu `unauthorized` non touché) |

## 10. Verdict

**VALIDÉ**

- Tous les montants de ligne (Zone B) partagent le même axe X (assertion géométrique ≤ 1,5 px).
- L’absence de `+` ne déplace plus les montants (Zone C réservée).
- L’indentation n’affecte plus les colonnes B/C.
- Aucun comportement métier modifié.
- Aucun commit, aucun push, aucune install Moto.

**Principe respecté : une seule grille, colonnes stables, actions indépendantes de la position des montants.**
