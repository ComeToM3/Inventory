# Blueprint — Application personnelle d'inventaire physique

Version 2.0 · 10 novembre 2026 · Document de référence architectural et fonctionnel

**Recentrage V1 (version 2.0) :** la V1 est désormais exclusivement une application Android, entièrement locale et hors ligne, sans synchronisation ni second appareil. Les sections historiques relatives à Windows et à la synchronisation réseau sont conservées en fin de document, à titre de référence pour une éventuelle évolution future, mais elles ne constituent plus des exigences de la V1.

Objectif : développer une application Flutter Android permettant d'inventorier, classer, localiser et retrouver ses biens physiques grâce à une hiérarchie de contenants imbriqués, avec une gestion simple de la valeur financière et sentimentale des biens.

Le blueprint fixe le périmètre de la V1, les choix techniques, le modèle de données, les règles métier, les risques et les critères de validation.

## Autorité des références V1

Les décisions explicitement confirmées par l'utilisateur prévalent. Les documents spécialisés sont les références détaillées de leur domaine :

- [road-sheet.md](road-sheet.md) est la feuille de route actuelle et la séquence directrice DEV-01 à DEV-15.
- [01-product-requirements.md](01-product-requirements.md) et [02-functional-specification.md](02-functional-specification.md) définissent les exigences et comportements métier.
- [03-technical-architecture.md](03-technical-architecture.md) définit les responsabilités et dépendances techniques.
- [04-data-domain-model.md](04-data-domain-model.md) est la référence du modèle de données actuel.
- [06-ux-ui.md](06-ux-ui.md), [07-security-privacy.md](07-security-privacy.md) et [09-backup-recovery.md](09-backup-recovery.md) sont les références de leurs domaines respectifs.
- [04-user-validation.md](04-user-validation.md) est le plan de validation utilisateur actuellement présent. Son préfixe `04` est distinct de celui du modèle de données.

Ce blueprint donne une vue d'ensemble; il ne remplace pas ces documents spécialisés. [essential-doc.md](essential-doc.md) conserve des recommandations documentaires historiques et ne constitue pas une source de décisions actives. Les anciens plans de développement sont explicitement historiques. En cas de contradiction non résolue entre les références ou avec une décision utilisateur, signaler les passages concernés et demander une décision; ne pas choisir arbitrairement.

## 1. Vision du produit

L'application doit répondre à quatre questions fondamentales :

- Qu'est-ce que je possède ? Inventaire exhaustif des biens physiques.
- Où se trouve cet objet ? Localisation précise dans une arborescence de contenants.
- Qu'y a-t-il dans ce contenant ? Consultation de son contenu direct et indirect.
- Comment retrouver rapidement un objet ? Recherche globale par nom, catégorie et emplacement.

### Principes directeurs

1. Local-first : l'appareil dispose de sa propre base de données et l'application reste utilisable hors ligne en permanence.
2. Android exclusivement : une seule plateforme cible pour la V1, aucun développement ni test Windows.
3. Sans cloud : aucune infrastructure externe, aucun compte utilisateur et aucun abonnement.
4. Hiérarchie universelle : un bien peut également être un contenant.
5. Simplicité : interface accessible sans connaissance technique.
6. Intégrité : aucune perte silencieuse de données, aucune boucle hiérarchique et aucune suppression accidentelle de contenu.

## 2. Architecture générale

Flutter Android

UI · Domaine · Drift/SQLite

Persistance locale

Drift / SQLite · Transactions · Sauvegardes

L'application est un module unique : une seule base de code Flutter Android, une seule base de données locale, aucun composant réseau.

### Stack retenue

| Couche         | Technologie                   |
| -------------- | ----------------------------- |
| Plateforme     | Android exclusivement         |
| Interface      | Flutter, Material 3           |
| Langage        | Dart                          |
| Gestion d'état | Riverpod                      |
| Navigation     | go_router                     |
| Persistance    | Drift + SQLite                |
| Identifiants   | UUID                          |
| Sauvegarde     | Archive locale exportable     |

Aucun backend, aucune base de données serveur, aucun service cloud, aucun transport réseau et aucun mécanisme de synchronisation ne sont nécessaires pour la V1.

## 3. Modèle métier et hiérarchie

Le modèle repose sur une entité centrale : `Node`.

Chaque nœud représente un élément de l'inventaire physique.

| Type           | Exemple                | Peut contenir |
| -------------- | ---------------------- | ------------- |
| Emplacement    | Appartement, bureau    | Oui           |
| Contenant      | Armoire, boîte, tiroir | Oui           |
| Bien simple    | Livre, câble, outil    | Non           |
| Bien-contenant | Valise, boîte à outils | Oui           |

Un bien peut changer de contenant sans changer de catégorie.

Un bien peut être valorisé selon un seul des deux modes suivants, mutuellement exclusifs : financier ou sentimental (voir section 3.1).

### Exemple

Appartement

Bureau

Armoire

Boîte électronique

Bloc d'alimentation EVGA

Câbles USB-C (× 4)

### Règles obligatoires

- Chaque nœud, sauf la racine, possède exactement un parent.
- Un nœud ne peut pas être son propre ancêtre.
- Un bien simple ne peut pas recevoir d'enfants.
- Le déplacement d'un contenant déplace logiquement tous ses descendants.
- Les catégories ne dépendent jamais des emplacements.
- Une suppression ne doit pas faire disparaître silencieusement les objets contenus ; un contenant non vide ne peut pas être supprimé. *(Décision confirmée)*
- Les opérations de déplacement sont transactionnelles.

### 3.1 Valeur financière et sentimentale

Chaque bien est valorisé selon **un seul des deux modes suivants**, jamais les deux à la fois : *(Décision confirmée)*

| Mode | Définition |
| --- | --- |
| Financier (par défaut) | Montant en dollars canadiens (CAD), initialisé à 0 $. Une valeur de 0 $ est parfaitement valide et modifiable librement. Aucune estimation automatique, aucune dépréciation, aucun module comptable. |
| Sentimental | Évaluation sur une échelle de 1 à 5, sans commentaire ni note textuelle. |

Règles :

- Les deux modes sont mutuellement exclusifs : un bien ne peut jamais porter simultanément une valeur financière et une valeur sentimentale.
- Le mode financier est proposé par défaut, avec un montant de 0 $.
- L'utilisateur peut changer de mode à tout moment. Lors d'un changement de mode, l'ancienne valeur n'est plus active : elle n'est ni affichée, ni comptabilisée, ni conservée dans l'autre mode.
- La valeur sentimentale n'est jamais convertie en montant financier, et inversement.
- Pour un lot d'objets identiques (quantité > 1) en mode financier, le montant saisi représente le prix unitaire par défaut, affiché avec un total calculé (quantité × prix unitaire) pour information. *(Recommandation : convention la plus simple à comprendre.)*

## 4. Schéma de données V1

| Table             | Responsabilité                                  |
| ----------------- | ----------------------------------------------- |
| `inventories`     | Identité de l'inventaire local                  |
| `nodes`           | Biens, emplacements et contenants               |
| `categories`      | Classification des biens                        |
| `node_categories` | Associations biens-catégories                   |

Les champs, types, contraintes et relations détaillés sont définis par [04-data-domain-model.md](04-data-domain-model.md). Pour éviter les descriptions concurrentes, les champs suivants des anciens aperçus n'appartiennent pas au modèle actuel :

- `can_contain` n'est pas listé comme colonne; le modèle recommande de déduire la capacité de `node_type`. Cette représentation reste une recommandation technique à confirmer au schéma.
- `financial_value` n'est pas le nom de champ du modèle actuel, qui recommande `financial_value_cents` en cents CAD; cette précision est une recommandation technique du modèle.
- `financial_value_is_total` est omis : le montant enregistré est unitaire et le total d'un lot est calculé à partir de la quantité.
- `deleted_at` est omis : une suppression définitive supprime la ligne; un retrait conserve le bien avec son statut, son motif et sa date.

Les biens utilisent `value_mode` (`financial` ou `sentimental`) et une seule valeur active, soit `financial_value_cents`, soit `sentimental_value`. Les statuts persistés sont `active` et `withdrawn`; `withdrawal_reason` et `withdrawn_at` ne sont renseignés que pour un bien retiré.

Les quantités concernent les lots de biens interchangeables. Les objets uniques ayant un numéro de série ou un historique individuel doivent posséder leur propre fiche.

Les identifiants sont des UUID, par cohérence avec une éventuelle évolution future, sans qu'un second appareil soit nécessaire en V1.

Les horodatages servent uniquement à l'affichage et au diagnostic.

## 5. Fonctionnalités V1

| Fonction        | Exigence                               |
| --------------- | -------------------------------------- |
| Inventaire      | Créer, modifier et consulter les biens |
| Contenants      | Imbrication à plusieurs niveaux        |
| Catégories      | Classification indépendante            |
| Recherche       | Nom, catégorie et emplacement          |
| Déplacements    | Bien seul ou contenant complet         |
| Quantités       | Gestion des lots simples               |
| Valeur          | Un seul mode à la fois : financier (CAD, 0 $ par défaut) ou sentimental (1 à 5), mutuellement exclusifs |
| Sortie d'inventaire | Retrait (perte, don, bris, vente) avec historique minimal, ou suppression définitive d'une fiche erronée |
| Hors ligne      | Lecture et modification complètes, en permanence |
| Sauvegarde      | Export et restauration locales         |

Hors V1 : comptabilité, amortissement, achats, garanties, assurance, statistiques patrimoniales avancées, reconnaissance automatique d'objets, intelligence artificielle, accès distant, gestion multiutilisateur, application Windows et synchronisation entre appareils.

Les photos et codes QR restent exclus de la V1. *(Décision confirmée)*

## 6. Synchronisation — Reportée hors V1 (historique)

La synchronisation entre un appareil Windows et un appareil Android faisait partie de la version 1.0 de ce blueprint. Elle est **retirée du périmètre de la V1** actuelle : la V1 est une application Android autonome, sans second appareil ni réseau.

Cette section est conservée uniquement comme référence historique, en cas d'évolution future vers une version multiplateforme synchronisée. Elle ne constitue plus une exigence active et ne doit pas être implémentée dans la V1.

Résumé de l'ancienne spécification (non active) : fonctionnement nominal en six étapes (modification locale, découverte mDNS, connexion sécurisée, échange des changements, validation, confirmation), contrat de synchronisation par appareil avec numéros de séquence et versions causales, table de gestion des conflits, appairage sécurisé par bibliothèque éprouvée. Le détail complet n'est plus reproduit ici ; il pourra être repris tel quel si une version multiplateforme est envisagée.

## 7. Expérience utilisateur

L'interface doit privilégier la navigation physique, plutôt qu'une interface comptable de type ERP.

Inventaire personnel

Maquette fonctionnelle illustrative

EmplacementsCatégoriesRecherche

Appartement

Bureau

8 biens

Armoire

Boîte électronique

Bloc EVGA 1300 W

Câbles USB-C × 4

Synchronisé (illustration — non active en V1)

&#x20;Ajouter

### Parcours utilisateurs obligatoires

Parcours A — Ajouter un bien

L'utilisateur sélectionne un contenant, ajoute un objet, renseigne son nom, sa catégorie, sa quantité et choisit un mode de valorisation (financier à 0 $ par défaut, ou sentimental), puis enregistre. Le nouvel objet apparaît immédiatement au bon emplacement.

Parcours B — Créer un contenant

L'utilisateur crée une boîte, choisit son emplacement parent et peut ensuite y ranger des biens ou d'autres contenants.

Parcours C — Retrouver un objet

L'utilisateur recherche un nom ou une catégorie. L'application présente le chemin physique complet jusqu'à l'objet.

Parcours D — Déplacer un contenant

L'utilisateur choisit un nouvel emplacement. Le contenant et tous ses descendants sont retrouvés sous leur nouvelle localisation.

## 8. Sauvegarde et récupération

La V1 doit offrir un export autonome et restaurable contenant les données nécessaires à la reconstruction de l'inventaire, avec un manifeste de version et des contrôles d'intégrité.

La restauration doit être validée sur une base séparée avant de remplacer les données actives.

## 9. Structure du projet Flutter

```
inventory_app/
├── lib/
│   ├── app/
│   │   ├── router/
│   │   └── theme/
│   ├── core/
│   │   ├── database/
│   │   ├── errors/
│   │   └── identifiers/
│   ├── features/
│   │   ├── inventory/
│   │   ├── containers/
│   │   ├── categories/
│   │   ├── valuation/
│   │   ├── search/
│   │   └── backup/
│   └── main.dart
├── test/
├── integration_test/
├── docs/
│   ├── architecture/
│   ├── decisions/
│   └── reports/
└── pubspec.yaml
```

Les fonctionnalités doivent communiquer à travers des contrats métier explicites. L'interface ne doit pas modifier directement les tables SQLite.

La gestion des nœuds et la validation des déplacements doivent passer par une couche métier commune, utilisée par l'interface.

## 10. Plan de développement historique — remplacé

**Ce plan en cinq mandats est historique et n'est pas la séquence active.** Il est remplacé par les quinze mandats DEV-01 à DEV-15 de [road-sheet.md](road-sheet.md), qui fait autorité pour l'ordre et les jalons actuels. Ne pas utiliser les mandats numérotés ci-dessous pour planifier la V1.

1. Ancien mandat 01 — Fondations et modèle métier

   Initialiser Flutter Android, Drift, les entités et les contraintes hiérarchiques.

   Validation : créer, enregistrer et retrouver une arborescence après redémarrage.
2. Ancien mandat 02 — Inventaire et navigation

   Développer les écrans, catégories, recherche, création et déplacement de biens.

   Validation : inventaire réel de 20 objets, plusieurs contenants imbriqués, déplacements et recherche.
3. Ancien mandat 03 — Valeur financière et sentimentale

   Ajouter la saisie, la modification et l'affichage de la valorisation, ainsi que le retrait et la suppression définitive d'un bien.

   Validation : un bien ne peut recevoir qu'un seul mode de valorisation à la fois, sans report de l'ancienne valeur lors d'un changement de mode ; un bien retiré disparaît de l'inventaire actif sans perte de son historique minimal.
4. Ancien mandat 04 — Sauvegarde et restauration

   Exporter, vérifier et restaurer un inventaire complet.

   Validation : restauration sur une installation Android propre.
5. Ancien mandat 05 — Validation finale V1

   Tester les parcours utilisateurs complets, corriger uniquement les défauts bloquants et préparer la distribution locale.

   Validation : utilisation autonome sans intervention technique ni dépendance cloud.

## 11. Risques et décisions de conception

| Risque                   | Importance | Mesure                                                 |
| ------------------------ | ---------- | ------------------------------------------------------ |
| Perte de données         | Élevée     | Transactions et sauvegardes locales                    |
| Boucles hiérarchiques    | Élevée     | Validation systématique des déplacements               |
| Confusion entre valeur financière et sentimentale | Moyenne | Modes mutuellement exclusifs, jamais convertis l'un en l'autre |
| Perte accidentelle d'un bien retiré | Faible | Historique minimal conservé hors de l'inventaire actif |
| Complexité excessive     | Moyenne    | Périmètre V1 strict et mandats indépendants            |

Les risques liés à la synchronisation réseau (conflits, découverte Wi-Fi, sécurité des échanges, compatibilité multiplateforme) ne s'appliquent plus à la V1 ; ils sont reportés avec la section 6.

## 12. Critères de livraison de la V1

Liste de validation finale

0/9

L'application fonctionne réellement sur Android.

Les biens et contenants persistent après fermeture.

Les contenants peuvent être imbriqués à plusieurs niveaux.

Les déplacements conservent tous les descendants.

La recherche retrouve un objet et son chemin complet.

Un bien est valorisé selon un seul mode à la fois (financier ou sentimental), modifiable sans report de l'ancienne valeur.

Un bien peut être retiré de l'inventaire actif (perte, don, bris, vente) ou supprimé définitivement s'il a été créé par erreur.

Un déplacement invalide (boucle), la suppression ou le retrait d'un contenant non vide sont refusés.

Une sauvegarde peut être restaurée sur une installation Android propre.

## Verdict architectural

Blueprint V1 — Validé comme base de conception, recentré sur Android

L'architecture est cohérente avec les objectifs : application personnelle Android, autonome, centrée sur les biens physiques et leur valeur, sans infrastructure serveur ni synchronisation.

La synchronisation multiplateforme reste documentée à titre historique (section 6) pour une évolution future éventuelle, mais n'est plus un investissement technique de la V1.

Conserver ce blueprint comme vue d'ensemble produit et technique; utiliser les documents spécialisés et [road-sheet.md](road-sheet.md) selon la hiérarchie de références définie au début du document.