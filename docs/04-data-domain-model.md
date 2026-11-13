# 04 — Modèle de données et règles métier

## 1. Objectif et périmètre

Ce document définit le modèle persistant et les invariants d'Inventory V1 pour une implémentation Flutter/Dart avec Drift et SQLite. Il complète le [PRD](01-product-requirements.md), la [spécification fonctionnelle](02-functional-specification.md) et l'[architecture technique](03-technical-architecture.md), sans en répéter les parcours.

Le périmètre est une application Android personnelle, locale et hors ligne, avec une seule base SQLite et un seul inventaire. Le modèle ne prévoit ni synchronisation, ni multiappareil, ni photos, ni comptabilité, ni gestion commerciale de stock.

Les éléments décidés dans les documents de référence sont indiqués comme règles. Les détails d'implémentation qui n'y sont pas fixés sont identifiés **Recommandation** ; ils ne changent pas les décisions approuvées.

## 2. Entités et responsabilités

| Entité | Responsabilité |
| --- | --- |
| `inventories` | Identité de l'inventaire local unique. |
| `nodes` | Arbre unifié des emplacements, contenants et biens, avec leur état actif ou retiré. |
| `categories` | Vocabulaire de classement indépendant de la position physique. |
| `node_categories` | Associations plusieurs-à-plusieurs entre biens et catégories. |

Un contenant ordinaire sert à ranger d'autres nœuds, mais n'est pas lui-même un bien valorisé. Un bien-contenant est à la fois un bien (avec quantité et valorisation) et une destination possible pour des enfants.

**Recommandation — types de nœuds :** représenter cette distinction avec `node_type` et en déduire la capacité de contenir, plutôt que stocker un booléen redondant `can_contain`.

| `node_type` | Bien valorisé | Peut contenir | Peut être racine |
| --- | --- | --- | --- |
| `location` (emplacement) | Non | Oui | Oui |
| `container` (contenant) | Non | Oui | Non |
| `item` (bien simple) | Oui | Non | Non |
| `item_container` (bien-contenant) | Oui | Oui | Non |

## 3. Tables, champs et relations

Les types ci-dessous sont les types de stockage SQLite recommandés pour Drift. Les UUID sont conservés comme texte canonique. Les contraintes métier indiquées séparément dans la section 4 ne sont pas toutes exprimables par une contrainte de ligne SQLite.

### 3.1 `inventories`

Cette table est conservée pour donner un périmètre explicite aux nœuds et catégories, conformément à l'aperçu d'architecture. Elle contient exactement un inventaire dans la V1.

| Champ | Type SQLite | Null / défaut | Règle |
| --- | --- | --- | --- |
| `id` | `TEXT` | Non | Clé primaire, UUID. |
| `singleton_key` | `INTEGER` | Non, `1` | Valeur constante `1`, unique ; interdit un deuxième inventaire. |
| `created_at` | `TEXT` | Non | Horodatage UTC ISO 8601. |
| `updated_at` | `TEXT` | Non | Horodatage UTC ISO 8601. |

La ligne d'inventaire est créée à l'initialisation locale. Une suppression ou un remplacement complet de l'inventaire n'est permis que dans le flux contrôlé de restauration.

### 3.2 `nodes`

| Champ | Type SQLite | Null / défaut | Règle |
| --- | --- | --- | --- |
| `id` | `TEXT` | Non | Clé primaire, UUID immuable. |
| `inventory_id` | `TEXT` | Non | Référence à `inventories.id`. |
| `parent_id` | `TEXT` | Oui | Parent dans le même inventaire ; nul seulement pour un emplacement racine actif ou un bien archivé retiré. |
| `name` | `TEXT` | Non | Nom non vide après validation. |
| `node_type` | `TEXT` | Non | Une des quatre valeurs du tableau ci-dessus. |
| `quantity` | `INTEGER` | Requis pour un bien ; recommandation : `1` par défaut | Requis pour `item` et `item_container`, entier strictement positif ; nul pour les autres types. |
| `description` | `TEXT` | Oui | Texte libre facultatif. |
| `condition` | `TEXT` | Oui | Texte libre facultatif ; aucun vocabulaire fermé n'est défini en V1. |
| `value_mode` | `TEXT` | Requis pour un bien ; défaut `financial` | `financial` ou `sentimental` pour un bien ; nul pour `location` et `container`. |
| `financial_value_cents` | `INTEGER` | Selon le mode | Montant financier par unité, en cents CAD ; `0` par défaut en mode financier. Nul en mode sentimental et pour les nœuds non valorisés. |
| `sentimental_value` | `INTEGER` | Selon le mode | Note entière de 1 à 5 en mode sentimental ; nulle en mode financier et pour les nœuds non valorisés. |
| `status` | `TEXT` | Non, `active` | `active` ou `withdrawn`. Un retrait est réservé aux biens. |
| `withdrawal_reason` | `TEXT` | Oui | `loss`, `donation`, `breakage` ou `sale` si retiré ; nul sinon. |
| `withdrawn_at` | `TEXT` | Oui | Horodatage UTC ISO 8601 si retiré ; nul sinon. |
| `created_at` | `TEXT` | Non | Horodatage UTC ISO 8601. |
| `updated_at` | `TEXT` | Non | Horodatage UTC ISO 8601. |

**Recommandation — valeurs persistées :** utiliser les codes ASCII ci-dessus pour les énumérations (`active`/`withdrawn`, `loss`/`donation`/`breakage`/`sale`) et les présenter en français dans l'interface. Les documents approuvent les concepts et motifs, pas leur encodage en base.

`nodes` porte une clé primaire sur `id` et une unicité sur le couple `(inventory_id, id)`. Une clé étrangère composite de `(inventory_id, parent_id)` vers `(inventory_id, id)` empêche qu'un parent appartienne à un autre inventaire. La référence `inventory_id` pointe vers `inventories.id`. La suppression d'un parent référencé doit être refusée (`RESTRICT`), jamais propagée en cascade.

### 3.3 `categories`

| Champ | Type SQLite | Null / défaut | Règle |
| --- | --- | --- | --- |
| `id` | `TEXT` | Non | Clé primaire, UUID immuable. |
| `inventory_id` | `TEXT` | Non | Référence à l'inventaire local. |
| `name` | `TEXT` | Non | Nom non vide après validation. |
| `created_at` | `TEXT` | Non | Horodatage UTC ISO 8601. |
| `updated_at` | `TEXT` | Non | Horodatage UTC ISO 8601. |

Chaque catégorie est propre à l'inventaire et n'a aucune relation avec l'arbre d'emplacements. Une contrainte d'unicité sur `(inventory_id, id)` permet de vérifier les associations composites.

### 3.4 `node_categories`

| Champ | Type SQLite | Null / défaut | Règle |
| --- | --- | --- | --- |
| `inventory_id` | `TEXT` | Non | Inventaire commun aux deux extrémités. |
| `node_id` | `TEXT` | Non | Référence à un nœud du même inventaire. |
| `category_id` | `TEXT` | Non | Référence à une catégorie du même inventaire. |

La clé primaire est `(node_id, category_id)`. Des clés étrangères composites vers `nodes(inventory_id, id)` et `categories(inventory_id, id)` interdisent les associations entre inventaires. La suppression d'un nœud ou d'une catégorie peut supprimer ses seules associations (cascade sur cette table de jointure), sans supprimer l'autre entité.

## 4. Contraintes et invariants

### 4.1 Hiérarchie et intégrité des nœuds

Règles métier :

- Tout nœud actif, sauf un emplacement racine, a exactement un parent existant dans le même inventaire.
- Seul un emplacement actif peut être racine. Les emplacements peuvent également être placés sous un parent valide si l'organisation physique l'exige.
- Un parent actif doit pouvoir contenir des enfants : types `location`, `container` ou `item_container`. Un `item` ne peut jamais être parent.
- Un nœud retiré est un bien seulement ; il n'est plus membre de l'arbre actif et ne peut pas avoir d'enfant ni servir de parent.
- Aucun nœud ne peut être son propre parent ou ancêtre.
- Déplacer un nœud contenant conserve ses descendants : seule sa référence de parent change.
- La hiérarchie active doit être acyclique et chaque chaîne parentale doit atteindre un emplacement racine.

Garanties SQLite recommandées :

- Clés primaires, contraintes `NOT NULL`, unicité des clés composites et clés étrangères activées sur chaque connexion.
- Vérification de ligne interdisant `id = parent_id`.
- Contrôles `CHECK` pour les énumérations, la cohérence des champs de type, les valeurs entières réellement stockées, la quantité positive et les combinaisons de statut/retrait/parent décrites dans les tableaux.
- Clés étrangères composites pour interdire les références inter-inventaires.
- Suppression du parent référencé interdite, sans cascade sur `nodes`.

Validations obligatoires dans la couche domaine Dart :

- Le type du parent permet de contenir et le parent est actif.
- Le nouvel emplacement n'est ni le nœud déplacé ni l'un de ses descendants.
- La chaîne des parents est valide et sans cycle ; le déplacement est refusé si ce n'est pas le cas.
- Les noms ne sont pas vides après normalisation des espaces, y compris les espaces Unicode.
- Le nœud et le parent appartiennent à l'inventaire attendu.

Une contrainte SQLite ordinaire ne peut pas garantir seule l'absence de cycle ni la capacité du parent déterminée par une autre ligne. La couche domaine est le point de passage de toutes les écritures ; des clés étrangères restent le dernier filet de cohérence référentielle.

### 4.2 Catégories

- Seuls `item` et `item_container` peuvent avoir des catégories.
- Un bien peut avoir zéro, une ou plusieurs catégories ; une association identique ne peut apparaître deux fois.
- Un déplacement ne modifie jamais les associations.
- Renommer une catégorie ne modifie ni l'emplacement ni les autres attributs des biens.
- La suppression d'une catégorie supprime ses associations, mais ne touche pas aux biens.
- Le retrait d'un bien conserve ses associations pour préserver les informations archivées. La suppression définitive du bien supprime ses associations.

Les clés étrangères et l'unicité de la table de jointure sont garanties par SQLite. Le contrôle qu'un nœud associé est bien un type de bien nécessite une validation Dart.

**Recommandation :** supprimer une catégorie est permis ; ses liens sont supprimés explicitement par cascade limitée à `node_categories`. Aucun historique de catégories n'est exigé.

### 4.3 Quantités

- `quantity` représente le nombre d'objets interchangeables d'une fiche de bien.
- La quantité est un entier supérieur ou égal à 1 ; une fiche ne représente jamais zéro objet.
- Un objet dont l'identité individuelle importe (par exemple numéro de série ou historique propre) est représenté par une fiche distincte, normalement de quantité 1.
- Les emplacements et contenants qui ne sont pas eux-mêmes des biens n'ont pas de quantité.
- La quantité n'est pas un stock commercial : aucun mouvement de stock, seuil, réservation, réapprovisionnement ou journal de variation n'est modélisé.

La validation SQLite doit vérifier que la quantité est stockée comme un entier et qu'elle est positive (par exemple avec un contrôle de classe de stockage, ou une table SQLite stricte si retenue). Le respect du type de nœud et la décision de créer une fiche séparée pour un objet individuel relèvent du domaine et de l'utilisateur. La valeur initiale `1` est une recommandation pour simplifier la création d'une fiche.

## 5. Valeurs financière et sentimentale

La valorisation s'applique aux biens (`item` et `item_container`), jamais aux emplacements ni aux contenants ordinaires.

| Mode | Valeur persistée | Valeur active | Règle |
| --- | --- | --- | --- |
| `financial` | `financial_value_cents` entier, initialisé à `0` | Montant CAD par unité | Une valeur de zéro est valide ; elle n'indique pas une absence de valeur. |
| `sentimental` | `sentimental_value` entier de 1 à 5 | Note sans texte associé | Aucune note textuelle ou conversion monétaire. |

Invariants garantis par des contraintes de ligne SQLite, en plus de la validation Dart :

- Un bien a exactement un `value_mode`.
- En mode `financial`, le montant entier est présent et la note sentimentale est nulle.
- En mode `sentimental`, la note de 1 à 5 est présente et le montant financier est nul.
- Un nœud non valorisable a ses trois champs de valorisation nuls.
- Un changement de mode met à jour le mode, la nouvelle valeur et l'effacement de l'ancienne valeur dans une seule opération atomique. Aucune ancienne valeur ne reste active ou conservée dans l'autre mode.
- Aucune conversion n'est faite entre les modes.

**Recommandation — précision monétaire :** stocker le montant en cents CAD dans un `INTEGER`, et non en nombre flottant. L'interface convertit le montant saisi en cents après validation de deux décimales au maximum. Cette convention suppose que la précision métier est le cent ; aucun besoin de fractions de cent n'est approuvé.

**Recommandation — borne financière :** refuser les montants négatifs et vérifier que le montant en cents est stocké comme un entier. Les documents approuvés ne définissent pas de borne minimale ; une valeur minimale de zéro est la règle proposée, cohérente avec une valeur patrimoniale et le défaut de 0 $.

Pour un lot financier, `financial_value_cents` est le montant **unitaire**. Le total informatif est calculé comme `quantity × financial_value_cents` et n'est pas persisté, afin d'éviter une valeur dérivée périmée après modification de la quantité ou du montant. Le domaine vérifie que le produit tient dans la plage entière prise en charge avant de l'afficher ; aucun flottant ne doit être utilisé pour le calcul financier.

Le prix unitaire est une recommandation déjà retenue comme convention fonctionnelle dans les documents. Le drapeau `financial_value_is_total` aperçu dans des descriptions antérieures n'est pas nécessaire et est omis : la convention unitaire est unique.

## 6. Retrait et suppression définitive

Ces opérations sont distinctes et ne doivent jamais être confondues.

| Opération | Résultat dans `nodes` | Historique |
| --- | --- | --- |
| Retrait (D07) | La ligne du bien reste, `status` devient `withdrawn`, le motif et la date sont renseignés, `parent_id` devient nul. | Les informations du bien et ses catégories restent conservées ; il n'est plus dans l'arbre actif. |
| Suppression définitive | La ligne est physiquement supprimée. | Aucune ligne de retrait ni trace de suppression n'est créée. Réservée à la correction d'une fiche créée par erreur. |

Motifs de retrait autorisés : perte, don, bris et vente. Un retrait ne crée ni transaction financière ni prix de vente.

**Recommandation de représentation de l'archive :** conserver le nœud retiré dans `nodes` plutôt que créer une table d'historique séparée. Le retrait n'est pas un journal d'événements : la ligne contient l'état final minimal demandé, son motif et sa date. Détacher `parent_id` empêche l'archive de dépendre de l'existence future de son ancien emplacement et libère celui-ci pour une suppression ultérieure. Aucun historique de localisation n'est promis.

Invariants :

- Un nœud `withdrawn` est un bien sans enfant, sans parent, avec un motif autorisé et une date de retrait.
- Un nœud `active` n'a ni motif ni date de retrait.
- Le passage actif → retiré est atomique ; il est refusé si le bien a un enfant.
- Un retrait ne supprime pas la valeur ni les autres informations du bien.
- Un bien retiré est exclu des vues et recherches de l'inventaire actif.
- La suppression définitive ne laisse aucun historique et ne peut pas être exécutée pour une fiche contenant encore un enfant.
- Aucun déplacement automatique, retrait en cascade ou suppression en cascade de nœuds n'est autorisé.

Les contraintes de ligne SQLite peuvent vérifier les combinaisons de statut et de champs de retrait. La vérification qu'un bien n'a aucun enfant doit être effectuée dans la couche domaine, dans la même transaction que le retrait ou la suppression.

**Réconciliation du champ `deleted_at` mentionné dans des aperçus antérieurs :** il est omis. Une suppression définitive supprime la ligne ; conserver `deleted_at` impliquerait de garder une trace, contrairement à D07.

## 7. Opérations transactionnelles

Les écritures métier passent par la couche domaine et une transaction Drift/SQLite. Une transaction qui échoue laisse les données antérieures inchangées.

| Opération | Vérifications et changements atomiques |
| --- | --- |
| Création d'un nœud | Valider le type, le parent, la quantité et le mode de valeur ; créer le nœud et ses associations de catégories. |
| Modification des catégories | Valider que le nœud est un bien ; remplacer ou ajuster ses associations sans toucher au parent. |
| Déplacement | Vérifier les deux nœuds actifs, la capacité du parent, le même inventaire et l'absence de cycle ; mettre à jour uniquement `parent_id`. Les descendants restent rattachés au nœud déplacé. |
| Changement de mode de valeur | Effacer l'ancienne colonne de valeur, renseigner la nouvelle et changer `value_mode` en une seule écriture cohérente. |
| Changement de quantité ou montant | Valider la valeur ; ne stocker aucun total dérivé. L'affichage du total reflète immédiatement le nouveau produit. |
| Retrait | Vérifier le type de bien et l'absence d'enfants ; enregistrer statut, motif et date, puis détacher le parent, sans perdre les autres champs. |
| Suppression définitive | Vérifier l'absence d'enfants ; supprimer la ligne. Les associations de catégories seules sont supprimées par leur clé étrangère en cascade. |
| Suppression de catégorie | Supprimer la catégorie et ses associations, jamais les biens. |
| Restauration | Valider la copie de sauvegarde avant remplacement ; appliquer le remplacement des données en une transaction ou une opération atomique équivalente. |

La clé étrangère auto-référentielle empêche les parents absents et inter-inventaires. Les règles de cycle et de capacité du parent sont validées dans le domaine avant l'écriture et dans la même transaction que le changement.

## 8. Recherche et chemin physique

L'arbre `nodes.parent_id` permet de rechercher les nœuds actifs et de reconstruire leur chemin en remontant les parents jusqu'à l'emplacement racine.

- **Par nom :** rechercher les nœuds actifs selon leur nom ; les résultats de biens affichent leur chemin complet. Les contenants et emplacements peuvent également être retournés lorsqu'ils correspondent.
- **Par catégorie :** joindre `node_categories` et `categories`, limiter les résultats aux biens actifs et dédupliquer les nœuds.
- **Par emplacement :** sélectionner les descendants actifs de l'emplacement choisi, directement ou à n'importe quelle profondeur.
- **Chemin :** présenter les noms depuis l'emplacement racine jusqu'au nœud cible, par exemple `Appartement → Bureau → Armoire → Boîte → Câbles`.
- **Retraits :** toutes les recherches de l'inventaire actif filtrent `status = active`. Les éléments retirés restent dans la base pour l'historique, mais ne figurent pas dans les résultats actifs.

La traversée récursive peut être réalisée par une requête récursive SQLite/Drift ou par plusieurs lectures de parents. Aucune table de chemin dénormalisée n'est nécessaire. L'accentuation, la sensibilité à la casse, les jokers et l'indexation plein texte ne sont pas spécifiés ; une recherche de nom simple, adaptée à un inventaire personnel local, suffit pour la V1.

## 9. Sauvegarde et restauration : exigences du modèle

Une exportation complète doit préserver les lignes de `inventories`, `nodes`, `categories` et `node_categories`, y compris les biens retirés, leurs valeurs, leurs motifs et dates de retrait. Les identifiants doivent être conservés afin que toutes les relations puissent être reconstituées.

Avant qu'une restauration remplace les données actives, les données importées doivent être vérifiées au minimum pour :

- l'unicité des identifiants et la présence de l'unique inventaire ;
- la résolution de toutes les références et l'absence de références inter-inventaires ;
- l'existence des parents, la validité des racines et l'absence de cycle ;
- la compatibilité des types parent/enfant et l'absence d'enfants sous un bien simple ou retiré ;
- l'intégrité des associations de catégories ;
- la validité des quantités, des modes et des valeurs, ainsi que des champs de retrait ;
- l'intégrité SQLite après chargement.

**Recommandation conforme à l'architecture :** charger et valider la sauvegarde dans une base temporaire séparée, puis remplacer les données actives dans une transaction qui peut être annulée. Si une validation ou une écriture échoue, l'inventaire actif antérieur reste utilisable et inchangé. Le format d'archive, le manifeste, l'interface et la mécanique concrète de remplacement sont hors du présent mandat.

## 10. Garanties SQLite et responsabilités Dart — synthèse

| Garantie | SQLite | Couche domaine Dart |
| --- | --- | --- |
| Identifiants, unicité des associations, références existantes | Clés primaires, uniques et étrangères activées | Génération et format UUID canonique |
| Un seul inventaire | Clé unique `singleton_key` et contrôle de ligne | Création initiale et maintien de la ligne |
| Quantité positive et colonnes de valeur cohérentes avec le mode | `CHECK` de ligne, y compris classe de stockage entière | Validation des saisies et changement atomique de mode |
| Motif/date compatibles avec le statut | `CHECK` sur la ligne | Choix du motif et opération complète de retrait |
| Parent du même inventaire et parent existant | Clé étrangère composite | Vérification du parent actif et de sa capacité |
| Nœud sans auto-parent | `CHECK` de ligne | Validation de l'opération |
| Aucune boucle et chemin aboutissant à une racine | Non garanti par les seules clés étrangères | Vérification récursive lors des déplacements et restauration |
| Pas de retrait/suppression d'un contenant non vide | Non garanti par une contrainte de ligne | Vérification des enfants dans la transaction |
| Catégories réservées aux biens | Les références sont vérifiées | Validation du type du nœud avant association |
| Recherche sans biens retirés | Filtre de requête | Toutes les voies de recherche appliquent le filtre actif |

Les contraintes SQLite doivent être activées sur chaque connexion. Toute restauration doit également exécuter les contrôles d'intégrité SQLite et les validations métier de l'arbre avant de rendre les données actives.
