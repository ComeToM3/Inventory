# Rapport de développement — DEV-02

**Statut :** implémentation terminée, prête à être soumise à la validation utilisateur  
**Verdict : VALIDÉ SOUS RÉSERVES**

## A. Verdict

Le schéma SQLite/Drift DEV-02 est implémenté et les vérifications automatisées ciblées sont réussies. Le verdict reste **VALIDÉ SOUS RÉSERVES** : l'APK Android a été compilé, mais aucune installation ni observation sur émulateur ou appareil physique n'a été effectuée pendant ce mandat. La validation physique reportée en DEV-01 reste ouverte.

Ce verdict ne clôt pas DEV-03 et ne prétend pas que les parcours ou règles métier qui lui sont réservés sont implémentés.

## B. Modèle implémenté

- `inventories` : identifiant texte, clé singleton égale à `1`, dates de création et de mise à jour. Une ligne est créée à l'initialisation.
- `nodes` : identifiant, inventaire, parent nullable, nom, type, quantité, description, état, mode et valeurs financières/sentimentales, statut, motif/date de retrait, dates de création et de mise à jour.
- `categories` : identifiant, inventaire, nom et dates de création et de mise à jour.
- `node_categories` : association entre un nœud et une catégorie avec l'identifiant d'inventaire commun.

Les montants sont enregistrés en cents CAD dans un entier; le montant financier est unitaire. Les catégories ne sont pas associées aux emplacements par la hiérarchie. Les contraintes d'unicité ne dépassent pas celles prévues par le modèle de domaine.

Index créés : `(inventory_id, parent_id)` sur les nœuds, `(inventory_id, status, name)` pour les recherches simples de nœuds actifs et `(inventory_id, category_id)` sur les associations.

## C. Intégrité

SQLite garantit les clés primaires et étrangères, l'unicité singleton, les références composites à l'intérieur d'un même inventaire, l'absence d'auto-parent, les domaines des énumérations, les quantités positives entières, l'exclusivité des champs de valeur et la cohérence des champs de retrait. La suppression d'un parent référencé est restreinte; la suppression d'un nœud ou d'une catégorie ne cascade que vers les associations. Les clés étrangères sont activées à l'ouverture.

Les clés étrangères composites couvrent les références parent-enfant et nœud-catégorie. La V1 n'autorisant qu'un inventaire, le test n'a pas construit un second inventaire valide; les références vers un inventaire inexistant et vers un parent inexistant sont refusées par SQLite.

Restent au moteur métier DEV-03 : cycles et chemins jusqu'à une racine, capacité et statut du parent, restriction des catégories aux biens, opérations de déplacement, retrait ou suppression atomiques, protection métier d'un contenant non vide et filtrage systématique des résultats actifs.

## D. Migrations

La version du schéma passe de 1 à 2. La migration crée les quatre tables, leurs index et l'inventaire local sans supprimer ni recréer `local_verification_entries`. Le test ouvre un véritable fichier SQLite préparé au format version 1 avec une valeur de vérification, vérifie cette valeur après migration, vérifie la version 2 et confirme la persistance après réouverture.

La génération Drift s'est achevée avec succès. L'option `--delete-conflicting-outputs` a émis un avertissement indiquant qu'elle est ignorée par cette version de l'outil; la génération a néanmoins terminé correctement.

## E. Transactions

Le test ciblé provoque une violation de clé primaire après une première insertion valide dans une transaction. L'erreur SQLite est propagée et l'insertion précédente est annulée. Les transactions métier complètes (création avec associations, déplacement, retrait, restauration) demeurent hors périmètre et sont réservées aux couches ultérieures.

## F. Tests et preuves

- Génération : `dart run build_runner build --delete-conflicting-outputs` — réussie.
- Formatage Dart : réussi; vérification `--set-exit-if-changed` sans modification additionnelle.
- `flutter analyze` — aucune anomalie.
- `flutter test test\core\database\inventory_database_test.dart` — 4 tests réussis : persistance après réouvertures, relations et contraintes SQLite, rollback transactionnel, migration depuis une base v1 préremplie.
- `flutter build apk --debug` — réussi.
- `git diff --check` — aucune erreur d'espacement.
- Installation ou observation sur Android : non réalisée pendant DEV-02. Le build réussi n'est pas une preuve d'exécution sur appareil.

## G. Modifications

- `.github/copilot-instructions.md` : ajout de la règle permanente « un mandat = un rapport distinct ».
- `lib/core/database/inventory_database.dart` : tables, contraintes, index, version 2 et migration non destructive; conservation de la table technique DEV-01.
- `lib/core/database/inventory_database.g.dart` : génération Drift.
- `test/core/database/inventory_database_test.dart` : tests SQLite/Drift réels, dont migration et rollback.
- `docs/rapport/rapport-dev-02.md` : présent rapport.

Aucune dépendance n'a été ajoutée ou modifiée.

## H. Réserves

- La validation Android réelle reste non vérifiée; aucune validation physique nouvelle n'était demandée pour DEV-02.
- Les règles métier identifiées en section C ne sont pas garanties par le schéma seul et doivent être appliquées par DEV-03 avant toute exposition d'opérations métier.
- La règle de protection d'un contenant non vide ne peut pas être garantie par les seules contraintes de ligne actuelles.
- Aucune compilation Android 32 bits ni test sur Moto G24 Power n'a été effectué.

## I. État Git

Branche active : `main`. Aucun changement n'a été indexé. Fichiers modifiés : les quatre fichiers listés en section G. Aucun commit ni push n'a été créé ou tenté, conformément au mandat. Les avertissements Git de conversion de fins de ligne concernent uniquement le fichier Drift généré et n'ont pas empêché `git diff --check`.

## J. Conclusion

DEV-02 est prêt à être soumis à la validation utilisateur pour le périmètre du modèle persistant. Les vérifications automatisées et la compilation Android réussissent; l'exécution réelle sur appareil reste **non vérifiée**. DEV-03 n'a pas commencé. Aucun commit ni push n'a été effectué.
