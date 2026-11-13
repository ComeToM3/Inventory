# 04 — Validation utilisateur

Statut des informations : **Confirmé** = décidé dans le blueprint · **Recommandation** = proposition à valider · **Ouvert** = à trancher.

Ce document définit un nombre limité de scénarios observables permettant de vérifier que l'application Android fonctionne réellement, du point de vue de l'utilisateur. Les tests automatisés pourront compléter ces scénarios, mais ne les remplacent pas : la preuve de fonctionnement vient d'une démonstration réelle dans l'interface, sur un appareil Android.

**Recentrage V1 :** tous les scénarios de synchronisation entre appareils ont été retirés ; la V1 ne concerne qu'un seul appareil Android, hors ligne.

## Scénario 1 — Mise en place de l'inventaire

**Objectif :** vérifier la création d'emplacements, de contenants imbriqués et de biens classés et quantifiés.

1. Créer plusieurs emplacements (ex. Appartement, Bureau).
2. Créer des contenants imbriqués sur au moins deux niveaux (ex. Armoire → Boîte électronique).
3. Ajouter des biens dans ces contenants, avec une catégorie et, pour certains, une quantité supérieure à 1.

**Résultat attendu :** l'arborescence reflète exactement les emplacements, contenants et biens créés, avec leurs catégories et quantités.

## Scénario 2 — Valeur financière et sentimentale

**Objectif :** vérifier que les deux modes de valorisation sont mutuellement exclusifs et que 0 $ est une valeur valide.

1. Sur un bien, conserver le mode financier par défaut et vérifier qu'il affiche 0 $.
2. Modifier librement ce montant financier.
3. Faire passer le même bien en mode sentimental (note de 1 à 5).
4. Vérifier que l'ancien montant financier n'est plus actif ni comptabilisé.
5. Faire passer un autre bien en mode sentimental dès sa création.

**Résultat attendu :** un bien n'affiche jamais les deux modes en même temps ; 0 $ est affiché normalement, sans distinction « non renseigné » ; aucune valeur n'est convertie dans l'autre mode ; le changement de mode ne conserve pas l'ancienne valeur.

## Scénario 3 — Déplacement, retrait et protections

**Objectif :** vérifier que les déplacements fonctionnent, que les opérations invalides sont refusées, et que le retrait/la suppression d'un bien fonctionnent correctement.

1. Déplacer un contenant imbriqué vers un nouvel emplacement.
2. Tenter de déplacer un contenant à l'intérieur de l'un de ses propres descendants (boucle hiérarchique).
3. Retirer un bien de l'inventaire actif en choisissant un motif (perte, don, bris ou vente).
4. Supprimer définitivement un bien créé par erreur.
5. Tenter de retirer, puis de supprimer, un contenant qui contient encore au moins un bien.

**Résultat attendu :** le déplacement valide conserve tout le contenu du contenant déplacé ; la boucle hiérarchique est refusée sans modification des données ; le bien retiré disparaît de l'inventaire actif sans supprimer son historique minimal ; le bien supprimé définitivement ne laisse aucune trace ; le retrait et la suppression du contenant non vide sont bloqués tant que son contenu n'a pas été traité explicitement.

## Scénario 4 — Recherche

**Objectif :** vérifier que la recherche retrouve un bien et son emplacement exact.

1. Rechercher un bien par son nom.
2. Rechercher le même bien par sa catégorie.

**Résultat attendu :** les deux recherches retrouvent le bien et affichent son chemin physique complet jusqu'à son emplacement actuel.

## Scénario 5 — Persistance après fermeture

**Objectif :** vérifier qu'aucune donnée n'est perdue après un redémarrage de l'application.

1. Fermer complètement l'application après les scénarios précédents.
2. Rouvrir l'application.

**Résultat attendu :** l'inventaire, les catégories, les emplacements et les valeurs financières/sentimentales sont intacts.

## Scénario 6 — Sauvegarde et restauration

**Objectif :** vérifier qu'une sauvegarde est réellement exploitable.

1. Exporter une sauvegarde de l'inventaire.
2. Installer l'application sur un appareil Android propre (ou réinitialisé).
3. Restaurer la sauvegarde.

**Résultat attendu :** l'inventaire restauré (biens, catégories, contenants, valeurs) correspond exactement à celui exporté, et l'application reste utilisable ensuite.

## Synthèse — Critères de livraison de la V1

| # | Critère |
| --- | --- |
| 1 | L'application fonctionne réellement sur Android |
| 2 | Les biens et contenants persistent après fermeture |
| 3 | Les contenants peuvent être imbriqués sur plusieurs niveaux |
| 4 | Les déplacements conservent tous les descendants |
| 5 | La recherche retrouve un objet et son chemin complet |
| 6 | La valeur financière (y compris 0 $) et la valeur sentimentale sont mutuellement exclusives, saisies et modifiées sans conversion entre elles |
| 7 | Un déplacement invalide (boucle), le retrait ou la suppression d'un contenant non vide sont refusés |
| 8 | Un bien peut être retiré (avec motif) ou supprimé définitivement sans affecter le reste de l'inventaire |
| 9 | Une sauvegarde peut être restaurée sur une installation Android propre |

## Points nécessitant une décision

Aucun point ouvert restant pour ce document.
