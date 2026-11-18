# Rapport de développement — DEV-06

**Verdict : VALIDÉ SOUS RÉSERVES**

La création rapide et la persistance ont été observées sur l'émulateur Android avec une base SQLite isolée. Le téléphone physique et un inventaire utilisateur déjà rempli n'ont pas été vérifiés.

## Réalisations

- Création du premier emplacement depuis l'état vide et d'autres emplacements principaux depuis Inventaire.
- Ajout contextuel dans un emplacement, un contenant ou un bien-contenant. Le bouton principal propose un bien ou un contenant, puis la sélection d'un parent compatible.
- Formulaire limité au type et au nom ; quantité initiale `1` et valeur financière initiale `0 $ CAD` affichées pour les biens. Nom vide refusé, confirmation avant abandon d'une saisie et enregistrement répété empêché.
- Après création confirmée, actualisation des seules racines ou des seuls enfants du parent, ouverture du parent et conservation des autres branches. Les erreurs d'écriture conservent la saisie ; une erreur de relecture reste distincte d'une création réussie et propose un réessai.

`InventoryEngine` reste le seul point de passage pour les écritures. Ses valeurs initiales sont exposées comme constantes partagées avec le formulaire, sans changer les règles métier. Le contrôleur attend les lectures en cours avant l'actualisation et suit les écritures en cours avant la fermeture de la base. Aucun schéma ni dépendance n'a été modifié.

## Parcours Android observé

Sur `Inventory_Moto_G24_API34` (Android 14), avec actions ADB et contrôle de l'interface :

1. Inventaire vide ; un nom vide est refusé et une création annulée après saisie ne laisse aucun nœud.
2. Création de **Maison → Bureau → Armoire → Valise → Livre** : emplacement principal, emplacement imbriqué, contenant, bien-contenant et bien simple.
3. Vérification du parent sélectionné, de l'affichage immédiat, des valeurs initiales et de l'absence d'action d'ajout sur le bien simple.
4. Arrêt complet puis relance : les cinq formes sont retrouvées au bon endroit dans une base SQLite fichier. Relations, valeurs par défaut, intégrité SQLite et clés étrangères ont été contrôlées.

Un test a révélé une perte possible du défilement pendant l'actualisation des racines ; elle a été corrigée. Une vérification Android ciblée avec 24 emplacements supplémentaires isolés a confirmé la conservation de la position visible et des branches ouvertes.

La base privée existante est restée inchangée pendant la démonstration, puis les fichiers de démonstration ont été supprimés. L'APK normal a été installé et lancé : la migration v1 vers v2 déjà prévue en DEV-02 a conservé la donnée technique existante ; aucun nœud de démonstration n'est présent.

## Vérifications et limites

- **Implémenté et compilé :** APK Android debug normal ; aucune nouvelle dépendance.
- **Testé automatiquement :** formatage conforme, `flutter analyze --no-pub` sans anomalie, six tests ciblés réussis, dont un test métier existant. Ils couvrent notamment double soumission, échec d'écriture, lecture concurrente, erreur de rafraîchissement et conservation du défilement. `git diff --check` réussit avec des avertissements de fins de ligne sur deux fichiers préexistants.
- **Observé sur Android :** parcours et persistance décrits ci-dessus ; l'échec d'écriture a été simulé en test automatisé, pas observé sur l'émulateur.
- **Non vérifié :** téléphone physique, inventaire utilisateur non vide et performance à grande échelle.

## Fichiers

- Créés : [`lib/app/inventory_creation_screen.dart`](../../lib/app/inventory_creation_screen.dart), [`test/app/inventory_creation_test.dart`](../../test/app/inventory_creation_test.dart) et ce rapport.
- Modifiés : [`lib/app/app_strings.dart`](../../lib/app/app_strings.dart), [`lib/app/inventory_tree_controller.dart`](../../lib/app/inventory_tree_controller.dart), [`lib/app/inventory_tree_screen.dart`](../../lib/app/inventory_tree_screen.dart), [`lib/app/main_navigation_screen.dart`](../../lib/app/main_navigation_screen.dart), [`lib/core/domain/inventory_engine.dart`](../../lib/core/domain/inventory_engine.dart).

## Réserves et arrêt

- **Bloquant :** aucun constaté dans le périmètre DEV-06.
- **Facultatif :** reprendre le parcours sur le téléphone physique et mesurer les performances sur un inventaire volumineux.

Aucune fonctionnalité DEV-07 ou ultérieure n'a été commencée.
