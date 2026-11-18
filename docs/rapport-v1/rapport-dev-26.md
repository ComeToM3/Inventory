# Rapport DEV-26 — Retrait UI, expansion 4 clics, DnD et atomicité

## Verdict

| État | Statut |
|---|---|
| Implémenté | Oui |
| Compilé | Oui (`1.0.9+10`) |
| Observé sur émulateur | Oui (retrait, expansion 4 clics, DnD valide) |
| DnD tactile « au doigt » | **Non démontré** de façon représentative (émulateur + `motionevent`) |
| Installé Moto | Non — non autorisé |
| Validé physique | **En attente** |

**VALIDÉ SOUS RÉSERVES**

**ARRÊT — attendre l’autorisation du propriétaire pour la validation physique.**

---

## 1. Composants existants réutilisés

| Besoin | Composant | Adaptation |
|---|---|---|
| Fiche création/modification | `InventoryCreationScreen` + `existing:` | 2ᵉ barre d’actions Retirer / Supprimer |
| Actions formulaires | `InventoryActionBar` | Deux rangées distinctes en édition |
| Retrait métier | `InventoryTreeController.withdrawItem` → `InventoryEngine.withdrawItem` | Branché depuis la fiche |
| Libellés / motifs | `AppStrings` (retrait, motifs, confirmations) | Réutilisés tels quels |
| Expansion | `_cycleExpand` / `_RowPhase` | Phase `childrenKeep` ajoutée |
| DnD | `LongPressDraggable` + `DragTarget` + `moveNode` | Délai, `rootOverlay`, surbrillance |
| Edit + move | Moteur + contrôleur | Nouvelle op. atomique `updateAndOptionallyMove` / `saveEditedNode` |

**Aucun nouvel écran, formulaire ou moteur de déplacement.**

---

## 2. Corrections réalisées

1. **Retirer de l’inventaire** restauré en mode modification (biens uniquement) : motif → confirmation → `withdrawItem`.
2. **Supprimer** conservé, séparé de Annuler / Enregistrer (2ᵉ rangée).
3. **Expansion** : 4 clics pour un parent avec enfants (le 3ᵉ masque seulement la sous-ligne).
4. **DnD** : appui long 450 ms, feedback en overlay racine, destination surlignée.
5. **Atomicité** : enregistrement modification + changement de position dans **une** transaction moteur.

---

## 3. Supprimer et Retirer — comportement final

### Présentation (édition seulement)

| Rangée | Actions |
|---|---|
| 1 | Annuler \| Enregistrer |
| 2 | Retirer de l’inventaire (biens) \| Supprimer |

- Pas de Retirer / Supprimer en consultation (sous-ligne ✎ uniquement).
- Emplacement : Supprimer seulement (pas de retrait).

### Retirer

1. Motif : Perte / Don / Bris / Vente.  
2. Confirmation avec nom + motif.  
3. Annulation ou échec → aucune écriture.  
4. Bien-contenant non vide → refus métier (`cannotWithdrawWithChildren`).  
5. Succès → disparition de l’arbre + snackbar + entrée Historique.

### Supprimer

Inchangé : confirmation irréversible, blocage si enfants, snackbar dédiée (`deleted`).

---

## 4. Glisser-déposer

### Implémentation

- Appui long **450 ms** (séparation plus nette du clic d’expansion).
- `rootOverlay: true` — feedback non découpé par le scroll.
- Dépôt via `details.data` (conserve le correctif DEV-23).
- Surbrillance menthe sur cible valide.
- Expand-au-survol (~650 ms) et auto-scroll bords conservés.
- Destinations : emplacement, bien-contenant, racine si `canBeRoot`.
- Refus : bien simple, soi-même, cycles (moteur + `canAcceptDrop`).

### Observé émulateur

| Parcours | Résultat |
|---|---|
| Long-press + glisser Boite → Ess26 (`motionevent`) | **Observé** — snackbar « Élément déplacé. », compteurs Ess26 (2) / Dest (0) |
| Dépôt invalide (bien simple) | Non rejoué UI ce mandat ; logique `canAcceptDrop` inchangée |
| Ressenti doigt / souris émulateur | **Non représentatif** — à valider sur Moto |

---

## 5. Expansion progressive — quatre clics

| Clic | Parent avec enfants | Sans enfants / feuille |
|---|---|---|
| 1 | Enfants | Infos |
| 2 | Enfants + sous-ligne | Fermé |
| 3 | Enfants seuls (infos masquées) | — |
| 4 | Fermé | — |

Phases : `closed` → `children` → `info` → `childrenKeep` → `closed`.

**Observé émulateur (Ess26) :**  
STEP1 enfants sans Modifier · STEP2 Modifier + enfants · STEP3 enfants sans Modifier · STEP4 fermé.

---

## 6. Atomicité modification + déplacement

**Choix :** extension ciblée du moteur — `InventoryEngine.updateAndOptionallyMove` — une seule transaction `_run`.

- Contrôleur : `saveEditedNode` (met à jour le cache comme un move si besoin).
- Si le déplacement échoue, les champs ne sont pas persistés.
- Pas de message de succès trompeur ; l’erreur reste celle du moteur (`parentUnavailable`, etc.).
- Pas de refactorisation générale.

---

## 7. Fichiers modifiés

| Fichier | Rôle |
|---|---|
| `lib/app/inventory_creation_screen.dart` | Retirer, barres d’actions, `saveEditedNode` |
| `lib/app/inventory_tree_screen.dart` | Cycle 4 clics, DnD, messages succès |
| `lib/app/inventory_tree_controller.dart` | `saveEditedNode` |
| `lib/core/domain/inventory_engine.dart` | `updateAndOptionallyMove` + helpers `_write*` |
| `pubspec.yaml` | `1.0.9+10` |

---

## 8. Compilation et APK

| Élément | Valeur |
|---|---|
| `flutter analyze` (fichiers touchés) | No issues found |
| `flutter run -d emulator-5554` | OK (debug) |
| APK | `dist/android/Inventory-v1.0.9-arm64-release.apk` |
| Taille | ~20,3 Mo |
| SHA-256 | `2899d7290c9fd6cfd2f80596c2ae072f8b665d73d7ed503449ecc2dd065f6a52` |
| `applicationId` | `io.github.cometom3.inventory` |
| versionName / versionCode | `1.0.9` / `2010` (split arm64) |
| Signature | Production Inventory V1 (même empreinte DEV-15) |
| Installation Moto | **Non effectuée** |

Aussi produit : `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.

---

## 9. Interactions observées sur émulateur

| # | Parcours | Statut |
|---|---|---|
| 1 | Modification : Annuler / Enregistrer / Retirer / Supprimer distincts | **Observé** |
| 2 | Retrait Livre · Don → snackbar + hors arbre | **Observé** |
| 3 | Historique : Livre · Don · date | **Observé** |
| 4 | Expansion 4 clics Ess26 | **Observé** |
| 5 | Feuille : infos ↔ fermeture | **Observé** (Livre avant retrait) |
| 6 | DnD valide Boite → Ess26 | **Observé** (`motionevent`) |
| 7 | DnD invalide UI | Non rejoué |
| 8 | Échec save+move partiel | Non forcé (garanti par transaction) |

---

## 10. Blocages restants / validation physique

À confirmer sur **Moto G24 Power** (après autorisation) :

1. Appui long + glisser au doigt (ressenti explorateur de fichiers).
2. Expand-au-survol et auto-scroll sur liste longue.
3. Retirer / Supprimer au pouce (clavier, bas d’écran).
4. Cycle 4 clics au doigt.
5. Persistance des données après quelques opérations.
6. Mise à jour `adb install -r` de `1.0.9` sans clear (même signature).

**Réserves :** DnD non prouvé comme interaction tactile humaine ; dépôt invalide non rejoué en UI ce mandat.

---

**ARRÊT IMMÉDIAT** — pas de tests auto, pas d’install Moto, pas de commit/push, pas de nouveau mandat.
