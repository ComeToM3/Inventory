# Rapport DEV-29 — Corrections consolidées du double screening V1

## 1. Résumé exécutif

Six défauts de finition (UI-001 … UI-006) ont été corrigés localement, sans toucher aux règles métier ni à la version `1.0.11+12`.

Validation sur `emulator-5554` (720×1612) avec captures dans `docs/rapport/_dev29_shots/`.

**Verdict : VALIDÉ**

## 2. Version et état initial

| Élément | Valeur |
|---|---|
| Version `pubspec` | `1.0.11+12` (inchangée) |
| Branche | `main` (working tree déjà sale hors mandat) |
| Base audit | `docs/rapport/rapport-double-screening-v1.md` (accepté) |
| UI-007 capitalisation | **Hors mandat** — non modifié |

## 3. Tableau des six corrections

| ID | Défaut initial | Correction | Preuve réelle | Statut |
|---|---|---|---|---|
| UI-001 | Menu parent décalé, plat, recouvre « Position » | `DropdownMenu` M3 + indentation par profondeur + libellé court | `07_parent_menu_v2.png` + dump UI | **Corrigé et observé** |
| UI-002 / UI-008 | Double prix `1 × 20,00 $ CAD` + `20 $` | Sous-titre financier omis si trailing `listPrice` présent | Sémantique `Wer` → `Bien simple / Wer / 20 $` ; `02_tree_wer.png` | **Corrigé et observé** |
| UI-003 | Chip « Emplacements » coupé | Padding fin `24` + scroll horizontal inchangé | Avant scroll coupé ; après swipe bounds `[460,322][678,406]` (`10_chips_scrolled`) | **Corrigé et observé** |
| UI-004 | Chemin recherche répète le nom | Présentation : retrait du dernier segment si = nom | `cable_usb` → `Ess26 → Boite` (`09_search.png`) | **Corrigé et observé** |
| UI-005 | SnackBar zone sémantique quasi plein écran | `MaterialBanner` sous AppBar + fermeture + auto 3 s | Bounds `[0,182][720,301]` (`08_banner.png`) | **Corrigé et observé** |
| UI-006 | `−` / `+` sans libellés a11y | Tooltips FR + état désactivé exposé | `Diminuer/Augmenter la quantité` (dump création) | **Corrigé et observé** |

## 4. Causes identifiées

| ID | Cause |
|---|---|
| UI-001 | `DropdownButtonFormField` : menu Material 2, chemins plats, ancrage haut quand le champ est bas (thumb layout) |
| UI-002 | `inventoryCompactValuation` ≠ `inventoryListPrice` → les deux s’affichaient |
| UI-003 | Rangée dense 4 chips sur 720 px sans marge de fin suffisante dans le contenu scrollable |
| UI-004 | CTE SQL `full_path` commence par le nom du nœud ; carte affiche aussi le titre |
| UI-005 | SnackBar floating avec seul `bottomMargin` ≈ hauteur écran → région sémantique disproportionnée |
| UI-006 | `IconButton` sans `tooltip` |

## 5. Fichiers modifiés

- `lib/app/inventory_parent_field.dart` — sélecteur parent
- `lib/app/inventory_tree_controller.dart` — `depth` dans les candidats
- `lib/app/inventory_tree_screen.dart` — dedup affichage financier
- `lib/app/inventory_search_screen.dart` — chips + chemin ancêtres
- `lib/app/inventory_messages.dart` — MaterialBanner
- `lib/app/inventory_ui.dart` — a11y stepper
- `lib/app/app_strings.dart` — libellés FR

**Non modifiés :** schéma SQLite, version, backup, DnD, navigation, calculs de valeur, UI-007.

## 6. Résultats observables avant / après

### UI-001
- **Avant :** chemins `Ess26 → Boite` plats ; menu recouvre « Position ».
- **Après :** noms courts indentés (Ess26 / Boite / Dest) ; « Position » reste lisible ; menu sous le champ (`07`).
- **Justification technique :** limitation réelle du menu legacy → `DropdownMenu` Material 3, même parcours in-form, pas de nouvel écran.

### UI-002
- **Avant :** `Wer` = sous-titre CAD + trailing `20 $`.
- **Après :** trailing `20 $` seul (qté 1).

### UI-003
- **Avant / après sans scroll :** chip encore partiellement hors viewport (normal en rangée scrollable).
- **Après swipe :** « Emplacements » entièrement dans l’écran et sélectionnable.

### UI-004
- **Avant :** `Ess26 → Boite → cable_usb`.
- **Après :** `Ess26 → Boite`.

### UI-005
- **Avant :** sémantique ≈ `[0,91]–[720,1444]`.
- **Après :** bandeau `[0,182][720,301]` + bouton « Fermer le message ».

### UI-006
- **Avant :** `content-desc` vide.
- **Après :** libellés FR ; `−` `enabled=false` à qté 1.

## 7. Vérifications ciblées

| Contrôle | Méthode | Résultat |
|---|---|---|
| Analyse statique fichiers touchés | `flutter analyze` | OK |
| Sélecteur parent + création | Émulateur | OK |
| Ligne bien valorisé | Émulateur + sémantique | OK |
| Recherche + filtres | Émulateur | OK |
| Message post-création | Émulateur + bounds | OK |
| Stepper quantité | Dump a11y | OK |
| Tests auto métier | Non relancés (hors mandat) | — |
| Moto G24 | Interdit | Non vérifié |

## 8. Régressions

Aucune régression fonctionnelle observée sur les parcours touchés.

**Changement UX assumé (UI-005) :** le message n’est plus un SnackBar flottant mais un `MaterialBanner` (fermeture explicite + disparition auto 3 s). Position sous AppBar et non-blocage du bas conservés.

## 9. Réserves et limites

- Validation visuelle uniquement sur émulateur 720×1612, pas sur appareil physique.
- UI-003 : troncature à l’état initial possible sur écran étroit ; l’accessibilité complète repose sur le scroll horizontal (vérifié).
- TalkBack complet non rejoué session entière ; libellés confirmés via UI Automator.
- UI-007 volontairement non traité.

## 10. Recommandation finale

Les six points du mandat sont **résolus avec preuves émulateur**.  
Passer à la **finition applicative V1** (icône, splash, À propos/version) sans nouvel audit général des composants.

---

## Verdict

**VALIDÉ** — Les six points sont résolus ou justifiés, avec preuves suffisantes.

### Réponses

1. **Oui** — sélecteur, prix, recherche, message et a11y quantité sont perceptiblement plus propres.
2. **Oui** — hiérarchie lisible, ancrage correct, parcours inchangé.
3. **Non** — aucun défaut bloquant restant dans le périmètre DEV-29.
4. **Oui** — corrections du mandat terminées.
5. **Oui** — finition périphérique possible sans nouvel audit général UI.

---

**ARRÊT OBLIGATOIRE.** Aucune finition applicative engagée. Attendre la décision du propriétaire.
