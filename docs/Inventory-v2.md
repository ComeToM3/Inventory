# Inventory V2 — Plan directeur de développement

**Version document :** 2.0.0-LIVRÉE — 25 novembre 2026  
**Statut :** Inventory V2 **livré** — version applicative officielle `2.0.0` (versionCode arm64 `6051`)  
**Plateforme :** Android uniquement (minSdk 24, targetSdk 36, ABI arm64-v8a)  
**Technologies :** Flutter, Dart, Drift/SQLite (schéma **15**)  
**Fonctionnement :** Local, hors ligne, sans compte ni synchronisation  
**Sauvegarde :** `.invbackup` format **2**, données **3**  
**Artefact :** `dist/android/Inventory-v2.0.0-arm64-release-vc6051.apk`  
**Rapport de livraison :** `docs/rapport-v2/m5-4-livraison-officielle-cloture-v2.md`  
**Référence comportementale :** Inventory V1 existante  
**Audit technique :** `docs/rapport-v2/spécification-technique-préliminaire-v2.md`

---

## 0. Objet et gouvernance

Ce document constitue la **référence fonctionnelle principale d'Inventory V2**.

Il définit :

- Les fonctionnalités attendues.
- Les décisions produit validées.
- Les règles métier des trois espaces.
- Les invariants techniques et ergonomiques.
- Les phases et mandats de développement.
- Les critères de validation et de réception.

Il ne remplace pas l'inspection du code réel pour déterminer les classes, tables, écrans, signatures, migrations et mécanismes existants.

Les rapports de mandats documentent les réalisations effectives. Le plan décrit la cible fonctionnelle et les décisions applicables.

### 0.1 Principes fondamentaux

1. **Préserver l'application existante.** Inventory V2 prolonge V1 ; il ne s'agit pas d'une réécriture.
2. **Réutiliser avant de créer.** Vérifier les composants, fonctions et modèles existants avant toute nouvelle implémentation.
3. **Préserver l'ergonomie V1.** Ne pas reconstruire les écrans ni modifier inutilement les parcours validés.
4. **Développer par mandats bornés.** Un mandat, un rapport, un verdict et un arrêt.
5. **Valider le fonctionnement réel.** Compilation, installation et parcours utilisateur sur émulateur lorsque le mandat modifie l'application.
6. **Corriger les défauts confirmés.** Ne pas accumuler les régressions, mais éviter les audits répétitifs et les améliorations facultatives sans fin.
7. **Respecter les décisions produit.** Ne pas ajouter de fonctionnalités hors périmètre.
8. **Aucun commit ou push automatique.**
9. **Aucune manipulation des données personnelles sans autorisation explicite.**

### 0.2 Politique de base de données V1 → V2 — décision mise à jour

La migration des anciennes données SQLite V1 vers V2 **n'est plus une obligation de développement**.

L'utilisateur accepte de démarrer avec une base V2 vierge lorsque la migration devient trop complexe, coûteuse ou ralentit inutilement le projet.

Cette décision concerne **uniquement les données et leur migration**, pas le code ni les fonctionnalités.

Conséquences :

- Conserver les composants et comportements V1.
- Conserver les mécanismes de migration déjà implémentés lorsqu'ils fonctionnent et ne gênent pas V2.
- Ne pas consacrer de nouveaux mandats à une compatibilité V1 non nécessaire.
- Autoriser la réinitialisation des données fictives de l'émulateur lorsque justifiée.
- Ne jamais effacer des données personnelles ou une base réelle sans autorisation spécifique.
- Maintenir des migrations sûres pour les évolutions ultérieures de V2 lorsque des données doivent être conservées.

**L'intégrité des données créées dans V2 demeure obligatoire.**

L'importation de sauvegardes V1 prévue par D10 reste une fonctionnalité distincte. Son éventuel retrait nécessite une décision produit explicite.

### 0.3 Politique de validation Android — décision mise à jour

**L'émulateur Android est l'environnement principal de développement et de validation.**

À chaque mandat pertinent :

1. Implémenter le périmètre autorisé.
2. Analyser et compiler.
3. Installer et lancer sur émulateur.
4. Exécuter des parcours fonctionnels réels.
5. Corriger les régressions confirmées.
6. Produire le rapport.
7. Arrêter.

La validation sur **Moto G24 Power** est réservée à la fin du développement pour les performances, l'ergonomie tactile et les ajustements matériels.

Une exception anticipée n'est justifiée que par un problème matériel spécifique impossible à reproduire sur émulateur, et nécessite une autorisation.

### 0.4 Statuts de décision

- **DÉCIDÉ :** arbitrage explicite de l'utilisateur.
- **RECOMMANDÉ :** proposition de conception non encore obligatoire.
- **À AUDITER :** point nécessitant inspection technique ou mesure.
- **IMPLÉMENTÉ :** présent dans le code.
- **VALIDÉ SUR ÉMULATEUR :** fonctionnement observé dans l'application.
- **VALIDATION FINALE :** réception utilisateur et vérification physique de fin de développement.

---

## 1. Décisions produit consolidées

Les décisions V2-00 restent applicables.

| ID | Décision | Statut |
|---|---|---|
| D01 | Indicateur Stock à quatre états (1 → ½ → ¼ → 0), cycle dans l'arborescence ; quantité de référence facultative | DÉCIDÉ (M2.1-C) |
| D02 | Pas d'unités de référence, coûts, poids ni volumes dans l'UI Stock courante | DÉCIDÉ (M2.1-C) |
| D03 | Fusion Stock lors d'une acquisition uniquement sur choix explicite | DÉCIDÉ |
| D04 | Besoins abandonnés conservés dans l'historique ; suppression distincte | DÉCIDÉ |
| D05 | Historique d'achat, acquisitions partielles et complètes | DÉCIDÉ |
| D06 | Prix payé distinct de la valorisation d'un bien | DÉCIDÉ |
| D07 | Documents PDF/JPEG/PNG/WebP, maximum 15 Mo par document | DÉCIDÉ |
| D08 | Caméra, galerie et stockage privé WebP optimisé | DÉCIDÉ |
| D09 | Organisation manuelle de l’arborescence — **évolution livrée :** manipulation directe par appui long et glisser-déposer (réordonnancement frères et changement de parent) ; le mode menu « Organiser » distinct a été retiré | DÉCIDÉ (livré DnD) |
| D10 | Sauvegarde `.invbackup` V2 versionnée, médias inclus, import V1 prévu | DÉCIDÉ, avec politique de migration SQLite assouplie |

Les décisions de fonctionnement, d'interface et de sécurité déjà validées restent en vigueur.

---

## 2. Vision générale et navigation

Inventory V2 comporte trois espaces accessibles depuis une navigation inférieure :

1. **Biens** — patrimoine matériel et objets durables.
2. **Stock** — produits consommables et proportion restante visible.
3. **À acheter** — besoins, achats planifiés et acquisitions.

Les trois espaces partagent un moteur commun, mais possèdent des hiérarchies indépendantes.

### Règles communes

- Chaque nœud appartient explicitement à un espace.
- Les relations parent-enfant doivent respecter cet espace.
- Aucun déplacement hiérarchique direct entre espaces.
- Aucun transfert automatique selon le nom.
- Aucune association automatique entre emplacements homonymes.
- Recherche et création contextualisées.
- Navigation et états d'expansion indépendants.
- Aucun mélange des règles de valorisation, de quantité ou d'historique.
- Paramètres, aide et sauvegardes accessibles sans créer trois applications distinctes.

### État d'implémentation

**Déjà implémenté :**

- Appartenance explicite `goods`, `stock`, `to_buy`.
- Navigation inférieure à trois destinations.
- Trois contrôleurs et arbres indépendants.
- Conservation des états d'expansion pendant la session.
- Filtrage des arbres par espace.
- Démarrage sur Biens.
- Stock et À acheter affichés comme espaces non encore fonctionnels.

**À finaliser en M1.3 :**

- Contextualisation complète de la recherche.
- Contextualisation de la création.
- Contextualisation de l'historique.
- Cohérence des actions et des retours de navigation.

---

## 3. Espace Biens — conservation de V1

L'espace Biens prolonge les fonctionnalités existantes.

### Fonctionnalités à préserver

- Emplacements.
- Biens simples.
- Biens-contenants valorisés.
- Hiérarchies imbriquées.
- Quantités entières.
- Valeur financière.
- Valeur sentimentale de 1 à 5.
- Exclusivité des modes de valorisation.
- Création et modification.
- Consultation progressive.
- Recherche hiérarchique.
- Déplacement entre parents admissibles.
- Retrait pour perte, don, bris ou vente.
- Historique des retraits.
- Agrégation des valeurs sans double comptage.
- Sauvegarde et restauration selon les capacités existantes, puis évolution vers V2.

Un bien-contenant peut avoir sa propre valeur et contenir des descendants valorisés. Les agrégations doivent rester cohérentes.

### Compatibilité

La conservation du **comportement V1** est obligatoire.

La conservation de **toutes les anciennes données SQLite V1** n'est plus une condition bloquante pour développer V2.

### État de validation

M1.2-C a démontré sur émulateur :

- Création et modification.
- Expansion multi-niveaux.
- Recherche avec chemin.
- Déplacement.
- Retrait et historique.
- Conservation des branches après changement d'onglet.
- Persistance après redémarrage.

Ces résultats constituent une validation de développement, pas une réception utilisateur finale.

---

## 4. Espace Stock — règles métier

Stock est un **inventaire visuel simple** : savoir instantanément si un produit est complet, à moitié, au quart ou épuisé.

Ce n'est **pas** un gestionnaire de quantités physiques, d'emballages, de poids, de volumes ni de coûts.

Chaque produit comporte au minimum :

- Un nom.
- Un emplacement hiérarchique.
- Un indicateur de proportion restante parmi **1**, **½**, **¼**, **0**.

Une **quantité de référence** facultative (ex. 10) peut être conservée dans la fiche. Elle n'est pas une unité de mesure et n'est pas affichée dans l'arborescence.

### 4.1 Quatre états — D01 (M2.1-C)

**DÉCIDÉ :**

- Quatre états seulement : **1** (complet), **½**, **¼**, **0** (épuisé).
- Aucune autre fraction (pas de ¾, 1,25, 2,5, etc.).
- Appréciation relative, pas une mesure physique exacte.
- Cycle tactile dans l'arborescence : **1 → ½ → ¼ → 0 → 1**.
- Une seule interaction par changement ; pas de dialogue ; persistance immédiate.
- Nouveau produit démarre à **1** ; aucune fraction demandée à la création.
- Contrôle circulaire uniquement sur les produits Stock (pas sur emplacements ni contenants), dans la zone d'actions à gauche du `+` lorsque celui-ci s'applique aux parents.
- Produit à 0 reste présent.
- Aucun transfert automatique vers À acheter.

| État | Signification | Persistance (`quantity`) |
|---|---|---|
| 1 | Complet | 4 |
| ½ | Environ la moitié | 2 |
| ¼ | Environ le quart | 1 |
| 0 | Épuisé | 0 |

Conversion déterministe des anciens soldes multi-quarts : `≤0 → 0`, `1 → ¼`, `2|3 → ½`, `≥4 → 1`.

### 4.2 Sans unités ni mesures dans l'UI — D02 (M2.1-C)

**DÉCIDÉ :**

- Retirer de la fiche Stock : unités de référence, coût par unité, poids/volume, choix de fraction à la création.
- Ne pas déplacer ces champs vers un autre écran.
- Ne pas imposer de libellés d'emballage (« paquet », « bouteille », etc.).
- Colonnes SQLite héritées peuvent rester non destructives ; l'UI ne les expose plus.
- Quantité de référence facultative seule conservée dans la fiche.

### 4.3 Historique des changements de niveau

Chaque changement d'état enregistre de façon atomique :

- Produit.
- Ancien état.
- Nouvel état.
- Date/heure.

L'utilisateur ne gère plus approvisionnement / consommation / correction en quarts pour l'opération courante. Le ledger technique existant est réutilisé (`correct` pour un cycle).

### 4.4 Valorisation Stock

Aucune valorisation monétaire Stock dans M2.1-C. Les coûts unitaires ne sont plus saisis ni affichés.

### 4.5 Validation attendue

- Création produit sans fraction ; état initial 1.
- Cycle 1 → ½ → ¼ → 0 → 1 dans l'arbre.
- Indépendance entre produits.
- Fiche sans unité ni coût.
- Historique lisible (produit, ancien → nouveau, date).
- Recherche Stock isolée.
- Persistance après redémarrage.
- Non-régression Biens et À acheter.

---

## 5. Espace À acheter — règles métier

Chaque besoin comprend :

- Nom.
- Emplacement hiérarchique.
- Quantité souhaitée.
- Prix cible unitaire facultatif.
- Priorité facultative, selon arbitrage.

Le prix cible n'est ni un prix réellement payé ni une valeur patrimoniale.

### 5.1 Acquisition

L'utilisateur doit choisir explicitement :

- Quantité réellement achetée.
- Destination Biens ou Stock.
- Emplacement de destination.
- Prix réellement payé, facultatif.

Aucune destination ne doit être déduite automatiquement du nom.

L'acquisition doit être atomique.

### 5.2 Achat partiel

Exemple :

Besoin initial : 10 unités.

Achat : 4 unités.

Résultat :

- 4 unités créées ou ajoutées dans la destination choisie.
- 6 unités restant dans À acheter.
- Événement d'acquisition enregistré.

### 5.3 Acquisition complète

Lorsqu'un besoin est entièrement satisfait :

- Il quitte la liste active.
- Son historique reste consultable.
- La destination est enregistrée.

### 5.4 Fusion Stock — D03

Deux possibilités :

- Sélectionner explicitement un produit Stock existant compatible.
- Créer un nouveau produit Stock.

Aucune fusion automatique basée uniquement sur le titre.

Si un produit existant est sélectionné, la quantité augmente dans la même transaction que l'acquisition.

Vers Biens, créer un bien distinct sans fusion silencieuse.

### 5.5 Abandon — D04

L'action **Abandonner** retire le besoin de la liste active, tout en conservant son historique.

La suppression définitive est une opération différente, volontaire et confirmée.

### 5.6 Historique des acquisitions — D05

Conserver au minimum :

- Date.
- Article.
- Quantité acquise.
- Prix cible au moment de l'achat.
- Prix réel facultatif.
- Espace de destination.
- Emplacement de destination.
- Référence du bien ou produit concerné.

### 5.7 Valorisation vers Biens — D06

À l'acquisition, permettre :

- Valeur financière.
- Valeur sentimentale.
- Absence de valorisation.

Les modes financier et sentimental restent exclusifs.

Le prix payé ne devient pas automatiquement la valeur du bien.

### 5.8 Validation attendue

- Création d'un besoin.
- Achat partiel.
- Achat complet.
- Destination explicite.
- Fusion Stock choisie.
- Création d'un nouveau produit.
- Acquisition vers Biens.
- Abandon.
- Historique.
- Gestion d'échec sans demi-transfert ni doublon.
- Persistance après redémarrage.

---

## 6. Fiches simples et informations avancées

Conserver le parcours de création/modification V1.

Ajouter une section repliable :

**Informations avancées**

La saisie simple ne doit pas devenir plus complexe.

### Préférences d'affichage

La préférence globale « Afficher les informations avancées par défaut » détermine uniquement l'état initial des nouvelles fiches.

Chaque fiche conserve ensuite son propre état.

Modifier la préférence globale ne doit pas changer les fiches déjà créées.

Masquer les informations avancées ne supprime aucune donnée.

### Champs avancés

Selon le type de fiche :

- Photo principale.
- Facture ou document.
- Code-barres ou référence.
- Informations d'achat.
- Objectif actif pour les biens pertinents : Aucun, Vendre, Réparer.

Un objectif n'est ni un état de retrait ni une tâche.

Aucun système complet de tâches, ventes, réparations ou garanties n'est prévu.

---

## 7. Photos et documents

### 7.1 Photos — D08

- Une photo principale par fiche.
- Stockage privé Android.
- SQLite conserve références et métadonnées.
- Aucun BLOB image en base.
- Format WebP avec perte.
- Qualité initiale 80.
- Dimension maximale 1 280 pixels sur le côté le plus long.
- Orientation corrigée.
- Métadonnées EXIF inutiles retirées.
- Original haute résolution non conservé dans Inventory.
- SHA-256 pour déduplication des fichiers optimisés.
- Gestion des références partagées.
- Miniatures régénérables.
- Cache mémoire borné.
- Chargement paresseux.
- Traitement local non bloquant.

### 7.2 Importation et remplacement

Utiliser une zone temporaire avant association définitive.

En cas d'annulation ou d'échec :

- Conserver la fiche.
- Conserver l'ancienne photo.
- Nettoyer les fichiers temporaires inutiles.

### 7.3 Caméra et galerie

- Utiliser le sélecteur Android lorsque disponible.
- Capture caméra dans un fichier temporaire privé.
- Aucun accès permanent global à la galerie.
- Aucune publication automatique dans la photothèque.
- Ne jamais supprimer les originaux personnels.
- Respecter les annulations et refus de permission.

### 7.4 Documents — D07

Formats :

- PDF.
- JPEG.
- PNG.
- WebP.

Taille maximale : **15 Mo par document**.

Une facture photographiée est un document justificatif distinct de la photo principale.

Les documents ne doivent pas être automatiquement convertis en WebP.

Leur lisibilité et leur intégrité doivent être préservées.

---

## 8. Organisation et déplacements — D09 (état livré)

Ordre manuel persistant entre frères d’un même parent.

### Manipulation directe (comportement livré)

- Appui long puis glisser-déposer dans l’arborescence de l’espace courant.
- Réordonnancement entre frères **et** changement de parent admissibles dans le même geste.
- Conserver les descendants, valeurs et historiques.
- Interdire les cycles.
- Respecter les parents admissibles.
- Interdire les déplacements directs entre espaces.
- Ordre conservé après redémarrage et restauration.

### Décision historique — mode menu « Organiser »

Un mode menu Organiser distinct du déplacement avait été envisagé (D09 initiale). Il a été **remplacé** par la manipulation directe (UX-CORR-02-R2) ; les API et écrans résiduels ont été retirés (INTER-03-C). La référence normative est le DnD appui long.

Pour une base V2 vierge, l’ordre initial suit le comportement d’affichage existant. La migration de l’ordre d’anciennes données V1 n’est pas une obligation bloquante.

---

## 9. Icônes automatiques et personnalisation

Les icônes sont attribuées automatiquement selon le titre et le type de nœud.

Règles :

- Fonctionnement local et hors ligne.
- Priorité aux expressions précises.
- Puis synonymes et mots-clés.
- Puis icône générique.
- Ne pas se limiter au premier mot.
- Aucun modèle IA ou catalogue distant.
- Aucun sélecteur obligatoire dans le formulaire normal.

### Paramètres

Prévoir :

- Bibliothèque d'icônes.
- Recherche.
- Associations personnalisées.
- Exceptions par élément.
- Réinitialisation.

Une exception manuelle prévaut sur l'association automatique.

Modifier le titre ne doit pas écraser une exception manuelle.

Les licences, la taille du binaire et les performances doivent être vérifiées au moment de l'implémentation.

---

## 10. Recherche, valorisation et historiques

### Recherche

- Contextuelle à l'espace courant.
- Chemins hiérarchiques fiables.
- Aucun mélange entre espaces.
- Pas de recherche globale interespaces dans le noyau V2.

### Valorisation

Conserver trois logiques distinctes :

**Biens :** valorisation **exclusive** — financière **ou** sentimentale (pas les deux simultanément sur la même fiche).

**Stock :** niveau (1 / ½ / ¼ / 0) et quantité de référence facultative.

**À acheter :** quantité souhaitée et prix cible.

Ne pas fusionner ces valeurs dans un total unique trompeur.

### Historiques

**Biens :** retraits et motifs.

**Stock :** changements de niveau (ancien → nouveau) et date.

**À acheter :** acquisitions partielles, complètes et abandons.

Les événements doivent être compréhensibles pour un utilisateur non technique.

Éviter les doublons lors des échecs, reprises et opérations transactionnelles.

---

## 11. Sauvegarde, restauration et compatibilité

### 11.1 Sauvegarde V2 — D10

Créer une archive `.invbackup` V2 versionnée comprenant :

- Les trois espaces.
- Les hiérarchies.
- Les historiques.
- Les préférences.
- Les photos.
- Les documents.
- Les références et métadonnées.
- Un manifeste d'intégrité.

### 11.2 Restauration V2

Exigences :

- Vérification des fichiers et empreintes.
- Vérification des références.
- Contrôle de l'espace disponible.
- Préparation temporaire avant activation.
- Aucune destruction préalable des données existantes.
- Reprise sûre après interruption.
- Protection contre les chemins malformés.
- Absence de plafond global fixe de 32 Mio.

### 11.3 Compatibilité V1

Deux mécanismes doivent être distingués.

**Migration directe de la base SQLite V1 :**

Facultative. Une base V2 vierge est acceptable.

**Importation d'une sauvegarde `.invbackup` V1 :**

Reste prévue dans D10, mais sa nécessité doit être réévaluée avant le mandat Phase 5 concerné si elle entraîne une complexité disproportionnée.

Aucune suppression automatique de cette exigence sans arbitrage utilisateur.

La compatibilité inverse V2 → V1 n'est pas prévue.

### 11.4 Protection des données

Aucune donnée réelle ne doit être effacée sans autorisation.

Les données V2 doivent être conservées pendant les mises à jour et les restaurations.

---

## 12. Architecture technique finale (V2.0.0)

- Flutter / Dart.
- Material Design 3.
- Android uniquement (`io.github.cometom3.inventory`, minSdk 24, targetSdk 36, arm64-v8a).
- Drift / SQLite local — **schéma 15**.
- Un moteur commun ; trois espaces `goods` / `stock` / `to_buy` ; hiérarchies indépendantes.
- Fiche unifiée / formulaires harmonisés (convergence UX).
- Règles métier spécialisées ; transactions pour mouvements et acquisitions.
- Médias privés (photos WebP, documents) référencés en base.
- Sauvegarde / restauration `.invbackup` (format 2, données 3).
- Aucun cloud, serveur, compte ou synchronisation.

### Règles de développement

Avant d'ajouter un composant :

1. Vérifier son existence.
2. Vérifier ses usages.
3. Déterminer s'il peut être prolongé.
4. Préserver ses contrats existants.
5. Modifier le minimum nécessaire.

Ne pas introduire de nouvelle architecture uniquement pour anticiper des besoins futurs.

---

## 13. Phases et mandats de développement

### Phase 0 — Audit et spécification

**Statut : TERMINÉ**

Réalisations :

- Audit de V1.
- Identification des risques.
- Découpage des mandats.
- Consolidation des décisions D01–D10.

Références :

- `docs/rapport-v2/spécification-technique-préliminaire-v2.md`
- Rapport V2-00.

### Phase 1 — Trois espaces et contextualisation

**Statut : TERMINÉ**

| Mandat | Objectif | Statut |
|---|---|---|
| M1.1 | Appartenance aux espaces et schéma SQLite | Terminé, sous réserves documentées |
| M1.2 | Navigation inférieure et trois arborescences | Terminé, sous réserves documentées |
| M1.2-C | Consolidation et validation réelle Biens sur émulateur | Terminé, validation de développement |
| M1.3 | Recherche, création et historique contextualisés | À exécuter |

**Porte de sortie Phase 1 :**

- Trois espaces navigables.
- Hiérarchies indépendantes.
- Biens fonctionnel.
- Recherche, création et historique correctement contextualisés.
- Actions non disponibles masquées ou désactivées.
- Aucune fuite de données entre espaces.
- Persistance après redémarrage.
- Compilation et parcours réels sur émulateur.
- Aucun défaut bloquant connu dans le périmètre.

La création de produits Stock et de besoins À acheter est prévue en Phase 2, pas en Phase 1.

### Phase 2 — Stock et À acheter

**Statut : TERMINÉ**

**M2.1 / M2.1-C — Stock**

- Modèle produit et hiérarchie Stock.
- Quatre états visuels 1 / ½ / ¼ / 0 (D01 M2.1-C) ; sans unités/coûts/poids dans l'UI (D02 M2.1-C).
- Création sans fraction ; démarrage à 1.
- Cycle tactile dans l'arborescence.
- Quantité de référence facultative dans la fiche.
- Historique des changements de niveau.
- Recherche Stock contextualisée.
- Validation sur émulateur.

**M2.2 — À acheter**

- Modèle besoin.
- Quantité souhaitée.
- Prix cible.
- Création et modification.
- Acquisition partielle et complète.
- Destination Biens ou Stock.
- Fusion explicite D03.
- Abandon D04.
- Historique D05.
- Valorisation D06.
- Transactions atomiques.
- Validation sur émulateur.

Les mandats peuvent être subdivisés si le périmètre réel le justifie, sans ajouter de fonctionnalités.

**Porte de sortie Phase 2 :** les trois espaces doivent être fonctionnels dans leurs parcours métier essentiels.

### Phase 3 — Organisation manuelle

**Statut : TERMINÉ** (DnD appui long ; voir §8)

**M3.1 — Ordre manuel**

- Ordre persistant par parent.
- Mode Organiser.
- Réordonnancement réel.
- Conservation après redémarrage.

**M3.2 — Distinction des interactions**

- Séparation Organiser / Déplacer.
- Préservation du déplacement V1.
- Anti-cycle.
- Interdiction des déplacements entre espaces.
- Vérification des valeurs et descendants.

**Porte de sortie :** organisation et déplacement fiables, sans confusion ergonomique.

### Phase 4 — Fiches avancées et médias

**Statut : TERMINÉ**

**M4.1 — Fiches avancées**

- Section repliable.
- Préférence globale.
- État individuel par fiche.
- Champs avancés pertinents.
- Préservation de la saisie simple.

**M4.2 — Médias et documents**

- Photo principale.
- Galerie et caméra.
- Optimisation WebP.
- Stockage privé.
- Déduplication.
- Documents D07.
- Remplacement sécurisé.
- Cache borné et traitement non bloquant.

**Porte de sortie :** fiches simples toujours utilisables et médias fiables sans perte de données.

### Phase 5 — Icônes, sauvegardes et stabilisation

**Statut : TERMINÉ** (livraison officielle 2.0.0)

**M5.1 — Icônes**

- Attribution automatique.
- Dictionnaire local.
- Bibliothèque Paramètres.
- Exceptions manuelles.
- Validation hors ligne.

**M5.2 — Sauvegarde V2**

- Archive versionnée.
- Trois espaces.
- Historiques.
- Préférences.
- Médias.
- Manifeste.
- Restauration sûre.
- Décision finale sur l'import V1.

**M5.3 — Stabilisation finale**

- Parcours complets.
- Validation de la restauration.
- Vérification des performances.
- Contrôle mémoire.
- Vérification des interactions tactiles.
- Validation sur Moto G24 Power après autorisation.
- Corrections finales réellement nécessaires.
- Rapport GO / SOUS RÉSERVES / NO-GO.

**Porte de sortie :** application V2 utilisable, stable, sauvegardable et validée.

---

## 14. Protocole obligatoire des mandats Cursor

Chaque mandat doit :

1. Commencer par « Agis comme un expert senior en… ».
2. Identifier la mission et les documents de référence.
3. Définir précisément le périmètre.
4. Inspecter les composants existants.
5. Préserver les décisions validées.
6. Implémenter sans élargissement injustifié.
7. Compiler et installer sur émulateur lorsque pertinent.
8. Vérifier les parcours utilisateur réels.
9. Corriger les défauts confirmés dans le périmètre.
10. Produire un rapport avec preuves et verdict.
11. S'arrêter sans lancer le mandat suivant.

### Classification des problèmes

**P0 — Bloquant :** perte de données, corruption, impossibilité d'utiliser un parcours essentiel, risque critique.

**P1 — Important :** régression fonctionnelle significative, incohérence métier, défaut empêchant la progression fiable.

**P2 — Secondaire :** défaut mineur, amélioration ergonomique non essentielle, limitation contournable.

Ne pas reporter systématiquement un P1 connu.

Ne pas lancer un mandat supplémentaire pour chaque P2.

### Critère de validation

Les tests automatisés sont des preuves complémentaires.

Une fonctionnalité n'est pas considérée comme démontrée uniquement parce que les tests passent.

Le rapport distingue explicitement :

- Implémenté.
- Testé techniquement.
- Observé sur émulateur.
- Validé par l'utilisateur.
- Non vérifié.

---

## 15. Critères de réception finale

1. Fonctionnalités et ergonomie essentielles de Biens V1 préservées.
2. Trois espaces indépendants et fonctionnels.
3. Recherche, création et historique contextualisés.
4. Stock conforme aux décisions D01–D02 (quarts d'unité ; pas de conversions g/kg ou mL/L obligatoires).
5. Mouvements transactionnels fiables et solde jamais négatif.
6. À acheter conforme aux décisions D03–D06.
7. Acquisitions atomiques, partielles et complètes.
8. Organisation manuelle de l’arborescence par manipulation directe (appui long / glisser-déposer).
9. Ordre manuel persistant et absence de cycles.
10. Fiches avancées facultatives et état propre à chaque fiche.
11. Photos WebP optimisées et originaux personnels préservés.
12. Documents conformes à D07.
13. Icônes automatiques hors ligne et personnalisables.
14. Sauvegarde V2 complète et restauration sûre.
15. Mises à jour V2 sans perte de données à conserver.
16. Parcours complets réellement démontrés.
17. Stabilité et performances validées sur appareil physique en fin de développement.
18. Aucun P0/P1 ouvert à la livraison.
19. Réserves secondaires documentées sans prolongation indéfinie des audits.

La migration exhaustive des anciennes bases SQLite V1 n'est plus un critère obligatoire de réception.

---

## 16. Hors périmètre Inventory V2

- Cloud et synchronisation.
- Comptes utilisateurs.
- Abonnements.
- iOS.
- Windows.
- Multiutilisateur.
- ERP commercial.
- Comptabilité.
- Suivi automatique des prix en ligne.
- IA de reconnaissance visuelle.
- Géolocalisation.
- Garanties automatisées.
- Péremption et alertes complexes.
- Dépréciation automatique.
- Gestion complète de tâches.
- Galerie multi-photo par fiche.
- Association automatique des emplacements homonymes.

Aucune de ces fonctionnalités ne doit être introduite sans arbitrage explicite.

---

## 17. Limitations et réserves acceptées (livraison 2.0.0)

Les décisions D01–D10 restent en vigueur (D09 selon l’évolution DnD documentée §8).

### Maturité livrée

- **Biens :** parcours matures (création, consultation, médias, valorisation exclusive, organisation).
- **Stock / À acheter :** parcours essentiels opérationnels (niveaux, besoins, acquisitions) — pas une couverture exhaustive de tous les scénarios secondaires.
- **Formulaires :** convergence ergonomique validée.
- **Sauvegarde / restauration :** mécanismes livrés ; démonstration bout-en-bout utilisateur requise pour lever certaines réserves de réception (voir M5.3-D / M5.4).

### Réserves non bloquantes documentées

- Acquisition complète et export/restauration `.invbackup` : confirmation physique utilisateur si non encore réalisée.
- Caméra / galerie / ouverture document / DnD doigt : non systématiquement rejoués à chaque mandat de clôture.
- Importation `.invbackup` V1 : prévue D10, non bloquante pour la livraison V2 (base vierge acceptable).
- Analyze : avertissements préexistants mineurs acceptés.

### Hors V2 — orientations V3 (aucune implémentation dans ce périmètre)

Création rapide en arbre, swipe latéral, objectif Donner, orthographe multilingue, titre original vs affichage, miniatures photo, portage Windows, etc. — conception ultérieure indépendante.

---

## 18. État livré Inventory V2.0.0

**Date de référence : 25 novembre 2026**

| Élément | État |
|---|---|
| Phases 0 à 5 | Terminées (gel fonctionnel) |
| Assainissement INTER-03-C | Appliqué (working tree local) |
| Validation M5.3-D | VALIDÉ SOUS RÉSERVES NON BLOQUANTES |
| Version officielle | `2.0.0` / versionCode arm64 `6051` |
| APK release signé | `dist/android/Inventory-v2.0.0-arm64-release-vc6051.apk` |
| ApplicationId | `io.github.cometom3.inventory` |
| Schéma SQLite | 15 |
| Backup | format 2 / data 3 |

**Clôture :** voir `docs/rapport-v2/m5-4-livraison-officielle-cloture-v2.md`.

Ne pas démarrer Inventory V3 sans mandat explicite.

---

**Principe directeur final**

Inventory V2 doit évoluer de manière progressive, cohérente et vérifiable.

Préserver ce qui fonctionne. Corriger ce qui bloque réellement. Éviter la complexité inutile. Valider les parcours dans l'application réelle. Avancer vers le produit complet plutôt que rechercher une perfection technique sans fin.