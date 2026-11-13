**Note de recentrage (V1 Android) :** ce document a été rédigé lorsque le projet visait une application multiplateforme Windows/Android synchronisée. La V1 est désormais exclusivement Android, locale et hors ligne, sans synchronisation. Les recommandations ci-dessous restent utiles pour la structure documentaire générale, mais tout ce qui concerne la synchronisation, l'appairage ou un second appareil (notamment le document 05 et l'ADR-003) est à considérer comme historique ou reporté, et non comme une exigence active de la V1.

**Statut documentaire :** ce document est une recommandation historique, pas une autorité de spécification pour la V1. La hiérarchie actuelle est définie au début de [blueprint.md](blueprint.md); [road-sheet.md](road-sheet.md) est la feuille de route active. Dans l'ancienne structure proposée ci-dessous, le plan de validation 08 est aujourd'hui couvert par [04-user-validation.md](04-user-validation.md), qui valide les parcours V1 sur un appareil Android réel, et non sur deux appareils. Les deux fichiers commençant par `04` sont distincts : `04-data-domain-model.md` décrit les données et `04-user-validation.md` les scénarios utilisateur.

Pour structurer ton application d'inventaire comme un projet logiciel professionnel, je te recommande de passer d'un simple blueprint à un dossier de conception produit et technique.

C'est une approche utilisée dans les grandes organisations technologiques : séparer les objectifs du produit, les exigences, l'architecture, les contrats techniques et les critères de validation.

Mais je ferais une distinction importante : nous voulons adopter la rigueur des grandes entreprises, pas leur bureaucratie. Ton application est personnelle, développée avec Flutter et Cursor, et elle doit rester relativement simple à maintenir.

Le blueprint actuel est une bonne base, mais il décrit surtout ce que l'application doit faire. Il manque encore plusieurs documents qui expliquent précisément comment elle doit fonctionner, comment les composants interagissent et comment prouver qu'elle fonctionne.

# 1. Les documents essentiels

Je recommande un dossier de 9 documents principaux, dont le blueprint existant.

01

Product Requirements Document (PRD)\
Fondamental

Vision, utilisateurs, fonctionnalités et limites

Décrit précisément le produit à construire, les scénarios d'utilisation et les critères d'acceptation.

02

Software Requirements Specification (SRS)\
Fondamental

Exigences fonctionnelles et non fonctionnelles

Transforme les intentions du PRD en exigences vérifiables et identifiées.

03

System Architecture Document (SAD)\
Fondamental

Architecture logique et technique

Définit les composants Flutter, leurs responsabilités, leurs interfaces et leurs dépendances.

04

Data Model & Domain Rules\
Fondamental

Données, relations et invariants

Décrit chaque entité, les contraintes SQLite, les transactions et les règles des contenants imbriqués.

05

Synchronization Protocol Specification\
Reportée hors V1 (historique)

Synchronisation Windows ↔ Android — non active pour la V1 Android

Formalise l'appairage, les messages réseau, la causalité, les conflits et la reprise après interruption. Conservée uniquement pour une évolution multiplateforme future.

06

UX/UI Specification\


Parcours, écrans et états de l'interface

Documente les interactions, les formulaires, les recherches, les déplacements et les états de l'interface.

07

Security & Privacy Design\


Sécurité des appareils et des données

Définit les frontières de confiance, les clés, les autorisations, la révocation et les menaces locales.

08

Verification & Validation Plan\
Fondamental

Tests, preuves et critères de livraison

Associe les exigences à des validations observables sur Android. Le plan de validation utilisateur actuellement présent dans le dépôt couvre ces parcours pour la V1.

09

Operations & Recovery Guide\


Installation, sauvegarde et récupération

Explique comment installer, mettre à jour, sauvegarder, restaurer et dépanner l'application.

Le blueprint que nous avons déjà produit deviendrait le document 00 — Project Blueprint, qui présente l'ensemble du système. Il ne faudrait pas répéter intégralement son contenu dans les autres documents.

# 2. Comment ces documents s'articulent

00 — Blueprint

Vision générale du projet

01 — PRD

Quoi et pourquoi ?

02 — SRS

Quelles exigences ?

03 — Architecture système

Comment les composants interagissent-ils ?

04 — Modèle de données

05 — Synchronisation

06 — UX/UI

07 — Sécurité

Validation utilisateur — [04-user-validation.md](04-user-validation.md)

Comment le prouver ?

09 — Exploitation

Comment le maintenir ?

Ces documents ne sont pas nécessairement rédigés dans un ordre strictement séquentiel. Les décisions sur les données, la synchronisation et la sécurité devront notamment être cohérentes entre elles.

## 3. Trois éléments supplémentaires que je considère indispensables

Au-delà des neuf documents, les équipes professionnelles utilisent des mécanismes de gouvernance technique. Pour ton projet, j'en retiendrais trois, légers mais importants.

### A. Architecture Decision Records (ADR)

Un ADR enregistre pourquoi une décision technique a été prise.

Par exemple :

| Décision                      | Justification                            |
| ----------------------------- | ---------------------------------------- |
| ADR-001 — Flutter             | Une base de code multiplateforme         |
| ADR-002 — SQLite + Drift      | Fonctionnement local et persistance      |
| ADR-003 — Synchronisation P2P (reportée hors V1) | Non applicable à la V1 Android ; conservée à titre historique pour une évolution multiplateforme future |
| ADR-004 — Modèle Node unifié  | Biens pouvant aussi servir de contenants |

Chaque ADR comprend le contexte, les options évaluées, la décision, ses conséquences et son statut.

Avantage : si tu reprends le projet dans un an, tu comprends pourquoi certaines technologies ont été choisies.

### B. Matrice de traçabilité

Elle relie chaque exigence à son implémentation et à sa validation.

| Exigence                             | Composant        | Validation                                  |
| ------------------------------------ | ---------------- | ------------------------------------------- |
| REQ-001 — Tout bien a un emplacement | Domaine / SQLite | Création sans parent refusée                |
| REQ-002 — Déplacement hiérarchique   | Domaine          | Descendants conservés                       |
| REQ-003 — Fonctionnement hors ligne permanent | Domaine / SQLite | Modification et consultation sans réseau |
| REQ-004 — Aucune perte silencieuse   | Domaine / Sauvegarde | Suppression bloquée, sauvegarde restaurée |

Cette matrice évite qu'une fonctionnalité soit déclarée terminée simplement parce que les tests automatisés passent.

### C. Definition of Done (DoD)

Une fonctionnalité est terminée lorsque :

- Elle répond aux exigences définies.
- Elle fonctionne dans l'interface réelle.
- Ses erreurs et états sont compréhensibles.
- Les tests pertinents passent.
- Les contraintes de sécurité et d'intégrité sont respectées.
- Sa documentation est actualisée.

Cela permet d'éviter les cycles interminables d'audits et de microcorrectifs facultatifs.

# 4. Structure documentaire recommandée

Cette arborescence est un exemple historique, pas la liste des fichiers présents ni une directive de création ou de renommage. Pour la V1, utiliser les références et noms de fichiers actuels définis dans [blueprint.md](blueprint.md).

Je placerais toute la documentation dans le dépôt Git du projet, en Markdown, pour qu'elle reste accessible à Cursor et versionnée avec le code.

```
inventory-app/
│
├── docs/
│   ├── 00-blueprint.md
│   ├── 01-product-requirements.md
│   ├── 02-software-requirements.md
│   ├── 03-system-architecture.md
│   ├── 04-data-domain-model.md
│   ├── 05-sync-protocol.md
│   ├── 06-ux-ui-specification.md
│   ├── 07-security-privacy.md
│   ├── 04-user-validation.md
│   ├── 09-operations-recovery.md
│   │
│   ├── adr/
│   │   ├── ADR-001-flutter.md
│   │   ├── ADR-002-sqlite.md
│   │   └── ADR-003-sync.md
│   │
│   └── reports/
│
├── lib/
├── test/
├── integration_test/
└── pubspec.yaml
```

# 5. Ordre de conception recommandé

Je ne rédigerais pas immédiatement dix documents exhaustifs. Je procéderais par trois étapes, avec des validations de cohérence à la fin de chacune.

Étape 1 — Définition complète du produit

Blueprint, PRD, SRS et parcours UX.

Livrable : toutes les fonctionnalités V1 sont définies, avec leurs limites et leurs comportements attendus.

Étape 2 — Conception technique détaillée

Architecture, modèle de données, protocole de synchronisation, sécurité et ADR.

Livrable : les composants, leurs responsabilités et les contrats entre eux sont suffisamment définis pour être implémentés.

Étape 3 — Préparation à l'exécution

Plan de validation, matrice de traçabilité, récupération et critères de livraison.

Livrable : chaque mandat Cursor peut être exécuté et évalué sans devoir redéfinir continuellement le produit.

## 6. Ce que je ne documenterais pas maintenant

Je n'ajouterais pas de dossier Kubernetes, de stratégie microservices, de système CI/CD complexe, de plan de montée en charge pour des milliers d'utilisateurs ou de documentation d'exploitation cloud.

Ces sujets ne correspondent pas à ton application personnelle.

Pour la V1 Android actuelle, le protocole de synchronisation n'est plus à traiter : seule la cohérence des données locales (une seule base SQLite) reste sérieuse à soigner. La remarque initiale sur « deux bases SQLite modifiées indépendamment » ne s'applique qu'à une éventuelle évolution multiplateforme future, non à la V1.


