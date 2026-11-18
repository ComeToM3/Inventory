# Rapport de développement — DEV-03

**Mise à jour :** 13 novembre 2026
**Statut :** implémentation terminée, soumise à l'analyse utilisateur
**Verdict : VALIDÉ SOUS RÉSERVES**

## A. Verdict

Le moteur métier local est implémenté au-dessus du schéma DEV-02 et ses invariants sont **testés automatiquement** sur une vraie base SQLite fichier via Drift. Aucune interface n'utilise encore le moteur : rien n'est **observé sur Android réel** pour ce mandat. Trois choix conservateurs non tranchés explicitement par les documents (section H) sont soumis à arbitrage. D'où le verdict **VALIDÉ SOUS RÉSERVES**.

## B. Architecture

Couche domaine créée dans `lib/core/domain/`, séparée de l'interface Flutter (aucun import Flutter) :

| Fichier | Responsabilité |
| --- | --- |
| `inventory_models.dart` | Modèles Dart purs : `NodeType` (capacité de contenir, bien, racine admise), `NodeStatus`, `WithdrawalReason`, valorisation scellée `FinancialValuation`/`SentimentalValuation`, `InventoryNode` (dont le total financier calculé), `InventoryCategory`. |
| `inventory_exception.dart` | `InventoryException` portant un `InventoryErrorCode` exploitable par l'interface. La cause technique est conservée pour le diagnostic local, mais `toString()` ne l'expose pas (pas de SQL ni de donnée personnelle, cf. `07-security-privacy.md` §9). |
| `inventory_engine.dart` | `InventoryEngine`, point de passage unique des opérations métier : validations, transactions, conversion des lignes Drift en modèles du domaine et des erreurs SQLite en erreurs métier. |
| `uuid_generator.dart` | Génération d'UUID v4 via `Random.secure()`, sans dépendance ajoutée. |

Pas de repository multiple ni d'abstraction générique. Horloge et générateur d'identifiants sont injectables, uniquement pour des tests déterministes. Riverpod n'est pas introduit : aucune interface ne consomme encore le moteur.

## C. Opérations métier

- **Consultation :** `getNode`, `getRootLocations`, `getChildren` (enfants directs actifs), `getAncestors` et `getPath` (racine → nœud), `getWithdrawnItems` (historique minimal, sans interface).
- **Création :** `createNode` pour les quatre types ; seul un emplacement peut être racine. Pour les biens : quantité `1` et valeur financière `0 $` par défaut ; associations de catégories facultatives dans la même transaction.
- **Modification :** `updateDetails` (nom, description, état, valables pour tous les types), `updateQuantity` (biens uniquement), `setValuation` (bascule exclusive de mode).
- **Déplacement :** `moveNode` modifie uniquement `parent_id` ; descendants et associations suivent sans être réécrits. Un emplacement peut redevenir racine.
- **Catégories :** `createCategory`, `renameCategory`, `deleteCategory` (associations seules supprimées), `getCategories`, `getNodeCategories`, `assignCategory`, `unassignCategory`.
- **Sortie d'inventaire :** `withdrawItem` (perte, don, bris, vente ; date ; parent détaché ; informations, valeur et catégories conservées) et `deleteNodePermanently` (aucune trace ; associations supprimées par cascade).

Normalisation : noms rognés et refusés s'ils sont vides, y compris avec des espaces Unicode ; description/état vides enregistrés à `NULL`. Aucune recherche, aucun stock, aucune comptabilité n'a été ajouté.

## D. Invariants

Appliqués par le moteur, en complément des contraintes DEV-02 :

1. Inventaire unique : chaque opération lit l'inventaire existant ; parent et catégories doivent lui appartenir (`inventoryMismatch`, `categoryNotFound`).
2. Parent requis sauf pour un emplacement racine (`parentRequired`).
3. Parent existant, actif et capable de contenir : `location`, `container`, `item_container` (`parentNotFound`, `parentInactive`, `parentCannotContain`).
4. Auto-parent et cycles indirects refusés avant toute écriture (`cycleDetected`).
5. Chaîne existante du parent vérifiée jusqu'à une racine `location` active, avec détection de boucle, sans profondeur maximale (`invalidHierarchy`).
6. Quantité entière ≥ 1, seulement pour les biens (`invalidQuantity`, `requiresItem`).
7. Valorisation unique : financière en cents ≥ 0, ou sentimentale de 1 à 5 ; le changement de mode efface l'ancienne colonne dans la même écriture (`invalidFinancialValue`, `invalidSentimentalValue`).
8. Total = quantité × montant unitaire, en entier ; dépassement 64 bits signalé (`financialTotalOverflow`), jamais arrondi.
9. Catégories réservées à `item` et `item_container` ; doublon et retrait d'une association absente signalés.
10. D02 : retrait ou suppression d'un nœud ayant un enfant refusé (`nodeHasChildren`), sans déplacement automatique ni cascade de nœuds.
11. D07 : retrait réservé aux biens ; un nœud retiré n'apparaît plus dans les consultations actives et ne peut plus être modifié, déplacé ni recevoir d'enfant.

Limites : le moteur fait confiance au schéma pour l'appartenance à l'unique inventaire (une seule ligne garantie par `singleton_key`). Les validations s'appliquent uniquement aux écritures passant par le moteur ; un accès SQL direct pourrait les contourner, d'où la règle d'architecture du point de passage unique. Le tri par nom suit l'ordre binaire SQLite (`É` après `O`) ; le tri localisé n'est pas spécifié et relève de l'affichage.

## E. Transactions

Chaque opération publique s'exécute dans une seule transaction Drift (lectures incluses, pour obtenir une vue cohérente). Les validations précèdent les écritures. Une erreur métier ou SQLite provoque le rollback complet. Les `SqliteException` deviennent `constraintViolation` (code 19) ou `storageFailure` ; un échec de rollback devient `storageFailure`. Aucune erreur n'est absorbée et les clés étrangères ne sont jamais désactivées.

Scénarios démontrés :

- Création avec une catégorie valide puis une absente : le nœud et la première association, déjà insérés, sont annulés.
- Collision forcée d'identifiant : la contrainte SQLite est convertie en `constraintViolation` et la base reste identique.
- Déplacements, retraits et suppressions invalides : instantané complet des tables identique avant et après.

## F. Tests

`test/core/domain/inventory_engine_test.dart` — 7 scénarios séquentiels sur base SQLite fichier temporaire :

1. Quatre types, hiérarchie de 6 niveaux, chemin, ancêtres, racines, enfants ; refus de racine non-emplacement, de parent `item`, de parent absent, de nom vide et de quantité sur un emplacement.
2. Déplacement d'une étagère avec sac, pochette et chargeur ; descendants et catégorie préservés ; auto-parent, cycle indirect et racine sous descendant refusés ; parent `item` et parent retiré refusés ; nœud retiré non déplaçable ; base inchangée ; emplacement replacé en racine.
3. Lot `4 × 12,50 $ = 50,00 $`, quantité modifiée à 3 → `37,50 $` ; quantités 0 et −1 refusées ; financier → sentimental → financier avec vérification des colonnes SQLite ; notes 0 et 6 et montant négatif refusés ; dépassement du total signalé ; propriétés générales modifiées sans déplacement.
4. Catégories multiples, doublon refusé, types interdits refusés, renommage sans déplacement, désassociation, suppression de catégorie sans suppression du bien.
5. Contenant et bien-contenant non vides : suppression/retrait refusés sans modification ; retrait d'un bien sentimental avec motif, date, nom, valeur et catégorie conservés ; exclusion des enfants actifs ; opérations sur nœud retiré refusées ; retrait du bien-contenant vidé puis suppression du contenant vide ; suppression définitive sans trace ni association résiduelle.
6. Rollback des opérations composées (section E).
7. Fermeture puis réouverture : chemin, quantité, total, catégorie, enfants actifs et historique de retrait retrouvés.

Résultats exécutés :

- `dart format lib test` — conforme.
- `flutter analyze` — aucun problème.
- `flutter test test\core` — **11 tests réussis** : 4 DEV-02 inchangés et 7 DEV-03.
- Premier passage : un échec réel sur l'ordre attendu des catégories (« Électronique » trié après « Outillage » en ordre binaire). Ce test fixait un tri non spécifié ; l'assertion est devenue indépendante de l'ordre, sans modifier le moteur.
- `git diff --check` — aucune erreur.
- Aucune génération Drift : le schéma n'a pas changé.

## G. Modifications

Créés :

- `lib/core/domain/inventory_engine.dart`
- `lib/core/domain/inventory_models.dart`
- `lib/core/domain/inventory_exception.dart`
- `lib/core/domain/uuid_generator.dart`
- `test/core/domain/inventory_engine_test.dart`
- `docs/rapport/rapport-dev-03.md`

Aucune dépendance ajoutée. Le schéma, les migrations, la table technique DEV-01 et les rapports DEV-01/DEV-02 n'ont pas été modifiés. Aucune lacune du schéma n'a empêché un invariant ; aucune migration n'a été nécessaire.

État Git : branche `main`, rien d'indexé, aucun commit ni push. Les changements DEV-02, encore non commités, coexistent dans l'arbre de travail avec les fichiers DEV-03, qui sont tous nouveaux.

## H. Réserves

Choix conservateurs sur des points non explicitement tranchés, soumis à arbitrage :

1. **Bien retiré non supprimable définitivement :** refus (`nodeInactive`) pour préserver l'historique D07. Les documents réservent la suppression aux fiches créées par erreur, sans traiter les fiches déjà retirées.
2. **Bien retiré non modifiable :** l'archive est figée (pas de nouvelle catégorie, quantité, valeur ou réactivation). Aucune réactivation n'est spécifiée.
3. **Type de nœud immuable :** aucune opération de conversion, par exemple de bien simple en bien-contenant, n'est spécifiée ; elle n'a pas été inventée.

Autres points :

- Placements permis selon `04-data-domain-model.md` §4.1 : tout type sous tout parent capable de contenir, y compris un emplacement sous un contenant. Aucune restriction supplémentaire n'a été inventée.
- Unicité des noms de catégorie non imposée, conformément au modèle qui ne la définit pas.
- Chemin reconstruit par lectures successives des parents : adapté à un inventaire personnel, non mesuré sur un très grand volume.
- Recherche par nom, catégorie et emplacement non implémentée : elle n'est pas dans le périmètre DEV-03.
- Facultatif : tri localisé côté interface ; opération de remplacement groupé des catégories si un formulaire DEV-06/07 l'exige.

Aucun bloquant connu.

## I. Validation réelle

| Élément | Classement |
| --- | --- |
| Règles, transactions, rollback et persistance via Drift sur SQLite natif de l'hôte Windows | **Testé automatiquement** |
| Compilation de la couche domaine | **Analysée** sans erreur. Aucun APK reconstruit : le moteur n'est encore importé par aucun écran. |
| Comportement du moteur dans l'application Android, émulateur ou Moto G24 Power | **Non vérifié** |

Les réserves DEV-01 (validation physique Moto G24 Power, build 32 bits) restent ouvertes.

## J. Conclusion

Le moteur est suffisamment cohérent pour être intégré aux futures interfaces. Ses opérations sont typées, transactionnelles et testées sur une vraie base SQLite, et ses erreurs sont identifiables. Cela ne valide aucune interface ni parcours Android. Les trois choix de la section H doivent être confirmés ou corrigés. DEV-04 n'a pas commencé ; aucun commit ni push n'a été effectué.
