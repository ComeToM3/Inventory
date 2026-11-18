# Rapport DEV-18 — Corrections fonctionnelles (attente validation physique)

## Verdict

**EN ATTENTE DE VALIDATION PHYSIQUE**

Corrections appliquées. APK release signé prêt (`1.0.1` / `versionCode 2002`).  
**Moto G24 Power non connecté** → installation non effectuée. Aucune validation déclarée à ta place.

---

## Corrections effectuées

1. **Création biens** — choix mutuellement exclusif dès la fiche :
   - Aucune valorisation
   - Financier (montant CAD)
   - Sentimental (note 1–5)
2. **Fiche détail** — bouton Modifier déplacé en bas (avec Déplacer / Retirer) ; suppression reste au menu ⋮.
3. **Paramètres** — actions Sauvegarder / Restaurer placées en zone basse via `InventoryThumbBody`.
4. **Version** — `1.0.0+1` → `1.0.1+2` pour mise à jour sans désinstallation.

Conservé (déjà en place DEV-17, non réouvert en audit) : 3 types, fiche complète + position, pas d’ⓘ, prix `$` si financier, `PopScope` + predictive back, pas de catégories/descriptions.

---

## Fichiers modifiés

| Fichier | Motif |
|---|---|
| `lib/app/inventory_creation_screen.dart` | Valorisation aucune / financier / sentimental |
| `lib/app/app_strings.dart` | `valuationNone` |
| `lib/app/node_details_screen.dart` | Actions principales en bas |
| `lib/app/settings_screen.dart` | Ergonomie bas d’écran |
| `pubspec.yaml` | `version: 1.0.1+2` |

---

## Version Android préparée

| Champ | Valeur |
|---|---|
| Package | `io.github.cometom3.inventory` |
| versionName | `1.0.1` |
| versionCode (arm64 split) | `2002` (> `2001` installé) |
| Signature | keystore production existant (`android/key.properties`) |
| APK | `dist/android/Inventory-v1.0.1-arm64-release.apk` (~20,5 Mo) |
| Données | Non touchées (pas de uninstall / clear) |

---

## Connexion Moto G24 Power

| État | Détail |
|---|---|
| ADB | **Connecté** — `ZT322P23HJ` / `moto g24 power` |
| Installation | **Réussie** — `adb install -r` sans clear données |
| Avant | `1.0.0` / `versionCode 2001` |
| Après | `1.0.1` / `versionCode 2002` (2026-11-14 17:47:38) |

**ARRÊT — attendre ton retour d’utilisation réelle.**

---

## Ce que tu pourras vérifier après installation

1. Création emplacement / bien simple / bien-contenant  
2. Position dans la fiche  
3. Valorisation financière **et** sentimentale à la création  
4. Prix en liste / rien sans prix  
5. Tap → fiche  
6. Retour balayage + garde formulaires dirty  
7. Champs / boutons vers le bas  
8. Modification, déplacement, persistance  

---

## Défauts encore observés

Aucun nouveau défaut utilisateur constaté sur téléphone (téléphone absent).

---

## Points attendant ta validation

- Utilisation réelle sur Moto après install.  
- Confirmation que le sentimental à la création et l’ergonomie bas te conviennent.

---

## Arrêt

**ARRÊT — téléphone indisponible.**  
Pas de tests automatisés. Pas d’install émulateur comme preuve. Pas de commit/push. Pas de nouveau mandat.
