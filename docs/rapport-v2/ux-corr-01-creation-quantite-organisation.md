# UX-CORR-01 — Création, quantité Stock et organisation

**Date :** 22 novembre 2026  
**Appareil de validation :** Pixel_7a (`emulator-5554`)  
**Motorola (`ZT322P23HJ`) :** non installé (hors périmètre de ce mandat)  
**APK :** `build/app/outputs/flutter-apk/app-debug.apk` (install `-r`, données conservées)  
**Verdict :** **VALIDÉ SOUS RÉSERVES**

---

## Synthèse

Quatre corrections ciblées appliquées sans refonte ni changement de schéma SQLite / `.invbackup`.

| # | Correction | État observé (émulateur) |
|---|---|---|
| 1 | Sélecteur Stock sans « Bien contenant » | Observé : Emplacement + Produit uniquement |
| 2 | Focus auto Nom à la création | Observé : clavier IME affiché dès l’ouverture du formulaire |
| 3 | Stock − / niveau / + (quarts) | Observé : arbre + formulaire ; 1 → ½ via − |
| 4 | Organiser : réordonner frères | Observé : Monter sur ligne ; ordre persisté en SQLite |

---

## 1. Stock — Choix de création

### Comportement initial
Le sélecteur Stock proposait Emplacement, Bien/Produit et **Bien contenant**, alors que le contenant est déjà géré dans le parcours Biens (bascule).

### Cause
`_creatableTypesFor` renvoyait `location + item + itemContainer` pour tout espace autre que Biens.

### Correction
Alignement sur Biens : `location` + `item` pour tous les espaces. Contenant Biens inchangé (switch formulaire). Modèle de données inchangé.

### Fichiers
- `lib/app/main_navigation_screen.dart`

### Observé (Pixel_7a)
Sélecteur Stock : **Emplacement** + **Produit** uniquement ; pas d’entrée « Bien contenant ».

### Régressions / réserves
Aucune. La capacité contenant reste dans Biens.

---

## 2. Création — Focus automatique sur le nom

### Comportement initial
Après choix du type, le champ Nom n’était pas focalisé ; second toucher requis.

### Cause
`TextFormField` Nom sans `FocusNode` / `autofocus` en création.

### Correction
- `FocusNode` + `autofocus: !_isEdit`
- `requestFocus` post-frame quand le formulaire de **création** est prêt (`_ready`)
- Pas de focus forcé en modification

### Fichiers
- `lib/app/inventory_creation_screen.dart`

### Observé (Pixel_7a)
À l’ouverture Nouveau produit / Nouveau bien / Nouvel article à acheter : **IME affiché** (`mInputShown=true`) sans second tap sur le champ.

### Régressions / réserves
- L’injection `adb input text` ne reflète pas toujours le contenu Flutter ; le critère retenu est l’apparition du clavier.
- Non rejoué manuellement au doigt sur appareil physique.

---

## 3. Stock — Contrôle de quantité − / +

### Comportement initial
Niveau Stock cyclé via pastille unique sur l’arbre ; pas de contrôle −/+ type Biens.

### Cause
UI limitée à `cycleStockLevel` ; pas d’exposition de `setStockLevel` côté contrôleur UI.

### Correction
- `InventoryStockLevelStepper` (réutilise le chrome `_StepButton` / mode compact)
- Pas de quarts : full → half → quarter → empty
- Formulaire Stock : « Niveau restant » + stepper ; en édition, `setStockLevel` immédiat (historique mouvements)
- Arbre Stock : pastille remplacée par − / glyphe / +
- `InventoryTreeController.setStockLevel` branché sur le moteur existant
- Référence conceptuelle (`stockReference`) conservée ; pas de second système d’unités

### Fichiers
- `lib/app/inventory_ui.dart`
- `lib/app/inventory_creation_screen.dart`
- `lib/app/inventory_tree_screen.dart`
- `lib/app/inventory_tree_controller.dart`
- `lib/app/app_strings.dart` (`stockRemainingLevel`)

### Observé (Pixel_7a)
- Arbre : Farine affiche **Diminuer / 1 / Augmenter** ; un tap − passe à **½**.
- Formulaire création produit : **Niveau restant** + stepper visibles.

### Régressions / réserves
Historique des mouvements non rouvert dans l’UI pour ce mandat (mécanisme moteur `setStockLevel` déjà journalisé). Glisser-déposer Stock non rejoué.

---

## 4. Organiser — Réordonner dans la même liste

### Comportement initial
Changement de parent possible ; réordonnancement frères peu découvrable (Monter/Descendre seulement après ouverture des détails).

### Cause
Commandes Monter/Descendre présentes uniquement dans la sous-ligne `infoOpen`, pas sur la ligne principale du mode Organiser.

### Correction
En mode Organiser, **Monter / Descendre** affichés sur la ligne principale (sans expansion préalable). Moteur `moveSibling` / `placeSiblingBefore` / DnD Organiser inchangés.

### Fichiers
- `lib/app/inventory_tree_screen.dart`

### Observé (Pixel_7a)
Sous Salonn (Biens), ordre initial :

`DocTestM42B` → `Lampem` → `Ordinateur portable`

Après deux **Monter** sur Ordinateur :

`Ordinateur portable` → `DocTestM42B` → `Lampem`

Persistance SQLite (`sibling_order`) et après Terminer / réouverture Organiser : **identique**.

Stock : flèches Monter/Descendre visibles en Organiser (Cellier / Farine).

### Régressions / réserves
- Critère A/B/C rejoué sur **Biens** (trois frères déjà présents) ; Stock n’avait qu’un produit sous Cellier au moment du test.
- Geste DnD tactile frère non rejoué au doigt (mécanisme déjà branché en Organiser).

---

## Preuves techniques

| Preuve | Résultat |
|---|---|
| `flutter analyze` (fichiers touchés) | Aucun problème |
| `flutter build apk --debug` | OK |
| `adb -s emulator-5554 install -r` | Success |
| UI Automator / dumps | `build/ux-corr-01/` (`final_obs.json`, dumps) |
| Focus app en fin de mandat | Inventory au premier plan, onglet Stock |

## Hors périmètre respecté

- Pas d’install Motorola  
- Pas de commit / push  
- Pas de M5.3-C  
- Pas de nouveau schéma SQLite / `.invbackup`  
- Pas d’enrichissement dictionnaire d’icônes  

---

## Verdict

**VALIDÉ SOUS RÉSERVES**

Corrections 1–4 fonctionnelles sur Pixel_7a. Réserves : confirmation tactile physique (focus / DnD), historique Stock non rouvert visuellement, réordonnancement A/B/C démontré sur Biens plutôt que Stock (jeu de données).

**STOP** — en attente du retour utilisateur.
