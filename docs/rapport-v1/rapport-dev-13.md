# Rapport DEV-13 — Restauration et récupération sécurisée

## Verdict

**VALIDÉ SOUS RÉSERVES** : restauration complète d’un `.invbackup` DEV-12 observée sur émulateur Android, avec rejet/annulation sans altération, reprise au démarrage pour `pending`/`committed`, et exclusion Auto Backup empaquetée. Coupure physique brutale pendant le commit SQLite non reproduite ; interruptions critiques démontrées par hooks automatisés et injection contrôlée du journal.

## Fonctionnalités implémentées

- Action **Restaurer une sauvegarde** (Paramètres) via SAF `ACTION_OPEN_DOCUMENT` + lecture limitée.
- Validation : `BackupCodec.decodeAndVerify` (contrat DEV-12) puis règles métier (`BackupPayload`) + reconstruction dans une base SQLite mémoire isolée (`integrity_check`, `foreign_key_check`, relecture).
- Confirmation explicite de remplacement (pas de fusion), résumé issu du fichier, anti double-soumission, annulation sans écriture.
- Remplacement transactionnel avec journal interne `pending` → `committed`, `PRAGMA synchronous = FULL`, vérifications post-commit.
- Reprise au démarrage (`RestorationRecovery`) : `pending` / `committed` / état non fiable bloquant.
- Réinitialisation des contrôleurs après succès (`resetAfterRestore`).
- Auto Backup : `allowBackup=false`, `fullBackupContent`, `dataExtractionRules` (cloud + device-transfer exclus).

## Protocole de remplacement et de récupération

1. Préparer : décoder/vérifier le fichier → valider métier → charger/vérifier dans une DB temporaire → **ne pas toucher** à la base active.
2. Après confirmation utilisateur : `synchronous=FULL` → transaction courte : écrire `pending`.
3. Transaction de remplacement : effacer les tables métier → insérer le snapshot → marquer `committed` → vérifier les comptes.
4. Succès UI seulement après finalisation ; journal nettoyé après acquittement (succès immédiat ou message de reprise).
5. Au démarrage : lire le journal → `integrity_check` / FK / invariants → message `notApplied` (`pending`) ou `completed` (`committed`) ; `unreliable` bloque les écritures normales.

## Fichiers créés ou modifiés

- Créés : `backup_payload.dart`, `backup_candidate.dart`, `backup_data_writer.dart`, `backup_restorer.dart`, `restoration_recovery.dart`, `backup_restore_controller.dart`, `test/core/backup/backup_restore_test.dart`, `android/.../xml/backup_rules.xml`, `android/.../xml/data_extraction_rules.xml`.
- Modifiés : `backup_contract.dart`, `inventory_database.dart` (+ `RestorationJournalEntries`, schéma v3), `AndroidManifest.xml`, `MainActivity.kt`, `android_document_store.dart`, `settings_screen.dart`, `inventory_app.dart`, `inventory_tree_controller.dart`, `main_navigation_screen.dart`, `app_strings.dart`, `docs/09-backup-recovery.md` §4.4.

## Observé sur Android

Émulateur **Inventory_Moto_G24_API34**, Android 14, base isolée `inventory_dev13.sqlite` (empreinte `inventory.sqlite` normale inchangée : `d6da3315…`).

### Parcours A — restauration complète

1. Seed A : Maison → Bureau → Lampe (×2), Photo retirée (don), catégories, Atelier.
2. Export DEV-12 → `inventory-20261114-150145.invbackup` (3584 o) — **Export vérifié**.
3. État B : ajout de **EtatB**.
4. Restauration du fichier A → confirmation (5 éléments, 2 catégories, 1 retiré) → **Remplacer**.
5. Message **Restauration effectuée** ; Inventaire = Atelier + Maison (EtatB absent) ; Maison → Bureau → Lampe ×2 ; Historique = Photo / Don.
6. Force-stop + relance : A persiste.

### Parcours B — annulation et rejet

- Annulation à la confirmation : **Restauration annulée** ; EtatB conservé.
- Fichier `corrupt.invbackup` : **Fichier de sauvegarde invalide…** ; inventaire B intact.

### Parcours C — interruption / reprise

- **Hooks unitaires** : interruption après `pending` et avant `committed` → ancien inventaire intact ; reprise `notApplied`.
- **Sur appareil** : injection contrôlée du journal `pending` puis `committed` dans `inventory_dev13.sqlite` + relance réelle → écrans « n’a pas été appliquée… » et « La restauration a été effectuée. », acquittement puis inventaire cohérent.
- **Non démontré** : kill du processus Android exactement pendant le commit SQLite / panne d’alimentation.

## Tests ciblés et résultats

- `backup_restore_test.dart` (6) + `backup_export_test.dart` : OK.
- Cas couverts : restauration relationnelle, rejet fichier altéré, interruption après `pending`, échec avant `committed`, cycle hiérarchique, inventaire vide.
- `flutter analyze lib test/core/backup` : sans anomalie.
- APK : `allowBackup=false`, `fullBackupContent`, `dataExtractionRules` présents ; XML empaquetés.

## Réserves, limitations et risques

- Coupure physique au moment exact du commit SQLite non reproduite (réserve de preuve, pas de scénario critique connu non maîtrisé dans le protocole documenté sous hypothèses SQLite).
- Transfert D2D / canaux OEM hors contrat Android non exercés (exclusion déclarée et empaquetée seulement).
- Seed/validation temporaire retiré après les parcours ; base utilisateur normale non modifiée.

## Écarts avec les spécifications

Aucun écart bloquant sur le contrat DEV-12 ni sur le protocole `pending`/`committed` de `docs/09-backup-recovery.md`.

**Arrêt après DEV-13. DEV-14 non commencé. Aucun commit/push.**
