# Rapport DEV-12 — Export et sauvegarde

## Verdict

**VALIDÉ SOUS RÉSERVES** : un export complet a été observé sur émulateur Android avec le sélecteur SAF, relecture conforme et message « Export vérifié ». La restauration n’est pas dans ce mandat. Aucun appareil physique n’a été utilisé.

## Contrat

Format `.invbackup` selon [09-backup-recovery.md](../09-backup-recovery.md) §4 :

- Magique `INVENTORY-BACKUP` + LF, en-tête JSON UTF-8 + LF, payload JSON UTF-8.
- `format_id = inventory-backup`, `format_version = 1`, `data_schema_version = 1`.
- `payload_length` et `payload_sha256` (hex) sur les octets exacts du payload.
- Payload : `inventory`, `nodes`, `categories`, `node_categories` ; tableaux ordonnés par clé primaire ; montants en cents entiers ; nulls JSON ; biens retirés inclus.
- Section **4.4** ajoutée pour figer l’état d’implémentation DEV-12 et le codec réutilisable par DEV-13.

## Implémentation

- Lecture transactionnelle unique via `BackupSnapshotReader` (tables métier seulement ; pas de `local_verification_entries`).
- `BackupCodec` : encodage, vérification longueur/SHA-256/forme minimale.
- `BackupExporter` : sélection SAF → instantané → temporaire privé vérifié → écriture → relecture optionnelle → états vérifié / écrit non vérifiable / échoué / annulé.
- Paramètres : avertissement de confidentialité (fichier non chiffré, SHA-256 ≠ chiffrement), action **Sauvegarder l’inventaire**, anti double-soumission.
- Pont Android SAF (`ACTION_CREATE_DOCUMENT`) dans `MainActivity`.
- Aucune restauration, journal pending/committed ni exclusion Auto Backup.

## Fichiers

- Créés : `lib/core/backup/*`, `lib/app/android_document_store.dart`, `lib/app/backup_export_controller.dart`, `lib/app/settings_screen.dart`, `test/core/backup/backup_export_test.dart`.
- Modifiés : `pubspec.yaml` (`crypto`), `MainActivity.kt`, `inventory_app.dart`, `main_navigation_screen.dart`, `app_strings.dart`, `docs/09-backup-recovery.md`, `test/app/inventory_search_test.dart`.


## Observé sur Android

Émulateur **Inventory_Moto_G24_API34**, Android 14, base `inventory_dev12.sqlite` isolée :

1. Inventaire seed : Maison → Bureau → Lampe (×2, 12,50 $), Photo sentimentale retirée (don), catégories, Atelier.
2. Paramètres → avertissement → SAF Downloads → `inventory-20261114-144124.invbackup`.
3. Message **Export vérifié** ; fichier présent (3584 octets) ; `BackupCodec.decodeAndVerify` réussi hors appareil (Lampe, Photo/donation, 1250 cents).
4. Second export annulé à l’avertissement : pas de nouveau succès ; inventaire et historique Photo inchangés.
5. Relance : arbre et historique persistants. Empreinte SHA-256 de `inventory.sqlite` inchangée.

## Tests et vérifications

- **5 tests automatisés** : export représentatif, inventaire vide, troncature/altération, annulation/écriture vérifiée/non relisible, ordre et relations.
- Formatage et `flutter analyze --no-pub` sans anomalie ; APK debug reconstruit.

## Réserves et reprise DEV-13

- **Bloquant DEV-12 : aucun.** Validation physique et durabilité après coupure non vérifiées.
- Non démontré ici : restauration, base temporaire, journal `pending`/`committed`, exclusion sauvegarde système (prévu DEV-13).
- À reprendre en DEV-13 : consommer `BackupCodec`/`BackupSnapshot` sans redéfinir le cadre ; valider métier + SQLite temporaire ; remplacer transactionnellement ; configurer Auto Backup.

**Arrêt après DEV-12. DEV-13 non commencé.**
