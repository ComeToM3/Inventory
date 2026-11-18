# Rapport DEV-11 — Retrait, historique et suppression

## Verdict

**VALIDÉ SOUS RÉSERVES** : le parcours demandé a été observé sur émulateur Android avec une base SQLite fichier isolée. Les doubles sorties, lectures obsolètes et refus métier ont été vérifiés automatiquement. Aucun appareil physique n’a été utilisé.

## Implémentation

- Action **Retirer de l’inventaire** depuis **Plus d’actions** sur la fiche d’un bien ou bien-contenant : motif obligatoire (perte, don, bris, vente), confirmation distincte, puis appel exclusif à `InventoryEngine.withdrawItem`.
- Action **Supprimer la fiche** distincte, avec avertissement d’irréversibilité, puis `InventoryEngine.deleteNodePermanently`.
- Protection contre les doubles soumissions ; messages d’erreur métier pour contenant non vide, nœud indisponible ou échec d’écriture. Une écriture confirmée n’est jamais présentée comme échouée si seule la relecture pose problème.
- Après sortie confirmée : retrait du cache d’arbre, invalidation des lectures du parent, snackbar de succès et fermeture de la fiche.
- Onglet **Historique** opérationnel via `getWithdrawnItems` : nom, type, motif, date ; états vide, chargement, erreur et réessai.
- Fiche historique en lecture seule, sans `getPath` ni emplacement inventé : propriétés et catégories encore persistées uniquement.
- Aucun changement de schéma, dépendance, restauration de biens retirés ni suppression en cascade.

## Fichiers

- Créés : [inventory_history_controller.dart](../../lib/app/inventory_history_controller.dart), [inventory_history_screen.dart](../../lib/app/inventory_history_screen.dart), [withdrawn_node_details_controller.dart](../../lib/app/withdrawn_node_details_controller.dart), [withdrawn_node_details_screen.dart](../../lib/app/withdrawn_node_details_screen.dart), [inventory_history_test.dart](../../test/app/inventory_history_test.dart).
- Modifiés : [inventory_tree_controller.dart](../../lib/app/inventory_tree_controller.dart), [node_details_controller.dart](../../lib/app/node_details_controller.dart), [node_details_screen.dart](../../lib/app/node_details_screen.dart), [main_navigation_screen.dart](../../lib/app/main_navigation_screen.dart), [app_strings.dart](../../lib/app/app_strings.dart).

## Observé sur Android

Sur l’émulateur **Inventory_Moto_G24_API34**, Android 14, base `inventory_dev11.sqlite` distincte de la base normale :

1. Hiérarchie **Maison → Bureau → Armoire** avec **Lampe**, **Sac → Clé**, **Erreur**, et **Atelier**.
2. Retrait de **Lampe** avec motif **Don** : disparition de l’arbre, snackbar de succès.
3. Historique : **Lampe · Bien · Don · 14/11/2026 14:13** ; fiche historique en lecture seule avec description, quantité et valeur financière conservées, sans chemin ni actions d’édition.
4. Contenant non vide **Sac** : retrait et suppression refusés avec messages explicites ; **Clé** toujours présente.
5. Suppression définitive de **Erreur** : snackbar de succès, absence dans l’arbre et dans la base ; historique inchangé.
6. Arrêt complet puis relance : arbre sans Lampe ni Erreur, Sac/Clé intacts, historique de Lampe conservé. `integrity_check = ok`. Empreinte SHA-256 de `inventory.sqlite` inchangée.

## Tests et vérifications

- **6 tests DEV-11 réussis** : retrait vers historique, suppression sans trace, refus non vide, lectures obsolètes et doubles sorties, annulation UI, refus d’une fiche historique sur nœud actif.
- Régressions ciblées déplacement, recherche et fiches : réussies.
- Formatage sans écart ; `flutter analyze --no-pub` sans anomalie ; APK debug recompilé et réinstallé.

## Réserves et écarts

- **Bloquant constaté dans DEV-11 : aucun.** Validation physique Moto G24 Power et performances sur grand volume restent non vérifiées.
- Restriction conservatrice DEV-03 : un bien déjà retiré n’est pas supprimable définitivement (`nodeInactive`) ; l’interface n’expose la suppression que depuis une fiche active. Conforme aux contrats actuels ; pas d’arbitrage requis pour ce mandat.
- Aucune restauration, recherche dans l’historique ni suppression en masse n’a été ajoutée.

**Arrêt après DEV-11. DEV-12 non commencé.**
