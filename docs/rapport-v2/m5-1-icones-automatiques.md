# M5.1 — Icônes automatiques et dictionnaire local

**Date :** 21 novembre 2026  
**Verdict :** VALIDÉ SOUS RÉSERVES

## 1. Composants réutilisés

- Pictogrammes **Material Icons** déjà embarqués (`uses-material-design: true`) — aucune nouvelle dépendance d’icônes
- Emplacement UI existant des icônes de ligne (`inventory_tree_screen`, historique, sélecteurs parent)
- Fiche Créer / Modifier existante : préfixe du champ nom + bottom sheet (pas de nouvel écran Inventory)
- Types métier inchangés (`NodeType.location` / `item` / `itemContainer`)

## 2. Nouveautés strictement nécessaires

| Élément | Rôle |
|---|---|
| `InventoryIconCatalog` | Clés stables → `IconData` Material |
| `InventoryIconDictionary` + générateur `tool/gen_icon_dictionary.py` | Termes FR-QC / synonymes / expressions |
| `InventoryIconResolver` | Normalisation + priorité déterministe |
| `InventoryIconPickerSheet` | Choix / réinitialisation manuelle compacte |
| Colonne `nodes.icon_key` (schéma **14**) | Exception manuelle uniquement |

Pas d’IA, pas d’API, pas de téléchargement, pas de cache disque d’icônes, pas de bibliothèque Paramètres dédiée (hors périmètre renforcé).

## 3. Couverture annoncée (dictionnaire)

| Indicateur | Valeur |
|---|---|
| Familles thématiques couvertes | **≥ 21** (habitation, rangement, mobilier, informatique, électro, cuisine/alim., vêtements, hygiène/santé, entretien/outils, transport, jardin, sports, musique/média, livres/docs, jeux/enfants/animaux, pro/conso, …) |
| Clés d’icônes distinctes (catalogue) | **185** |
| Glyphes Material distincts référencés | **177** |
| Termes / expressions reconnus | **967** |
| Expressions multi-mots | **~200** |
| Termes avec accents (formes sources) | **~125** |
| Langues | **Français (dont variantes QC)** prioritaire ; **anglais courant** en complément |
| Variantes | Pluriels légers, accents, ponctuation, synonymes |

Le dictionnaire est **généraliste étendu**, pas limité à l’inventaire actuel ni aux seuls exemples de prompts.

## 4. Résolution

1. Exception manuelle (`icon_key`) si présente  
2. Expressions multi-mots (bonus de priorité)  
3. Jetons normalisés (synonymes)  
4. Bonus si `preferredType` correspond  
5. Sinon icône générique du type de nœud  

Ambiguïtés traitées sans probabilités : ex. « Bureau » (lieu) → `business` ; « Bureau meuble » (bien) → `desk`. « Boîte à outils » privilégie l’expression spécifique face à « boîte ».

## 5. Exemples de correspondances

| Nom | Type | Icône attendue | Statut |
|---|---|---|---|
| Salon | lieu | `living` | Vérifié (logique) |
| Salle de bain | lieu | `bathroom` | Vérifié |
| Ordinateur portable | bien | `laptop` | Vérifié + créé sur émulateur |
| Écran Dell | bien | `monitor` | Vérifié |
| Clavier / Souris / Imprimante / Câble / Routeur | bien | distincts | Vérifié |
| Valise | contenant | `luggage` | Vérifié |
| Médicaments / Vélo électrique / Livre / Guitare | bien | famille dédiée | Vérifié |
| Nom inconnu | — | générique type | Vérifié |

## 6. Parcours observés (émulateur `Pixel_7a`)

| Parcours | Résultat |
|---|---|
| Migration schéma 13 → 14 (`icon_key`) | **Observé** (`user_version=14`) |
| Création « Ordinateur portable » | **Observé** (présent dans l’arbre) |
| Stock / À acheter non cassés au lancement | **Observé** (app au premier plan) |
| Choix manuel via fiche (préfixe nom) | **Implémenté** — non rejoué bout-en-bout UI dans cette session |
| Renommage sans `icon_key` → auto | **Implémenté** (résolution à l’affichage) |
| Exception manuelle préservée | **Implémenté** (persistée en `icon_key`) |

## 7. Impact taille application

- **Aucune** nouvelle dépendance pub  
- Icônes : police Material déjà présente  
- Dictionnaire : source Dart statique (~967 entrées)  
- Install émulateur : APK **x86_64 debug** `app-x86_64-debug.apk` (**~74 Mo**) faute d’espace pour le fat APK (~188 Mo) ; données Inventory **conservées** (`adb install -r`, pas de wipe)

## 8. Limites connues

| ID | Sévérité | Détail |
|---|---|---|
| R1 | P2 | Couverture large mais non exhaustive ; objets rares → générique |
| R2 | P2 | Pluriels FR approximatifs (garde-fous `is/us/as/…`) |
| R3 | P2 | Bibliothèque Paramètres / associations globales du plan V2 non livrées (volontairement, directive renforcée) |
| R4 | P2 | Validation visuelle systématique de chaque famille non effectuée ; échantillon ciblé seulement |

## 9. Verdict

**VALIDÉ SOUS RÉSERVES** — dictionnaire local étendu + catalogue Material diversifié, résolution déterministe, exception manuelle minimale, UI de ligne préservée, migration v14 OK sur émulateur.

**STOP** — ne pas démarrer M5.2.
