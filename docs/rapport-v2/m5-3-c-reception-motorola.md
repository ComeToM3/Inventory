# M5.3-C — Réception physique sur Motorola Moto G24 Power

**Date :** 21–22 novembre 2026  
**Verdict :** **VALIDÉ SOUS RÉSERVES** (parcours essentiels OK ; gestes caméra/galerie/PDF/DnD au doigt encore à confirmer par l’utilisateur)  
**Code modifié :** aucun  
**Autorisation d’install :** accordée et exécutée

---

## A. Installation

| Élément | Valeur |
|---|---|
| Serial ADB | `ZT322P23HJ` |
| État ADB | `device` (reconnecté après débranchement temporaire) |
| Modèle | moto g24 power (`fogorow`) |
| Android | 14 |
| ABI | `arm64-v8a` |
| Avant install | Inventory **absent** |
| APK | `build/app/outputs/flutter-apk/app-arm64-v8a-debug.apk` (rebuild split-per-abi incl. Organiser M5.3-B) |
| `versionName` | `1.0.15` |
| `versionCode` | **4017** (code ABI Flutter depuis `+2017` ; **pas** de `-d`) |
| Commande | `adb -s ZT322P23HJ install -r <apk_arm64>` |
| Résultat | **Success** |
| Effacement | **Aucun** |
| Blocage initial | Keyguard puis perte USB — levés après intervention utilisateur |

Pixel_7a (`emulator-5554`) : conservé, Inventory relancé ; pas de nouveau code à réinstaller.

---

## B. Matrice de réception

| Parcours | Action | Résultat observé | Méthode | Verdict |
|---|---|---|---|---|
| Démarrage | start MainActivity | · Biens, onglets, FAB | ADB/UI | Observé via ADB/UI |
| Nav 3 espaces | Biens / Stock / À acheter | En-têtes et listes vides puis remplies | ADB/UI | Observé via ADB/UI |
| Création emplacement | SalonM53C | Présent en arbre + DB | ADB/UI | Observé via ADB/UI |
| Création bien | ChaiseM53C, 25 $ | Ligne 25 $ ; DB `financial_value_cents=2500` | ADB/UI | Observé via ADB/UI |
| Création contenant | BoiteM53C + switch contenant | `node_type=item_container` | ADB/UI | Observé via ADB/UI |
| Suppression non vide | Supprimer Salon confirmé | « Supprimez d’abord le contenu… » | ADB/UI | Observé via ADB/UI |
| Organiser menu | ⋯ → Organiser | Bannière + Terminer | ADB/UI | Observé via ADB/UI |
| Monter/Descendre | Descendre Chaise | Ordre DB Chaise↔Boite inversé | ADB/UI | Observé via ADB/UI |
| Déplacer vers… | Tap action | Feuille destination **non capturée** de façon fiable via ADB | ADB/UI | Observé avec défaut (geste/feuille) |
| DnD frères au doigt | — | Non exécuté au doigt | — | **Non vérifié — intervention doigt** |
| Stock emplacement | CellierM53C | OK | ADB/UI | Observé via ADB/UI |
| Stock produit | RizM53C | Badge 1 | ADB/UI | Observé via ADB/UI |
| Niveaux 1→½→¼→0 | Cycles badge | Historique + `stock_movements` ; restauration plein | ADB/UI | Observé via ADB/UI |
| Historique Stock | Écran Historique | Entrées création + changements | ADB/UI | Observé via ADB/UI |
| Besoin À acheter | CafeM53C ×2 sous CoursesM53C | Créé | ADB/UI | Observé via ADB/UI |
| Acquisition complète | Acheté → Stock → Associer conserver → RizM53C | `purchase_events.acquire` ; Cafe `acquired` qté 0 ; Riz niveau conservé (4) | ADB/UI | Observé via ADB/UI |
| Champs avancés | Objectif Vendre + REF-M53C | DB `objective=sell`, `barcode_ref=REF-M53C` | ADB/UI | Observé via ADB/UI |
| Icônes | Choisir / Automatique | Sélecteur visible | ADB/UI | Observé via ADB/UI |
| UI Photo/Caméra/Docs | Formulaire Chaise développé | Photo principale, Galerie, Caméra, Documents | ADB/UI | Observé via ADB/UI |
| Capture caméra réelle | — | Non faite | — | **Non vérifié — doigt + permission** |
| Galerie / PDF / ouverture docs | — | Non faits | — | **Non vérifié — doigt** |
| Persistance | force-stop + relance | Salon/Chaise/Boite/Cellier/Riz/Courses/Cafe conservés | ADB/UI | Observé via ADB/UI |
| Stabilité | Parcours ADB | Pas de crash applicatif constaté ; 1 retour launcher (focus perdu) récupéré | ADB | Observé via ADB |

---

## C. Défauts

| Symptôme | Reproduction | Cause | Priorité | Correction | Résultat |
|---|---|---|---|---|---|
| Déplacer vers… peu fiable sous ADB | Tap « Déplacer vers… » | Feuille destination non observée / focus parfois perdu | P2 | Aucune (besoin spot-check doigt) | Ouvert |
| Sélecteur de type (Bien/Produit/Article) | Tap parfois sans navigation | Sensibilité zone / timing ADB | P3 | Contournement : tap centre carte | Accepté |
| Aucun P0/P1 produit confirmé sur Motorola | — | — | — | — | — |

---

## D. Réserves

### P0/P1 ouverts
Aucun P0/P1 applicatif confirmé sur Motorola après réception ADB.

### P2 acceptables
- Déplacer vers… à revalider au doigt.
- DnD Organiser au doigt non prouvé.
- Caméra / galerie / PDF / annulation retrait document : UI présente, parcours fichiers **non** menés au bout.

### Interventions physiques encore utiles
Sur le Motorola, dans Inventory (déjà installé) :

1. **Organiser** → glisser un frère sur un autre (DnD).
2. **Déplacer vers…** Chaise → BoiteM53C (ou inverse).
3. Sur Chaise : **Caméra** (accepter la permission si demandée) → enregistrer → vérifier la photo.
4. **Galerie** : choisir une image → enregistrer.
5. **Ajouter un document** PDF + image → ouvrir chacun → tester Annuler sur Retirer.

Répondre ici avec le constat pour lever les réserves F/C restantes.

---

## E. Décision

| Question | Réponse |
|---|---|
| Inventory fonctionne sur Motorola ? | **Oui** |
| Parcours essentiels démontrés ? | **Oui** (nav, CRUD Biens, Organiser Monter/Descendre, Stock niveaux+histo, acquisition Stock associée, avancés, persistance) |
| Caméra + documents bout-en-bout ? | **Pas encore** (UI OK) |
| Organiser au doigt (DnD / Déplacer) ? | **Partiel** (Monter/Descendre OK) |
| Prêt clôture V2 stricte ? | **Presque** — spot-checks doigt media/DnD recommandés |
| Travaux code indispensables | **Aucun** à ce stade |
| Corrections facultatives | **Arrêt recommandé** hors retours utilisateur |

### État final
- Motorola : Inventory installé, données de test M53C intactes, app utilisable.
- Pixel_7a : démarré, inventaire précédent conservé.

### Verdict M5.3-C
**VALIDÉ SOUS RÉSERVES** — réception physique réussie pour le cœur fonctionnel ; medias/DnD au doigt en attente de confirmation utilisateur.

**STOP** — en attente des gestes doigt listés en §D si vous souhaitez lever les dernières réserves.
