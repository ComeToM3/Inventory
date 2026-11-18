# Rapport de développement — DEV-04

**Mise à jour :** 13 novembre 2026  
**Verdict : VALIDÉ SOUS RÉSERVES**

## A. Verdict

Les quatre destinations et leur navigation sont implémentées, compilées et observées sur l'émulateur Android demandé. Le parcours a été exécuté par interactions ADB et observé à l'aide de captures et de l'arbre d'accessibilité, **pas par une personne manipulant l'émulateur**. Le parcours manuel humain et le téléphone physique restent non vérifiés.

Les tests existants de persistance et du moteur réussissent. Ces résultats ne valident pas les fonctionnalités des mandats suivants.

## B. Structure implémentée

- Un seul point d'entrée Flutter et un `MaterialApp`.
- Barre inférieure Material 3 : **Inventaire**, **Recherche**, **Historique** et **Paramètres**, avec icône, libellé et indicateur de sélection.
- Inventaire s'affiche au démarrage. Chaque destination présente son titre et un message provisoire adapté, sans prétendre que les données sont vides.
- Retour Android : depuis une autre destination, retour à Inventaire ; depuis Inventaire, retour au lanceur Android. Une nouvelle ouverture démarre sur Inventaire.
- État de sélection local et navigation native Flutter, sans routeur externe ni connexion artificielle au moteur.
- Le contrôle de persistance DEV-01 et son contrôleur restent dans le code, mais ne sont plus démarrés ni exposés dans la navigation normale. Les écrans provisoires n'ouvrent pas la base : la migration existante sera exécutée lors d'un accès ultérieur à celle-ci.

**Écart documentaire explicite :** [06-ux-ui.md](../06-ux-ui.md), section 2, indique « trois destinations » et des Paramètres « accessibles séparément ». Le mandat DEV-04 demande explicitement quatre destinations **dans la barre inférieure** ; cette instruction a été appliquée sans modifier silencieusement la spécification historique. Sa mise en cohérence documentaire éventuelle reste à décider.

## C. Thème

Thème clair Material 3 provisoire, créé au même endroit dans [app_theme.dart](../../lib/app/app_theme.dart) avec un `ColorScheme` issu d'une couleur gris-bleu neutre. Les écrans n'ont pas de couleurs individuelles. La palette n'est pas une décision esthétique définitive ; aucun thème sombre bleu-vert ni sélecteur n'a été ajouté. Le bandeau de débogage est masqué pour ne pas recouvrir la zone système.

La dépendance **`flutter_localizations` du SDK Flutter** a été ajoutée pour fournir les annonces Material en français, notamment « Onglet 1 sur 4 » ; `intl` est sa dépendance transitive. Seul le français est configuré. Aucun paquet de navigation externe n'a été ajouté.

## D. Validation Android

**Cible :** émulateur `Inventory_Moto_G24_API34`, Android 14 / API 34, 720 × 1 612 pixels, densité 280 dpi. APK debug installé avec remplacement, sans effacement des données.

**Observé sur l'émulateur :**

1. Démarrage sur Inventaire ; titre, message et destination sélectionnée corrects.
2. Recherche → Historique → Paramètres → Inventaire, puis nouveaux changements entre les destinations : titres, messages et sélections conformes.
3. Retour depuis Paramètres par touche Android et depuis Historique par geste de bord : retour à Inventaire. Le geste depuis le bord opposé a également été vérifié.
4. En navigation Android à trois boutons, appui sur le bouton Retour depuis Historique : retour à Inventaire. Depuis Inventaire, Retour ramène au lanceur ; la réouverture revient à Inventaire.
5. Quatre commandes accessibles et nommées en français dans l'arbre Android, avec état sélectionné. Sur la cible, leurs zones mesurées font environ 103 × 80 dp.
6. Vérification visuelle des quatre écrans, des zones système et des textes agrandis à **1,5× et 2×** : aucun débordement manifeste observé. Les libellés de `NavigationBar` sont plafonnés à 1,3× par le composant Material ; les messages et titres suivent l'agrandissement Android.
7. Le réglage initial de taille de texte et la navigation gestuelle initiale ont été rétablis. L'empreinte SHA-256 du fichier SQLite privé existant est identique avant et après installation et parcours.

La recherche de débordements et exceptions Flutter dans les journaux du processus final n'a trouvé aucune correspondance. Ces observations ne constituent pas une validation physique ni une certification d'accessibilité.

## E. Vérifications techniques

| Vérification | Résultat |
| --- | --- |
| `flutter pub get` | Réussi après ajout de la localisation du SDK ; deux dépendances résolues en plus, dont `intl` transitive. |
| `dart format --output=none --set-exit-if-changed` sur les quatre fichiers UI concernés | Réussi. |
| `flutter analyze --no-pub` | Réussi, aucun problème. |
| `flutter build apk --debug --no-pub` | Réussi ; APK final installé et exécuté sur l'émulateur. |
| `flutter test --no-pub test\core` | **11 tests réussis** : 4 tests SQLite et 7 tests du moteur existants. |
| `git diff --check` | Réussi ; avertissements Git de conversion de fins de ligne, sans erreur de whitespace. |

Aucun nouveau test de navigation redondant n'a été créé. Les tests SQLite/métier existants ont été relancés car les écrans provisoires ne permettent pas de vérifier ces invariants.

Incidents de vérification : une première assertion Android sur un texte accentué a échoué à cause de l'encodage du script PowerShell, alors que le texte était correct dans l'arbre Android ; elle a été reprise en Unicode et réussie. Une première lecture du diagnostic de retour racine utilisait une commande `dumpsys` inadaptée ; le retour au lanceur a ensuite été vérifié avec la bonne commande. La suppression du réglage temporaire de texte a d'abord été normalisée à `1.0` par Android ; une seconde suppression a rétabli la valeur initiale absente, puis celle-ci a été revérifiée.

## F. Modifications

- Modifiés : [inventory_app.dart](../../lib/app/inventory_app.dart), [app_strings.dart](../../lib/app/app_strings.dart), [pubspec.yaml](../../pubspec.yaml) et [pubspec.lock](../../pubspec.lock).
- Créés : [app_theme.dart](../../lib/app/app_theme.dart), [main_navigation_screen.dart](../../lib/app/main_navigation_screen.dart) et le présent rapport.
- Aucun changement au schéma, aux migrations, au moteur métier, à la configuration Android, aux tests existants ou aux rapports DEV-01 à DEV-03.
- Les changements DEV-02 et DEV-03 déjà présents dans l'arbre de travail ont été conservés. Aucun fichier n'a été indexé ; aucun commit ni push n'a été effectué.

## G. Réserves

**Validation restant à confirmer :** parcours manuel par une personne sur l'émulateur ; l'exécution ADB et l'observation visuelle ne sont pas présentées comme une manipulation humaine. Aucun défaut fonctionnel bloquant n'a été observé dans le périmètre DEV-04.

**Non vérifié / facultatif :** Moto G24 Power physique, parcours TalkBack complet, mesure formelle du contraste et validation esthétique définitive. La validation physique pourra être reprise au jalon DEV-07. Les écrans ne lisent pas les données : le fonctionnement du moteur et la migration dans cette nouvelle interface Android ne sont donc pas démontrés par ce mandat.

## H. Conclusion

La structure peut servir de base à l'intégration de l'arborescence DEV-05, sous réserve de la validation utilisateur et des limites ci-dessus. DEV-05 n'a pas été commencé.
