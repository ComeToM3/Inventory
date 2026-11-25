# M5.2 — Sauvegarde complète et restauration sécurisée

**Date :** 21 novembre 2026  
**Verdict :** VALIDÉ SOUS RÉSERVES

## 1. Mécanismes V1 réellement réutilisés

- Extension `.invbackup`, magique `INVENTORY-BACKUP`, en-tête JSON à 6 champs
- Empreinte **SHA-256** + contrôle de longueur du payload
- Journal `restoration_journal_entries` (`pending` / `committed`)
- Préparation isolée via `BackupCandidate` (SQLite mémoire)
- UI Paramètres existante (`BackupExportController` / `BackupRestoreController`)
- Pont SAF Android (`AndroidDocumentStore` + `MainActivity`)
- Normalisation legacy (`container` → `item_container`, `space` manquant → `goods`)

## 2. Différences format V1 → V2

| Élément | V1 | V2 (export actuel) |
|---|---|---|
| `format_version` | 1 | **2** |
| `data_schema_version` | 1–2 | **3** |
| Payload | JSON pur | `u32be json_len` + JSON + blobs médias |
| Tables | inventaire / nodes / categories | + stock_movements, purchase_events, app_preferences, node_documents |
| Colonnes nodes | V1 (+ `space` en schéma 2) | champs Stock / À acheter / avancés / `photo_rel_path` / `icon_key` / ordre |
| Médias | absents | manifeste `media_files` + octets bruts |
| Plafond | 32 Mio | plafond de sécurité **512 Mio** (plus de limite produit 32 Mio) |

**Distinction conservée :** `format_version` (fichier `.invbackup`) ≠ `schemaVersion` Drift SQLite (14).

## 3. Structure du fichier `.invbackup`

```
INVENTORY-BACKUP\n
{format_id, format_version, data_schema_version, created_at_utc, payload_length, payload_sha256}\n
[payload]
```

Payload format 2 :

```
uint32_be json_length
json_utf8[json_length]
for each media_files[i] in order:
  uint32_be byte_size
  bytes[byte_size]
```

Le SHA-256 porte sur **tout** le payload (JSON préfixé + médias).

## 4. Données et médias inclus

**SQLite :** inventaire, nœuds (3 espaces + champs avancés), mouvements Stock, événements d’achat, préférences, métadonnées `node_documents`, catégories (forme conservée, vidée à l’import comme V1/DEV-17).

**Médias :** fichiers réellement référencés (`nodes.photo_rel_path`, `node_documents.rel_path`), octets inchangés, chemins relatifs `photos/…` et `documents/…` uniquement.

**Hors sauvegarde :** dictionnaire d’icônes / glyphes Material (code applicatif). Seul `icon_key` utilisateur est exporté.

## 5. Garanties d’intégrité

- Troncature → `lengthMismatch`
- Altération → `checksumMismatch`
- Version hors plage → `unsupportedVersion`
- Manifeste ≠ blobs / SHA média / taille → `mediaMissing` ou `checksumMismatch`
- Chemins `..`, absolus, hors préfixes → refus
- Références SQLite sans média inclus → `mediaMissing`
- Médias orphelins non référencés → refus
- Validation métier + insertion candidate SQLite avant confirmation

## 6. Restauration et protections

1. Copie SAF → fichier temporaire (`copyDocumentToPath`)
2. Décodage + staging médias (`restore_media_staging/`)
3. Validation candidate mémoire
4. Confirmation UI explicite
5. Journal `pending` → remplacement transactionnel DB → `committed`
6. Activation médias (bascule `photos`/`documents`, conservation temporaire `restore_media_previous/`)
7. Vérification SHA des médias live
8. Nettoyage staging / précédent
9. Accusé journal

Échec avant `committed` : transaction SQLite annulée, inventaire précédent conservé (comportement V1 inchangé).  
Échec d’activation médias après commit DB : tentative de restauration des arbres précédents ; sinon signalement d’échec.

## 7. Mémoire et stockage temporaire

- Export : encodage progressif disque (`encodeToFile`) pour les médias
- SAF : `writeDocumentFromPath` / `copyDocumentToPath` (flux Kotlin, sans Base64)
- Décodage : le fichier est encore lu en mémoire pour la vérification SHA globale (plafond 512 Mio) — adaptation minimale ; streaming SHA complet reporté si inventaires réellement plus lourds
- Pas de recompression WebP / PDF
- Temps `inventory_export_*` / `inventory_import_*` nettoyés

## 8. Parcours observés sur émulateur

| Observation | Résultat |
|---|---|
| APK debug x86_64 compilé | `build/app/outputs/flutter-apk/app-x86_64-debug.apk` (~103 Mio) |
| `adb install -r` sur `emulator-5554` | Success |
| Lancement Inventory | `MainActivity` top resumed / visible |
| Données existantes | Conservées (SQLite schéma 14, 4 nœuds goods, 1 préférence) |
| Export/restauration UI SAF | Non rejoués de bout en bout (sélecteur document non automatisé sans risque) |
| Restauration destructive sur copie unique | **Non effectuée** (interdit par mandat / risque) |

## 9. Vérifications techniques

- Tests unitaires `test/core/backup/` : export, troncature, corruption, restauration, journal pending, cycles, inventaire vide — **OK**
- Test médias : inclusion / manifeste manquant — **OK**
- Test isolé round-trip médias + restauration (`backup_media_roundtrip_test.dart`) : photo WebP + PDF, `icon_key`, préférence, octets identiques — **OK**
- Requête hors ligne de la base émulateur : spaces/prefs/médias documentés ci-dessus

## 10. Compatibilité V1

- Import `format_version` 1 + `data_schema_version` 1–2 : **accepté** (JSON pur, sans médias)
- Normalisation legacy conservée
- Pas de moteur de migration disproportionné V1→V2 au-delà de cette importation
- Export V2 uniquement (`format_version` 2 / schéma 3)
- Compatibilité inverse V2→V1 : hors périmètre

## 11. Préservation des données existantes

Confirmée : aucune désinstallation, aucun wipe, aucune restauration destructive sur l’émulateur. Taille SQLite live ≈ 135 Ko après installation.

## 12. État final de l’émulateur

- AVD `Pixel_7a` (`emulator-5554`) démarré
- Inventory installé (debug x86_64) et au premier plan (activité reprise)
- Données utilisateur non effacées

## 13. Réserves

| Priorité | Réserve |
|---|---|
| P1 | Parcours SAF export/restauration non observé manuellement de bout en bout sur l’émulateur |
| P1 | Jeu émulateur actuel sans photo/document/Stock/À acheter ; couverture médias/Stock validée en environnement isolé |
| P2 | Décodage charge encore le fichier complet en RAM (plafond 512 Mio) |
| P2 | Échec média après `committed` DB reste un cas limite (rollback best-effort des arbres fichiers) |

## 14. Verdict

**VALIDÉ SOUS RÉSERVES**

Le système V1 a été étendu (pas remplacé) pour couvrir le schéma métier V2 et les médias, avec intégrité SHA-256, journal et UI Paramètres conservés. Les preuves automatisées et l’installation émulateur sont positives ; la validation UI SAF complète et la restauration destructive sur la copie unique restent volontairement hors essais.

---

**STOP** — M5.3 non démarré.
