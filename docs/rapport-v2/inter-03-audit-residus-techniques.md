# INTER-03 — Audit final des doublons, du code mort et des résidus techniques

**Date :** 25 novembre 2026  
**Nature :** analyse statique et documentaire exclusive  
**Code modifié :** aucun  
**Verdict :** **NETTOYAGE CIBLÉ RECOMMANDÉ**

---

## 1. Résumé exécutif

Inventory V2 ne présente **pas** d’incohérence structurelle majeure ni de double moteur concurrent actif pour les parcours validés. Les responsabilités centrales (fiche unique, arbre + DnD appui long, médias, backup, moteur Drift) ont une **source de vérité claire**.

Les itérations UX ont toutefois laissé un **petit ensemble démontré de résidus** :

- 2 écrans/contrôleurs de diagnostic orphelins ;
- 1 widget de section avancée remplacé mais encore présent ;
- 1 bannière de valorisation + chaînes associées inutilisées ;
- quelques API contrôleur héritées du mode Organiser / sélecteur « Déplacer vers… » ;
- un bloc d’aide in-app décrivant encore l’ancien cycle d’expansion ;
- le plan directeur V2 qui présente encore le mode Organiser comme référence.

Ces éléments **ne modifient pas le comportement actuel** s’ils restent en place, mais ils **augmentent le risque de réutilisation accidentelle** lors de V3. Un nettoyage **fermé et non comportemental** est justifié ; aucune refonte n’est nécessaire.

Le gel fonctionnel V2 est compatible avec ce constat : le nettoyage, s’il est autorisé, doit se limiter à la liste §7.

---

## 2. Périmètre réellement inspecté

| Zone | Couverture |
|---|---|
| `lib/app/*` (écrans, formulaires, arbre, aide) | Complet |
| `lib/core/domain/*`, `lib/core/media/*`, `lib/core/backup/*`, `lib/core/icons/*` | Complet (références) |
| `lib/core/database/*` | Migrations / tables historiques (préservation) |
| `pubspec.yaml` dépendances | Complet |
| Chaînes `AppStrings` | Scan références externes |
| Points d’entrée `main.dart` / navigation | Complet |
| Tests `test/` (consommateurs) | Scan références |
| Plan `docs/Inventory-v2.md` + rapports UX-CORR/ARB | Contradictions documentaires |
| Rapports historiques V1/V2 | Conservés comme traces (non candidats à suppression) |

Hors périmètre d’exécution : compilation, install, refactor, suppression réelle.

---

## 3. Méthodes et preuves utilisées

1. `dart analyze lib` (non modificateur) — 1 alerte locale `unnecessary_null_comparison` dans `inventory_tree_screen.dart` (hors objet mort).
2. Recherche ripgrep des symboles issus des rapports de remplacement (Organiser, expansion, section avancée, FAB, Align bottom).
3. Inventaire des types `lib/**/*.dart` sans référence externe (hors générés Drift).
4. Scan des membres `AppStrings` sans `AppStrings.<nom>` hors fichier de définition.
5. Croisement avec `docs/rapport-v2/ux-corr-04-fiche-biens-unifiee.md`, UX-CORR-02-R2, INTER-02, plan directeur.

Les typedefs internes backup, classes `_Private` et enums utilisés uniquement dans leur fichier ne sont **pas** traités comme code mort.

---

## 4. Inventaire des constats significatifs

### R-01 — Écran diagnostic orphelin

| Champ | Contenu |
|---|---|
| Identifiant | R-01 |
| Fichiers / symboles | `lib/app/persistence_check_screen.dart` (`PersistenceCheckScreen`) ; `lib/app/persistence_check_controller.dart` (`PersistenceCheckController`) |
| Responsabilité initiale | Diagnostic DEV de persistance SQLite |
| Responsabilité actuelle | Aucune — non branché navigation / Paramètres / tests |
| Consommateurs | **Aucun** hors leurs fichiers (confirmé V1 PR-07 ; inchangé) |
| Référence actuelle | Aucune — hors produit |
| Preuve | Grep dépôt : seules définitions ; aucun import |
| Conservation | Confusion possible si réactivé par erreur |
| Risque suppression | Nul pour les parcours validés |
| Classification | **A — Suppression justifiée** |
| Recommandation | Supprimer les deux fichiers lors d’un mandat de nettoyage autorisé |

### R-02 — Section avancée remplacée, fichier conservé

| Champ | Contenu |
|---|---|
| Identifiant | R-02 |
| Fichier / symbole | `lib/app/inventory_advanced_section.dart` (`InventoryAdvancedSection`) |
| Responsabilité initiale | Bloc repliable « Informations avancées » (M4.1) |
| Responsabilité actuelle | Champs avancés / médias **inline** dans `InventoryCreationScreen` (UX-CORR-04) |
| Consommateurs | **Aucun** import Dart |
| Référence | `inventory_creation_screen.dart` |
| Preuve | UX-CORR-04 : « fichier conservé, plus référencé » ; scan orphelin |
| Conservation | Risque de réintroduire un second layout de fiche |
| Risque suppression | Nul si champs déjà dans la fiche unifiée |
| Classification | **A** |
| Recommandation | Supprimer le fichier |

### R-03 — Bannière valorisation inutilisée

| Champ | Contenu |
|---|---|
| Identifiant | R-03 |
| Fichier / symbole | `InventoryValuationBanner` (`inventory_ui.dart`) ; `AppStrings.valuationChangeNotice` |
| Responsabilité initiale | Notice visuelle de changement de mode de valorisation |
| Actuelle | Non affichée ; `InventoryValuationField` + roulette partagée |
| Consommateurs | Aucun |
| Classification | **A** |
| Recommandation | Retirer la classe et la chaîne associée |

### R-04 — API Organiser / déplacement menu sans consommateur UI

| Champ | Contenu |
|---|---|
| Identifiant | R-04 |
| Fichier | `lib/app/inventory_tree_controller.dart` |
| Symboles | `moveSibling`, `listSiblings`, `relocateNode`, `isSameParentDrop` |
| Responsabilité initiale | Monter/Descendre, liste destinations, relocation indexée (mode Organiser / « Déplacer vers… ») |
| Actuelle | DnD : `resolveOrganizeDrop` + `placeSiblingBefore/After` + `moveNode` (arbre) |
| Consommateurs | **Aucun** hors définitions (tests inclus) |
| Note | `canAcceptReorder` / `reorderSiblings` / `placeSibling*` / `moveNode` **restent vivants** |
| Classification | **A** (méthodes mortes) |
| Recommandation | Supprimer uniquement les quatre symboles listés ; **ne pas** toucher au DnD vivant |

### R-05 — Chaînes UI du sélecteur de destination obsolète

| Champ | Contenu |
|---|---|
| Identifiant | R-05 |
| Fichier | `lib/app/app_strings.dart` |
| Symboles (ex.) | `chooseDestination`, `moveHere`, `confirmMove`, `noMoveDestinations`, `noChildDestinations`, `currentDestination`, `moveTo`, `moveWithContents`, … |
| Preuve | Aucune référence `AppStrings.<…>` hors fichier |
| Contexte | UI « Déplacer vers… » retirée avec le mode Organiser (UX-CORR-02-R2) |
| Classification | **A** (chaînes) — attention : `moveSuccess` / `moveError` / `invalidDestination` / `cyclicDestination` **encore utilisées** par le DnD |
| Recommandation | Purge ciblée des chaînes **sans** référence ; conserver les messages d’erreur DnD |

### R-06 — Aide in-app : ancien cycle d’expansion

| Champ | Contenu |
|---|---|
| Identifiant | R-06 |
| Symbole | `AppStrings.helpBrowseBody` |
| Texte actuel | Décrit un cycle « contenu → résumé → retour » au toucher de ligne |
| Réalité produit | UX-ARB-02 : expansions enfants et détails **indépendantes** ; chevron ≠ ligne pour contenants |
| `helpMoveBody` | **À jour** (appui long / glisser) |
| Classification | **B — Doublon / ambiguïté documentaire produit** (aide vs comportement) |
| Recommandation | Réécrire `helpBrowseBody` (et au besoin `helpIntro`) pour coller au comportement gelé — **sans** changer le code métier |

### R-07 — Plan directeur : mode Organiser encore normatif

| Champ | Contenu |
|---|---|
| Identifiant | R-07 |
| Document | `docs/Inventory-v2.md` (D09, § Organiser, critère réception §15.8, §18 phases) |
| Réalité | Mode menu Organiser **supprimé** ; DnD unique (UX-CORR-02-R2) ; phases M2–M5 faites (INTER-02) |
| Classification | **B** (gouvernance) — pas du code mort |
| Recommandation | Mettre à jour le plan **lors du mandat livraison / clôture doc** ; **ne pas** supprimer les rapports historiques |

### R-08 — Enum `NeedStatus` sans consommateur

| Champ | Contenu |
|---|---|
| Identifiant | R-08 |
| Fichier | `lib/core/domain/purchase_models.dart` |
| Preuve | Aucune référence hors définition ; les besoins utilisent `NodeStatus` |
| Classification | **D — Ambigu** (peut servir de doc métier / futur) |
| Recommandation | **Conserver** sauf preuve d’innocuité renforcée ; ne pas prioriser |

### R-09 — Tables / payload `categories` (backup & Drift)

| Champ | Contenu |
|---|---|
| Identifiant | R-09 |
| Zone | Migrations + snapshot backup |
| Classification | **C — Historique nécessaire** |
| Recommandation | **Préserver** (compatibilité formats / migrations) |

### R-10 — Dépendances pubspec

| Champ | Contenu |
|---|---|
| Identifiant | R-10 |
| Constat | `crypto`, `file_picker`, `image_picker`, `flutter_image_compress`, `open_filex`, `package_info_plus`, Drift, path* — **toutes référencées** |
| Classification | Pas de constat A |
| Recommandation | Aucune suppression de dépendance |

### R-11 — Variantes Biens / Stock / À acheter (non-doublons)

| Champ | Contenu |
|---|---|
| Identifiant | R-11 |
| Exemples | `InventoryQuantityStepper` vs `InventoryStockLevelStepper` ; `GoodsPhotoStore` vs `AndroidDocumentStore` (SAF) ; écrans d’historique distincts |
| Classification | Variantes légitimes — **E** si mutualisation speculative |
| Recommandation | **Ne pas** mutualiser avant V3 |

### R-12 — Thème FAB sans FAB

| Champ | Contenu |
|---|---|
| Identifiant | R-12 |
| Symbole | `floatingActionButtonTheme` dans `app_theme.dart` |
| Classification | **E** |
| Recommandation | Reporter ; inoffensif |

---

## 5. Composants de référence (sources de vérité)

| Responsabilité | Référence actuelle |
|---|---|
| Navigation 3 espaces | `MainNavigationScreen` |
| Arbre / expansion / DnD | `InventoryTreeScreen` + `InventoryTreeController` (`resolveOrganizeDrop`, `placeSibling*`, `moveNode`, `_infoOpenIds` / `_expanded`) |
| Création / édition | `InventoryCreationScreen` (fiche unifiée) |
| Parent / position | `InventoryParentField` + `InventoryCompactRoulette` |
| Valorisation | `InventoryValuationField` + roulette partagée |
| Quantité Biens / besoin | `InventoryQuantityStepper` |
| Niveau Stock | `InventoryStockLevelStepper` + cycle arbre |
| Médias biens | `GoodsMainPhotoField` / `GoodsDocumentsField` + `GoodsPhotoStore` / `GoodsDocumentStore` |
| Acquisition | `PurchaseAcquireScreen` |
| Sauvegarde | `BackupExporter` / `BackupRestorer` / `RestorationRecovery` + contrôleurs Paramètres |
| Règles métier | `InventoryEngine` |
| Persistance | `InventoryDatabase` (schéma 15) |
| Chaînes UI | `AppStrings` |
| Icônes | `InventoryIconResolver` + picker sheet |

Toute réintroduction d’un second formulaire avancé, d’un mode Organiser parallèle ou d’un Align bottom permanent serait une **régression de gouvernance**, pas une évolution.

---

## 6. Éléments historiques à préserver (**C**)

- Migrations Drift et tables/colonnes héritées (`categories` / `node_categories`, journal restauration, etc.).
- Import `.invbackup` format 1 / data schema 1–2.
- `RestorationRecovery` et statut `db_ready`.
- Code généré `inventory_database.g.dart`.
- `MainActivity` / Manifest / permissions caméra.
- Stores médias et canaux SAF Android.
- Tests historiques encore compilables / pertinents.
- Rapports `docs/rapport-v1/*` et `docs/rapport-v2/*` (traces).
- Keystore / `key.properties` (hors git) pour distribution.

---

## 7. Liste fermée des suppressions / clarifications recommandées

**Uniquement si mandat de nettoyage explicitement autorisé.** Aucune exécution dans INTER-03.

### 7.1 Suppressions code (comportement inchangé attendu)

1. `lib/app/persistence_check_screen.dart`
2. `lib/app/persistence_check_controller.dart`
3. `lib/app/inventory_advanced_section.dart`
4. Classe `InventoryValuationBanner` dans `inventory_ui.dart`
5. Méthodes mortes du contrôleur : `moveSibling`, `listSiblings`, `relocateNode`, `isSameParentDrop`
6. Chaînes `AppStrings` sans référence listées en R-05 (exclure messages DnD encore utilisés)
7. `AppStrings.valuationChangeNotice`

### 7.2 Clarifications sans suppression de logique métier

8. Réécriture de `helpBrowseBody` (R-06)  
9. Mise à jour documentaire `docs/Inventory-v2.md` (R-07) — mandat livraison / clôture doc

### 7.3 Explicitement hors liste

- Aucune mutualisation Stock/Biens  
- Aucun renommage massif  
- Aucune suppression de migrations / backup V1  
- Aucune modification DnD / fiche / médias  
- `NeedStatus` (R-08)  
- Thème FAB (R-12)

---

## 8. Risques associés aux interventions

| Intervention | Risque | Mitigation |
|---|---|---|
| Suppression R-01…R-05 | Faible (aucun consommateur trouvé) | Grep final + `dart analyze` avant commit |
| Purge chaînes | Moyen-faible (faux négatif scan) | Ne retirer que les constantes sans `AppStrings.x` ; garder groupe `move*Error/Success` |
| Aide R-06 | Nul sur données ; impact texte utilisateur | Relecture utilisateur courte |
| Plan R-07 | Nul runtime | Diff doc seul |
| Toucher au DnD / engine | **Élevé** | Interdit dans ce nettoyage |

Le nettoyage **n’est pas un prérequis bloquant** de la livraison APK signée (INTER-02 L-01/L-02). Il réduit surtout la dette de confusion pour V3.

---

## 9. Recommandation concernant la clôture V2

1. **Maintenir le gel fonctionnel** (comportements Biens / Stock / À acheter).  
2. Traiter le nettoyage §7 comme **mandat optionnel, borné, non comportemental**, idéalement **après** ou **en parallèle doc** de la préparation livraison — pas comme phase de perfectionnement produit.  
3. Mettre à jour le plan directeur (Organiser → DnD ; statut des phases) pour éviter qu’un superviseur sans accès dépôt croie l’ancien mode encore requis.  
4. **Ne pas** ouvrir d’audit architectural élargi.

---

## Verdict

**NETTOYAGE CIBLÉ RECOMMANDÉ**

Périmètre = liste fermée §7 (résidus démontrés).  
Absence d’incohérence structurelle à arbitrer.  
Absence de nettoyage « nécessaire à la survie » de V2 ; présence d’un nettoyage **utile à la maintenabilité** avant de figer V2 comme base future.

---

**STOP** — rapport livré. Aucune intervention sans autorisation explicite.
