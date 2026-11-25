# UX-CORR-02-R — Correction glisser-déposer (appareil physique)

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` (Moto G24 Power) — installé  
**Pixel_7a :** non traité (consigne utilisateur : travail Motorola uniquement)  
**Statut :** **EN ATTENTE DE VALIDATION TACTILE**

---

## Version initiale Motorola

| Champ | Valeur |
|---|---|
| `versionName` | `1.0.15` |
| `versionCode` | **6021** (= arm64, build Flutter **4021**) |
| Correspondance | UX-CORR-03 (inclut déjà le code UX-CORR-02) |

**Conclusion :** le problème n’était **pas** une APK obsolète.

---

## Cause réelle

Deux facteurs combinés :

1. **Geste conditionné au mode Organiser** — hors ⋯ → Organiser, `maxSimultaneousDrags: 0` : l’appui long ne démarrait aucun déplacement, alors que l’exigence est un accès **direct** depuis l’arborescence.
2. **Concurrence ScrollView / LongPress** — sur doigt réel, un micro-mouvement pendant le maintien fait gagner le défilement avant le démarrage du drag (validations ADB précédentes : doigt parfaitement immobile).

---

## Correction minimale

1. DnD **toujours actif** sur l’arborescence (plus de gate `organizing` pour drag/drop / cible racine).
2. Verrouillage anticipé du scroll (~180 ms d’appui) + `touchSlop` relevé à 56 px.
3. Mode Organiser conservé uniquement pour masquer `+` / édition (chrome), **pas** pour activer le geste.

### Fichiers

- `lib/app/inventory_tree_screen.dart`
- `lib/app/app_strings.dart` (libellé bannière Organiser)

Aucun schéma SQLite, aucune sauvegarde, aucun commit.

---

## Installation

| Appareil | APK | versionCode attendu | Résultat |
|---|---|---|---|
| Motorola `ZT322P23HJ` | `app-arm64-v8a-debug.apk` (`--build-number=4022`) | **6022** | install `-r` + Inventory au premier plan |
| Pixel_7a | — | — | **non installé** (hors demande) |

Données Motorola préservées (pas de désinstall / clear).

---

## À vérifier par l’utilisateur (même geste)

**Appui long → maintenir → glisser → relâcher** (sans obligation d’ouvrir Organiser) :

- **A** — Même emplacement : A,B,C → C,A,B  
- **B** — Même contenant : A,B,C → B,C,A  
- **C** — Salon → Chambre  
- **D** — Boîte → autre boîte  
- **E** — Persistance après fermeture / réouverture  

---

## Limitations

- Validation tactile **non déclarée** ici : en attente du retour utilisateur.
- Pixel_7a non mis à jour dans ce mandat.

---

## Verdict

**EN ATTENTE DE VALIDATION TACTILE**

**STOP** — attendre confirmation Motorola avant toute autre intervention.
