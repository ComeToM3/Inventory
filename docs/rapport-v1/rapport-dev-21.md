# Rapport DEV-21 — Incohérences ergonomiques des fiches

## Verdict

| État | Statut |
|---|---|
| Implémenté | Oui |
| Compilé | Oui (`1.0.4+5`) |
| Installé (Moto) | Non — appareil absent (seul `emulator-5554`) |
| Validé par l’utilisateur | **En attente** |

**ARRÊT — validation physique du propriétaire requise.**

---

## 1. Quatre corrections

| # | Problème | Correction |
|---|---|---|
| 1 | SnackBars en bas masquant les actions | `showInventoryMessage` : SnackBar flottant sous l’AppBar |
| 2 | Position via page séparée | `InventoryParentField` : liste déroulante in-fiche + `+` emplacement |
| 3 | Édition ≠ création | `NodeEditScreen` aligné sur création (ordre + `$`/`♡` + barre) |
| 4 | Consultation collée en haut | Fiche détail via `InventoryThumbBody` |

---

## 2. Causes identifiées

1. **Notifications** : `SnackBar` par défaut (bas) ; pas de marge haute partagée.
2. **Position** : `Navigator.push` vers `_ParentSelectionScreen` / arbre.
3. **Modification** : ancienne UI (condition, switches, slider) non portée sur le modèle DEV-19/20.
4. **Consultation** : `ListView` dans `Expanded` sans `InventoryThumbBody` → contenu ancré en haut.

---

## 3. Composants réutilisés / mutualisés

- `showInventoryMessage` / `showInventoryMessageOn` — `inventory_messages.dart`
- `InventoryParentField` — sélecteur commun création / modification
- `InventoryValuationField` — ligne `$` / ♡ / valeur
- `InventoryActionBar` — Annuler | (+)| Créer / Annuler | Enregistrer / Modifier | Déplacer
- `InventoryThumbBody` — fiches courtes vers le bas
- `listContainmentCandidates` — candidats hiérarchiques (hors sous-arbre en édition)

---

## 4. Fichiers modifiés / ajoutés

**Ajoutés :** `inventory_messages.dart`, `inventory_parent_field.dart`, `inventory_valuation_field.dart`

**Modifiés :** `inventory_creation_screen.dart`, `node_edit_screen.dart`, `node_details_screen.dart`, `node_details_controller.dart`, `inventory_tree_controller.dart`, `main_navigation_screen.dart`, `settings_screen.dart`, `pubspec.yaml` (`1.0.4+5`)

---

## 5. Limites

- Déplacement dédié (écran Move) conservé ; la fiche d’édition peut aussi changer la position (même règles moteur).
- Messages backup/restore : SnackBar haut **en plus** du texte de statut Paramètres.
- Fiche « retiré » non retouchée (hors périmètre principal).
- Moto non branchée → pas d’installation physique.

---

## 6. Version Android

- **versionName** : `1.0.4`
- **versionCode** : `5`
- **APK** : `build/app/outputs/flutter-apk/app-release.apk`
- Identifiant / signature production inchangés.

---

## 7. Installation physique

- ADB : `emulator-5554` seulement.
- Moto G24 Power : **non détecté** → arrêt après préparation APK (pas d’install émulateur comme preuve).

---

## 8. Points à valider (propriétaire)

1. Notification temporaire **en haut** (création, édition, déplacement, retrait/suppression, backup/restore).
2. Position **dropdown** dans la fiche (sans page dédiée) ; `+` crée un emplacement puis revient.
3. Création et modification **visuellement cohérentes** (Position → Quantité → Valorisation → Nom ; édition sans `+` central).
4. Consultation : infos **vers le bas** si fiche courte.
5. Navigation et données préservées.

Ne pas marquer **VALIDÉ** avant ce retour.
