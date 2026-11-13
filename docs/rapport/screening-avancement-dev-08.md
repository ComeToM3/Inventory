# Screening d'avancement Inventory V1 — après DEV-08

## 1. Synthèse exécutive

**Verdict : VALIDÉ SOUS RÉSERVES pour le screening ; V1 non livrable à ce stade.** Les parcours d'inventaire jusqu'au déplacement sont présents dans le code et leurs rapports décrivent des observations sur émulateur. Catégories et valorisations disposent de contrats métier, mais leur édition n'est pas accessible ; recherche, sorties d'inventaire, sauvegarde et restauration restent à construire. Aucun blocage imprévu de DEV-09 n'est démontré par cette lecture.

**Méthode :** inspection ciblée des instructions, [blueprint](../blueprint.md), [essential-doc](../essential-doc.md), [feuille de route](../road-sheet.md), spécifications, rapports DEV-01 à DEV-08 et code. Les observations Android et résultats de tests ci-dessous sont **rapportés**, non réexécutés ici. Aucune nouvelle observation physique, compilation ou campagne de tests.

Le parcours émulateur jusqu'à DEV-08 ne prouve ni l'expérience sur Moto G24 Power ni la protection et la récupération des données de la V1. La validation physique du jalon 2 reste ouverte ; les validations de livraison sont prévues après les fonctions restantes.

## 2. Matrice d'avancement DEV-01 à DEV-15

Statut « terminé » : périmètre du mandat réalisé, sans effacer les réserves du rapport. « Non commencé » : fonctionnalité du mandat non livrée en interface, même si des fondations existent.

| Mandat | Statut | Preuve et limite principale |
| --- | --- | --- |
| DEV-01 — Socle | Terminé, sous réserves | [Rapport](rapport-dev-01.md) : persistance observée sur émulateur ; téléphone installé mais verrouillé ; release arm64 historique construite, 32 bits bloqué par Windows Application Control. |
| DEV-02 — Schéma | Terminé, sous réserves | [Base Drift](../../lib/core/database/inventory_database.dart), schéma v2 et migration v1→v2 ; [rapport](rapport-dev-02.md) : tests SQLite et compilation, pas d'observation Android pendant DEV-02. Migration normale observée ultérieurement selon [DEV-05](rapport-dev-05.md). |
| DEV-03 — Domaine | Terminé, sous réserves | [Moteur](../../lib/core/domain/inventory_engine.dart), transactions et [tests](../../test/core/domain/inventory_engine_test.dart) ; [rapport](rapport-dev-03.md) : règles vérifiées automatiquement et trois choix conservateurs soumis à arbitrage. |
| DEV-04 — Navigation | Terminé, sous réserves | [Navigation](../../lib/app/main_navigation_screen.dart) ; [rapport](rapport-dev-04.md) : quatre destinations observées sur émulateur par ADB, pas de manipulation humaine ni validation physique. |
| DEV-05 — Arbre | Terminé, sous réserves | [Contrôleur](../../lib/app/inventory_tree_controller.dart), [écran](../../lib/app/inventory_tree_screen.dart) ; [rapport](rapport-dev-05.md) : branches et défilement observés sur émulateur avec base en mémoire. |
| DEV-06 — Création | Terminé, sous réserves | [Formulaire](../../lib/app/inventory_creation_screen.dart) et [rapport](rapport-dev-06.md) : cinq formes et persistance observées sur base fichier isolée. |
| DEV-07 — Fiches et édition | Terminé, sous réserves | [Fiche](../../lib/app/node_details_screen.dart), [édition](../../lib/app/node_edit_screen.dart) et [rapport](rapport-dev-07.md) : parcours complet observé sur émulateur ; jalon 2 sous réserve physique. |
| DEV-08 — Déplacement | Terminé | [Sélecteur](../../lib/app/node_move_screen.dart), [moteur](../../lib/core/domain/inventory_engine.dart) et [rapport](rapport-dev-08.md) : déplacement et persistance sur émulateur ; cas critiques complémentaires en tests. Réserve physique inchangée. |
| DEV-09 — Catégories et valorisation | Non commencé en interface | Contrats métier et consultation existent ; aucun formulaire spécialisé opérationnel. |
| DEV-10 — Recherche | Non commencé | Écran provisoire ; aucun contrat de recherche globale identifié dans le moteur. |
| DEV-11 — Retrait, historique, suppression | Non commencé en interface | Contrats métier présents ; écran Historique provisoire et aucune action de sortie exposée. |
| DEV-12 — Export | Non commencé | Format et procédure documentés, pas de parcours d'export identifié. |
| DEV-13 — Restauration | Non commencé | Contrat de reprise documenté, sans implémentation de restauration ou de journal dédiée identifiée. |
| DEV-14 — Validation V1 | Non commencé | [Scénarios](../04-user-validation.md) couvrent des fonctions encore absentes ; parcours physique complet non démontré. |
| DEV-15 — Livraison | Non commencé | Build debug récent rapporté ; la configuration release actuelle utilise la clé de debug, pas une signature de distribution dédiée. |

## 3. État fonctionnel réel

| Capacité | Statut | Preuve et écart important |
| --- | --- | --- |
| Fondations Android et persistance | **Opérationnel sur émulateur, sous réserves** | Point d'entrée [main](../../lib/main.dart), base privée Drift et rapports [DEV-01](rapport-dev-01.md), [DEV-06](rapport-dev-06.md) ; persistance après relance rapportée. Téléphone physique et utilisation d'un inventaire réel non vérifiés ici. |
| Modèle et moteur métier | **Opérationnel en interne, sous réserves** | Tables et contraintes dans [la base](../../lib/core/database/inventory_database.dart), règles dans [le moteur](../../lib/core/domain/inventory_engine.dart) ; tests ciblés rapportés. La recherche et les opérations complètes de sauvegarde ne sont pas incluses. |
| Navigation et arbre | **Opérationnel sur émulateur** | `IndexedStack`, cache des branches, chargement à la demande ; [DEV-05](rapport-dev-05.md) rapporte ouvertures et retour. Inventaire volumineux et performance non mesurés. |
| Création | **Opérationnel sur émulateur** | Création rapide par l'interface et moteur ; [DEV-06](rapport-dev-06.md) rapporte annulation, validation et persistance. Champs avancés réservés aux mandats suivants. |
| Consultation et modification | **Opérationnel sur émulateur** | Nom, description, état et quantité modifiables ; catégories et valorisation en lecture seule. [DEV-07](rapport-dev-07.md) rapporte sauvegarde, annulation et relance. |
| Déplacement | **Opérationnel sur émulateur** | Action depuis la fiche, sélecteur, confirmation et opération transactionnelle ; [DEV-08](rapport-dev-08.md) rapporte conservation des descendants, catégories et propriétés après relance. |
| Catégories et valeurs | **Partiel** | Création/association des catégories et changement exclusif de valeur existent dans le moteur ; fiche en lecture seule. Édition utilisateur et validation associée relèvent de DEV-09. |
| Recherche et historique | **Partiel** | Les onglets sont des [écrans provisoires](../../lib/app/main_navigation_screen.dart) ; `getWithdrawnItems`, retrait et suppression existent dans le moteur, sans parcours utilisateur. Pas de recherche par nom/catégorie/emplacement. |
| Sauvegarde, restauration, distribution | **Non implémenté pour l'utilisateur** | [Conception de récupération](../09-backup-recovery.md) uniquement ; Paramètres est provisoire. Builds historiques et actuels rapportés, mais aucune sauvegarde restaurable, signature finale ou distribution V1 démontrée. |

## 4. Cohérence architecturale

- **Constat de code :** [main](../../lib/main.dart) compose une base unique ; [InventoryApp](../../lib/app/inventory_app.dart) crée `InventoryEngine` et le contrôleur d'arbre. Les écrans examinés passent par leurs contrôleurs et le moteur, sans écriture SQL directe. Le moteur utilise des transactions Drift ; contraintes et clés étrangères complètent les validations inter-lignes.
- **Intégration :** création et édition relisent le parent concerné ; déplacement invalide les lectures antérieures et rafraîchit source/destination. Les branches et le défilement sont de l'état de présentation. Les [tests de déplacement](../../test/app/node_move_test.dart) couvrent notamment lectures retardées et réessai ; le [rapport DEV-08](rapport-dev-08.md) rapporte leur réussite, non réexécutée ici.
- **Échecs et asynchronisme :** écriture confirmée distinguée d'une erreur de relecture, messages génériques, double soumission et résultats obsolètes traités dans les parcours inspectés. Ces mécanismes devront être intégrés aux futures écritures, pas contournés.
- **Écart architectural documenté :** [l'architecture](../03-technical-architecture.md) et le [blueprint](../blueprint.md) qualifient Riverpod et `go_router` de choix retenus ; [pubspec](../../pubspec.yaml) et le code utilisent `ChangeNotifier`, `IndexedStack` et `Navigator` natifs. L'écart est réel, mais aucun défaut fonctionnel lié ni nécessité de migration immédiate n'est démontré. Ne pas changer silencieusement les décisions : arbitrer ou documenter la divergence avant d'en faire une exigence de mandat.
- **Écart UX connu :** [UX §2](../06-ux-ui.md) indique trois onglets et Paramètres séparés ; DEV-04 a demandé et livré quatre onglets, comme expliqué dans son [rapport](rapport-dev-04.md). Ne pas traiter la documentation historique comme preuve que l'interface actuelle est identique ; clarification à conserver pour les prochains écrans, sans refonte automatique.

## 5. Risques et réserves

### Bloquants pour les jalons futurs, déjà prévus

- **Protection et récupération des données :** aucun export/restauration accessible ; une perte ou désinstallation avant sauvegarde exploitable peut rendre l'inventaire irrécupérable. Cela bloque la validation de récupération DEV-14 et la livraison V1 tant que DEV-12/13 ne sont pas réalisés.
- **Exclusion des sauvegardes système :** le [manifeste principal](../../android/app/src/main/AndroidManifest.xml) ne déclare ni `allowBackup`, ni `fullBackupContent`, ni `dataExtractionRules` ; aucune ressource de règles correspondante n'a été identifiée dans les sources Android. L'exclusion exigée par [sécurité](../07-security-privacy.md) et [récupération](../09-backup-recovery.md) n'est donc pas démontrée. Manifeste fusionné, comportement cloud/transfert et OEM : **non vérifiés ici** ; aucune copie effective n'est affirmée. Conformité obligatoire avant livraison, prévue en DEV-13.
- **Signature :** [build.gradle.kts](../../android/app/build.gradle.kts) affecte encore la signature debug à `release`. Ce n'est pas une configuration de livraison finale ; DEV-15 doit traiter la signature et sa conservation. Le build arm64 historique DEV-01 ne valide pas l'APK actuel pour distribution.

### À surveiller

- **DEV-09 — atomicité et dépassement :** `setValuation`, `updateQuantity`, `assignCategory` et `unassignCategory` sont des transactions séparées. [UX §6](../06-ux-ui.md) exige l'atomicité des modifications soumises ensemble ; les appeler successivement depuis un formulaire unique ne la garantit pas. De plus, `setValuation` vérifie le montant mais pas le produit quantité × montant ; le [test existant](../../test/core/domain/inventory_engine_test.dart) accepte une valeur dont le total lève ensuite `financialTotalOverflow`. Le formulaire DEV-07 contrôle déjà le total lors d'une modification de quantité ; DEV-09 devra empêcher une validation invalide du formulaire étendu, sans supposer que le contrat actuel le fait.
- **DEV-11 — historique :** le retrait détache le parent (`parentId = null`) et `getPath` exige un nœud actif. La fiche active actuelle ne peut donc pas simplement ouvrir un bien retiré en appelant ce chemin ; adapter la consultation historique en lecture seule sans inventer d'ancien emplacement. Les trois restrictions conservatrices du [rapport DEV-03](rapport-dev-03.md) — bien retiré non supprimable/non modifiable, type immuable — restent à confirmer si un futur mandat en dépend ; aucune décision ultérieure n'a été identifiée dans ce screening.
- **Restitution et caches :** la restauration doit bloquer les opérations concurrentes, récupérer l'issue incertaine et rafraîchir l'ensemble des états après remplacement. Le démarrage actuel lance immédiatement `loadRoots` ; le journal `pending`/`committed` et sa reprise ne sont pas présents dans le schéma actuel. Leur ajout nécessite la migration explicite prévue par DEV-13.
- **Validation :** les rapports DEV-04 à DEV-08 décrivent des interactions ADB sur émulateur, pas une campagne humaine sur téléphone. Taille réelle, clavier, accessibilité, performance en grand volume et comportement physique restent non vérifiés. Le précédent échec de build release 32 bits concerne l'environnement DEV-01 ; sa pertinence dépend des architectures retenues pour DEV-15.

### Facultatif

- Les libellés d'avancement initiaux de la [feuille de route](../road-sheet.md) indiquent encore « DEV-00 terminé » et « DEV-01 à démarrer », contrairement aux rapports et au code actuels. C'est une incohérence documentaire, sans incidence démontrée sur le fonctionnement.

## 6. Préparation DEV-09 à DEV-15

| Mandat | Réutilisable → reste à développer | Dépendances et vigilance |
| --- | --- | --- |
| **DEV-09** | Modèles, catégories, `setValuation`, fiche et formulaire existants → sélection/gestion des catégories et édition des deux modes. | Cohérence d'un enregistrement groupé, total exact et dépassement ; conserver exclusivité, annulation, actualisation fiche/arbre. Pas de refonte d'écrans demandée. |
| **DEV-10** | Tables, index, chemins et fiche active → requêtes et interface de recherche/filtrage, accès aux résultats. | Catégories DEV-09 pour un parcours utilisateur complet ; exclure les retirés, restituer le chemin et préserver le contexte. |
| **DEV-11** | `withdrawItem`, `deleteNodePermanently`, `getWithdrawnItems`, protections D02/D07 → actions distinctes, confirmations et historique. | Actualiser caches ; historique sans `getPath` actif, motif/date et préservation de l'archive ; clarifier les restrictions DEV-03 si nécessaires. |
| **DEV-12** | Schéma métier et transactions de lecture → export complet, sélecteur Android, encadrement et vérification. | Respecter [contrat d'export](../09-backup-recovery.md) : instantané logique SQLite cohérent, JSON UTF-8 encadré, longueur et SHA-256 ; fichier non chiffré, fournisseur parfois non relisible. « Instantané SQLite » dans la feuille de route n'impose pas une copie brute : le document spécialisé l'interdit. |
| **DEV-13** | Contraintes SQLite et modèle → validation en base temporaire, remplacement transactionnel, journal/reprise, exclusion système. | Format DEV-12 ; migration explicite du journal, `synchronous=FULL` sur la connexion concernée, issue de commit incertaine et rafraîchissement contrôlé ; test des règles Android par API. Aucun mécanisme existant ne démontre déjà ces garanties. |
| **DEV-14** | [Plan utilisateur](../04-user-validation.md), parcours émulateur et tests rapportés → validation de bout en bout sur appareil réel. | Fonctions DEV-09 à DEV-13, appareil accessible et scénarios de persistance/sauvegarde/restauration ; tests automatisés complémentaires, pas substituts. |
| **DEV-15** | Configuration Android et résultats de builds historiques → signature de distribution, configuration finale et installation de l'APK retenu. | Validation DEV-14, politique d'exclusion système, architectures retenues et clé de signature ; vérifier le manifeste fusionné/release actuel plutôt que déduire son contenu de DEV-01. |

L'ordre DEV-09 → DEV-15 reste cohérent avec ces dépendances. Les règles de sauvegarde système sont planifiées en DEV-13 : tant qu'elles ne sont pas vérifiées, ne pas présenter l'application comme sûre pour des données réelles sensibles ou comme prête à distribuer.

## 7. Recommandation et arrêt

**Poursuivre la séquence prévue avec DEV-09 après autorisation**, en explicitant dans ce mandat l'atomicité du formulaire étendu et le contrôle du total. Maintenir les réserves de validation physique et de protection des données jusqu'aux jalons correspondants. Faire arbitrer les divergences documentaires ou choix conservateurs seulement lorsqu'une décision devient nécessaire ; aucun changement d'ordre ni refonte générale n'est justifié par les preuves examinées.

Ce screening ne corrige aucun défaut, ne modifie aucun fichier existant et ne lance pas DEV-09. **Arrêt après remise du rapport.**
