# Rapport DEV-24 — Liste originale + sous-ligne compacte

## Verdict

| État | Statut |
|---|---|
| Implémenté | Oui |
| Compilé | Oui (`1.0.7+8`) |
| Observé sur émulateur | Oui |
| Installé Moto | Non |
| Validé physique | **En attente** |

**ARRÊT — attendre le retour du propriétaire.**

---

## 1. Causes de la régression visuelle

- Fond `selectedRow` / panneau `mintSoft` sur la fiche dépliée → aspect « carte ».
- Consultation en **colonne** (Type, Position, boutons) au lieu d’une sous-ligne.
- Menu ⋮ avec **Supprimer** en consultation.
- `bottom: 4` et padding supplémentaires sur les lignes.

## 2. Modifications

1. Ligne fermée : fond transparent (sauf survol DnD), pas de carte, espacement d’origine.
2. Consultation = **une sous-ligne** `infos · infos` + icône ✎.
3. **Supprimer** uniquement en mode Modifier (`Annuler | Enregistrer | Supprimer`).
4. Retrait d’inventaire conservé en édition (biens), hors consultation.

## 3. Ligne principale (fermée)

Identique à l’esprit DEV-20 : chevron · icône · nom · sous-titre/totaux · prix · `+` enfant.  
Liste courte alignée en bas.

## 4. Sous-ligne

Exemple observé (bien) : `Qté : 1 · Ess2` + ✎  
Exemple (emplacement racine) : `Emplacement` + ✎  
Pas de nom / prix répétés, pas de Supprimer.

## 5. Supprimer

Dans le formulaire Modifier, style destructif, confirmation avec nom de l’élément.

## 6. Fichiers

`inventory_inline_sheet.dart`, `inventory_tree_screen.dart`, `inventory_action_bar.dart`, `app_strings.dart`, `pubspec.yaml`

---

## 7. Compilation

`flutter analyze` OK · `flutter run -d emulator-5554` OK

## 8. Validation émulateur

| Point | Statut |
|---|---|
| Ligne fermée sobre | **Observé** (screencap) |
| Sous-ligne unique | **Observé** |
| 2ᵉ appui referme | **Observé** |
| Pas de prix/nom répétés | **Observé** (Ray) |
| Pas de Supprimer en consultation | **Observé** |
| Modifier → édition | **Observé** |
| Supprimer en édition | **Observé** |
| Chevron ≠ consultation | **Observé** |
| Liste courte en bas | **Observé** |
| DnD non retouché | Non rejoué (inchangé) |

## 9. Limites

- DnD : pas de re-validation ce mandat.
- Confirmation suppression : dialogue standard (nom inclus).
