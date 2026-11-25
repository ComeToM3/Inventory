# UX-ARB-02 — Ancrage visuel dynamique de l'arborescence

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` — versionCode **6049** (build Flutter **4049**, arm64 debug)  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION UTILISATEUR**

---

## 1. Cause réelle

| Symptôme | Mécanisme |
|---|---|
| Ligne refermée « chute » vers le bas | `Align(alignment: Alignment.bottomCenter)` dans le `SingleChildScrollView` : le bloc contenu restait collé au bas de la hauteur minimale viewport ; en raccourcissant, tout le bloc (dont la ligne fermée) glissait vers le bas. |

Ce n’était pas un bug d’offset de scroll isolé, ni un problème d’indentations / colonnes.

---

## 2. Correction

Fichier : `lib/app/inventory_tree_screen.dart` (+ getter `isInitialLocationsExpandDone` dans `inventory_tree_controller.dart`).

| Exigence | Implémentation |
|---|---|
| Position initiale centrale (contenu court) | Inset haut ponctuel `_initialTopInset`, mesuré **une seule fois** après l’expand initial des emplacements |
| Pas de recentrage auto ensuite | `_initialTopInsetLocked` ; un scroll utilisateur verrouille aussi sans changer l’inset |
| Conserver le Y de la ligne ouverte/fermée | Ancrage haut du contenu + `_runKeepingRowY` (mesure Y avant/après, correction `jumpTo` si clamp scroll) |
| Déploiement sous la ligne | Enfants / détails restent sous la ligne ; pas d’`Align` bas/centre permanent |
| Même `ScrollView` | `SingleChildScrollView` + `ClampingScrollPhysics` conservés ; pas de padding artificiel permanent ni second scroll |

---

## 3. Périmètre préservé

Dimensions de lignes, indentations, colonnes, expansions indépendantes, appui long / DnD, ajouts / édition, formulaires et données : **inchangés**.

---

## 4. Livraison

| Élément | Valeur |
|---|---|
| Install | Success `adb -s ZT322P23HJ install -r` (données conservées) |
| versionCode | **6049** |
| Capture | `_ux-arb-02/motorola-ancrage-apres.png` (arbre court centré une fois) |

---

## 5. Validation manuelle (à charge utilisateur)

- Ouverture / fermeture emplacement  
- Ouverture / fermeture bien-contenant  
- Ouverture / fermeture sous-lignes descriptives  
- Fermeture après défilement haut / bas  
- Passage arbre long → court  
- Conservation du Y de la ligne manipulée  
- Absence de saut / conflit avec le déplacement tactile  

**STOP — EN ATTENTE DE VALIDATION UTILISATEUR.**
