# Rapport DEV-30 — Clôture DEV-29 et finition applicative V1

## 1. Résumé exécutif

DEV-29 est **clôturé** (six corrections présentes dans le code, rapport VALIDÉ).  

La finition applicative V1 est en place : **icône Inventory**, **splash pétrole**, **À propos / version / confidentialité / licences**, **aide intégrée**.  

APK release arm64 signée préparée pour validation physique **sans installation** dans ce mandat.

**Verdict : VALIDÉ** — Finition applicative réalisée et vérifiée sur émulateur, prête pour validation physique.

## 2. État initial et clôture DEV-29

| Élément | Constat |
|---|---|
| Version de départ | `1.0.11+12` → montée à **`1.0.12+13`** pour l’APK de livraison |
| DEV-29 | Présent (`DropdownMenu` parent, dedup prix, chips, chemin recherche, MaterialBanner, a11y quantité) |
| Audits | Non relancés |
| UI-007 capitalisation | Non traité (hors mandat) |

## 3. Identité Android réalisée

- Pictogramme V1 : cadres imbriqués (hiérarchie contenants) sur fond pétrole `#0B3D3A`, accents menthe.
- **Choix documenté :** identité V1 générée à partir de la palette existante — **non validée graphiquement par le propriétaire**.
- Ressources : `mipmap-*` legacy, adaptive `mipmap-anydpi-v26/ic_launcher.xml`, foreground densités, monochrome Android 13+.
- **Observé lanceur émulateur :** plus de logo Flutter ; icône nette et circulaire (`09_launcher.png`).

## 4. Splash réalisé

- Fond `@color/splash_background` (pétrole) + `splash_icon`.
- Android 12+ : `values-v31` / `values-night-v31` (`windowSplashScreenBackground` + icône).
- Pas d’animation ni délai artificiel.
- **Observé :** démarrage à froid pétrole + pictogramme (`07_splash_attempt.png`).

## 5. À propos et version

- Entrées **Aide** / **À propos** dans Paramètres ; **Aide** aussi dans le menu ⋮.
- `AboutScreen` : nom, version/build via `package_info_plus`, éditeur **ComeToM3** (DN certificat / docs projet).
- **Observé :** `Version 1.0.12 (build 13)` (`05_about.png`).

## 6. Confidentialité et licences

- Texte local / hors compte / `.invbackup` non chiffré / pas de sync cloud — aligné doc `07-security-privacy.md` et APK release **sans permission INTERNET**.
- Licences : `showLicensePage` Flutter (dépendances redistribuées).
- **Non inventé :** pas de licence Inventory, pas de site/email.

## 7. Aide intégrée

- `HelpScreen` : organisation, consultation, déplacement (appui long), gestion, sauvegarde.
- Formulations vérifiées contre le code actuel ; mention explicite validation émulateur vs téléphone.
- Accessible ⋮ et Paramètres ; défilement OK (`02_help.png`).

## 8. Fichiers modifiés / ajoutés (principaux)

| Zone | Fichiers |
|---|---|
| Icône / splash | `res/mipmap-*`, `mipmap-anydpi-v26`, `drawable*`, `values/colors.xml`, `values-v31`, `values-night-v31` |
| App | `about_screen.dart`, `help_screen.dart`, `settings_screen.dart`, `main_navigation_screen.dart`, `app_strings.dart` |
| Dépendance | `package_info_plus` |
| Version | `pubspec.yaml` → `1.0.12+13` |

## 9. Résultats observés sur émulateur

| # | Contrôle | Résultat |
|---|---|---|
| 1 | Icône lanceur | OK — Inventory distinct, pas Flutter |
| 2 | Splash froid | OK — pétrole + marque |
| 3 | Paramètres | OK — Aide + À propos + backup |
| 4 | À propos | OK |
| 5 | Version/build | OK — 1.0.12 / 13 |
| 6 | Confidentialité | OK — texte exact observé |
| 7–8 | Aide + scroll | OK |
| 9 | Retour | OK |
| 10 | Régression écrans touchés | Aucune visible |

## 10. Captures disponibles

`docs/rapport/_dev30_shots/` : `icon_preview`, `01_tree`, `02_help`, `04_settings`, `05_about`, `06_licenses`, `07_splash_attempt`, `08_after_cold_start`, `09_launcher`.

## 11. APK release et métadonnées

| Champ | Valeur |
|---|---|
| Chemin | `dist/android/Inventory-v1.0.12-arm64-release.apk` |
| versionName | `1.0.12` |
| versionCode (arm64) | `2013` (> `2012` de v1.0.11) |
| Taille | ≈ 19,6 Mo (20 513 258 octets) |
| SHA-256 fichier | `b11006c39991c08a0fc9bf9800d8553edaab84355bbc4ad30d4bba2444bdfbd8` |
| Signature | Vérifiée — DN `CN=Inventory V1, OU=Personal, O=ComeToM3, …` |
| Cert SHA-256 | `30d16cbe…81b998b0` (**identique** à `Inventory-v1.0.11-arm64-release.apk`) |
| applicationId | `io.github.cometom3.inventory` |
| Permissions | Pas d’`INTERNET` ; permission technique receiver non exporté |
| Mise à jour données | **Compatible signature** avec l’install existante (même certificat) — **non installée** ici |

Fichier empreinte : `dist/android/Inventory-v1.0.12-arm64-release.apk.sha256`.

## 12. Réserves techniques

- Identité visuelle = proposition V1, pas validation design propriétaire.
- Splash froid capturé rapidement (timing OS) ; cohérence confirmée visuellement.
- Aide / DnD : formulations honnêtes (émulateur) ; confirmation tactile Moto encore à faire.
- `package_info_plus` ajouté (léger) pour version runtime fiable.
- Non validé sur appareil physique dans DEV-30.

## 13. Décisions propriétaire éventuelles

1. Approuver ou remplacer le pictogramme V1.
2. Libellé éditeur « ComeToM3 » (issu du certificat / projet) — conserver, renommer ou retirer.
3. Licence / publication open source d’Inventory (non décidée).
4. Autoriser l’install Moto de `1.0.12` (mise à jour préservant les données, sous réserve du test réel).

## 14. Préparation validation Moto

| Critère | État |
|---|---|
| APK signée production | Prête |
| Même certificat que 1.0.11 | Oui |
| versionCode supérieur | Oui (`2013` > `2012`) |
| Pas d’install / clear / restore dans DEV-30 | Respecté |
| Prochaine étape | Autorisation explicite → `adb install -r` sur Moto G24 Power |

## 15. Verdict et recommandation de livraison

**VALIDÉ** — Finition applicative réalisée et vérifiée sur émulateur, prête pour validation physique.

### Synthèse

| Élément | Réalisé | Observé | Réserve |
|---|---|---|---|
| Icône | Oui | Émulateur lanceur | Proposition V1 |
| Splash | Oui | Cold start | Timing OS |
| À propos/version | Oui | 1.0.12 (13) | — |
| Confidentialité | Oui | Texte + APK sans INTERNET | — |
| Licences | Oui | Page Flutter | — |
| Aide | Oui | Menu + Paramètres | Gestes à confirmer Moto |
| APK signée | Oui | Métadonnées + même cert | Non installée sur Moto |

### Réponses

1. **Oui** — identité Android propre (hors Flutter).
2. **Oui** — À propos / version / confidentialité accessibles et exactes.
3. **Oui** — aide courte couvre les interactions importantes.
4. **Oui, sous réserve** — APK signée même certificat, versionCode plus élevé ; confirmation uniquement après install Moto autorisée.
5. **Non** — aucun défaut bloquant DEV-30.
6. **Oui** — on peut passer à la validation finale Moto dès autorisation.

---

**Distinction :** Implémenté + vérifié techniquement + observé émulateur · **Non validé sur appareil physique.**

**ARRÊT OBLIGATOIRE.** Pas d’install Moto, pas de commit/push, pas de mandat suivant.
