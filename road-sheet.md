# Inventory V1 — Feuille de route complète du développement

Je propose 15 mandats de développement, de DEV-01 à DEV-15, organisés en cinq phases, jusqu'à la livraison de la V1 Android.

L'objectif est de conserver un ordre logique : construire d'abord une base fiable, rendre ensuite l'inventaire réellement utilisable, ajouter les fonctions complémentaires, puis sécuriser les données et préparer la distribution.

Cette feuille de route est la séquence directrice actuelle DEV-01 à DEV-15. Les anciens plans de cinq mandats conservés dans [blueprint.md](blueprint.md) sont remplacés et ne doivent pas être suivis pour la V1.

Préparation documentaire

Terminée

Développement

À démarrer — DEV-01

## Vue d'ensemble des cinq phases

1

Fondations techniques

DEV-01 à 03

Application Android, base locale et règles métier

2

Inventaire utilisable

DEV-04 à 07

Arborescence, création, consultation et modifications

3

Fonctions métier complètes

DEV-08 à 11

Déplacements, catégories, recherche et retraits

4

Protection des données

DEV-12 à 13

Sauvegarde, restauration et récupération

5

Validation et livraison

DEV-14 à 15

Parcours réels, corrections bloquantes et APK de production

## Phase 1 — Fondations techniques

| Mandat                         | Objectif et résultat attendu                                                                                                                                                                     |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DEV-01 — Socle Flutter Android | Créer et exécuter l'application sur un téléphone Android. Configurer Flutter, Drift/SQLite et le stockage privé; choisir puis configurer `minSdkVersion` et `targetSdkVersion` uniquement après approbation. Vérifier la persistance après redémarrage. |
| DEV-02 — Modèle de données     | Implémenter les tables `inventories`, `nodes`, `categories`, `node_categories`, les contraintes, les migrations et les transactions.                                                             |
| DEV-03 — Moteur métier         | Implémenter les règles de hiérarchie, quantités, valorisations, catégories, retrait et suppression. Tester les invariants, notamment l'interdiction des cycles et la protection des descendants. |

Jalon 1 : le moteur local peut créer, retrouver et modifier des données cohérentes, même si l'interface utilisateur reste minimale.

## Phase 2 — Inventaire utilisable

| Mandat                                    | Objectif et résultat attendu                                                                                                                                                   |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| DEV-04 — Structure visuelle et navigation | Créer les écrans Inventaire, Recherche, Historique et Paramètres, ainsi que la navigation principale. La palette et le thème restent ouverts comme indiqué dans [docs/06-ux-ui.md](docs/06-ux-ui.md) ; ne pas figer le thème sombre bleu-vert sans confirmation utilisateur. |
| DEV-05 — Arborescence interactive         | Afficher emplacements, contenants et biens. Permettre plusieurs branches ouvertes, gérer l'indentation et conserver le défilement et les branches ouvertes après consultation. |
| DEV-06 — Création rapide                  | Ajouter emplacements racines, contenants, biens simples et biens-contenants. Préremplir le parent et les valeurs par défaut.                                                   |
| DEV-07 — Consultation et modification     | Créer la fiche et le formulaire des propriétés générales (nom, description, état et quantité), puis revenir à la même position dans l'arbre. Présenter catégories et valorisation sans en implémenter l'édition spécialisée, réservée à DEV-09. |

Jalon 2 : première version réellement utilisable.

L'utilisateur peut organiser ses possessions dans une arborescence, ajouter des biens, consulter leurs détails et les modifier sur Android.

À ce stade, je recommande une validation manuelle complète de ce parcours avant d'ajouter les fonctions suivantes.

## Phase 3 — Fonctions métier complètes

| Mandat                                       | Objectif et résultat attendu                                                                                                                                                                |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| DEV-08 — Déplacements                        | Déplacer un bien ou un contenant vers un autre emplacement. Afficher les chemins complets et empêcher les déplacements circulaires. Les descendants suivent automatiquement leur contenant. |
| DEV-09 — Catégories et valorisation          | Ajouter l'association de plusieurs catégories par bien et l'édition des modes de valorisation CAD/sentimental au sein des fiches et formulaires créés en DEV-07. Ne pas recréer ces écrans ; respecter les invariants et totaux du modèle. |
| DEV-10 — Recherche et filtres                | Rechercher les biens par nom, emplacement ou catégorie selon les spécifications. Ouvrir directement une fiche depuis les résultats.                                                         |
| DEV-11 — Retraits, historique et suppression | Distinguer retrait réel et suppression d'une erreur. Enregistrer les motifs et dates de retrait, consulter l'historique et empêcher la suppression ou le retrait d'un contenant non vide.   |

Jalon 3 : périmètre fonctionnel V1 complet.

L'application permet de gérer le cycle de vie des possessions, sans sauvegarde externe pour le moment.

## Phase 4 — Protection des données

| Mandat                                | Objectif et résultat attendu                                                                                                                                                                                                           |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| DEV-12 — Export et sauvegarde         | Générer le fichier `.invbackup`, utiliser un instantané SQLite cohérent, vérifier longueur et SHA-256, intégrer le sélecteur Android et les états de succès ou d'échec.                                                                |
| DEV-13 — Restauration et récupération | Valider le fichier dans une base temporaire, confirmer le remplacement, restaurer transactionnellement, gérer `pending` / `committed` et vérifier les interruptions. Configurer et tester l'exclusion des sauvegardes système Android. |

Jalon 4 : données récupérables.

Un utilisateur peut sauvegarder son inventaire, le restaurer et retrouver ses biens, catégories, valeurs et historique. Les scénarios d'interruption doivent être vérifiés sur Android réel.

## Phase 5 — Validation et livraison

| Mandat                                 | Objectif et résultat attendu                                                                                                                                                                                                     |
| -------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| DEV-14 — Validation V1 de bout en bout | Exécuter les scénarios de [docs/04-user-validation.md](docs/04-user-validation.md) sur un appareil Android réel : navigation, inventaire profond, recherche, retraits, erreurs, sauvegarde, restauration et redémarrage. Corriger uniquement les défauts bloquants constatés. |
| DEV-15 — Préparation et livraison V1   | Vérifier le manifeste, les permissions, la configuration de production, les dépendances, la signature et l'APK Android. Installer la version finale et effectuer un dernier parcours utilisateur complet.                        |

Jalon 5 : Inventory V1 livrable.

Le résultat attendu est un APK Android signé et installable, fonctionnant hors ligne, avec des données persistantes et un mécanisme de sauvegarde/restauration validé.

## Les points de contrôle du projet

Socle technique opérationnelAprès DEV-03

Base SQLite persistante

Règles métier et transactions vérifiées

Première expérience utilisateurAprès DEV-07

Fonctions V1 complètesAprès DEV-11

Données protégéesAprès DEV-13

Livraison V1Après DEV-15

## Comment utiliser cette feuille de route avec Copilot

Je recommande de conserver DEV-01 à DEV-15 comme identifiants stables. Chaque mandat devra préciser ses dépendances, son périmètre, ses critères d'acceptation observables et son rapport final.

Le principe restera le même :

- Un seul mandat actif à la fois.
- Une fonctionnalité ne sera pas déclarée validée uniquement parce que ses tests automatisés passent.
- Les problèmes bloquants seront corrigés avant d'avancer ; les améliorations facultatives pourront attendre.
- Aucun mandat suivant ne sera lancé automatiquement.

L'ordre proposé n'est pas totalement rigide : une dépendance technique découverte pendant l'implémentation pourra justifier un ajustement, mais sans perdre les cinq jalons.

Ma recommandation finale : garder ces 15 mandats comme feuille de route directrice d'Inventory V1. Nous sommes actuellement à DEV-00 terminé — préparation documentaire, et le prochain travail autorisé sera DEV-01 — Socle Flutter Android.

Cette structure donne un objectif clair à chaque étape, tout en évitant que le projet se transforme en succession d'audits sans fin.