# M5.3-B — Stabilisation fonctionnelle, validation tactile et réception Android

**Date :** 21–22 novembre 2026  
**Appareils :** Pixel_7a (`emulator-5554`) ; Motorola Moto G24 Power (`ZT322P23HJ`) détecté, non installé  
**Code modifié :** restauration minimale du mode Organiser (P1 confirmé)  
**Verdict émulateur :** **VALIDÉ SOUS RÉSERVES**  
**Réception Motorola :** **EN ATTENTE D’AUTORISATION**

---

## A. Synthèse

Les parcours essentiels Biens / Stock / À acheter, médias, icônes et champs avancés ont été **observés** sur Pixel_7a à partir de l’inventaire M5.3-A (schéma SQLite **15**).

Un défaut **P1** a été confirmé puis corrigé : le mode **Organiser** (menu ⋯, Monter/Descendre, Déplacer vers…, Terminer) n’était plus branché dans l’UI alors que le moteur et les chaînes existaient encore (régression vs M3.1 / D09).

Aucun P0 observé. Aucune nouvelle fonctionnalité hors correction Organiser.

| Catégorie | État |
|---|---|
| Navigation 3 espaces + retour arbre | Observé et fonctionnel |
| Fiches / formulaires / Annuler–Abandonner | Observé et fonctionnel |
| Stock niveaux 1→½→¼→0 + historique | Observé et fonctionnel |
| À acheter + feuille « Confirmer l’achat » | Observé (UI) ; acquisition complète non finalisée volontairement |
| Champs avancés Biens | Observé et fonctionnel |
| Photo + ouverture PDF externe | Observé et fonctionnel |
| Icônes auto/manuel (sélecteur) | Observé et fonctionnel |
| Organiser (après correction) | Observé et fonctionnel |
| Création emplacement | Observé et fonctionnel (`CaveM53B`) |
| Caméra capture bout-en-bout | Non vérifié (AVD) |
| Glisser-déposer frère au doigt | Testé techniquement (code + accept reorder) ; geste DnD non rejoué |
| Motorola physique | Non installé — autorisation requise |

**Défauts réellement observés :**

1. **P1 — Organiser inaccessible** (menu sans entrée, Monter/Descendre / Déplacer vers… non exposés) → **corrigé et rejoué**.
2. Création « Bien » via sélecteur de type : taps ADB parfois restés sur l’écran de choix (pas de défaut moteur prouvé) ; création **Emplacement** OK via bouton **Créer**.

---

## B. Tableau des validations

| Fonctionnalité | Appareil | Action effectuée | Résultat observable | Statut |
|---|---|---|---|---|
| Nav Biens ↔ Stock ↔ À acheter | Pixel_7a | Taps onglets | En-têtes · Stock / · À acheter ; Cellier/Farine ; Courses/Café | Observé et fonctionnel |
| Retour position arbre | Pixel_7a | Stock puis retour Biens | Salonn / Ordinateur toujours visibles | Observé et fonctionnel |
| Expansion / détails feuille | Pixel_7a | 1er clic Ordinateur → détails ; 2e → fermeture | « Qté : 1 · Salonn » + Modifier | Observé et fonctionnel |
| Formulaire Modifier | Pixel_7a | Modifier Ordinateur | Parent, qté, valorisation 199,99, nom, Annuler/Enregistrer/Retirer/Supprimer | Observé et fonctionnel |
| Valeurs $ / sentimental | Pixel_7a | Ligne + DB | 199 $ / icon laptop ; Lampem 4/5 ; DB `19999` / `sentimental_value=4` | Observé et fonctionnel |
| Création emplacement | Pixel_7a | Ajouter → Emplacement → CaveM53B → Créer | Nœud `CaveM53B` en DB | Observé et fonctionnel |
| Suppression contenant non vide | Pixel_7a | Supprimer Salonn confirmé | Message « Supprimez d’abord le contenu… » ; Salonn conservé | Observé et fonctionnel |
| Organiser menu | Pixel_7a | ⋯ → Organiser | Bannière + Terminer ; FAB masqué | Observé et fonctionnel |
| Monter/Descendre | Pixel_7a | Descendre Lampem | Ordre DB Lampem 0→1 (DocTest devant) | Observé et fonctionnel |
| Déplacer vers… | Pixel_7a | Détails en mode Organiser | Action « Déplacer vers… » visible | Observé et fonctionnel |
| Sortie Organiser | Pixel_7a | Terminer | Menu Plus revenu | Observé et fonctionnel |
| Stock nav + form | Pixel_7a | Farine → Modifier | Formulaire produit + Historique | Observé et fonctionnel |
| Niveaux Stock | Pixel_7a | Tap badge 1→½→¼→0 puis restauration | UI + `stock_movements` (correct) ; Farine revenu à 4 | Observé et fonctionnel |
| Historique Stock | Pixel_7a | Historique Farine | Entrée création + mouvements | Observé et fonctionnel |
| À acheter form | Pixel_7a | Café → Modifier | Quantité, prix, Acheté / Abandonner | Observé et fonctionnel |
| Feuille acquisition | Pixel_7a | Acheté | « Confirmer l’achat » Destination Biens/Stock, valorisation | Observé et fonctionnel |
| Acquisition complète + assoc. Stock | Pixel_7a | — | Non finalisée (évite mutation Café) | Non vérifié (volontaire) |
| Champs avancés | Pixel_7a | Lampem section développée | Objectif / date / code ABC-123 en XML | Observé et fonctionnel |
| Préférence avancée globale | Pixel_7a | DB prefs | `show_advanced_by_default=0` | Testé techniquement seulement |
| Photo principale | Pixel_7a | Form Ordinateur | Image + Remplacer / Caméra / Supprimer | Observé et fonctionnel |
| Ouverture PDF | Pixel_7a | Tap facture.pdf (hors Retirer) | `PdfViewerActivity` (Google Docs) | Observé et fonctionnel |
| Ouverture image justificatif | Pixel_7a | — | Tentative interrompue / non isolée | Non vérifié |
| Annulation retrait document | Pixel_7a | Dialog Retirer → Annuler (parcours antérieur) | Logique présente ; revalidation partielle | Observé avec défaut (parcours ADB fragile sur icône Retirer) |
| Capture caméra | Pixel_7a | Bouton Caméra visible | Capture non aboutie sur AVD | Non vérifié |
| Icône auto | Pixel_7a | Ordinateur + laptop | `icon_key=laptop` | Observé et fonctionnel |
| Sélecteur icône | Pixel_7a | Choisir l’icône | « Automatique (générique)… » | Observé et fonctionnel |
| Clavier / UX-01–03 | Pixel_7a | Formulaires + Annuler | Pas de régression bloquante observée | Observé et fonctionnel |
| Motorola démarrage / tactile | Moto G24 | — | App non installée | Non vérifié — autorisation requise |

---

## C. Corrections

### C1 — Mode Organiser inaccessible (P1)

| | |
|---|---|
| **Défaut initial** | Menu ⋯ : Ajouter / Historique / Aide / Paramètres seulement. Pas de Monter/Descendre ni Déplacer vers… ; `_openMoveTo` et `canAcceptReorder` / `moveSibling` existaient sans branchement UI. |
| **Cause** | Régression d’intégration UI vs M3.1 : chaînes + moteur présents, entrée menu et mode absents. |
| **Impact** | Parcours Organiser / ordre frères / D09 inutilisable. |
| **Fichiers** | `lib/app/main_navigation_screen.dart`, `lib/app/inventory_tree_screen.dart` |
| **Correction minimale** | État `_organizing` par espace ; menu Organiser + Terminer ; bannière ; Monter/Descendre ; Déplacer vers… → `_openMoveTo` ; DnD frère via `canAcceptReorder` / `placeSiblingBefore` ; FAB masqué en mode Organiser. |
| **Résultat après** | Menu Organiser OK ; Descendre Lampem : ordre DB mis à jour ; Terminer OK. |

Aucune autre correction code. Format sauvegarde inchangé.

---

## D. Réserves

### P0 / P1 restantes (émulateur)

| ID | Priorité | Statut |
|---|---|---|
| Organiser UI | P1 | **Clos** (corrigé M5.3-B) |
| I-01 / I-02 / I-03 | P1 | Clos côté M5.3-A (hors rejeu ici) |
| I-20 Motorola | P1 réception | **Ouvert — attente autorisation** |

### P2 / limitations acceptables

| ID | Description | Décision |
|---|---|---|
| I-08 | Caméra AVD non validée bout-en-bout | Reporter / Motorola |
| I-09 | Image justificatif non isolée ici (PDF OK) | Spot-check Motorola |
| I-10 | Annulation retrait doc : UI sensible (tap Retirer vs ouvrir) | Acceptable ; logique confirmée |
| I-12 | Validation « au doigt » réelle | Partielle ADB ; Motorola |
| I-13 | DnD frère geste non rejoué | Monter/Descendre OK ; DnD code branché |
| I-15 | Acquisition complète non finalisée | UI feuille OK ; finaliser sur Motorola ou spot-check |
| I-05 / I-07 | Couverture icônes | Sélecteur OK ; dictionnaire non enrichi (garde-fou) |

### Reportés / hors mandat

P3 cosmétiques, streaming backup, biblio icônes Paramètres, optimisation non demandée.

---

## E. Motorola

| Élément | Valeur |
|---|---|
| Serial ADB | `ZT322P23HJ` |
| État ADB | `device` |
| Modèle | `moto g24 power` (`fogorow`) |
| Android | 14 |
| Émulateur | `emulator-5554` (`sdk_gphone64_x86_64`) — `device` |
| Inventory sur Motorola | **Non installé** (`pm path` vide) |
| Données app Motorola | Aucune (pas d’install) |
| Autorisation d’installation | **Non obtenue** |

### Plan d’installation (après votre accord explicite)

1. Conserver Pixel_7a tel quel (pas de wipe Motorola).
2. Installer uniquement :  
   `adb -s ZT322P23HJ install -r build/app/outputs/flutter-apk/app-debug.apk`  
   (jamais `flutter install` ; jamais sans `-s ZT322P23HJ`).
3. Démarrer MainActivity ; contrôles prioritaires : démarrage, tactile, création/modif, clavier, Organiser, Stock / À acheter, caméra/galerie, documents, stabilité.
4. Ne pas désinstaller, effacer données, ni modifier les paramètres système.

**STOP — attendre votre autorisation avant toute installation Motorola.**

---

## F. Décision

| Question | Réponse |
|---|---|
| Prêt pour réception finale ? | **Émulateur : oui sous réserves documentées.** **Réception finale : non** tant que Motorola n’est pas autorisé et spot-checké. |
| Travaux indispensables restants | 1) Autorisation + install Motorola ; 2) spot-checks caméra / acquisition / tactile réel. |
| Corrections facultatives | **Arrêt recommandé** (P2/P3) hors retours Motorola. |

### État final laissé

- Pixel_7a démarré (`emulator-5554`)
- APK debug présent : `build/app/outputs/flutter-apk/app-debug.apk` (installé avec `adb -s emulator-5554 install -r -d` — versionCode local 2017 vs ancien 6017)
- Inventory au premier plan
- Données émulateur conservées (CaveM53B ajouté ; ordre frères Salonn modifié par test Organiser ; Farine niveau plein restauré)

### Verdict M5.3-B

**VALIDÉ SOUS RÉSERVES** (parcours émulateur + P1 Organiser corrigé ; réception Motorola en attente).
