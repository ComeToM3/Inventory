# Notes de version — Inventory 2.0.0

**Date :** 25 novembre 2026  
**Identifiant :** `io.github.cometom3.inventory`  
**versionName :** `2.0.0`  
**versionCode (arm64-v8a) :** `6051`  
**Artefact :** `dist/android/Inventory-v2.0.0-arm64-release-vc6051.apk`

## Calcul du versionCode

Compilation : `flutter build apk --release --target-platform=android-arm64 --split-per-abi --build-name=2.0.0 --build-number=4051`

Formule Flutter `--split-per-abi` pour `arm64-v8a` :

`versionCode = 2000 + buildNumber` → `2000 + 4051 = 6051`

Exigence : strictement supérieur au debug installé `6050` et aux releases historiques (max connu `2016`).

## Contenu de cette version

Inventory V2 livré sur Android (local, hors ligne) :

- Trois espaces : **Biens**, **Stock**, **À acheter**
- Formulaires harmonisés (convergence ergonomique)
- Organisation de l’arborescence par **appui long / glisser-déposer**
- Photographies (WebP) et documents justificatifs
- Valorisation Biens **exclusive** financière ou sentimentale
- Sauvegarde / restauration `.invbackup` (format 2, données 3)
- Schéma SQLite **15**
- Compatibilité : Android 7.0+ (minSdk 24), cible API 36, ABI **arm64-v8a** uniquement

## Signature

Certificat de production Inventory (CN=Inventory V1) — même clé que les releases V1 historiques.  
Les builds **debug** ne sont pas mis à jour sur place : signatures incompatibles → installation propre.

## Limitations acceptées

Voir `docs/Inventory-v2.md` §17 et le rapport `m5-4-livraison-officielle-cloture-v2.md`.

## Hors périmètre

Aucune fonctionnalité Inventory V3 dans cette livraison.
