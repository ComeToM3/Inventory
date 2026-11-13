# Rapport DEV-09 — Catégories et valorisations

## Verdict

**VALIDÉ SOUS RÉSERVES** : le parcours demandé a été observé sur émulateur et les protections critiques sont testées. La correction finale du cache et l'action « suivant » du clavier n'ont pas été rejouées sur Android ; la première est couverte par un test automatisé. Aucun téléphone physique n'a été utilisé.

## Implémenté

- Depuis la fiche d'un bien ou bien-contenant : création de catégories, sélection multiple et retrait d'associations. Les catégories existantes restent réutilisables et indépendantes de l'emplacement. Les nouvelles catégories sont des brouillons créés seulement lors de l'enregistrement.
- Formulaire prérempli : montant unitaire CAD converti exactement en cents entiers, total selon la quantité, ou note sentimentale explicite de 1 à 5. Changer de mode efface le brouillon de l'ancien mode ; le retour au financier propose 0 $.
- Annulation avec confirmation si nécessaire, conservation des saisies en cas d'échec, protection contre les doubles soumissions et fiche actualisée après écriture confirmée.

## Choix techniques et fichiers

- [inventory_engine.dart](../../lib/core/domain/inventory_engine.dart) : contrat transactionnel groupé pour propriétés, quantité, valorisation et associations, y compris création des nouvelles catégories. Le couple quantité/valeur **final** est validé ; création, changement de quantité et changement de valorisation refusent également un total hors entier signé 64 bits.
- [node_edit_screen.dart](../../lib/app/node_edit_screen.dart), [node_details_controller.dart](../../lib/app/node_details_controller.dart) et [app_strings.dart](../../lib/app/app_strings.dart) : saisie, validation et coordination sans accès SQLite depuis l'interface.
- [inventory_tree_controller.dart](../../lib/app/inventory_tree_controller.dart) : mise à jour du cache avec le nœud confirmé et invalidation des lectures antérieures, puis relecture de la branche. Un échec de relecture reste distinct d'une écriture réussie.
- Tests : [inventory_engine_test.dart](../../test/core/domain/inventory_engine_test.dart) et [node_details_test.dart](../../test/app/node_details_test.dart). Aucun changement de schéma, migration ou dépendance.

## Observé sur Android

Sur l'émulateur **Inventory_Moto_G24_API34**, Android 14, avec une base SQLite fichier isolée :

1. Création d'un bien, puis de **Lecture** et **Loisirs** dans son formulaire ; les deux apparaissent dans la fiche.
2. Quantité 3, montant unitaire **12,50 $ CAD**, total **37,50 $ CAD** ; réouverture et retrait de l'association Loisirs.
3. Passage à **4 / 5** sentimental : seule Lecture reste affichée et la colonne financière est nulle dans SQLite.
4. Retour au mode financier : **0,00 $ CAD**, sans réapparition de l'ancienne valeur ; la colonne sentimentale est nulle.
5. Création en brouillon d'une autre catégorie, annulation et abandon ; elle n'existe pas dans la base.
6. Arrêt complet et relance : quantité, catégorie Lecture et valeur financière nulle retrouvées dans la fiche. `integrity_check` : `ok` ; aucune violation de clé étrangère.

Le parcours a été effectué avant les deux ajustements finaux précisés dans le verdict ; aucune validation physique n'est revendiquée.

## Tests et vérifications

- **21 tests ciblés réussis**, incluant les régressions directement liées à la création, la fiche et le déplacement.
- Une panne SQLite injectée après insertion d'une association annule aussi les autres modifications, le retrait d'association et la création de catégorie ; instantané intégral inchangé.
- Dépassement refusé à la création, lors de la modification indépendante de quantité ou de montant, et lors de l'enregistrement groupé ; limite exacte et couple final valides acceptés.
- Exclusivité des modes et colonnes inactives nulles ; saisie décimale et limite de cents contrôlées sans flottant.
- Échec d'écriture : saisies et catégories en brouillon conservées, aucune modification persistée ; double soumission bloquée. Échec de relecture après écriture groupée : fiche et cache conservent les valeurs confirmées, erreur de branche explicite.
- Formatage sans écart, `flutter analyze --no-pub` sans anomalie et APK Android debug normal compilé.

## Limites et nettoyage

- **Bloquant constaté dans le périmètre DEV-09 : aucun.** Réserve : ajustements finaux non observés sur Android, comme indiqué au verdict ; tests de panne et double soumission effectués automatiquement, non provoqués sur l'émulateur.
- Écart préexistant à surveiller : la création rapide ne propose pas directement les informations facultatives prévues par l'UX ; catégories et valorisation sont accessibles depuis la fiche après création. La feuille de route situe DEV-09 dans les formulaires de DEV-07.
- Base normale de l'émulateur : empreinte SHA-256 inchangée. APK normal réinstallé sans ouvrir cette base ; base isolée et point d'entrée temporaire supprimés, émulateur arrêté.

**Arrêt après DEV-09. DEV-10 non commencé.**
