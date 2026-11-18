# Rapport Phase 0 — Audit V1 et spécification technique préliminaire V2

| Champ | Valeur |
| --- | --- |
| Date | 17 novembre 2026 |
| Mandat | Inventory V2 — Phase 0 (analyse uniquement) |
| Application inspectée | Inventory V1 (`pubspec.yaml` version `1.0.15+16`) |
| Verdict | **VALIDÉ SOUS RÉSERVES** |
| Périmètre | Lecture du dépôt + rédaction de ce rapport ; aucune modification de code, schéma, données, APK ou appareil |

---

## 1. Résumé exécutif et verdict

Inventory V1 est une application Flutter/Android locale, structurée autour d’un moteur unique (`InventoryEngine`) et d’une table `nodes` Drift/SQLite (`schemaVersion = 4`). Les parcours Biens (hiérarchie, valorisation, création/modification, déplacement long-press, recherche, retrait, historique minimal, sauvegarde `.invbackup`) sont implémentés et réutilisables.

La trajectoire V2 est réalisable **par extension ciblée**, sans refonte générale :

- introduire un **espace d’appartenance** (`goods` / `stock` / `to_buy`) sur les nœuds ;
- assouplir ou spécialiser les règles de **quantité** (aujourd’hui `>= 1` en CHECK SQL et dans le domaine) pour Stock ;
- ajouter des tables d’**événements** (mouvements Stock, acquisitions) ;
- ajouter un **ordre manuel** persistant ;
- prolonger le formulaire existant pour les fiches avancées et les médias hors BLOB ;
- étendre `.invbackup` (médias + schéma versionné) tout en important les sauvegardes V1.

**Verdict : VALIDÉ SOUS RÉSERVES.**  
Validation = plan technique et réutilisation V1 suffisamment établis pour autoriser la Phase 1 après arbitrages produit listés en §15. Ce n’est **pas** une validation de l’application V2 (inexistante).

**Réserves principales :** décisions produit ouvertes (unités, fusion Stock, ordre UX, documents) ; absences V1 structurelles (pas d’ordre manuel, pas de journal d’événements, pas de médias, pas de préférences persistantes, pas de navigation multi-espace).

---

## 2. Références documentaires consultées

| Document | Statut |
| --- | --- |
| `docs/Inventory-v2.md` | **Source produit V2 utilisée** (contenu du plan directeur ; date 16 nov. 2026) |
| `docs/plan/INVENTORY_V2_PLAN_DIRECTEUR.md` | **Absent** — dossier `docs/plan/` inexistant |
| `docs/03-technical-architecture.md` | Consulté (partiellement obsolète vs code : Riverpod/go_router absents du `pubspec.yaml`) |
| `docs/04-data-domain-model.md` | Non relu intégralement ; schéma réel lu dans le code Drift |
| `docs/09-backup-recovery.md` | Référencé par le code backup ; contrat réel lu dans `lib/core/backup/` |
| Rapports V1 sous `docs/rapport-v1/` | Convention de nommage observée |

**Emplacement du présent rapport :** `docs/rapport-v2/` (convention observée : `rapport-v1` / `rapport-v2`). Le mandat mentionnait `docs/rapport/`, dossier désormais inexistant après réorganisation.

---

## 3. État réel de l’architecture V1

### 3.1 Organisation Flutter

```
lib/
  main.dart                         → InventoryDatabase + InventoryApp
  app/                              → UI (écrans, contrôleurs ChangeNotifier, thème, strings)
  core/
    database/inventory_database.dart (+ .g.dart)
    domain/                         → InventoryEngine, modèles, exceptions, UUID, noms
    backup/                         → .invbackup encode/decode/export/restore
android/                            → minSdk 24, targetSdk 36, applicationId io.github.cometom3.inventory
```

- **État UI :** `ChangeNotifier` (`InventoryTreeController`, contrôleurs recherche/historique/backup) — pas de Riverpod.
- **Navigation :** `MaterialPageRoute` / `Navigator` — pas de go_router.
- **Persistance :** Drift + SQLite via `drift_flutter`, répertoire `getApplicationSupportDirectory`.
- **Dépendances runtime :** `drift`, `drift_flutter`, `path_provider`, `crypto`, `package_info_plus`, `flutter_localizations`. **Aucune** bibliothèque image, caméra, `shared_preferences`, réseau.

### 3.2 Navigation et écrans

| Chemin | Classe | Rôle actuel |
| --- | --- | --- |
| `lib/app/main_navigation_screen.dart` | `MainNavigationScreen` | Coque unique : arbre + FAB + recherche / menu (Historique, Aide, Paramètres) |
| `lib/app/inventory_tree_screen.dart` | `InventoryTreeScreen` | Arbre, cycle d’expansion, DnD long-press (changement de parent) |
| `lib/app/inventory_creation_screen.dart` | `InventoryCreationScreen` | Création **et** modification (même écran) |
| `lib/app/inventory_inline_sheet.dart` | `InventoryInlineSheet` | Sous-ligne compacte + bouton Modifier |
| `lib/app/inventory_search_screen.dart` | `InventorySearchScreen` | Recherche (nom, type, branche) |
| `lib/app/inventory_history_screen.dart` | `InventoryHistoryScreen` | Liste des biens retirés |
| `lib/app/withdrawn_node_details_screen.dart` | `WithdrawnNodeDetailsScreen` | Détail d’un bien retiré |
| `lib/app/settings_screen.dart` | `SettingsScreen` | Aide, À propos, export/restauration |
| `lib/app/help_screen.dart` / `about_screen.dart` | — | Contenu statique |

**Pas de barre de navigation inférieure multi-espace.** Une seule hiérarchie d’inventaire.

### 3.3 Domaine et règles

`InventoryEngine` est le **seul point d’écriture** métier ; chaque opération publique s’exécute dans `_db.transaction`.

Types officiels (`NodeType`) : `location`, `item`, `item_container`.  
Statuts : `active`, `withdrawn`.  
Retrait : `loss` / `donation` / `breakage` / `sale` (bien sans enfants, `parent_id` nullifié).  
Valorisation exclusive : financière (cents CAD unitaires) ou sentimentale (1–5), ou absente.  
Agrégation sous-arbre : CTE récursive dans `getSubtreeFinancialTotals` (sans double comptage sentimental).  
Quantité item : **entier ≥ 1** (`_validateQuantity` + CHECK SQL).  
Ordre d’affichage frères : biens (simple + contenant) puis emplacements, puis nom (`_byTreeDisplay`) — **pas d’ordre manuel**.

### 3.4 Historique et préférences

- **Historique = nœuds `withdrawn`**, pas de table d’événements générique.
- **Aucune préférence utilisateur persistante** (pas de SharedPreferences, pas de table settings) : Paramètres = sauvegarde + liens Aide/À propos.
- Colonnes `description` et tables `categories` / `node_categories` : encore dans le schéma et le backup, mais **vidées / abandonnées** depuis migration V4 (DEV-17).

### 3.5 Comportements démontrés par le code vs NON VÉRIFIÉ manuellement

| Comportement | Preuve code | Validation manuelle Phase 0 |
| --- | --- | --- |
| Cycle expansion contenant : enfants → info → garder enfants → fermer | `_cycleExpand` / `_RowPhase` | NON VÉRIFIÉ (interdit d’émuler) |
| Item sans enfants : info ↔ fermé | idem | NON VÉRIFIÉ |
| Long-press → drop change `parent_id` uniquement | `_commitMove` → `moveNode` | NON VÉRIFIÉ |
| Restauration journalisée pending/committed | `BackupRestorer` | NON VÉRIFIÉ sur appareil |
| Performance Moto G24 Power | — | NON VÉRIFIÉ (appareil non utilisé) |

---

## 4. Cartographie des fichiers, classes et tables

### 4.1 Tables Drift (`InventoryDatabase`, `schemaVersion = 4`)

| Table | Responsabilité | Réutilisation V2 |
| --- | --- | --- |
| `inventories` | Singleton inventaire local | Conserver ; identité V1 préservée |
| `nodes` | Hiérarchie + valorisation + statut | **Noyau** — étendre (espace, ordre, champs avancés, quantité Stock) |
| `categories` / `node_categories` | Legacy abandonné | Conserver pour backup V1 ; ne pas réactiver sans décision |
| `local_verification_entries` | Vérif. locale diagnostic | Conserver |
| `restoration_journal_entries` | Journal restauration (non exporté) | Conserver / étendre pour médias |

### 4.2 Colonnes `nodes` actuelles (extrait)

`id`, `inventory_id`, `parent_id`, `name`, `node_type`, `quantity`, `description`, `condition`, `value_mode`, `financial_value_cents`, `sentimental_value`, `status`, `withdrawal_reason`, `withdrawn_at`, `created_at`, `updated_at`.

**Absents V2 :** `space`, `sort_index` / `display_order`, `unit`, `unit_cost`, `barcode`, `objective`, `show_advanced`, `photo_media_id`, `document_media_id`, etc.

### 4.3 Couche backup

| Chemin | Classe | Rôle |
| --- | --- | --- |
| `backup_contract.dart` | constantes + `BackupSnapshot` | `format_version=1`, `data_schema_version=1`, extension `.invbackup` |
| `backup_codec.dart` | `BackupCodec` | Magic `INVENTORY-BACKUP` + header JSON + payload JSON + SHA-256 |
| `backup_snapshot_reader.dart` | `BackupSnapshotReader` | Snapshot DB → maps |
| `backup_exporter.dart` | `BackupExporter` | Export SAF via temp vérifié |
| `backup_restorer.dart` | `BackupRestorer` | Validate temp DB → journal → replace → verify |
| `backup_candidate.dart` | `BackupCandidate` | Validation hors base active |
| `android_document_store.dart` | `AndroidDocumentStore` | Channel SAF `io.github.cometom3.inventory/documents` |

Payload actuel : `inventory` + `nodes` + `categories` + `node_categories` — **aucun fichier média**. Limite `backupMaxFileBytes = 32 MiB`.

### 4.4 Icônes

`inventoryNodeIcon(NodeType)` dans `inventory_ui.dart` : icône **par type uniquement** (`apartment_outlined` / `view_in_ar_outlined` / `luggage_outlined`). Pas d’attribution par titre, pas de bibliothèque Paramètres.

---

## 5. Fonctionnalités directement réutilisables

| Capacité V1 | Composants | Adaptation V2 |
| --- | --- | --- |
| Moteur hiérarchie + anti-cycles | `InventoryEngine._requireValidParent`, `_validatedChain` | Filtrer / contraindre par `space` |
| CRUD + conversion item/item_container | `createNode`, `updateAndOptionallyMove`, `convertItemKind` | Paramétrer règles par espace |
| Valorisation Biens + totaux sous-arbre | modèles + CTE | Réserver à l’espace Biens |
| Quantité entière Biens (≥ 1) | `_validateQuantity` + CHECK | Conserver pour Biens ; autre règle Stock |
| Arbre + expansion progressive | `InventoryTreeScreen`, `InventoryTreeController` | Instancier / filtrer par espace |
| Formulaire création/édition | `InventoryCreationScreen` | Section avancée repliable ; champs Stock/À acheter |
| DnD changement de parent | `LongPressDraggable` + `moveNode` | Conserver pour déplacement ; séparer réordonnancement |
| Recherche contextuelle | `searchNodes` + écrans | Scoper par espace (pas de recherche globale noyau) |
| Retrait + historique Biens | `withdrawItem`, `getWithdrawnItems` | Espace Biens ; historiques Stock/achat séparés |
| Backup/restore transactionnel | stack `lib/core/backup/` | Versionner schéma ; ajouter médias ; importer V1 |
| SHA-256 déjà présent | package `crypto` | Réutiliser pour médias et manifeste V2 |
| SAF documents | `AndroidDocumentStore` | Réutiliser pour `.invbackup` ; médias = stockage privé app |

---

## 6. Modifications techniques V2 nécessaires

### 6.1 Trois espaces

**Proposition (RECOMMANDÉ, alignée plan) :**

1. Colonne `nodes.space` TEXT NOT NULL, valeurs `goods` | `stock` | `to_buy`.
2. Migration : toutes les lignes V1 → `goods` ; IDs et `parent_id` inchangés.
3. Contrainte d’intégrité : parent et enfant même `space` (CHECK applicatif + éventuellement trigger/CHECK composite si faisable en SQLite).
4. Racines : `getRootLocations` filtré par espace actif.
5. UI : `NavigationBar` à 3 destinations ; chaque onglet réutilise `InventoryTreeController`/`InventoryTreeScreen` avec `space` injecté ; états d’expansion **indépendants** par espace (plan RECOMMANDÉ).
6. Recherche / création / historique : contextuels à l’espace courant.

**Ne pas** créer trois moteurs ni trois tables hiérarchiques parallèles tant que les règles parentales restent proches.

### 6.2 Navigation proposée (extension, pas reconstruction)

```
MainNavigationScreen
  └─ NavigationBar [Biens | Stock | À acheter]
       └─ InventoryTreeScreen(space: …)   // réutilisation
  AppBar actions : Recherche (espace courant), menu → Historique (espace), Aide, Paramètres
  FAB : création typée selon l’espace
```

Paramètres / Aide / sauvegarde restent hors onglets (comme aujourd’hui via menu).

### 6.3 Autres blocs

| Bloc | Modification |
| --- | --- |
| Stock | Solde ≥ 0 ; unités ; coût unitaire optionnel ; table `stock_movements` ; API add/consume/correct atomiques |
| À acheter | Quantité souhaitée ; prix cible ; priorité optionnelle ; acquisition transactionnelle vers Biens/Stock |
| Ordre | Colonne `sort_index` (ou équivalent) par `(inventory_id, space, parent_id)` |
| Avancé | Préférences (global + par fiche) ; médias fichiers privés + refs SQLite |
| Icônes | Dictionnaire local + exceptions persistantes ; pas de sélecteur en création |
| Backup | `data_schema_version` ↑ ; archive multimédia ; import V1 (`format_version=1`) |

---

## 7. Proposition de modèle de données et de migration

### 7.1 Évolutions `nodes` (non destructives)

| Évolution | Détail | Compatibilité V1 | Risque |
| --- | --- | --- | --- |
| `space` | TEXT NOT NULL DEFAULT `'goods'` | V1 → Biens | Faible si défaut + backfill |
| `sort_index` | INTEGER NOT NULL DEFAULT 0 (puis backfill stable) | Ordre actuel = dérivé nom/type | Moyen si backfill incorrect |
| Assouplir `quantity` | Stock : `>= 0` ; Biens : garder `>= 1` | Exige recréation CHECK (pattern déjà utilisé en `_migrateToV4`) | **Majeur si mal testé** — même pattern table rename |
| `unit` / `unit_cost_cents` | Nullable ; pertinents Stock (et éventuellement À acheter) | NULL sur Biens | Faible |
| Champs avancés | `barcode_ref`, `objective`, `show_advanced_override`, FKs médias | NULL | Faible |
| `desired_quantity` / `target_unit_price_cents` / `priority` | Espace `to_buy` | NULL ailleurs | Faible |

**Stratégie migration :** bump `schemaVersion` (5+), `onUpgrade` additif d’abord ; toute modification de CHECK `nodes` via rename/recreate **sur copie de test** avant appareil réel (pattern V4 déjà dans le dépôt). **Aucune migration exécutée dans ce mandat.**

### 7.2 Nouvelles structures proposées

| Structure | Rôle | Contraintes |
| --- | --- | --- |
| `stock_movements` | Approvisionnement / consommation / correction | FK `node_id` ; type ; delta ; `balance_after` ; `created_at` ; écriture dans la même transaction que la MAJ solde |
| `acquisition_events` | Marquage acheté + destination | Quantités ; `dest_space` ; `dest_parent_id` ; prix réel optionnel ; lien besoin source |
| `media_assets` | Métadonnées fichiers privés | `id`, `sha256`, `rel_path`, `kind` (photo/doc), `mime`, `byte_size`, `width/height?`, `ref_count` |
| `app_preferences` (ou équivalent) | Préférence globale avancées, associations icônes | Une ligne clé/valeur ou colonnes dédiées |
| `icon_overrides` | Exception manuelle par `node_id` | Prévaut sur auto |

### 7.3 Intégrité espace

- Interdire `parent_id` pointant vers un nœud d’un autre `space` (domaine + validation backup).
- Interdire déplacement inter-espaces sauf parcours métier explicite (acquisition).
- Préservation IDs V1 : **obligatoire** pour Biens.

### 7.4 Précision numérique Stock (proposition technique — à confirmer)

- Solde et mouvements : **entier** initialement si unités discrètes ; pour g/mL, **décimal stocké en milli-unités entières** (ex. milli-grammes) **ou** `REAL` avec règles strictes — **décision produit §15**.
- Interdiction d’additionner des unités incompatibles (domaine).

---

## 8. Analyse des trois espaces

| Espace | Contenu plan | Mapping V1 | Hiérarchie | Spécificités |
| --- | --- | --- | --- | --- |
| **Biens** (`goods`) | Patrimoine V1 | Migration 1:1 | Identique V1 | Valorisation, retrait, totaux sous-arbre |
| **Stock** (`stock`) | Consommables | Vide au départ | Indépendante | Quantité ≥ 0, mouvements, coût ≠ valeur patrimoniale |
| **À acheter** (`to_buy`) | Besoins | Vide au départ | Indépendante | Prix cible ≠ payé ; acquisition explicite |

**Services partagés :** hiérarchie, recherche, formulaire de base, arbre UI, backup framing.  
**Services spécialisés :** moteur Stock (mouvements), moteur Acquisition, règles de valorisation Biens uniquement.

Homonymes entre espaces : **non liés** (DÉCIDÉ produit).

---

## 9. Stock et acquisitions

### 9.1 Stock — propositions

| Opération | Comportement technique |
| --- | --- |
| Ajouter | Transaction : `quantity += n` (n > 0) + insert `stock_movements` (type supply, delta, balance_after) |
| Consommer | Refuser si `quantity - n < 0` ; sinon MAJ + mouvement consume |
| Corriger | Remplacer solde par valeur comptée ≥ 0 ; mouvement adjust avec delta = new − old |
| Quantité 0 | **Conserver** le nœud (DÉCIDÉ) ; pas de transfert auto vers À acheter |
| Anti-doublon | Idempotence via contrainte métier (pas de retry silencieux créant 2 mouvements) ; une seule écriture dans `_run`/transaction |
| Négatif | CHECK SQL `quantity >= 0` pour Stock + garde domaine |

**Incompatibilité V1 actuelle :** CHECK `quantity >= 1` et `_validateQuantity` — **bloquant pour Stock zéro** tant que non migré (voir risques).

### 9.2 À acheter — propositions

| Étape | Règle |
| --- | --- |
| Besoin | Nom, parent même espace, quantité souhaitée > 0, prix cible optionnel, priorité optionnelle |
| Marquer acheté | Dialogue : qty acquise, destination Biens\|Stock, parent destination, prix réel optionnel |
| Atomique | Une transaction : ↓ besoin (ou delete si 0), ↑/crée destination, insert `acquisition_events` |
| Partiel | RECOMMANDÉ : ex. 10→4 achetés laisse 6 ; destination +4 |
| Fusion Stock | **Ne pas** fusionner sur titre seul ; règle à confirmer (§15) |
| Biens durable | Création nœud distinct (identité nouvelle) sauf règle produit contraire |
| Sentimentale | Si destination Biens : permettre valeur sentimentale / financière / aucune sans imposer (§15) |
| Échec | Rollback SQL ; aucun demi-transfert ; pas d’événement orphelin |

Historique : événements d’acquisition lisibles + conservation du besoin résiduel ; détail minimal à confirmer.

---

## 10. Fiches avancées et médias

### 10.1 Formulaire

Prolonger `InventoryCreationScreen` avec section **Informations avancées** repliable :

- Préférence globale « afficher avancées par défaut » (nouvelle persistance).
- Override par fiche (`show_advanced_override` nullable : null = suivre global).
- Changer le global **ne réécrit pas** les fiches existantes (RECOMMANDÉ plan).
- Masquer ≠ supprimer données.

Champs : photo principale, document/facture, code-barres/référence, objectif `none|sell|repair` (biens pertinents).

### 10.2 Architecture média (conforme plan DÉCIDÉ)

- Fichiers dans stockage privé applicatif ; SQLite = refs + métadonnées uniquement.
- Photos : WebP lossy q≈80, max 1280 px côté long, orientation corrigée, EXIF inutiles retirés.
- Import galerie : original photothèque intact ; copie optimisée interne.
- Capture caméra : **ne pas** publier en galerie ; nettoyer temporaires.
- Dédup SHA-256 (`crypto` déjà présent) + `ref_count`.
- Documents : **pas** de WebP aveugle ; PDF / types à figer après tests.
- Cache mémoire borné ; décodage hors UI isolate/`compute`.

### 10.3 Dépendances supplémentaires réellement nécessaires

| Besoin | Proposition | Justification |
| --- | --- | --- |
| Choisir image / capture | `image_picker` (ou équivalent maintenu) | Absent du dépôt |
| Encode WebP / resize | `image` (Dart) et/ou API Android native via plugin | Absent ; critique qualité/mémoire |
| Préférences simples | table SQLite `app_preferences` **de préférence** à SharedPreferences | Cohérence backup ; une source de vérité |
| Icônes Material étendues | `Icons` Flutter / évent. police icônes **hors ligne** | Pas de réseau ; auditer taille APK |

**Ne pas** ajouter de SDK cloud, ML, ni galerie multi-photo.

### 10.4 Risque mémoire Moto G24 Power (analyse statique)

- Appareil d’entrée de gamme : éviter décodage full-res sur UI thread ; borner cache (ex. N miniatures) ; traiter une image à la fois.
- Pic mémoire = décode bitmap source avant downscale → lire/réencoder en streaming ou étape native si possible.
- **NON VÉRIFIÉ** sur appareil (interdit Phase 0) — mesurer en Phase 4/5 après autorisation.

---

## 11. Réorganisation et icônes

### 11.1 Réorganisation

**État V1 :** le long-press DnD **déplace** (`parent_id`) ; l’ordre frères est **alphabétique / type**, non persistant manuellement.

**Proposition V2 :**

| Intention | Mécanisme | Persistance |
| --- | --- | --- |
| Réordonner entre frères | Mode « Organiser » (RECOMMANDÉ plan) ou poignées `ReorderableListView` borné aux enfants d’un parent | `sort_index` |
| Déplacer vers autre parent | Conserver DnD long-press actuel + règles anti-cycle / parent admissible / même espace | `parent_id` + recalcul `sort_index` cible |

Sur restauration / redémarrage : `ORDER BY sort_index, name, id`.  
Backfill initial : assigner index selon ordre `_byTreeDisplay` actuel pour non-régression visuelle Biens.

### 11.2 Icônes

- Attribution auto locale à la création (titre + type) : expressions exactes → synonymes → générique type.
- Pas de sélecteur dans le formulaire de création (DÉCIDÉ).
- Paramètres : bibliothèque, recherche, associations, exceptions, reset.
- Exception manuelle **non écrasée** par renommage.
- Aucune IA / réseau.

---

## 12. Sauvegarde et restauration

### 12.1 État V1

- Fichier texte/binaire : magic + header JSON + payload JSON ; SHA-256 payload.
- Restore : decode → validate temp DB → journal `pending` → clear/insert → `committed` → verify → ack UI.
- **Pas de médias.**

### 12.2 Adaptations V2

1. Incrémenter `data_schema_version` (et éventuellement `format_version` si framing change).
2. Payload : tables nouvelles + préférences + métadonnées médias.
3. Archive : DB cohérente **ou** payload JSON + répertoire `media/` relatif ; manifeste empreintes (SHA-256 fichiers).
4. Validation pré-activation : chemins relatifs sandboxés, empreintes, refs orphelines, tailles, formats.
5. Staging isolé (déjà : `BackupCandidate` temp DB) **étendu aux fichiers** ; bascule atomique logique (DB + swap répertoire médias) ; reprise via journal enrichi.
6. **Import V1 :** si `data_schema_version == 1` / format actuel → migrer snapshot vers modèle V2 (space=`goods`, médias absents) avant insert.
7. Export V2 **non** promis lisible par V1.
8. Revoir `backupMaxFileBytes` (32 MiB probablement insuffisant avec photos) — **décision à confirmer**.

Aucune restauration ni manipulation de sauvegarde personnelle dans ce mandat.

---

## 13. Risques P0 à P3 (avec preuves)

### P0 — Bloquant

*Aucun P0 d’impossibilité architecturale démontré.* La V2 est réalisable par extension.

| ID | Risque | Preuve / justification | Conséquence | Prévention | Phase |
| --- | --- | --- | --- | --- | --- |
| P0-1 | Migration CHECK `nodes` mal conduite (recreate table) | `_migrateToV4` recrée déjà `nodes` ; erreur = perte/corruption | Inventaire illisible | Migrations versionnées + tests sur **copie** ; jamais sur Moto sans autorisation | 1 |

### P1 — Majeur

| ID | Risque | Preuve | Conséquence | Prévention | Phase |
| --- | --- | --- | --- | --- | --- |
| P1-1 | Quantité Stock 0 impossible sans changer domaine+SQL | CHECK `quantity >= 1` ; `_validateQuantity` refuse `< 1` | Stock zéro non conforme plan | Migration CHECK par espace + règles moteur | 1–2 |
| P1-2 | Parent/enfant d’espaces différents | Aucune colonne `space` aujourd’hui | Hiérarchies incohérentes | Contrainte domaine + validation backup | 1 |
| P1-3 | Acquisition non atomique | Pas de table/parcours acquisition | Doublons / transfert partiel fantôme | Une transaction + journal événement | 2 |
| P1-4 | Mouvement Stock sans MAJ solde liée | Pas de `stock_movements` | Historique faux / solde dérivé | Écriture atomique solde+événement | 2 |
| P1-5 | Backup V2 sans médias ou import V1 cassé | Payload JSON nodes only ; `data_schema_version=1` | Perte photos / impossibilité migrer sauvegarde | Contrat versionné + tests import V1 sur copie | 5 (préparer dès 1/4) |
| P1-6 | Régression parcours Biens (expansion, DnD, valorisation) | UI dense dans `inventory_tree_screen.dart` | UX V1 cassée | Mandats bornés + validation manuelle Biens à chaque phase | 1+ |

### P2 — Modéré

| ID | Risque | Preuve | Conséquence | Prévention | Phase |
| --- | --- | --- | --- | --- | --- |
| P2-1 | Confusion DnD move vs reorder | DnD = move only | Ordre non persistant / gestes ambigus | Mode Organiser explicite | 3 |
| P2-2 | Limite 32 MiB backup | `backupMaxFileBytes` | Export échoue avec médias | Revoir limite + streaming | 5 |
| P2-3 | Taille APK bibliothèque icônes | À auditer | APK lourd | Sous-ensemble maîtrisé | 5 |
| P2-4 | Docs techniques obsolètes (Riverpod/go_router) | `03-technical-architecture.md` vs `pubspec.yaml` | Confusion agents | Ne pas suivre doc obsolète ; code = vérité | 0 (noté) |

### P3 — Facultatif

| ID | Risque | Note |
| --- | --- | --- |
| P3-1 | Tables categories legacy dans chaque backup | Bruit ; garder pour compat V1 |
| P3-2 | Optimisations CTE / perf grands arbres | Mesurer si besoin réel |
| P3-3 | Unités fractionnaires avancées | Hors noyau si pièce suffit au lancement Stock |

---

## 14. Découpage proposé en mandats

Respecte les phases 1–5 du plan. Proposition soumise à validation — **prompts d’exécution non rédigés** ; **aucun mandat lancé**.

### Phase 1 — Espaces et migration

#### M1.1 — Schéma `space` + migration Biens
- **Objectif :** Ajouter `space`, migrer V1 → `goods`, préserver IDs/parents.
- **Composants :** `inventory_database.dart`, modèles, `InventoryEngine` (filtres racines/enfants), backup reader/writer minimal.
- **Dépendances :** aucune (après Phase 0).
- **Périmètre :** pas d’UI bottom nav complète si découpé ; sinon avec M1.2.
- **Observable :** données existantes toujours en Biens après upgrade schéma (copie de test).
- **Acceptation :** IDs inchangés ; parents inchangés ; CHECK/contraintes OK ; backup V1 encore lisible ou migré.
- **Risques :** P0-1, P1-2.

#### M1.2 — Navigation trois espaces + arbre filtré
- **Objectif :** Barre inférieure Biens/Stock/À acheter ; états d’arbre indépendants.
- **Composants :** `main_navigation_screen.dart`, `InventoryTreeController` (param `space`), strings.
- **Dépendances :** M1.1.
- **Périmètre :** pas Stock mouvements / pas médias.
- **Observable :** bascule d’onglets ; Stock/À acheter vides ; Biens = V1.
- **Acceptation :** parcours Biens non régressé (création, expansion, recherche scopée).
- **Risques :** P1-6.

#### M1.3 — Recherche / historique / création scopés
- **Objectif :** Parcours secondaires respectent l’espace courant.
- **Composants :** search/history/creation + engine.
- **Dépendances :** M1.1–M1.2.
- **Observable :** recherche Stock ne liste pas Biens.
- **Acceptation :** pas de fuite inter-espace.
- **Risques :** P1-2, P1-6.

### Phase 2 — Stock et À acheter

#### M2.1 — Quantités Stock + mouvements transactionnels
- **Objectif :** add/consume/correct ; zéro conservé ; historique mouvements.
- **Composants :** schéma quantité/unité, `stock_movements`, APIs engine, UI minimale Stock.
- **Dépendances :** Phase 1.
- **Périmètre :** pas acquisition.
- **Observable :** consommer jusqu’à 0 sans disparition ; refus négatif.
- **Acceptation :** atomicité solde+événement ; pas de doublon sur retry UI.
- **Risques :** P1-1, P1-4.

#### M2.2 — Besoins À acheter + acquisition atomique (+ partiel)
- **Objectif :** prix cible ; marquer acheté vers Biens/Stock ; partiel.
- **Composants :** champs besoin, `acquisition_events`, dialogue destination, engine.
- **Dépendances :** M2.1 (si destination Stock) ; Phase 1.
- **Périmètre :** pas fusion auto titre ; pas médias.
- **Observable :** achat partiel laisse reste ; destination correcte.
- **Acceptation :** échec = aucun demi-état ; historique compréhensible.
- **Risques :** P1-3 ; décisions fusion/sentimental.

### Phase 3 — Organisation manuelle

#### M3.1 — `sort_index` + réordonnancement frères
- **Objectif :** Ordre manuel persistant par parent.
- **Composants :** DB, `getChildren` orderBy, UI Organiser ou reorder.
- **Dépendances :** Phase 1 (espace).
- **Périmètre :** pas changer règles parentales DnD existantes sauf coordination.
- **Observable :** ordre stable après kill process.
- **Acceptation :** backup/restore conserve l’ordre.
- **Risques :** P2-1.

#### M3.2 — Distinguer move vs reorder + anti-cycle
- **Objectif :** Gestes clairs ; move conserve descendants.
- **Composants :** `inventory_tree_screen.dart`, `moveNode`.
- **Dépendances :** M3.1.
- **Observable :** reorder ne change pas parent ; move change parent.
- **Acceptation :** cycles refusés ; même espace.
- **Risques :** P1-6, P2-1.

### Phase 4 — Fiches avancées et médias

#### M4.1 — Préférences avancées + champs non média
- **Objectif :** Section repliable ; barcode ; objectif ; override fiche.
- **Composants :** `InventoryCreationScreen`, préférences, schéma.
- **Dépendances :** Phase 1.
- **Périmètre :** pas photo encore si découpé.
- **Observable :** saisie simple inchangée si avancées masquées.
- **Acceptation :** masquage ne détruit pas données.
- **Risques :** faibles.

#### M4.2 — Pipeline photo WebP privé + documents
- **Objectif :** Architecture média imposée ; une photo ; document optionnel.
- **Composants :** `media_assets`, service fichiers, deps image, UI.
- **Dépendances :** M4.1.
- **Observable :** photo affichée ; absente de la galerie système (à vérifier plus tard sur device).
- **Acceptation :** échec import conserve ancienne photo ; SHA dédup.
- **Risques :** mémoire ; permissions Android — NON VÉRIFIÉ device.

### Phase 5 — Icônes, sauvegarde, stabilisation

#### M5.1 — Dictionnaire icônes + Paramètres
- **Objectif :** Auto + bibliothèque + exceptions.
- **Dépendances :** Phase 1.
- **Acceptation :** pas de sélecteur en création ; exception stable au rename.
- **Risques :** P2-3.

#### M5.2 — `.invbackup` V2 + import V1 + restauration médias
- **Objectif :** Archive complète ; restore staging ; compat V1.
- **Dépendances :** M4.2, schémas Phase 1–2.
- **Acceptation :** round-trip copie de test ; V1 import → Biens.
- **Risques :** P1-5, P2-2.

#### M5.3 — Stabilisation parcours + perf (après autorisation device)
- **Objectif :** Preuves utilisateur sur émulateur puis Moto si autorisé.
- **Dépendances :** M5.1–M5.2.
- **Acceptation :** critères §13 du plan directeur ; aucun P0/P1 ouvert.
- **Risques :** reports terrain.

---

## 15. Décisions utilisateur restant à confirmer

Issues du plan §15 + constats audit :

1. **Précision Stock** : entier seulement au lancement, ou fractions (g, mL) ? Règle de changement d’unité ?
2. **Fusion acquisition → Stock** : jamais auto / même unité+parent / confirmation utilisateur ?
3. **Besoins abandonnés** : conserver, archiver, supprimer ? Contenu minimal historique d’achat ?
4. **Transfert vers Biens** : valeur sentimentale autorisée sans financière ?
5. **Documents** : types MIME, taille max, photos de factures = doc ou photo ?
6. **Caméra / sélecteur** : stratégie exacte permissions Android 13+ ; comportement si refus.
7. **Ordre manuel UX** : mode Organiser dédié vs gesture unique ?
8. **Limite taille `.invbackup`** avec médias (remplacer 32 MiB ?).
9. **Priorité À acheter** : retenir basse/normale/haute (RECOMMANDÉ) ?
10. **Emplacement rapport** : confirmer `docs/rapport-v2/` comme norme V2 (vs ancien `docs/rapport/`).

Ces points **ne bloquent pas** le lancement de la Phase 1 (espace + migration Biens), mais doivent être tranchés avant le mandat module concerné.

---

## 16. Recommandation de lancement de la Phase 1

**Recommandation : AUTORISER la Phase 1 après validation humaine de ce rapport**, en commençant par le mandat **M1.1** (schéma `space` + migration non destructive vers Biens), puis **M1.2** (navigation trois espaces).

Conditions :

- Aucun commit/push/APK/Moto sans demande explicite.
- Travailler d’abord sur copie de base / émulateur.
- Ne pas enchaîner automatiquement Phase 2.
- Tranche préalable utile mais non bloquante : confirmation du nom de colonne/valeurs `space` (`goods`/`stock`/`to_buy`) et indépendance des états de navigation (RECOMMANDÉ plan).

---

## Annexes

### A. Invariants respectés par cette Phase 0

- Aucun fichier source modifié hors ce rapport.
- Aucune migration créée/exécutée.
- Aucun test, compile, émulateur, APK, restauration, commit, push.
- Appareil Moto G24 Power non utilisé.

### B. Écart documentation V1 vs code

`docs/03-technical-architecture.md` cite Riverpod et go_router ; le code V1 utilise `ChangeNotifier` + `Navigator`. Pour V2, **le code et `docs/Inventory-v2.md` primaires**.

### C. Verdict formalisé

**VALIDÉ SOUS RÉSERVES** — trajectoire V2 claire, réutilisation V1 dominante, migration non destructive préparable ; réserves = décisions produit §15 + risques P1 listés ; aucun obstacle architectural P0 d’impossibilité.
