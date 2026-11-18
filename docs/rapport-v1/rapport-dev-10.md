# Rapport DEV-10 — Recherche et filtres

## Verdict

**VALIDÉ SOUS RÉSERVES** : le parcours demandé a été observé sur émulateur Android avec une base persistante isolée. Les réponses obsolètes et les erreurs de lecture ont été vérifiées automatiquement, pas provoquées sur l'émulateur. Aucun appareil physique n'a été utilisé.

## Implémentation

- Recherche partielle par nom sur les nœuds actifs persistés, sans distinction de casse ; les accents restent significatifs et `%` et `_` sont traités littéralement.
- Filtres combinables par type, une catégorie et branche hiérarchique, avec réinitialisation. La branche comprend ses descendants actifs, pas le nœud choisi lui-même.
- Résultats dédupliqués avec nom, type et chemin complet. Ouverture de la fiche existante, conservation des critères au retour et relecture après consultation.
- Contrat `InventoryEngine.searchNodes` transactionnel : sélection SQLite, `EXISTS` pour la catégorie et requêtes récursives pour descendants et chemins. Une hiérarchie invalide produit une erreur explicite.
- Temporisation de la saisie et invalidation des réponses obsolètes. Les erreurs proposent un nouvel essai. Un déplacement depuis Recherche ne développe pas les branches de l'onglet Inventaire.
- Aucun changement de schéma ni ajout de dépendance.

## Fichiers

- Créés : [inventory_search_controller.dart](../../lib/app/inventory_search_controller.dart), [inventory_search_screen.dart](../../lib/app/inventory_search_screen.dart) et [inventory_search_test.dart](../../test/app/inventory_search_test.dart).
- Modifiés : [inventory_models.dart](../../lib/core/domain/inventory_models.dart), [inventory_engine.dart](../../lib/core/domain/inventory_engine.dart), [inventory_tree_controller.dart](../../lib/app/inventory_tree_controller.dart), [main_navigation_screen.dart](../../lib/app/main_navigation_screen.dart), [node_details_screen.dart](../../lib/app/node_details_screen.dart), [node_move_screen.dart](../../lib/app/node_move_screen.dart), [node_move_controller.dart](../../lib/app/node_move_controller.dart), [app_strings.dart](../../lib/app/app_strings.dart) et [inventory_engine_test.dart](../../test/core/domain/inventory_engine_test.dart).

## Observé sur Android

Sur l'émulateur **Inventory_Moto_G24_API34**, Android 14, avec une base SQLite fichier distincte de la base normale :

1. `LAM` retrouve deux biens **Lampe**, distingués par les chemins **Maison → Bureau → Armoire → Lampe** et **Atelier → Bureau → Étagère → Lampe** ; la lampe retirée n'apparaît pas.
2. Les filtres **Bien**, **Éclairage** et **Maison → Bureau → Armoire** combinés réduisent les résultats à une lampe, malgré ses deux catégories.
3. Ouverture de la fiche, retour avec critères conservés, puis déplacement vers **Atelier** depuis Recherche. Au retour, le filtre de branche ne trouve plus cette lampe ; la réinitialisation montre les deux lampes et le nouveau chemin **Atelier → Lampe**.
4. L'état sans résultat et l'effacement de la requête ont été observés. Dans Inventaire, **Maison** reste développée et **Atelier** fermée après le déplacement.
5. Après arrêt complet et relance, la recherche retrouve les deux lampes et le chemin modifié. `integrity_check` renvoie `ok` et `foreign_key_check` ne signale aucune violation.

Une recherche de démonstration portant sur **200 résultats** a pris **87 ms** en debug sur cet émulateur ; il s'agit d'une mesure ponctuelle, pas d'une garantie de performance.

## Tests et vérifications

- **20 tests ciblés réussis**, incluant les tests du moteur, de la recherche, des fiches et des déplacements.
- Requêtes combinées, casse accentuée, caractères littéraux, retrait, absence de doublon, branche profonde, déplacement, persistance et cycle invalide vérifiés automatiquement.
- Réponses et erreurs obsolètes ignorées ; échec de lecture et nouvel essai testés. Un test de navigation couvre le déplacement, le maintien du défilement et des branches, ainsi qu'un résultat devenu indisponible.
- Formatage sans écart ; `flutter analyze --no-pub` sans anomalie ; APK Android debug normal compilé.
- APK normal réinstallé sans ouvrir la base normale ; son empreinte SHA-256 est restée inchangée. Base et fichiers temporaires de démonstration supprimés, émulateur arrêté.

## Réserves et écarts

- **Bloquant constaté dans DEV-10 : aucun.** Le fonctionnement sur appareil Android physique et les performances sur un inventaire beaucoup plus volumineux restent non vérifiés.
- La sélection porte sur une catégorie à la fois, conformément au filtre par catégorie documenté ; les biens peuvent toujours appartenir à plusieurs catégories. Aucune recherche dans l'historique n'a été ajoutée.
- Aucun écart bloquant aux spécifications identifié. Les tests de panne et de concurrence complètent l'observation sur émulateur sans s'y substituer.

**Arrêt après DEV-10. DEV-11 non commencé.**
