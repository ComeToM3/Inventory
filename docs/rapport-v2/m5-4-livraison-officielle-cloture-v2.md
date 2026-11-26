# M5.4 — Livraison officielle et clôture définitive d'Inventory V2

**Date :** 25 novembre 2026  
**Appareil :** Moto G24 Power `ZT322P23HJ` (Android 14, arm64)  
**Mandat :** Livraison et clôture — aucune évolution fonctionnelle V3

---

## 1. Résumé exécutif

Inventory V2 est livré en version officielle **2.0.0** (versionCode arm64 **6051**).

- APK release arm64 signé avec la clé de production historique.
- Artefact déposé dans `dist/android/` avec empreinte SHA-256.
- Installation propre sur le Motorola (signatures debug ≠ release).
- Réception minimale release démontrée physiquement.
- Plan directeur et notes de version actualisés.
- Aucune fonctionnalité V3 introduite.
- Aucun commit / tag / push effectué.

**Verdict : LIVRAISON V2 VALIDÉE SOUS RÉSERVES EXPLICITEMENT ACCEPTÉES**

---

## 2. État initial et final du dépôt

| Élément | Initial (début M5.4) | Final |
|---|---|---|
| Branche | `main` = `origin/main` | inchangé |
| Commit HEAD | `1d6b69be2a026faecbac745acfcf17788d13dbe6` (`1d6b69b`) | **identique** |
| Working tree | Modifications INTER-03-C + rapports non commités | + versionnement 2.0.0 + docs M5.4 + artefact `dist/` |
| App Motorola | Debug `1.0.15` / vc **6050** (DEBUGGABLE) | Release `2.0.0` / vc **6051** (non débogable) |

**Important :** l’APK release correspond au working tree local (HEAD `1d6b69b` **plus** les modifications INTER-03-C et `pubspec.yaml` 2.0.0+4051). Ce n’est **pas** un commit Git immuable tant que ces changements ne sont pas enregistrés.

---

## 3. Réserves de réception et décisions

### Issues de M5.3-D (conservées)

| ID | Nature | Décision M5.4 |
|---|---|---|
| R-01 | Acquisition / export-restauration `.invbackup` non démontrés bout-en-bout | **Acceptée** pour clôture (non bloquante) ; mécanismes présents, non rejoués ici |
| R-02 | Historique Stock / médias / DnD doigt non rejoués | **Acceptée** pour clôture (non bloquante) |
| R-03 | Libellé test ADB cosmétique | Non applicable (install propre) |

### Décisions d’installation

| Décision | Constat |
|---|---|
| Mise à jour `-r` | **Échouée** — `INSTALL_FAILED_UPDATE_INCOMPATIBLE` |
| Cause | Certificat debug ≠ certificat production |
| Sauvegarde avant wipe | Proposée ; utilisateur a répondu **non** |
| Effacement Inventory | Autorisé explicitement ; exécuté via `adb uninstall` (Inventory uniquement) |

---

## 4. Versionnement officiel

| Champ | Valeur |
|---|---|
| `pubspec.yaml` | `version: 2.0.0+4051` |
| versionName | `2.0.0` |
| buildNumber | `4051` |
| versionCode arm64 effectif | **6051** |
| applicationId | `io.github.cometom3.inventory` |

### Calcul du versionCode

Commande :

```text
flutter build apk --release --target-platform=android-arm64 --split-per-abi \
  --build-name=2.0.0 --build-number=4051
```

Formule Flutter `--split-per-abi` pour `arm64-v8a` :

`versionCode = 2000 + buildNumber` → `2000 + 4051 = 6051`

Contrôles : `6051 > 6050` (debug M5.3-D) et `6051 > 2016` (max release historique connue dans `dist/`).

Mécanisme existant conservé (pas de nouveau schéma de versionnement).

---

## 5. Résultats de compilation

| Contrôle | Résultat |
|---|---|
| Compilation | **OK** (`app-arm64-v8a-release.apk`, ≈ 20,7 Mo) |
| Mode | release |
| ABI | **arm64-v8a** uniquement |
| minSdk / targetSdk | 24 / 36 |

---

## 6. Vérification de signature

| Contrôle | Résultat |
|---|---|
| `apksigner verify` | **Verifies** (APK Signature Scheme v2) |
| DN | `CN=Inventory V1, OU=Personal, O=ComeToM3, L=Unknown, ST=Unknown, C=CA` |
| SHA-256 certificat | `30d16cbecf51a231cbc995fbe59e32715ea23dc7d790814cfd4ff24381b998b0` |
| Identité vs release V1.0.15 | **Identique** (même clé de production) |
| Secrets | Non exposés |

---

## 7. Métadonnées et empreinte SHA-256

| Métadonnée | Valeur |
|---|---|
| package | `io.github.cometom3.inventory` |
| versionName | `2.0.0` |
| versionCode | `6051` |
| native-code | `arm64-v8a` |
| Taille | 21 671 025 octets (≈ 20,67 Mo) |
| SHA-256 APK | `3663833136096f34f740be65ff93054d0cb0fe36e2186653765b95d5e00a4833` |

Fichier empreinte : `dist/android/Inventory-v2.0.0-arm64-release-vc6051.apk.sha256`

---

## 8. Chemin exact de l’artefact

```text
C:\Users\ComeToM3\Dev\Inventory\dist\android\Inventory-v2.0.0-arm64-release-vc6051.apk
C:\Users\ComeToM3\Dev\Inventory\dist\android\Inventory-v2.0.0-arm64-release-vc6051.apk.sha256
```

Preuves UI : `docs/rapport-v2/_m54/`

---

## 9. Installation Motorola

| Étape | Résultat |
|---|---|
| Appareil | `ZT322P23HJ` présent |
| `install -r` | Échec signatures incompatibles |
| `adb uninstall io.github.cometom3.inventory` | Success |
| `adb install` release | Success |
| Métadonnées installées | `versionName=2.0.0` / `versionCode=6051` / minSdk 24 / targetSdk 36 |
| Flags | `HAS_CODE ALLOW_CLEAR_USER_DATA` — **sans** `DEBUGGABLE` |
| À propos (UI) | `Version 2.0.0 (build 6051)` |

---

## 10. Validations physiques réalisées

| Contrôle | Méthode | Résultat |
|---|---|---|
| Démarrage release | Launch + screenshot | OK |
| Trois espaces | UI Biens / Stock / À acheter | OK |
| Création d’un bien | `M54Bien` créé sous Inventaire | OK |
| Consultation | Visible dans l’arbre (libellé + valeur) | OK |
| Persistance | `am force-stop` + relance | `M54Bien` présent |
| Paramètres | Menu → Paramètres | OK |
| Sauvegarde / restauration (accès) | Entrées « Sauvegarder l’inventaire » et « Restaurer une sauvegarde » | OK |
| Version affichée | À propos | `2.0.0 (build 6051)` |

---

## 11. Validations non réalisées (M5.4)

Non déclarées validées :

1. Acquisition d’un besoin vers Biens.
2. Acquisition d’un besoin vers un produit Stock existant.
3. Export effectif d’un fichier `.invbackup`.
4. Restauration contrôlée de cette sauvegarde.
5. Conservation médias après restauration + redémarrage.
6. Caméra / galerie / ouverture document / DnD doigt.

Ces points restent des **réserves non bloquantes acceptées** pour la clôture officielle V2 (suite M5.3-D + mandat M5.4 + refus explicite de sauvegarde pré-wipe).

---

## 12. Documentation actualisée

| Document | Action |
|---|---|
| `docs/Inventory-v2.md` | Mis à jour : statut livré 2.0.0, D09/DnD, architecture finale, phases terminées, limitations §17, état §18 |
| `docs/rapport-v2/notes-version-2.0.0.md` | **Créé** — notes officielles 2.0.0 |
| Rapports historiques INTER-*/M5.3-D | Conservés sans réécriture |

---

## 13. Limitations résiduelles acceptées

- Maturité Stock / À acheter : parcours essentiels, non exhaustifs.
- Réserves R-01 / R-02 (M5.3-D) non rejouées en M5.4.
- Working tree non figé par commit : clôture Git ultérieure sur autorisation.
- Orientations V3 explicitement hors périmètre (aucune implémentation).

---

## 14. État Git (référence V2)

| Élément | Valeur |
|---|---|
| Commit de référence actuel | `1d6b69be2a026faecbac745acfcf17788d13dbe6` |
| Artefact = commit seul ? | **Non** — working tree dirty |
| Modifications code (INTER-03-C + version) | `app_strings.dart`, `inventory_tree_controller.dart`, `inventory_ui.dart`, `purchase_models.dart`, suppressions `inventory_advanced_section` / `persistence_check_*`, `pubspec.yaml` → `2.0.0+4051` |
| Docs ajoutées / modifiées M5.4 | `Inventory-v2.md`, `notes-version-2.0.0.md`, le présent rapport, preuves `_m54/` |
| Artefacts | `dist/android/Inventory-v2.0.0-arm64-release-vc6051.apk` (+ `.sha256`) ; `dist/` non suivi historiquement |
| Commit / tag / push | **Aucun** (en attente d’autorisation) |

Éléments prêts pour une future clôture Git (hors mandat tant que non autorisée) : commit des sources + docs de livraison, tag éventuel `v2.0.0`, conservation de l’empreinte SHA-256 de l’APK.

---

## 15. Verdict final

**LIVRAISON V2 VALIDÉE SOUS RÉSERVES EXPLICITEMENT ACCEPTÉES**

Critères 1–5, 7–9 satisfaits. Critère 6 satisfait par acceptation explicite des réserves non bloquantes (poursuite M5.4 après M5.3-D ; refus de sauvegarde pré-wipe ; absence de P0/P1).

**STOP** — attendre les instructions de l’utilisateur. Ne pas démarrer V3. Ne pas commit/push sans autorisation.
