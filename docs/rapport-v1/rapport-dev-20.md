# Rapport DEV-20 — Ergonomie cohérente et navigation simplifiée

## Verdict

**EN ATTENTE DE VALIDATION PHYSIQUE**

Corrections implémentées et compilées. Installation Moto selon disponibilité ADB.

---

## 1. Modifications réalisées

| Point | Résultat |
|---|---|
| Modifier / Déplacer | Une ligne horizontale via `InventoryActionBar` |
| Barres d’actions | Composant partagé (2 ou 3 actions configurables) |
| Onglets Inventaire / Recherche / Historique | **Supprimés** |
| Recherche | Icône AppBar → route |
| Historique + Paramètres | Menu ⋮ |
| Liste courte | Alignée en bas (ordre naturel, sans `reverse`) |
| DEV-19 création | Conservé (ordre, `$`/`♡`, `+` position / `+` central) |

---

## 2. Composants mutualisés / adaptés

1. **`InventoryActionBar`** (`inventory_action_bar.dart`) — ligne d’actions horizontale.
2. **`InventoryThumbBody`** — inchangé dans son rôle (formulaires) ; clavier stable.
3. **Liste arbre** — même principe bas d’écran (espace libre au-dessus du groupe).

---

## 3. Duplications supprimées

- `_ActionBar` privée de la fiche de création → remplacée par `InventoryActionBar`.
- Barre d’onglets custom + `IndexedStack` multi-destinations.
- Empilement vertical Modifier puis Déplacer dans la fiche détail.

---

## 4. Nouvelle navigation

- Page unique : Inventaire (+ FAB).
- AppBar : titre Inventory, Recherche, ⋮ (Ajouter / Historique / Paramètres).
- Piles : Inventaire → Recherche|Historique|Paramètres|fiche → retour.

---

## 5. Liste courte / longue

- Courte : groupe de lignes en bas, ordre inchangé.
- Longue : `SingleChildScrollView` + `minHeight` + `Align.bottomCenter` → défilement normal.
- Arborescence, indent, prix, totaux, ⊕, expansion : conservés.

---

## 6. Fichiers modifiés

| Fichier |
|---|
| `lib/app/inventory_action_bar.dart` *(nouveau)* |
| `lib/app/main_navigation_screen.dart` |
| `lib/app/inventory_tree_screen.dart` |
| `lib/app/node_details_screen.dart` |
| `lib/app/inventory_creation_screen.dart` |
| `pubspec.yaml` → `1.0.3+4` |

---

## 7. Version Android

| Champ | Valeur |
|---|---|
| versionName | `1.0.3` |
| versionCode arm64 | `2004` |
| APK | `dist/android/Inventory-v1.0.3-arm64-release.apk` |
| Signature | production existante |

---

## 8. Installation physique

| État | Détail |
|---|---|
| Implémenté | Oui |
| Compilé | Oui (release split) |
| Installé | **Non** — Moto absent (seul émulateur ADB) |
| Validé physiquement | **Non** — à confirmer par le propriétaire |

---

## 9. Limites

- Retrait d’un bien : menu ⋮ de la fiche (plus sur la barre inférieure).
- Pas de tests automatisés (mandat).

---

## 10. À valider sur le Moto

1. Modifier | Déplacer côte à côte  
2. Plus d’onglets ; Recherche AppBar ; Historique/Paramètres ⋮  
3. Peu d’emplacements → bas d’écran  
4. Liste longue → défilement  
5. Parcours DEV-19 inchangé  
6. Persistance / données intactes  

---

## Arrêt

**ARRÊT — attendre le retour du propriétaire.**
