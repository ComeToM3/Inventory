# Rapport DEV-08 — Déplacement des nœuds

## Verdict

**VALIDÉ dans le périmètre DEV-08 : parcours sur émulateur Android et protections ciblées vérifiés.**

Aucun problème bloquant connu. Ce verdict ne lève pas la réserve de validation physique du jalon 2 : aucun Moto G24 Power n'était connecté.

## Implémenté

- Action **Déplacer** depuis la fiche, distincte de la modification.
- Sélecteur hiérarchique par niveaux, navigation vers le niveau précédent, chemin complet visible et confirmation explicite. Pour un nœud pouvant contenir, la confirmation précise que tous les descendants suivent.
- Nœud déplacé et sous-arbre inaccessibles comme destinations ; biens simples et nœuds retirés exclus. Le parent actuel n'est pas sélectionnable comme nouvelle destination.
- Retour à la racine proposé seulement pour un emplacement imbriqué. État sans destination, erreurs de lecture avec réessai, annulation et retour sans écriture.
- Actions bloquées pendant le déplacement, erreur compréhensible conservant la destination et possibilité de réessayer.
- Après réussite : fiche relue, branches source/destination actualisées, chemin de destination ouvert sans fermer les branches non concernées ; descendants et cache de leur contenu conservés.

## Choix techniques

- Appel exclusif à **`InventoryEngine.moveNode`**, inchangé. Ses validations et sa transaction restent l'autorité : parent actif compatible, absence de cycle, racines autorisées et conservation des descendants.
- Le sélecteur utilise les lectures du moteur via le coordinateur existant. Son chemin de navigation est un état de présentation, pas une seconde hiérarchie persistante ; il ne modifie pas les ouvertures de l'arbre principal pendant la sélection.
- Les lectures obsolètes du sélecteur sont ignorées. Dans l'arbre, une version de lecture par parent invalide les instantanés antérieurs au déplacement, y compris ceux des racines.
- Après écriture confirmée, l'ancienne relation est retirée du cache et seuls les parents concernés sont relus. Une erreur de relecture reste explicite et ne réintroduit pas un nœud fantôme ni ne présente l'écriture comme échouée.
- Aucun changement de schéma, migration, règle métier ou dépendance ; aucune refonte générale de l'arbre.

## Réellement observé sur Android

Émulateur **Inventory_Moto_G24_API34**, Android 14/API 34. Jeu de neuf nœuds initialisé par le moteur dans une **base SQLite fichier isolée**, sans insertion dans la base normale :

- **Maison → Bureau → Armoire**, contenant **Livres** et **Valise → Carnet**.
- **Atelier → Bureau → Tiroir**. Les deux emplacements nommés Bureau permettent de vérifier l'utilité du chemin complet.

Parcours effectué dans l'interface :

1. Ouverture des deux branches et de leurs contenus avant déplacement.
2. Sélection **Atelier → Bureau → Tiroir** pour Livres ; annulation de la confirmation, avec comparaison SQLite inchangée, puis déplacement confirmé.
3. Vérification du chemin actualisé et des propriétés : description Papier, état Bon, quantité 3, valeur unitaire **12,50 $ CAD**, total **37,50 $ CAD**, catégorie Lecture.
4. Depuis Armoire, constat que son propre sous-arbre n'est pas proposé et que le parent actuel est désactivé. Retour Android hors du sélecteur : aucune écriture.
5. Déplacement d'Armoire vers **Atelier → Bureau**, avec confirmation du déplacement des descendants. Valise et Carnet suivent ; branches source/destination cohérentes et chaque nœud visible une seule fois.
6. Consultation de Carnet : nouveau chemin complet, valeur sentimentale **4 / 5** et catégorie Souvenirs conservées.
7. Arrêt complet du processus puis relance : hiérarchie modifiée retrouvée, neuf lignes et associations identiques à l'instantané enregistré après déplacement.

Comparaison avant/après : mêmes identifiants, propriétés, quantités, valeurs, catégories et relations entre descendants ; seuls les liens parents d'Armoire et de Livres changent, avec la métadonnée de mise à jour prévue par le moteur. `integrity_check = ok`, aucune erreur de clé étrangère.

## Testé automatiquement et vérifications techniques

**12 tests ciblés réussis**, dont quatre nouveaux et un scénario métier étendu :

- Anciennes lectures source/destination et racines retardées, suivies d'échecs de relecture : aucune ancienne relation réintroduite ; réessai sans doublon et sous-arbre conservé.
- Déplacement vers/depuis les racines, branches non concernées et position de défilement conservées.
- Filtrage du sous-arbre, parent actuel, absence de destination et navigation asynchrone obsolète.
- Double confirmation, échec d'écriture sans succès fictif, destination conservée et nouvelle tentative réussie.
- Refus des cycles, parents incompatibles/inactifs et racines interdites ; panne SQLite injectée après mise à jour, avec instantané intégral inchangé.
- Régressions directement concernées de création, consultation et modification DEV-06/07.

Un défaut de l'interface en cours de développement a été reproduit par test : un double appui sur la confirmation pouvait dépiler aussi le sélecteur. La fermeture du dialogue est désormais à réponse unique ; le test vérifie qu'aucun succès n'apparaît avant l'écriture et que le sélecteur reste présent en cas d'échec.

Formatage : aucun écart sur les sept fichiers de code/tests concernés. `flutter analyze --no-pub` : aucune anomalie. Compilation APK Android debug normale : réussie.

## Limites, réserves et nettoyage

- **Bloquants : aucun constaté.**
- Les pannes techniques, doubles confirmations rapides, courses de lectures, transitions racine et défilement long sont vérifiés automatiquement, sans répétition supplémentaire du parcours Android. Aucune campagne exhaustive de volume ni validation de production revendiquée.
- Validation sur téléphone physique non effectuée ; réserve du jalon 2 maintenue.
- Empreinte SHA-256 de la base normale inchangée. APK normal réinstallé sans ouvrir cette base ; base isolée et fichiers temporaires supprimés, émulateur arrêté.

## Fichiers créés ou modifiés

| Responsabilité | Fichiers |
| --- | --- |
| Sélecteur et déplacement | [node_move_controller.dart](../../lib/app/node_move_controller.dart), [node_move_screen.dart](../../lib/app/node_move_screen.dart) |
| Fiche et libellés | [node_details_screen.dart](../../lib/app/node_details_screen.dart), [app_strings.dart](../../lib/app/app_strings.dart) |
| Cohérence des caches | [inventory_tree_controller.dart](../../lib/app/inventory_tree_controller.dart) |
| Tests ciblés | [node_move_test.dart](../../test/app/node_move_test.dart), [inventory_engine_test.dart](../../test/core/domain/inventory_engine_test.dart) |
| Rapport | [rapport-dev-08.md](rapport-dev-08.md) |

Rapports précédents et instructions du projet inchangés pendant ce mandat. **Arrêt après DEV-08. DEV-09 et fonctionnalités ultérieures non commencés.**
