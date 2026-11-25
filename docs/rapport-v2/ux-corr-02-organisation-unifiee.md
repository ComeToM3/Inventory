# UX-CORR-02 — Organisation unifiée (appui long + glisser-déposer)

**Date :** 23 novembre 2026  
**Appareil :** Pixel_7a (`emulator-5554`)  
**Motorola :** non démarré (hors périmètre)  
**APK :** `app-x86_64-debug.apk` (`--build-number=4020`) — `adb -s emulator-5554 install -r`  
**Verdict :** **VALIDÉ SOUS RÉSERVES**

---

## Synthèse

L’organisation repose désormais sur **un seul geste en mode Organiser** : appui long → glisser → relâcher.

| Exigence | Résultat observé |
|---|---|
| Réordonner frères (A,B,C → C,A,B) | **Observé** (ADB `motionevent`) |
| Déplacer entre emplacements | **Observé** (ItemB → LocB) |
| Déposer dans un contenant | **Observé** (ItemA → Boite) |
| Réordonner dans un contenant | **Observé** (In3 avant In1/In2) |
| Sortir d’un contenant | **Observé** (In2 → LocA) |
| Persistance après force-stop | **Observé** (SQLite) |
| Pas d’organisation dans Paramètres | **Observé** |
| Plus de Monter/Descendre / Déplacer vers… | **Observé** (absents en Organiser) |

---

## Comportement initial

Deux systèmes concurrentes :

1. **Hors Organiser** : `LongPressDraggable` changeait déjà le parent.
2. **En Organiser** : DnD limité au réordre frère + **Monter/Descendre** + feuille **Déplacer vers…**.

Le mode Organiser du menu ⋯ restait le point d’entrée ; Paramètres n’avait déjà plus d’UI d’organisation (vérifié).

---

## Cause

Le DnD Organiser n’acceptait que `canAcceptReorder` (même parent). Le changement de parent passait par une UI parallèle (`_openMoveTo` / Monter-Descendre), en contradiction avec l’interaction unique demandée.

---

## Correction effectuée

1. **`resolveOrganizeDrop`** (contrôleur) : un seul résolution nest vs reorder selon la cible.
2. **DnD uniquement si Organiser actif** (`maxSimultaneousDrags: 0` sinon).
3. **Cible racine** disponible en Organiser pour les emplacements.
4. **Suppression UI concurrente** : Monter/Descendre, Déplacer vers…, feuilles de destination/position.
5. **Bannière** : « appui long, puis glisser… ».
6. Paramètres : aucune entrée d’organisation à retirer (déjà absente).

### Fichiers

- `lib/app/inventory_tree_controller.dart`
- `lib/app/inventory_tree_screen.dart`
- `lib/app/inventory_inline_sheet.dart`
- `lib/app/app_strings.dart`

Aucun schéma SQLite, aucun `.invbackup`, aucun commit.

---

## Preuves Pixel_7a

### Préparation (simulation ADB / UI)

Jeu créé via formulaires UI (pas d’injection SQLite finale) : LocA, LocB, ItemA/B/C, Boite (contenant), In1/In2/In3.

### Gestes réellement exercés (ADB `input motionevent`)

| # | Geste | Avant → Après | Nature |
|---|---|---|---|
| 1 | ItemC → ItemA | A,B,C → **C,A,B** | Simulation ADB du long-press + drag |
| 2 | ItemB → LocB | ItemB sous **LocB** | Simulation ADB |
| 3 | ItemA → Boite | ItemA enfant de **Boite** | Simulation ADB |
| 4 | In3 → In1 | ordre interne **In3, In1, In2** (+ ItemA) | Simulation ADB |
| 5 | In2 → LocA | In2 sorti de Boite sous **LocA** | Simulation ADB |

### Persistance

Après `am force-stop` + lecture SQLite :

- ItemC sous LocA  
- ItemB sous LocB  
- ItemA, In3, In1 sous Boite  
- In2 sous LocA  

Réouverture app : Inventory au premier plan, arbre cohérent.

### Paramètres

Écran Paramètres : Aide, À propos, avancées, sauvegarde/restauration — **aucune** commande Organiser / Monter / Déplacer.

### UI Organiser

- Entrée menu **Organiser** / **Terminer** : présentes  
- **Monter / Descendre / Déplacer vers…** : absents  
- Appui court : expansion / détails inchangés (hors drag)

---

## Distinction des preuves

| Type | Contenu |
|---|---|
| Observé dans l’app (uiautomator) | États d’arbre, absences UI, Paramètres, Terminer |
| Simulation ADB | Séquences `motionevent` DOWN/MOVE/UP (pas un doigt humain) |
| Technique | `flutter analyze` OK ; build/install OK ; SQLite après stop |

**Non fait :** validation tactile au doigt ; réception Motorola.

---

## Régressions / réserves

1. Gestes validés via ADB, pas au doigt (réserve P2 historique I-12/I-13).  
2. Bannière Organiser non capturée en `content-desc` uiautomator (texte UI présent côté code).  
3. Incidents de copie SQLite en début de session (DB malformée) — rétablis via UI ; données finales saines.  
4. Réordonnancement de deux emplacements frères : volontairement traité comme réordre (pas nest) ; non exercé dans cette session.

---

## Verdict

**VALIDÉ SOUS RÉSERVES**

Les sept critères de démonstration sont couverts sur Pixel_7a. Réserve principale : confirmation au doigt / Motorola ultérieure.

**STOP** — pas de réception Motorola.
