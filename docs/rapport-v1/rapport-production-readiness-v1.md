# Rapport — Audit de préparation à la production Inventory V1

**Mandat :** lecture seule · code et preuves existantes · aucune modification hors ce document  
**Version inspectée :** `1.0.8+9` (`pubspec.yaml`)  
**Date :** 2026-11-15  
**Périmètre de preuve :** inspection statique + rapports DEV-15 à DEV-25 (rapports = preuves partielles)

---

## 1. Synthèse exécutive

### État général

Inventory V1 dispose d’une base technique cohérente (moteur Drift/SQLite transactionnel, trois types officiels, arborescence, création/modification mutualisée, recherche, historique lecture, sauvegarde/restauration, signature Android). Les mandats DEV-19 à DEV-25 ont recentré l’ergonomie (navigation unique, expansion progressive, sous-ligne compacte, page commune de création/modification).

### Forces confirmées

- **Moteur métier** : création, déplacement avec descendants, prévention de cycles, suppression/retrait conditionnés aux enfants, valorisation exclusive, totaux de sous-arbre — présents et structurés.
- **UI principale** alignée sur les décisions récentes (DEV-20/24/25) : lignes sobres, cycle d’expansion, modification via `InventoryCreationScreen(existing:)`, suppression en mode modification seulement.
- **Android** : `applicationId` stable, `minSdk 24` / `targetSdk 36`, `allowBackup=false`, signature release conditionnée à `key.properties`.
- **Compilation / émulateur** : démontrés jusqu’à DEV-25 pour la build courante.

### Principaux risques

1. **Retrait d’inventaire (D07) inaccessible dans l’UI** — régression après suppression des fiches détail/édition (DEV-23) et non réintroduit dans la page de modification (DEV-25). Le moteur et l’historique existent ; aucun écran n’appelle `withdrawItem`.
2. **Écart de preuves physiques** : la validation Moto (DEV-15/18) porte sur des builds antérieures (`1.0.0`–`1.0.1`). La build `1.0.8` n’a **pas** été installée ni validée sur appareil physique.
3. **Glisser-déposer** : logique corrigée (DEV-23), observée surtout via gestes synthétiques ; ressenti tactile réel non validé.
4. **Documentation produit ancienne** (PRD / spec) encore mentionne catégories, contenant autonome et 0 $ par défaut — contredite par les décisions DEV-17+ réellement implémentées.

### Verdict préliminaire

**VALIDÉ SOUS RÉSERVES** — l’application peut devenir une V1 fiable avec peu de corrections ciblées, mais elle n’est pas prête pour une validation finale physique tant que le parcours de retrait n’est pas restauré et que la build actuelle n’a pas été exercée sur appareil.

---

## 2. Matrice de conformité

| Exigence | État | Preuve | Écart |
|---|---|---|---|
| Emplacement / Bien simple / Bien-contenant | **Conforme** | `NodeType` (3 valeurs) ; picker FAB ; CHECK SQL v4 | Contenant autonome abandonné (DEV-17) — OK produit |
| Relations parent-enfant + anti-cycles | **Conforme** (code) | `InventoryEngine.moveNode` / `_requireValidParent` / `_validatedChain` | Cycle UI DnD non rejoué récemment |
| Déplacement descendants | **Conforme** (code + partiel ému) | `moveNode` change uniquement `parent_id` | Preuve physique stale |
| Suppression fiche erreur | **Conforme** (code + DEV-24 ému) | `InventoryCreationScreen._delete` + confirmation | — |
| Retrait avec motif (D07) | **Non conforme** (UI) | Moteur + contrôleur OK ; **aucun appel UI** à `withdrawItem` | Parcours principal manquant |
| Historique des retirés | **Partiellement conforme** | `InventoryHistoryScreen` + détail retiré | Utile seulement si retraits existent |
| Création compacte DEV-19 | **Conforme** (code + DEV-19–25) | Position → Qté → `$`/`♡` → Nom ; `+` position / `+` central | Validation physique stale |
| Valorisation exclusive + « aucune » ≠ 0 $ | **Conforme** aux décisions DEV-17/18/19 | `InventoryValuationMode.none` ; `FinancialValuation(0)` explicite | Écart vs PRD ancien (0 $ défaut) |
| Page commune création/modif | **Conforme** | `InventoryCreationScreen` + `existing:` (DEV-25) | — |
| Expansion progressive | **Conforme** (code + DEV-25 ému) | `_cycleExpand` / `_RowPhase` | — |
| Sous-ligne compacte sans doublons | **Conforme** (code + DEV-24/25) | `InventoryInlineSheet` | — |
| Appui long / DnD | **Partiellement conforme** | `LongPressDraggable` + dépôt `details.data` | Finger réel / expand-survol / auto-scroll non démontrés solidement |
| Recherche + chemin | **Conforme** (code ; observé builds antérieures) | `searchNodes` + filtres types officiels | Recherche→arbre non rejouée DEV-25 |
| Navigation Recherche / Historique / Paramètres | **Conforme** | AppBar + menu ⋮ (DEV-20) | — |
| Sauvegarde / restauration | **Conforme** (code + tests + DEV-15/16 partiel) | Paramètres + format `.invbackup` | Restore manuelle récente non rejouée |
| Catégories | **Hors périmètre V1 actuel** | Abandonnées DEV-17 ; tables vides conservées | Specs écrites non mises à jour |
| Persistance locale | **Conforme** (architecture + preuves antérieures) | Drift / redémarrage DEV-15 | Non rejouée sur `1.0.8` |

---

## 3. Architecture et réutilisation

### Composants correctement mutualisés

| Composant | Rôle |
|---|---|
| `InventoryEngine` | Seule porte d’écriture métier, transactions |
| `InventoryTreeController` | Cache arbre + opérations UI |
| `InventoryCreationScreen` | Création **et** modification |
| `InventoryParentField` / `InventoryValuationField` / `InventoryActionBar` | Formulaires partagés |
| `InventoryThumbBody` | Contenu court vers le bas |
| `InventoryInlineSheet` | Consultation compacte |
| `showInventoryMessage` | SnackBars hautes |

### Doublons / dettes significatifs

| Élément | Gravité | Note |
|---|---|---|
| Chaînes / API `withdraw*` sans UI | P1 | Code mort côté présentation |
| `PersistenceCheckScreen` non branché | P3 | Écran de diagnostic orphelin |
| Tables `categories` / `node_categories` vides | P3 | Compat backup ; pas d’UI |
| Specs PRD/SRS vs modèle réel | P2 doc | Trois types + valorisation optionnelle décidés en DEV-17 |

### Écarts aux règles permanentes

- **Réutilisation** : globalement respectée après DEV-23–25 (pages détail/édition/move retirées).
- **Responsabilités** : présentation / contrôleur / moteur / Drift clairement séparés.
- **Régression fonctionnelle** : la simplification des fiches a **omis** le retrait — non conforme à « préserver les comportements déjà fonctionnels » pour D07.
- **Sources de vérité** : une seule pour les nœuds actifs (`nodes` via moteur). Pas de double état concurrent critique détecté ; phases d’expansion locales (`_phase`) distinctes du cache enfants (acceptable).

---

## 4. Fonctionnalités V1

### Conformes (implémentation + cohérence technique)

- Modèle à trois types ; pas de « Contenant » autonome dans l’UI.
- Création racine / enfant ; préremplissage parent ; `+` emplacement contextuel ; `+` central (création série).
- Modification préremplie ; Annuler / Enregistrer ; Supprimer en modification.
- Arbre : indentation, chevrons, prix, totaux branche, liste courte en bas.
- Expansion progressive (contenant avec enfants / feuille).
- Recherche par nom / type / branche.
- Historique en lecture des biens déjà retirés.
- Export / restore / recovery journal (Paramètres + boot).
- Anti-cycle et parents invalides au niveau moteur.

### Partielles

- **Déplacement DnD** : implémenté et partiellement observé (émulateur / `motionevent`) ; pas de validation tactile Moto sur la version actuelle.
- **Recherche → révélation arbre** : code présent (`openDetailFor`) ; non rejoué en DEV-25.
- **Édition + changement de position** : deux appels séquentiels (`updateItemDetails` puis `moveNode`) — pas une seule transaction moteur.

### Non vérifiées / non conformes

| Fonction | État | Commentaire |
|---|---|---|
| Retrait (perte/don/bris/vente) | **Non conforme** | Aucun point d’entrée UI |
| Validation physique `1.0.8` | **Non vérifiable** ici | Mandat interdit install Moto |
| Expand-au-survol / auto-scroll DnD | **Non vérifiable** (rapports) | Listés « non vérifiés » DEV-22/23 |
| Distribution store | **Hors périmètre** si non décidé | APK sideload documenté pour `1.0.0` |

---

## 5. Risques de production

### P0 — Critique

*Aucun écart P0 démontré* (pas de preuve de corruption silencieuse, cascade destructive ou bypass d’intégrité moteur).

### P1 — Bloquant V1

| ID | Composant | Attendu | Constaté | Preuve | Impact | Mesure minimale |
|---|---|---|---|---|---|---|
| **PR-01** | Sortie d’inventaire / édition | Retirer un bien avec motif, historique minimal | `withdrawItem` exposé au contrôleur mais **jamais appelé** depuis l’UI ; édition n’offre que Supprimer | Grep `lib/app` : seuls strings + contrôleur ; création/inline sans Retirer ; DEV-23 a retiré les fiches qui portaient l’action | Impossible de sortir un bien sans destruction définitive | Réintroduire Retirer (motif + confirmation) dans le mode Modification de `InventoryCreationScreen` (biens seulement), en réutilisant le contrôleur existant |

### P2 — Important, potentiellement reportable

| ID | Composant | Attendu | Constaté / risque | Preuve | Impact | Mesure minimale |
|---|---|---|---|---|---|---|
| **PR-02** | Modification + déplacement | Opération cohérente | Update puis move séparés | `_persistEdit` | Si move échoue après update, état partiel | Envelopper dans une opération moteur unique, ou enchaîner avec message clair + rechargement |
| **PR-03** | DnD tactile | Déplacement fiable au doigt | Fix course critique OK ; preuve surtout ADB | DEV-22/23 | Frustration / dépôt raté perçu | Validation manuelle Moto après PR-01 |
| **PR-04** | Docs produit | Specs = produit | PRD/SRS/blueprint parlent encore catégories, contenant, 0 $ défaut | `01-product-requirements.md`, `02-functional-specification.md` vs DEV-17 | Confusion d’audit / futures régressions | Mettre à jour les docs (hors code) |
| **PR-05** | Artefacts dist | APK aligné version courante | `dist/` documente surtout `1.0.0` ; code à `1.0.8+9` | `dist/android/INSTALL.md`, `pubspec.yaml` | Mauvaise base d’install si on s’appuie sur dist sans rebuild | Rebuild release après corrections P1 |

### P3 — Facultatif

| ID | Composant | Note |
|---|---|---|
| **PR-06** | Compteur `(n)` après collapse | Cache enfants conservé (noté DEV-25) |
| **PR-07** | `PersistenceCheckScreen` | Non branché — nettoyage possible |
| **PR-08** | Tables catégories vides | Dette de forme backup |
| **PR-09** | Defaults Drift `value_mode`/`cents` | Surclassés par écritures moteur + CHECK v4 ; cosmétique schéma |

---

## 6. État des validations

### Démontré (niveaux élevés)

| Élément | Niveau max observé |
|---|---|
| Moteur (cycles, enfants, valorisation, withdraw API) | Code + tests unitaires historiques (non réexécutés ce mandat) |
| APK release signé `1.0.0` sur Moto | DEV-15 (création, totaux, recherche, **retrait**, backup, persistance) |
| Install Moto `1.0.1` | DEV-18 (install OK ; validation usage propriétaire demandée) |
| Ergonomie DEV-19–25 sur émulateur | Rapports DEV-19…25 (compilation + observations UI) |
| Expansion + page modification `1.0.8` | DEV-25 émulateur |

### Repose surtout sur des rapports (sans re-preuve ici)

- Corrections DnD DEV-23.
- Sous-ligne / suppression en édition DEV-24.
- Cycle d’expansion DEV-25.
- Migration schéma v4 / abandon catégories DEV-17.
- Backup legacy `container` → `item_container`.

### À valider manuellement (appareil)

1. **Après correction PR-01** : retrait + motif → disparition arbre → apparition Historique.
2. Création / modification / `+` position / `+` central sur Moto (`1.0.8+` rebuild).
3. Expansion progressive au pouce (3 clics / 2 clics).
4. Long-press + glisser-déposer réel (cible valide / invalide / cycle).
5. Recherche → retour arbre + sous-ligne.
6. Export puis restore (données personnelles).
7. Force-stop / redémarrage : persistance.
8. Confirmation propriétaire que le produit sans catégories / avec « aucune valorisation » est accepté (décision déjà codée depuis DEV-17).

**Ne pas confondre** : événements ADB ≠ ergonomie réelle.

---

## 7. Chemin minimal vers V1

### Indispensable avant validation finale physique

1. **Corriger PR-01** — réactiver le retrait en mode Modification (réutiliser `InventoryTreeController.withdrawItem`, motifs existants, confirmations existantes).  
2. **Rebuild** APK release `≥ 1.0.9` (ou bump juste) signé.  
3. **Installer sur Moto** (autorisation propriétaire) **sans** clear si même signature.  
4. **Parcourir** la checklist §6 sur données réelles ou jeu minimal.

### Vérifications manuelles restantes (non bloquantes si OK au doigt)

- PR-03 DnD (expand-survol, auto-scroll si liste longue).
- Recherche → reveal.
- Backup/restore de bout en bout.

### Peut attendre (P2/P3)

- Atomicité edit+move (PR-02) si le message d’erreur reste clair.
- Alignement documentaire (PR-04).
- Nettoyage PersistenceCheck / compteurs / tables catégories (PR-06–09).

### Dépendances

```text
PR-01 (retrait UI)
    → rebuild APK
        → install Moto
            → validation physique (dont DnD + backup)
                → décision propriétaire VALIDÉ / réserves restantes
```

Sans PR-01, une validation physique confirmerait une V1 **incomplète** sur D07.

---

## 8. Verdict final

### **VALIDÉ SOUS RÉSERVES — Corrections ou preuves ciblées nécessaires.**

**Justification :**

- L’architecture et le cœur métier sont suffisamment sains pour soutenir une V1 locale Android.
- Les parcours inventaire / création / consultation / modification / recherche / paramètres sont implémentés de façon cohérente avec les décisions ergonomiques récentes.
- **Un blocage fonctionnel majeur demeure :** le retrait d’inventaire, exigence V1 confirmée (D07), n’est plus atteignable dans l’interface actuelle malgré un moteur intact — non-conformité P1 avérée par inspection du code, pas une simple absence de preuve.
- La build courante n’a pas de preuve d’usage sur appareil physique ; les preuves Moto portent sur des versions antérieures encore pourvues du retrait UI.

**Ce verdict signifie :** prêt pour une **correction minimale puis validation finale physique**, **pas** prêt pour distribution publique automatique, et **pas** « validé produit » sans retour propriétaire sur appareil.

---

### Dimensions d’évaluation

| Dimension | Évaluation |
|---|---|
| A. Conformité fonctionnelle | **Sous réserves** (retrait UI) |
| B. Conformité ergonomique | **Sous réserves** (cohérente DEV-25 ; non validée physiquement) |
| C. Architecture / maintenabilité | **Conforme** pour V1 |
| D. Intégrité des données | **Sous réserves** (moteur solide ; edit+move non atomique = P2) |
| E. Préparation Android | **Conforme** pour finalisation / sideload (signing, SDK, identité) |
| F. Preuves de fonctionnement | **Preuves insuffisantes** pour `1.0.8` sur appareil |

---

**ARRÊT OBLIGATOIRE** — aucune correction, aucun test, aucune installation. Attendre l’analyse du propriétaire.
