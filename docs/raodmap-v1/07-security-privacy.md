# 07 — Sécurité et confidentialité d'Inventory V1 Android

## 1. Objectif et périmètre

Ce document fixe les protections proportionnées aux données d'une application personnelle Android, locale et hors ligne. Il couvre la confidentialité, l'intégrité et la disponibilité des données ; il ne constitue ni un audit général, ni une promesse de protection contre un appareil compromis.

Inventory V1 utilise Flutter/Dart, Drift et SQLite, sans compte utilisateur, serveur, API distante, synchronisation, télémétrie, publicité, photo ni QR. L'export et la restauration sont des actions locales explicites. Le document s'appuie sur le [blueprint](blueprint.md), le [PRD](01-product-requirements.md), la [spécification fonctionnelle](02-functional-specification.md), l'[architecture](03-technical-architecture.md), le [modèle de données](04-data-domain-model.md), la [validation utilisateur](04-user-validation.md) et la [spécification UX/UI](06-ux-ui.md).

Les contrôles **bloquants V1** sont les exigences minimales avant livraison. Les contrôles **facultatifs** réduisent un risque résiduel ou ajoutent un confort, mais nécessitent une décision avant d'élargir le périmètre.

## 2. Données traitées et sensibilité

Inventory conserve localement :

- les noms des possessions, les descriptions et leur état éventuel ;
- les emplacements et chemins physiques de l'inventaire ;
- les catégories et quantités ;
- les valeurs financières ou sentimentales ;
- le motif et la date de retrait d'un bien ;
- les identifiants et horodatages techniques des lignes.

L'ensemble peut révéler le contenu ou l'organisation d'un domicile. Il doit être considéré comme **personnel et sensible**, même si l'application n'enregistre pas de données de compte, de paiement ou de santé. Une sauvegarde complète a une sensibilité au moins équivalente à celle de la base.

Inventory ne collecte pas d'identifiant publicitaire, d'identifiant de suivi, de données analytiques ni de contenu destiné à un service distant.

## 3. Modèle de menace V1

| Menace | Protection attendue | Responsable | Risque résiduel / priorité |
| --- | --- | --- | --- |
| Perte ou vol d'un appareil éteint/verrouillé | S'appuyer sur le verrouillage d'écran et le chiffrement de stockage pris en charge par l'appareil Android ; ne pas exposer la base dans le stockage partagé. | Android / utilisateur ; Inventory choisit le stockage privé. | **Bloquant V1** : stockage privé et absence d'export automatique. Le niveau réel de protection dépend de l'appareil, de sa configuration et de son état de verrouillage. |
| Accès au téléphone déverrouillé ou déjà ouvert | Pas de protection absolue dans V1 ; l'utilisateur doit protéger l'appareil avec le verrouillage Android. Limiter les données affichées aux écrans nécessaires et ne pas les journaliser. | Android / utilisateur ; Inventory pour l'affichage et les journaux. | **Résiduel accepté V1** : aucune authentification propre à l'application n'est prévue. |
| Appareil compromis, rooté, débogage système ou accès privilégié | Ne pas revendiquer de protection contre l'accès système complet. | Hors contrôle d'Inventory. | **Résiduel accepté**. |
| Copie ou exposition accidentelle d'une sauvegarde | Export volontaire, destination choisie, avertissement de sensibilité, pas de transmission par Inventory. Valider les fichiers avant restauration. | Inventory ; fournisseur de destination choisi par l'utilisateur pour le fichier externe. | **Bloquant V1** : avertissement, choix explicite et restauration sans écriture partielle. |
| Copie automatique de données par la sauvegarde système Android | Exclure les données Inventory de l'Auto Backup cloud, du transfert direct et de tout canal système applicable ; configurer les règles selon l'API et le `targetSdkVersion`, puis vérifier les flux pertinents. | Configuration Android de l'application ; comportements OEM hors contrôle. | **Bloquant V1 — décision confirmée** : aucune sauvegarde ou transfert système des données Inventory. |
| Corruption ou écriture interrompue de SQLite | Contraintes SQLite, clés étrangères, transactions, erreurs explicites et sauvegardes locales volontaires. | Inventory / Drift / SQLite. | **Bloquant V1** pour éviter les écritures partielles ; corruption matérielle reste possible. |
| Suppression ou déplacement accidentel | Confirmation distincte pour retrait, suppression définitive et restauration ; bloquer le retrait/suppression d'un contenant non vide. | Inventory. | **Bloquant V1**. |
| Fichier invalide, malformé ou incompatible restauré | Valider intégrité, format et modèle avant activation ; restaurer comme remplacement atomique ; conserver la base active si échec. | Inventory. | **Bloquant V1**. |
| Données personnelles dans les journaux ou rapports | Redaction des noms, chemins, valeurs et contenus de sauvegarde ; aucun rapport automatique. | Inventory et ses dépendances. | **Bloquant V1**. |
| Accès d'une autre application aux données privées | Base dans le répertoire privé de l'application ; aucun composant exporté inutile ; accès aux fichiers externes limité aux URI choisies. | Android et configuration Inventory. | **Bloquant V1**. |

### Répartition des garanties

**Android fournit** l'isolation du répertoire privé entre applications sous le modèle normal d'exécution, les mécanismes de permissions et de sélection de documents, ainsi que les protections de stockage dépendant de l'appareil et de son état. Ces protections ne couvrent pas un appareil compromis, un utilisateur disposant d'un accès système complet, ni un écran consulté par une personne devant un appareil déjà déverrouillé.

**Inventory doit fournir** des écritures métier cohérentes, des transactions, des validations d'import, des confirmations destructives, une politique explicite de sauvegarde système, une configuration de permissions minimale et des journaux non sensibles.

**Risques résiduels acceptables** : accès aux informations affichées sur un appareil déverrouillé, copie volontaire d'une sauvegarde vers un emplacement choisi par l'utilisateur, panne physique et appareil compromis. La V1 ne promet ni contrôle des copies externes, ni effacement à distance, ni récupération en l'absence de sauvegarde.

## 4. Stockage local et isolation Android

### Base SQLite

**Exigence — bloquante V1 :** placer le fichier SQLite et ses fichiers de travail nécessaires dans le stockage privé interne attribué à l'application Android (répertoire de données privé), avec des accès système de fichiers privés par défaut. Ne pas placer la base, ses journaux ou fichiers temporaires dans un répertoire partagé ou public.

Le sandbox Android empêche normalement les autres applications d'ouvrir directement ces fichiers sous leurs identités applicatives respectives. Cette isolation n'est pas une défense contre le root, un exploit système, une sauvegarde système configurée pour copier ces fichiers, ni l'utilisateur de l'application sur un appareil déverrouillé.

Les fichiers temporaires et fichiers WAL/journal SQLite doivent rester dans le même espace privé et ne pas être exportés séparément. Éviter les copies de base non maîtrisées, notamment pendant l'export ; la sauvegarde doit provenir d'un état cohérent de SQLite.

### Désinstallation et effacement des données

La désinstallation ou l'effacement des données de l'application supprime normalement la base privée et les préférences locales. L'utilisateur ne doit pas interpréter une sauvegarde exportée comme automatiquement supprimée avec l'application : un fichier choisi dans un stockage externe ou chez un fournisseur de documents peut persister après désinstallation. L'interface de sauvegarde doit avertir l'utilisateur de conserver une copie dans un emplacement sûr.

La récupération après désinstallation dépend donc d'une sauvegarde exportée valide. Inventory ne peut pas restaurer des données privées effacées si aucune sauvegarde utilisable ne subsiste.

### Sauvegarde système Android

La sauvegarde automatique Android est distincte du module de sauvegarde local Inventory : selon la configuration de l'application, de l'appareil et du service système, elle peut copier les données de l'application vers un mécanisme de sauvegarde de la plateforme. Une application sans fonctionnalité réseau peut donc néanmoins être concernée par ce mécanisme système.

**Décision confirmée — bloquante V1 :** les données Inventory sont exclues de l'Auto Backup Android et des transferts système, notamment du cloud et du transfert direct d'appareil. La configuration doit couvrir les règles historiques et, lorsque l'API de l'appareil et le `targetSdkVersion` le requièrent, `dataExtractionRules` avec des exclusions distinctes pour `cloud-backup` et `device-transfer`. `android:allowBackup="false"` seul ne prouve pas l'exclusion de tous les transferts. Les exigences conditionnelles et la matrice de vérification figurent dans [09 — Sauvegarde et récupération](09-backup-recovery.md), section 9. Les outils de migration propriétaires peuvent ne pas respecter ces règles ; cette limite doit être testée et signalée, sans revendiquer une garantie universelle.

Cette décision porte sur la configuration et le comportement de l'application avec la plateforme ; elle ne permet pas de garantir les politiques propriétaires de chaque fabricant ou outil de transfert. L'export volontaire décrit à la section 7 reste le mécanisme de sauvegarde sous contrôle UX d'Inventory.

## 5. Permissions et confidentialité

### Permissions Android

| Capacité V1 | Permission Android recommandée | Raison |
| --- | --- | --- |
| Base SQLite privée et fonctionnement local | Aucune permission de stockage | L'accès au répertoire privé de l'application ne requiert pas une permission générale de stockage. |
| Export d'une sauvegarde | Aucune permission générale de stockage ; utiliser le sélecteur système de destination lorsque possible. | L'utilisateur choisit explicitement où créer le document. |
| Restauration d'une sauvegarde | Aucune permission générale de stockage ; utiliser le sélecteur système pour ouvrir le fichier choisi. | L'accès est limité au document choisi et aux autorisations URI accordées. |
| Recherche, inventaire, catégories, valeurs | Aucune permission réseau, localisation, contacts, caméra ou média. | Ces fonctionnalités sont locales et textuelles. |

Le Storage Access Framework permet à l'utilisateur de sélectionner un document et d'accorder à l'application un accès ciblé sans permission générale de stockage. Le fournisseur choisi peut toutefois être un service cloud ou une application tierce : l'interface doit indiquer que le fichier pourra être transmis ou synchronisé selon le fournisseur sélectionné.

**Exigence — bloquante V1 :** ne pas demander `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`, accès à la localisation, caméra, contacts ou autres permissions sans besoin V1 démontré. Utiliser un sélecteur Android de fichiers pour la sauvegarde et la restauration plutôt que l'accès général au stockage.

Examiner le manifeste fusionné de la version de production : aucune permission ni composant exporté ne doit être ajouté indirectement par une dépendance sans justification. Une éventuelle permission `INTERNET` doit être absente si aucun composant V1 ne la nécessite. Si une dépendance l'introduit, déterminer pourquoi avant livraison et la retirer si elle n'a pas de raison fonctionnelle approuvée.

### Confidentialité de l'application

- Inventory ne transmet volontairement aucune donnée vers un serveur ou une API.
- Aucun SDK analytique, identifiant de suivi, publicité, rapport de plantage avec contenu utilisateur ou télémétrie n'est prévu.
- Les données restent dans SQLite privée, sauf export ou ouverture d'un fichier demandé explicitement par l'utilisateur via le sélecteur de fichiers.
- L'application ne contrôle pas les pratiques d'un fournisseur de documents, d'une application de partage ou d'une sauvegarde système que l'utilisateur a activée séparément.
- Les partages via une autre application ne sont pas une fonction V1. Si un partage de fichier est introduit ultérieurement, il nécessitera une action explicite et une confirmation du destinataire ou de l'application cible.

La sélection d'un fournisseur cloud depuis le sélecteur reste un choix de l'utilisateur et peut provoquer un transfert géré par ce fournisseur. Ce transfert ne doit pas être présenté comme un envoi par Inventory ni comme une sauvegarde garantie par Inventory.

## 6. Intégrité SQLite et règles métier

Le document [04 — Modèle de données et règles métier](04-data-domain-model.md) définit les règles détaillées. La sécurité d'intégrité V1 doit respecter ces invariants, sans les redéfinir :

- contraintes SQLite : clés primaires et étrangères, unicités, valeurs permises, cohérence des modes financiers/sentimentaux, quantités et champs de retrait ;
- clés étrangères activées sur chaque connexion ;
- validation dans le domaine des règles inter-lignes : parent actif et capable de contenir, absence de cycle, chemin atteignant une racine, catégories réservées aux biens, absence d'enfant pour les biens simples ou retirés ;
- transaction pour les créations avec catégories, changements de valorisation, déplacements, retrait, suppression et restauration ;
- échec atomique : une écriture invalide ou interrompue ne doit pas être rapportée comme réussie ni laisser une modification métier partielle ;
- suppression du parent référencé non propagée en cascade vers les nœuds ; seules les associations de jointure peuvent être supprimées en cascade selon le modèle ;
- confirmations UX distinctes pour le retrait et la suppression définitive ; aucune suppression ou retrait automatique des descendants ;
- valeurs monétaires stockées en entiers selon le modèle et aucune conversion silencieuse entre modes.

**Responsable :** Inventory et ses couches domaine/persistance. **Vérification :** scénarios de validation Android, complétés par des tests de contraintes et de transactions. **Priorité :** bloquant V1 pour toute règle susceptible de corrompre l'arbre, de perdre des enfants ou d'activer des valeurs incohérentes.

## 7. Sécurité des sauvegardes et restaurations

Une sauvegarde exportée contient les mêmes données sensibles que l'inventaire. Elle est créée uniquement à la demande de l'utilisateur, après choix explicite d'une destination via le sélecteur Android. Le fournisseur choisi peut être externe ou synchroniser le fichier ; Inventory ne le contrôle pas. La sauvegarde n'est pas chiffrée et un avertissement compréhensible sur son contenu et sa sensibilité est requis.

### Export

- Ne pas exporter automatiquement, à intervalle régulier ou vers un service distant.
- Choisir explicitement le document/la destination via le sélecteur de fichiers Android lorsque possible.
- Exporter un état cohérent et complet de l'inventaire, y compris les catégories, valeurs et biens retirés prévus par le modèle.
- Distinguer l'export relu et vérifié de l'état « écrit, mais non vérifiable » lorsqu'un fournisseur ne permet pas la relecture ; ne jamais présenter cet état comme un fichier vérifié ou durablement conservé.
- En cas d'annulation ou d'erreur d'écriture/fermeture, ne pas annoncer un export réussi.
- Informer que le fichier peut être copié, sauvegardé ou synchronisé par le fournisseur choisi et qu'Inventory n'en contrôle plus la conservation une fois hors de son stockage privé.

### Restauration

- Considérer tout fichier sélectionné comme une entrée non fiable, même si son nom ressemble à une sauvegarde Inventory.
- Vérifier le format attendu, l'intégrité, la cohérence structurelle, les références, les types, les contraintes métier et la compatibilité avant de remplacer les données actives.
- Ne pas exécuter de contenu provenant du fichier ni extraire des chemins arbitraires si un futur format utilise une archive.
- Charger et vérifier les données dans une base temporaire séparée avant activation, conformément à l'architecture et au modèle.
- Demander confirmation avant le remplacement complet de l'inventaire actif.
- Effectuer le remplacement sans état partiel. Avant le commit, un rollback confirmé doit conserver l'inventaire précédent ; si le résultat du commit est incertain, résoudre l'état après récupération SQLite avant toute nouvelle écriture ou tout message de résultat.
- Fournir un message correspondant à l'état vérifié : échec et inventaire précédent conservé, ou restauration commise et nouvel inventaire actif. Ne pas annoncer d'échec ou de succès à partir d'une erreur de commit seule.

Le contrat `.invbackup`, les limites et les états de vérification de destination sont définis dans [09 — Sauvegarde et récupération](09-backup-recovery.md). Les décisions V1 excluent tout chiffrement supplémentaire ; la sauvegarde reste un fichier sensible en clair.

## 8. Évaluation du chiffrement et du verrouillage

| Mesure | Risque atténué | Coût et limites | Statut V1 |
| --- | --- | --- | --- |
| Chiffrement du stockage Android | Lecture hors ligne du stockage retiré d'un appareil ou d'un support, selon la protection et l'état de déverrouillage de l'appareil. | Dépend de la version Android, de l'appareil, de la configuration de verrouillage et de la gestion des clés système ; Inventory n'en contrôle pas toute la chaîne. | **Protection de plateforme à recommander** : demander à l'utilisateur de maintenir Android et le verrouillage d'écran à jour ; ne pas prétendre que chaque appareil fournit une garantie identique. |
| Chiffrement supplémentaire de SQLite | Réduire la lisibilité d'une copie brute de la base obtenue hors de l'application, notamment après accès à des fichiers. | Nécessite une solution SQLite compatible avec Drift, la gestion et récupération de clés, une stratégie en cas de perte du secret, des migrations et une incidence sur sauvegarde/restauration. Ne protège pas nécessairement les données si l'application est ouverte ou si les clés sont accessibles. | **Décision confirmée V1 : non prévu.** Aucun chiffrement SQLite/SQLCipher ni gestion de clé propre à Inventory. |
| Chiffrement des sauvegardes exportées | Réduire l'accès au contenu si le fichier exporté est copié ou perdu. | Ajoute mot de passe/clé, expérience de récupération, risque d'oubli rendant la sauvegarde inutilisable, et compatibilité à long terme. Ne contrôle pas les copies si le secret est partagé avec le fichier. | **Décision confirmée V1 : non prévu.** Aucun mot de passe, chiffrement d'archive ou clé Inventory ; le fichier demeure lisible par qui y a accès. |
| Verrouillage applicatif par code | Limiter l'accès occasionnel lorsque le téléphone est déjà déverrouillé. | Ajoute un secret propre à l'application, récupération, délais/verrouillage et friction ; ne protège pas la base contre l'accès root ou une extraction de données, et peut dupliquer le verrouillage Android. | **Décision confirmée V1 : non prévu.** Aucun verrou applicatif, code ni mot de passe maître ; le verrouillage Android reste la protection de plateforme retenue. |
| Déverrouillage biométrique | Accès pratique à un éventuel verrou applicatif ou à une clé locale. | Dépend du matériel et de l'intégration Android ; ne remplace pas une politique de récupération de clé. Introduit une dépendance UX et cryptographique. | **Décision confirmée V1 : non prévu.** Aucun verrou applicatif ni chiffrement local à déverrouiller. |

**Décision V1 :** aucun chiffrement applicatif ou d'export, mot de passe maître, verrouillage applicatif ou biométrie. S'appuyer sur le stockage privé et les protections du système Android, préciser leurs limites, et traiter l'export non chiffré comme un fichier sensible contrôlé par l'utilisateur.

## 9. Journaux, erreurs et données personnelles

### Journaux permis

En développement, les journaux peuvent contenir des informations techniques nécessaires au diagnostic, de préférence des catégories d'événements et identifiants non directement personnels. En production, limiter les journaux aux informations techniques minimales :

- type d'opération et résultat (par exemple échec de sauvegarde) ;
- code d'erreur interne non sensible ;
- durée ou étape technique si nécessaire au diagnostic ;
- identifiant opaque de corrélation local, sans réutilisation comme identifiant de suivi.

Ne pas journaliser en production les noms de biens ou catégories, les chemins physiques, descriptions, valeurs, contenu d'une sauvegarde, données complètes de requête SQLite, noms de fichiers privés ou URI de documents contenant des jetons d'accès.

### Erreurs utilisateur et erreurs techniques

La couche domaine/persistance peut conserver l'erreur technique nécessaire à la gestion locale et au diagnostic. L'interface présente un message simple, sans SQL, trace de pile, chemin privé, donnée de sauvegarde ou contenu personnel. L'erreur reste visible : elle ne doit pas être transformée en réussite ou en état vide.

Aucun rapport de plantage ou de diagnostic contenant des données personnelles ne doit être transmis automatiquement. Aucun système de télémétrie ou d'envoi d'erreur n'est ajouté en V1.

**Vérification :** provoquer une erreur de validation et une erreur d'accès à un fichier de sauvegarde sur Android ; contrôler le message utilisateur et les journaux de production. **Priorité : bloquant V1.**

## 10. Dépendances et configuration de production

### Dépendances

- Ajouter uniquement les dépendances nécessaires au périmètre Android local approuvé.
- Avant adoption, vérifier la maintenance raisonnable, la provenance, la nécessité, les permissions ajoutées et les fonctionnalités de collecte/transmission éventuelles.
- Garder Flutter, Dart, Drift/SQLite et les composants Android sur des versions prises en charge ; traiter les avis de sécurité pertinents lors des mises à jour.
- Examiner les dépendances transitives lorsqu'elles ajoutent des permissions, du code natif, des SDK analytiques, des composants réseau ou des mécanismes de sauvegarde.
- Ne pas ajouter de scanner SaaS, service externe, télémétrie ou pipeline CI/CD dans le cadre de ce mandat.

### Construction et configuration Android

**Exigences — bloquantes V1 :**

- Vérifier le manifeste fusionné de la variante de production et justifier chaque permission.
- Ne laisser aucun composant (activité, service, fournisseur ou récepteur) exporté sans besoin fonctionnel documenté ; limiter l'accès inter-applications.
- Ne pas activer de communications réseau en clair ou de fonctionnalités de réseau qui n'existent pas dans le périmètre produit.
- Utiliser une construction de production sans options de débogage et distribuée avec une signature de version protégée.
- Ne pas inclure de clés de signature, secrets ou données utilisateur dans le dépôt, les journaux ou l'artefact de distribution.
- Vérifier la configuration de sauvegarde Android décrite à la section 4.

Ces exigences restent proportionnées : aucun service de surveillance, infrastructure de sécurité distante ou procédure complexe de réponse à incident n'est requis pour une application personnelle locale.

## 11. Risques résiduels et limites de protection

Inventory V1 ne peut garantir :

- la confidentialité face à une personne utilisant l'application alors que l'appareil est déverrouillé ;
- la confidentialité sur un appareil compromis, rooté ou sous contrôle système complet ;
- l'absence de copie par un fournisseur de fichiers ou une application tierce choisi par l'utilisateur ; Inventory exclut les données des mécanismes Android configurables, mais ne peut garantir le comportement d'un outil de migration propriétaire qui contourne ces règles ;
- l'effacement de sauvegardes externes lors d'une suppression ou désinstallation ;
- la disponibilité des données après panne matérielle ou effacement si aucune sauvegarde indépendante n'existe ;
- la protection physique contre observation de l'écran, capture d'écran ou appareil laissé sans surveillance.

Les garanties de V1 reposent sur le stockage privé, les contrôles d'intégrité, les décisions explicites de l'utilisateur et les protections Android usuelles. L'absence de chiffrement applicatif ne signifie pas que les données sont sans sensibilité ; elle est un choix proportionné au contexte et aux limites des clés locales.

## 12. Exigences de sécurité vérifiables

| ID | Exigence et vérification | Responsable | Priorité |
| --- | --- | --- | --- |
| SEC-01 | La base, ses journaux et fichiers temporaires résident dans le stockage privé de l'application ; vérifier sur une construction Android de production et confirmer qu'ils ne sont pas dans un espace partagé. | Inventory / Android | Bloquant V1 |
| SEC-02 | Exclure les données Inventory du cloud Android, des transferts directs et de tout canal système applicable ; vérifier les règles `fullBackupContent` et, pour les appareils/API et cibles concernés, `dataExtractionRules` (`cloud-backup`, `device-transfer` et canal supplémentaire pris en charge). Tester les flux sur les API et niveaux de cible retenus ; `allowBackup=false` seul ne suffit pas. | Configuration Android / Inventory | Bloquant V1 — décision confirmée |
| SEC-03 | L'export et la restauration sont déclenchés volontairement et passent par une destination/source choisie ; confirmer l'absence de permission générale de stockage et tester l'accès à un fichier non choisi, qui doit être refusé. | Inventory / Android | Bloquant V1 |
| SEC-04 | Le manifeste fusionné de production ne contient aucune permission ou composant injustifié ; contrôler les permissions réseau, stockage, caméra, localisation et composants exportés. | Construction Android / Inventory | Bloquant V1 |
| SEC-05 | Aucune transmission réseau, analytique, publicité ou identifiant de suivi n'est utilisée par les fonctionnalités V1 ; examiner dépendances et comportement de production, et vérifier que l'application fonctionne sans réseau. | Inventory / dépendances | Bloquant V1 |
| SEC-06 | Les noms, chemins, descriptions, valeurs et contenus de sauvegarde ne figurent pas dans les journaux de production ; provoquer des erreurs et vérifier les sorties locales. | Inventory | Bloquant V1 |
| SEC-07 | Toute écriture métier utilise les validations et transactions prévues ; un échec ne laisse pas de résultat partiel et n'affiche pas de succès. | Domaine / Drift / SQLite | Bloquant V1 |
| SEC-08 | Les contraintes de hiérarchie, catégories, quantités, valeurs et statuts sont celles du document 04 ; tenter les cas invalides et vérifier le refus sans altération. | Domaine / SQLite | Bloquant V1 |
| SEC-09 | Un fichier invalide/incompatible, une annulation ou un rollback vérifié avant commit ne modifie pas l'inventaire actif ; si le commit est incertain, résoudre l'issue à partir du journal après récupération SQLite avant d'annoncer un résultat. | Inventory / Drift / SQLite | Bloquant V1 |
| SEC-10 | Une sauvegarde est décrite à l'utilisateur comme un fichier sensible, et l'interface signale que le fournisseur choisi peut le copier ou le synchroniser indépendamment d'Inventory. | UX Inventory | Bloquant V1 |
| SEC-11 | Les configurations de production sont non-débogables et signées ; aucun secret ou fichier de signature n'est livré dans le dépôt ou l'artefact. | Distribution Android | Bloquant V1 |
| SEC-12 | Toute dépendance ajoutée est justifiée et vérifiée quant à sa maintenance, ses permissions, sa collecte et ses capacités réseau. | Développement | Bloquant V1 à chaque ajout |
| SEC-13 | Aucun chiffrement applicatif SQLite ou de sauvegarde, mot de passe maître, verrou applicatif ou biométrie n'est prévu en V1 ; le fichier exporté est explicitement traité comme sensible et non chiffré. | Produit / développement | Décision confirmée V1 |

## 13. Scénarios de validation Android

Les vérifications ci-dessous sont réalisables sur un appareil Android réel. Les contrôles techniques complètent les parcours visibles ; ils ne remplacent pas la validation d'usage.

### Scénario 1 — Isolation et hors ligne

1. Installer la version de production sur un appareil de validation.
2. Créer plusieurs biens avec des chemins et valeurs distinctifs.
3. Activer le mode avion et utiliser l'inventaire, la recherche et les modifications.
4. Quitter et rouvrir l'application.

**Résultat attendu :** toutes les fonctions métier demeurent disponibles hors ligne ; les données persistent ; aucune fonction n'exige un compte ou un accès réseau.

### Scénario 2 — Permissions minimales

1. Examiner les permissions déclarées dans l'artefact de production.
2. Utiliser sauvegarde et restauration au moyen du sélecteur Android.
3. Refuser toute permission générale qui ne serait pas nécessaire.

**Résultat attendu :** les opérations V1 fonctionnent sans permission générale de stockage, caméra, contacts ou localisation ; seules les URI choisies sont accessibles.

### Scénario 3 — Fichier exporté et fournisseur de documents

1. Lancer l'export, choisir une destination locale et confirmer.
2. Annuler un second export, puis provoquer une destination indisponible si le fournisseur de test le permet.
3. Répéter avec un fournisseur externe disponible, en vérifiant que l'interface ne qualifie pas ce fournisseur de stockage privé Inventory.

**Résultat attendu :** état « export vérifié » seulement après relecture conforme ; si la relecture est impossible, état « écrit, mais non vérifiable » sans promesse de validité distante ; annulation ou erreur explicitement signalée ; avertissement sur la sensibilité et les copies éventuelles hors d'Inventory.

### Scénario 4 — Restauration invalide et atomique

1. Créer un inventaire de référence et en vérifier quelques biens.
2. Sélectionner un fichier invalide ou incompatible et lancer la restauration.
3. Vérifier l'erreur puis rouvrir l'inventaire.
4. Sélectionner une sauvegarde valide et confirmer le remplacement.

**Résultat attendu :** le fichier invalide n'altère aucune donnée active ; la sauvegarde valide restaure les relations, valeurs et historiques ; aucun état partiel n'est visible en cas d'échec.

### Scénario 5 — Erreurs et journaux

1. Tenter une opération métier invalide, comme un déplacement qui créerait une boucle.
2. Déclencher une erreur de lecture de fichier et une interruption d'écriture sur environnement de test lorsque possible.
3. Examiner les messages de l'application et les journaux de production disponibles.

**Résultat attendu :** message clair sans détails internes ni donnée personnelle ; échec non présenté comme succès ; aucune valeur, nom ou chemin personnel dans les journaux.

### Scénario 6 — Sauvegarde système et désinstallation

1. Vérifier la configuration Android de sauvegarde système de la construction de production.
2. Tester les scénarios de sauvegarde/restauration de plateforme pertinents sur les versions Android ciblées, sans les confondre avec l'export Inventory.
3. Vérifier que l'interface explique que la désinstallation peut effacer la base privée, tandis qu'un fichier exporté ailleurs peut rester présent.

**Résultat attendu :** la politique de sauvegarde système correspond à la décision locale ; l'utilisateur comprend que la récupération après désinstallation exige une sauvegarde exportée et conservée indépendamment.

## 14. Décisions confirmées et vérifications d'implémentation

### Confirmé par les documents produit

- V1 Android, locale et hors ligne, sans compte, serveur, API distante ni synchronisation.
- Données persistées par Drift/SQLite ; la couche domaine valide les règles métier et les opérations sensibles sont transactionnelles.
- Export et restauration locaux ; restauration complète après validation et remplacement des données actives.
- Les données Inventory sont exclues des sauvegardes automatiques et transferts système Android, avec règles conditionnelles par API et `targetSdkVersion` ; cette décision n'est pas une simple recommandation.
- Aucun chiffrement supplémentaire des sauvegardes exportées ni chiffrement SQLite/SQLCipher, mot de passe maître, verrouillage applicatif ou biométrie en V1.
- Pas de photos ni QR ; pas de télémétrie, publicité ou fonctionnalités de partage distantes dans le périmètre du mandat.
- Le modèle du document 04 définit les contraintes de hiérarchie, valorisation, catégories, retrait et suppression.

### Exigences de sécurité et mise en œuvre

- Stocker SQLite et ses fichiers auxiliaires uniquement dans le répertoire privé interne de l'application.
- Appliquer la décision confirmée d'exclusion à toutes les règles Android applicables et tester le cloud, les transferts directs et tout canal ultérieur pris en charge.
- Utiliser le Storage Access Framework/sélecteur Android pour sauvegarde et restauration, sans permission générale de stockage.
- Présenter les fichiers exportés comme sensibles et non chiffrés ; expliquer les risques de copie/synchronisation par le fournisseur choisi. Distinguer un export vérifié d'un fichier écrit mais non vérifiable.
- Garder les journaux de production dépourvus de noms, valeurs, chemins et contenus de sauvegarde.
- Ne pas inclure de chiffrement SQLite, chiffrement de sauvegarde, verrouillage applicatif ou biométrie, conformément aux décisions V1.
- Vérifier le manifeste fusionné, les dépendances et la configuration de production avant distribution.

### Points d'implémentation à vérifier, non décisions ouvertes

- Les versions minimale/cible Android et le `targetSdkVersion` détermineront les fichiers de règles à appliquer ; leurs valeurs ne sont pas inventées par ce document.
- La configuration Android doit exclure chaque domaine effectivement utilisé et doit être testée sur les versions et transferts visés. Les outils OEM qui contournent les règles Android restent une limite à mesurer, pas une autorisation de réactiver les sauvegardes système.
- Le fichier `.invbackup` n'est pas chiffré. Si le fournisseur ne permet pas de le relire après écriture, l'interface doit afficher l'état « écrit, mais non vérifiable » sans promettre que le fichier est valide ou conservé.

## Références Android

- [Bonnes pratiques de sécurité Android](https://developer.android.com/privacy-and-security/security-best-practices)
- [Sauvegarde des données Android](https://developer.android.com/identity/data/backup)
- [Accès aux documents et fichiers avec le Storage Access Framework](https://developer.android.com/training/data-storage/shared/documents-files)
