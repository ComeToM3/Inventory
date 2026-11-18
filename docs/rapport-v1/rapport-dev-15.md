# Rapport DEV-15 — Distribution, signature et validation APK

## Verdict

**VALIDÉ** : APK release ARM64 **signé production** produit, vérifié, installé et exercé sur **moto g24 power** (après désinstallation autorisée de la build debug). Parcours release observés : création, modification/totaux, recherche, retrait/historique, export « Export vérifié », rejet de restauration invalide, persistance après force-stop.

**Décision : GO pour distribution V1** (installation manuelle de l’APK signé). Aucune publication automatique effectuée.

Réserve hors blocage produit : sauvegarde chiffrée **indépendante** du keystore **non encore prouvée** (procédure documentée ; à faire par le détenteur de la clé).

## Configuration Android finale

| Élément | Valeur |
|---------|--------|
| `applicationId` | `io.github.cometom3.inventory` |
| `versionName` | `1.0.0` |
| `versionCode` (APK arm64 split) | `2001` (encodage Flutter `--split-per-abi` à partir de `+1`) |
| `minSdk` / `targetSdk` | 24 / 36 |
| `allowBackup` | `false` + règles DEV-13 |
| Release signing | `android/key.properties` → keystore hors dépôt |
| Package installé (téléphone) | `versionCode=2001`, **non** `DEBUGGABLE` |

## Stratégie de signature

- Clé **production** dédiée Inventory V1 (autorisation explicite).
- Emplacement : `%USERPROFILE%\AppSigning\Inventory\` (hors Git, ACL restreintes).
- Gradle release **refuse** de signer sans `android/key.properties` (pas de repli debug).
- Secrets : absents du dépôt, des journaux et du code ; `key.properties` gitignored.

## État de la clé (sans secret)

| Élément | Valeur |
|---------|--------|
| Fichier | `inventory-upload-keystore.jks` |
| Alias | `inventory` |
| Algo | RSA 2048, SHA256withRSA |
| Validité | 2026-11-14 → 2054-04-01 |
| Empreinte cert. SHA-256 | `30:D1:6C:BE:CF:51:A2:31:CB:C9:95:FB:E5:9E:32:71:5E:A2:3D:C7:D7:90:81:4C:FD:4F:F2:43:81:B9:98:B0` |
| Sauvegarde chiffrée indépendante | **Non effectuée / non prouvée** — `AppSigning\Inventory\README-BACKUP.md` |

## Compilation

```text
flutter build apk --release --target-platform=android-arm64 --split-per-abi
```

Succès (contrainte Windows / `gen_snapshot` 32 bits non rencontrée en ARM64).

## Vérification signature / architecture

| Contrôle | Résultat |
|----------|----------|
| `apksigner verify` | OK (v2) |
| DN | `CN=Inventory V1, OU=Personal, O=ComeToM3, …` (**pas** Android Debug) |
| ABI | `arm64-v8a` uniquement |
| Seeds DEV-13.x/14 dans l’APK | Absents (scan chaînes) |

## Artefacts

Dossier : `dist/android/`

| Fichier | Détail |
|---------|--------|
| `Inventory-v1.0.0-arm64-release.apk` | 20 377 862 octets |
| SHA-256 | `292a8a3e7542072668510156028d2a8568da4c3cc21d40a7d49d5f705c1b40b3` |
| `INSTALL.md` / `REBUILD.md` | Installation et reconstruction |

## Protection des données (téléphone)

- Build debug déjà présente → conflit de signature ; **désinstallation autorisée** explicitement.
- Copie préalable non destructive : `AppSigning\Inventory\phone-pre-release-backup\` (`inventory.sqlite` + `inventory-pre-uninstall.sqlite`, 8192 o chacun).
- Aucun `pm clear` hors désinstallation nécessaire à l’install release.
- Aucune publication store / CI.

## Validation release sur Moto G24 Power

| Élément | Valeur |
|---------|--------|
| Appareil | Motorola **moto g24 power** (`ZT322P23HJ`) |
| Android | 14, `arm64-v8a` |
| Install | `adb uninstall` debug → `adb install` APK release `dist/android/` |
| Signature installée | `a163acac` (≠ debug `c7f5e02f`) |

| Domaine | Résultat observé |
|---------|------------------|
| Lancement vide | « Aucun emplacement… » / Ajouter |
| Création | Emplacement `MaisonDEV15` ; bien `LampeDEV15` |
| Modification / totaux | qté 2 × 25,00 $ → fiche **50,00 $** ; arbre Maison **50,00 $ CAD** |
| Recherche | « Lampe » → 1 résultat, chemin MaisonDEV15, badge **2 × 25,00 $ CAD** |
| Retrait / historique | Motif **Vente** ; historique `LampeDEV15 · Vente · 14/11/2026` ; Maison sans valeur |
| Export SAF | Téléchargements → **Export vérifié** ; `inventory-20261114-182312.invbackup` (1353 o) |
| Restauration invalide | `bad-dev14.invbackup` → **Fichier de sauvegarde invalide… n’a pas été modifié** |
| Relance à froid | `MaisonDEV15` + historique Vente toujours présents après `force-stop` |

Captures : [`docs/rapport/captures-dev-15/`](captures-dev-15/).

## Tests techniques

- Compilation release ARM64 : OK
- Vérification signature : OK
- Install + smoke physique release : OK
- `flutter analyze` / suite tests : non rejoués dans cette reprise (déjà verts en DEV-14)

## Anomalies / réserves

| ID | Sévérité | Description |
|----|----------|-------------|
| B2 | P2 (ops clé) | Sauvegarde chiffrée hors machine du keystore non encore faite / non prouvée |
| ~~B1~~ | — | Conflit debug→release résolu par désinstallation autorisée |

## Procédure de reconstruction

Voir `dist/android/REBUILD.md`.

## Décision

**GO** pour distribution V1 sous forme d’APK ARM64 signé (remise manuelle).  
Ne pas publier automatiquement. Traiter B2 (sauvegarde chiffrée du keystore) avant toute dépendance long terme à cette clé.
