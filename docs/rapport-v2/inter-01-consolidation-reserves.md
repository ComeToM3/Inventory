# INTER-01 — Consolidation des réserves et plan de correction

**Date :** 21 novembre 2026  
**Nature :** revue transversale documentaire + vérifications code / émulateur non destructives  
**Code modifié :** aucun  
**Verdict de progression :** **poursuivre vers M5.3**, après un petit ensemble de validations / durcissements ciblés

---

## A. Synthèse exécutive

Inventory V2 est fonctionnellement avancée : trois espaces, Organiser, champs avancés Biens, photo/documents, icônes locales, sauvegarde V2 format 2 / schéma données 3, schéma SQLite **14**. Les rapports successifs sont majoritairement **VALIDÉ** ou **VALIDÉ SOUS RÉSERVES** ; beaucoup de réserves anciennes sont devenues **Clos** (implémentation ultérieure ou risque écarté).

| Priorité ouverte | Nombre (points distincts) |
|---|---|
| P0 | **0** |
| P1 | **3** |
| P2 | **11** |
| P3 | **4** |
| Clos | **14+** (principaux listés en §C) |

**Risques encore présents (essentiels) :**

1. **Garantie de restauration non démontrée bout-en-bout** sur l’émulateur (SAF + inventaire avec médias) — validation manquante, pas un défaut UI prouvé.
2. **Fenêtre DB `committed` / activation médias** : en cas d’échec après commit SQLite, le journal et `RestorationRecovery` ne vérifient pas la présence des fichiers ; incohérence SQLite↔médias possible.
3. **Jeu de données émulateur trop mince** pour exercer Stock / À acheter / médias dans un parcours sauvegarde réel (constat live : 4 nœuds `goods`, 0 photo, 0 doc, 0 mouvements).

**Recommandation :** **poursuivre** le développement via **M5.3** (stabilisation), en y intégrant la validation sauvegarde/restauration et un durcissement minimal du cas médias post-commit. Ne pas ouvrir une batterie de mandats P2 cosmétiques avant cela.

---

## B. Registre consolidé

Légende statut : **confirmé** = défaut ou risque encore présent dans le code/produit ; **à vérifier** = validation manquante sans preuve de panne ; **Clos** = plus d’intervention utile.

| ID | Source | Description | Statut | Prio | Impact utilisateur | Travail nécessaire | Effort | Moment |
|---|---|---|---|---|---|---|---|---|
| I-01 | M5.2 §13 | Parcours SAF export/restauration non observé bout-en-bout | à vérifier | **P1** | Confiance livraison sauvegarde/restauration insuffisante | Validation manuelle contrôlée (fichier test + confirmation UI) ; pas de wipe | moyen | **avant / dans M5.3** |
| I-02 | M5.2 §13 + code `BackupRestorer` / `RestorationRecovery` | Après `committed` DB, échec d’activation médias : rollback fichiers best-effort ; recovery ne contrôle pas les médias | confirmé (risque) | **P1** | Inventaire restauré pouvant pointer vers fichiers absents / anciens | Durcir ordre ou journal + vérif médias au démarrage ; prouver sur copie isolée | moyen | **dans M5.3** |
| I-03 | M5.2 §13 | Couverture Stock/À acheter/médias de la sauvegarde non démontrée sur données émulateur actuelles | à vérifier | **P1** | Incertitude sur restauration d’un inventaire « réel » V2 | Petit jeu de données non destructif + export vérifié ; restauration sur copie / après sauvegarde de sécurité | moyen | **dans M5.3** |
| I-04 | M5.2 §13 | Décodage `.invbackup` charge le fichier entier en RAM (plafond 512 Mio) | confirmé | **P2** | OOM possible sur très gros inventaires | Streaming SHA/décodage seulement si besoin terrain | élevé | après V2 / si constat |
| I-05 | M5.1 R1–R2 | Couverture dictionnaire / pluriels FR approximatifs | confirmé (limite) | **P2** | Icône générique pour noms rares | Enrichir au fil des retours ; pas de mandat dédié | faible | après V2 |
| I-06 | M5.1 R3 | Bibliothèque d’icônes Paramètres / associations globales du plan | confirmé (hors scope volontaire) | **P3** | Pas de bibliothèque globale | Arbitrage produit ; abandon probable pour V2 | — | abandon / après V2 |
| I-07 | M5.1 R4 | Choix manuel d’icône / familles non rejoués exhaustivement UI | à vérifier | **P2** | Confiance visuelle partielle | Spot-check dans M5.3 | faible | dans M5.3 |
| I-08 | M4.2-A R1 | Capture caméra bout-en-bout non validée sur AVD | à vérifier | **P2** | Photo caméra peut échouer sur device | Test caméra émulateur ou Moto en M5.3 | faible | dans M5.3 |
| I-09 | M4.2-B R1 | Viewer externe PDF/image non confirmé sur AVD | à vérifier | **P2** | Ouverture document peut dépendre des apps installées | Un essai avec viewer présent | faible | dans M5.3 |
| I-10 | M4.2-B R2 | Annulation suppression document déjà marquée : logique présente, UI peu revalidée | à vérifier | **P2** | Confusion mineure cancel | Spot-check fiche | faible | dans M5.3 |
| I-11 | M4.2-A R2 | Déduplication SHA / `ref_count` photos | confirmé (report plan) | **P3** | Stockage un peu plus lourd | Hors V2 sauf arbitrage | élevé | après V2 / abandon |
| I-12 | UX-01 / UX-02 / UX-03 / M3.1 | Validation tactile « au doigt » non faite (ADB) | à vérifier | **P2** | Risque ergonomie réelle | Session tactile émulateur + Moto fin M5.3 | moyen | **dans M5.3** |
| I-13 | M3.1 R2 | Glisser-déposer frère non exercé (Monter/Descendre OK) | à vérifier | **P2** | DnD peut être fragile | Un essai Organiser | faible | dans M5.3 |
| I-14 | M2.1-C / M2.2 | Libellé type « Bien simple » pour produit Stock / besoin | confirmé (cosmétique) | **P3** | Libellé trompeur secondaire | Ajuster chaînes si simple | faible | après V2 / optionnel M5.3 |
| I-15 | M2.2 | Parcours UI « associer Stock existant » peu rejoué | à vérifier | **P2** | Acquisition vers Stock existant incertaine | Un parcours acquisition | faible | dans M5.3 |
| I-16 | UX-01 R2 | Retour formulaire → picker : champs non restaurés | confirmé (comportement) | **P3** | Resaisie possible | Conserver sauf plainte | faible | abandon / après V2 |
| I-17 | UX-02 R2 | Micro-décalage IME à l’ouverture clavier | confirmé (mineur) | **P3** | Léger confort | Ne pas ouvrir mandat | faible | abandon |
| I-18 | Plan §17 / D10 | Décision finale import sauvegardes V1 | ouvert produit | **P2** | Clarité support V1 | Arbitrage : conserver import actuel (déjà accepté) ou documenter limite | faible | **avant livraison** (décision, pas code massif) |
| I-19 | Plan §17 | Priorité besoins À acheter ; mesures physiques facultatives | ouvert produit | **P3** | Fonctions absentes | Hors V2 sauf arbitrage | — | après V2 / abandon |
| I-20 | Plan / réception §15.17 | Validation Moto G24 Power | à faire | **P1** (réception) | Performances / tactile device | Session autorisée en fin M5.3 | moyen | **fin M5.3** |
| I-21 | git-01 / M1.1 | CHECK SQL hérités post-migration vs moteur | atténué | **P3** | Risque théorique écriture hors moteur | Aucun si app reste seule à écrire | — | Clos pratique / surveillance |
| I-22 | M1.3 | `inventory_history_test.dart` incompatible API | confirmé (dette test) | **P3** | Aucun impact runtime | Adapter si campagne tests autorisée | faible | après V2 |

**Vérification émulateur non destructive (21 nov. 2026) :** `emulator-5554` actif ; Inventory au premier plan ; SQLite `user_version=14` ; 4 nœuds `goods` ; préférence `show_advanced_by_default` ; 0 photo / 0 document / 0 `stock_movements` / 0 `purchase_events`. Données intactes ; aucune restauration lancée.

---

## C. Points déjà résolus (Clos)

| Ancienne réserve | Source | Pourquoi Clos |
|---|---|---|
| Backup sans `stock_movements` | M2.1 R2 | Inclus M5.2 (`data_schema` 3) |
| Photos hors sauvegarde | M4.2-A R3 | Inclus M5.2 |
| Documents hors sauvegarde | M4.2-B R3 | Inclus M5.2 |
| Préférences hors sauvegarde V1 | M4.1-A §limites | `app_preferences` exportées M5.2 |
| Section avancée non visible / non observée | M4.1-A | Levée par M4.1-B (**VALIDÉ**) |
| Spec P1-1 quantité Stock 0 | spécif. technique | Traité M2.1-C (niveaux 0/1/2/4) |
| Spec P1-2 isolation espaces | spécif. | Traité M1.x + moteur |
| Spec P1-3 acquisition atomique | spécif. | Traité M2.2 |
| Spec P1-4 mouvements Stock | spécif. | Traité M2.1 |
| Spec P1-5 backup médias / import V1 | spécif. | M5.2 : médias + import format 1 accepté |
| Fuite Recherche/Historique hors Biens | M1.3 F1/F2 | Corrigé |
| Régression Biens arbre vide M1.2 | M1.2 R1 | Levée par M1.2-C et mandats suivants (parcours observés) |
| Stock / À acheter « coquilles » M1.2 | M1.2-C | Remplis Phases 2–3 |
| Plafond produit 32 Mio backup | plan 11.2 / M5.2 | Remplacé par plafond sécurité 512 Mio |

Les réserves « validation manuelle utilisateur » répétées de M1→M3 ne sont **pas** des défauts : elles restent regroupées sous **I-12 / I-20** pour M5.3, sans les multiplier.

---

## D. Travaux recommandés (regroupements)

### Groupe A — Confiance sauvegarde / restauration (prioritaire)

**Contenu :** I-01, I-02, I-03 (+ I-18 décision produit import V1).

**Ordre :**

1. Créer une **sauvegarde de sécurité** de l’inventaire émulateur actuel.
2. Enrichir **sans wipe** un petit jeu (1 Stock, 1 À acheter, 1 photo, ≥2 documents, 1 `icon_key`, préférence).
3. Export `.invbackup` via Paramètres ; contrôler intégrité (SHA / ouverture refus fichier corrompu).
4. Restauration sur **copie isolée** ou après confirmation, jamais sur unique copie sans filet.
5. Si I-02 se manifeste ou reste structurel : correction minimale (vérif médias dans recovery et/ou commit journal après médias OK).

**Critères de fin :** export V2 avec médias et trois espaces démontré ; restauration fidèle observée ; échec simulé ne laisse pas inventaire irrécupérable ; décision V1 écrite (conserver import actuel suffit).

**Effort global :** moyen.

### Groupe B — Parcours essentiels M5.3 (stabilisation)

**Contenu :** I-07 à I-10, I-12, I-13, I-15, I-20.

**Ordre :** checklist M5.3 des parcours Biens / Stock / À acheter / Organiser / médias / acquisition ; tactile ; Moto en fin après autorisation.

**Critères de fin :** aucun P0/P1 ouvert à la réception ; P2 documentés sans nouveaux mandats.

**Effort global :** moyen à élevé (surtout Moto).

### Groupe C — Confort reportable

**Contenu :** I-04, I-05, I-06, I-11, I-14, I-16, I-17, I-19, I-21, I-22.

**Action :** aucune correction obligatoire avant livraison V2.

---

## E. Points reportables

| ID | Justification du report | Risque accepté |
|---|---|---|
| I-04 | Pas de preuve OOM sur inventaires réels actuels | Gros inventaires futurs |
| I-05 / I-06 | Couverture icônes déjà large ; biblio Paramètres hors directive M5.1 | Icônes génériques rares |
| I-11 | Dédup hors M4.2-A volontairement | Disque un peu plus utilisé |
| I-14 / I-16 / I-17 | Cosmétique / confort | Aucun parcours bloqué |
| I-19 | Points ouverts plan, hors réception stricte | Fonctions absentes connues |
| I-21 / I-22 | Dette SQL/tests sans impact runtime | Outils de test seulement |

---

## F. Décision de progression

### Avant M5.3 (bloquant confiance)

- Rien d’obligatoire en **code** si M5.3 démarre immédiatement avec le **Groupe A** en tête.
- Préparer sauvegarde de sécurité émulateur avant tout essai de restauration.

### Intégrer à M5.3

- **Groupe A** (validation + durcissement I-02 si besoin).
- **Groupe B** (parcours, tactile, Moto autorisée).
- Décision écrite **I-18** (import V1 : conserver tel quel recommandé).

### Après V2

- Streaming backup (I-04), enrichissement dictionnaire (I-05), dédup médias (I-11), libellés (I-14), dette tests (I-22).

### Abandonner / ne pas transformer en mandats

- Bibliothèque icônes Paramètres (I-06) sans arbitrage produit.
- Mesures physiques / priorité À acheter (I-19) sans demande.
- Micro-IME et restauration champs picker (I-16/I-17).
- Recréer CHECK SQL historiques (I-21) sans incident réel.
- Un mandat distinct par P2 cosmétique.

---

## Conclusion — plus petit ensemble cohérent

Pour poursuivre Inventory V2 **avec confiance**, un seul ensemble suffit :

### 1) M5.3 axé « preuve sauvegarde + cohérence médias » (Groupe A)

Validation réelle export/restauration avec médias et trois espaces, sur filet de sécurité ; durcissement minimal du cas `committed`/médias (I-02) si la revue M5.3 le confirme.

### 2) Checklist stabilisation parcours + tactile (+ Moto) (Groupe B)

Couvrir les validations manquantes sans rouvrir les décisions produit.

### 3) (Optionnel) Décision produit unique sur l’import V1 (I-18)

Sans nouveau moteur de migration.

**Ne pas** lancer trois mandats de polish P2 avant ces preuves.

**Recommandation finale :** **GO M5.3** avec le Groupe A comme premier jalon observable ; **0 P0** ouvert ; **3 P1** surtout de *validation / durcissement restauration*, pas de panne quotidienne constatée sur l’inventaire actuel.

---

**STOP** — aucun code modifié ; attendre arbitrage avant correction.
