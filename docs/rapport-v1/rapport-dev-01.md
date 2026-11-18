# Rapport de développement — DEV-01

**Mise à jour :** 13 novembre 2026
**Statut : clôturé — validation physique reportée**
**Verdict : VALIDÉ SOUS RÉSERVES**

## A. Objectif et verdict

DEV-01 établit le socle Flutter Android, une base Drift/SQLite dans le stockage privé de l'application, et un parcours minimal démontrant la persistance après la fermeture complète puis le redémarrage.

Le projet Flutter Android a été créé et compilé; le parcours complet a été observé sur l'émulateur `Inventory_Moto_G24_API34`. Drift/SQLite fonctionne dans le stockage privé Android. L'application a été installée sur le Moto G24 Power, mais son écran était verrouillé : l'interface et les cycles de persistance physiques restent **NON VÉRIFIÉS**. La clôture **VALIDÉ SOUS RÉSERVES** est une décision de gouvernance et ne constitue pas une preuve supplémentaire de fonctionnement physique.

DEV-02 n'a pas commencé.

## B. Architecture créée

- [Point d'entrée Flutter](../../lib/main.dart) et [application minimale](../../lib/app/inventory_app.dart).
- [Écran technique](../../lib/app/persistence_check_screen.dart) indiquant l'état de la base et permettant de saisir puis enregistrer une valeur de vérification.
- [Contrôleur](../../lib/app/persistence_check_controller.dart) séparant la coordination de l'interface et de la persistance, avec erreurs affichées.
- [Base Drift](../../lib/core/database/inventory_database.dart) séparée de l'interface, ouverte par `drift_flutter` dans le répertoire d'assistance privé Android.

La table technique `local_verification_entries` est l'unique table applicative. Aucune table métier, fonctionnalité d'inventaire, catégorie, valorisation ou sauvegarde n'a été ajoutée.

Les dépendances directes sont Flutter, Drift `2.35.4`, `drift_flutter` `0.3.1` et `path_provider` `2.1.6`. Les outils de développement sont `drift_dev`, `build_runner`, `flutter_lints` et `flutter_test`; les versions résolues figurent dans [pubspec.lock](../../pubspec.lock).

## C. Configuration Android

| Élément | Valeur ou résultat |
| --- | --- |
| Flutter / Dart | Flutter `3.44.2`, Dart `3.12.2`. |
| Android SDK | SDK `36.1.0`; compilation avec `compileSdk 36`. |
| JDK | JDK `21.0.8` d'Android Studio. Le build release final a été relancé et réussi sous ce JDK. |
| Gradle | Wrapper et version effective `9.1.0`. |
| Android Gradle Plugin | `9.0.1`. |
| Kotlin Gradle Plugin | `2.3.20`; cible JVM déclarée `17`. |
| Application ID / namespace | `io.github.cometom3.inventory`. |
| `minSdk` / `targetSdk` | `24` / `36`, confirmés dans la configuration et les métadonnées APK. |

Un premier build Gradle a utilisé le JDK `17.0.17` par défaut du terminal. Le build release final a été effectué avec le JDK 21 d'Android Studio et a réussi; aucune variable système persistante n'a été modifiée.

Le manifeste principal ne demande aucune permission applicative. Les manifestes debug/profile générés ajoutent `INTERNET` pour les outils Flutter de développement. L'APK release vérifié ne contient pas cette permission; il déclare uniquement la permission technique `io.github.cometom3.inventory.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.

## D. Drift / SQLite

- La base persistante est créée via `driftDatabase` et `getApplicationSupportDirectory`.
- Sur l'émulateur, `run-as` a confirmé le fichier `files/inventory.sqlite` dans le stockage privé de l'application.
- La table technique `local_verification_entries` a été lue depuis le fichier SQLite après le second cycle; elle contenait `(id: 1, value: DEV01_STAGE_TWO)`.
- L'interface a affiché l'état « Base locale prête », la valeur enregistrée et la confirmation de sauvegarde.
- À la destruction du contrôleur, la fermeture de la base attend l'opération en cours; aucune donnée n'a été effacée entre les cycles.

Le test ciblé sur l'hôte vérifie également écriture, fermeture/réouverture, modification et seconde fermeture/réouverture.

## E. Validation sur l'émulateur

Cible : `Inventory_Moto_G24_API34`, exécutée comme `emulator-5554` (Android 14 / API 34).

1. Build debug, installation et démarrage réussis.
2. L'écran technique a été observé; aucun débordement apparent n'était visible.
3. La valeur `DEV01_STAGE_ONE` a été enregistrée et sa confirmation affichée.
4. L'application a été arrêtée complètement avec `am force-stop`, sans effacer ses données, puis relancée. L'écran affichait encore `DEV01_STAGE_ONE`.
5. La valeur a été remplacée par `DEV01_STAGE_TWO`; la confirmation de sauvegarde a été affichée.
6. Après un second arrêt complet et redémarrage, l'écran affichait `DEV01_STAGE_TWO`, également retrouvé directement dans le fichier SQLite privé.

**Résultat :** les deux cycles de persistance demandés ont été observés sur l'émulateur. Ce résultat ne vaut pas preuve pour l'appareil physique.

## F. Validation sur le Motorola Moto G24 Power

Cible ADB : `ZT322P23HJ`, modèle Moto G24 Power, Android 14 / API 34.

| Étape | Résultat |
| --- | --- |
| Détection ADB | Réussie. |
| Installation de l'APK debug | Réussie. |
| Démarrage demandé par ADB | L'activité a été acceptée, mais l'écran est resté sur l'écran de verrouillage. |
| Interface visible et utilisable | **NON VÉRIFIÉ** — téléphone verrouillé. |
| Écritures et deux cycles après redémarrage | **NON VÉRIFIÉ**. |
| Affichage réel, clavier, marges et absence de débordement | **NON VÉRIFIÉ**. |
| Fonctionnement hors ligne | **NON VÉRIFIÉ**. |

Aucun contournement du verrouillage ni changement des paramètres personnels n'a été effectué. Une intervention locale de déverrouillage est nécessaire pour poursuivre cette validation.

## G. Qualité et compilation

| Vérification | Résultat |
| --- | --- |
| `flutter analyze` | Réussie, aucun problème signalé. |
| `flutter test test\core\database\inventory_database_test.dart` | Réussi : persistance sur deux cycles de fermeture/réouverture. |
| `flutter build apk --debug` | Réussi précédemment; APK installé et lancé sur l'émulateur. |
| `flutter build apk --release --target-platform android-arm64` sous JDK 21 | Réussi. |
| Build release sans restriction de plateforme | Échec sur la cible `android-arm` : Windows Application Control a bloqué `gen_snapshot.exe`. Le build arm64 a réussi; cet échec de compilation 32 bits ne prouve pas une incompatibilité des cibles vérifiées. |
| Métadonnées de l'APK release | Application ID, `minSdk 24` et `targetSdk 36` confirmés par `aapt`. |
| Permission Internet dans l'APK release | Absente. |
| Validation Android physique | Incomplète, voir section F. |

## H. Modifications et état Git

Le socle DEV-01 comprend les sources Flutter et Drift, la configuration Dart (`pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`), le test ciblé, les métadonnées Flutter et la plateforme Android générée sous [android/](../../android). La plateforme configure l'identifiant approuvé et les SDK approuvés. Le présent rapport a été actualisé avec les résultats disponibles.

Les sources Flutter/Drift, la configuration, le test ciblé et la plateforme Android font partie du périmètre DEV-01. Les trois documents de référence ont été déplacés sous `docs/` sans perte ni modification de contenu métier; seuls les liens relatifs cassés par les déplacements ont été corrigés. Aucun changement de décision produit ou de code fonctionnel n'a été effectué pendant la clôture.

## I. Réserves et clôture

**Réserve — Moto G24 Power :** installation réussie; interface, interactions, affichage et persistance non vérifiés, car le téléphone était verrouillé.

**Vérifié :** configuration SDK et identifiant, build Android debug sur émulateur, build release arm64 sous JDK 21, analyse statique, test ciblé Drift, deux cycles de persistance sur l'émulateur et absence de permission Internet dans le manifeste release.

**Validation physique reportée :** à reprendre idéalement après DEV-07 et obligatoirement pendant DEV-14, avant la livraison.

**Réserve — build 32 bits :** la cible release `android-arm` a été bloquée par Windows Application Control; la cible arm64 a compilé avec succès. Réexaminer la cible 32 bits pendant DEV-15 selon les architectures de distribution retenues.

Les réserves restent ouvertes et traçables, mais ne bloquent pas DEV-02.

**Conclusion : VALIDÉ SOUS RÉSERVES.** DEV-02 n'a pas commencé.
