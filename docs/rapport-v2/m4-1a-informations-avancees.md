# M4.1-A — Informations avancées et préférence d’affichage

**Date :** 21 novembre 2026  
**Verdict :** VALIDÉ SOUS RÉSERVES

## Éléments existants réutilisés

- `InventoryCreationScreen` (création / modification Biens, Stock, À acheter)
- `SettingsScreen` + `InventoryThumbBody`
- `InventoryDatabase` Drift/SQLite (schéma v9 → v10)
- `InventoryEngine` / `InventoryTreeController` pour les écritures
- Convention visuelle `ExpansionTile` déjà présente (Recherche)

## Modifications réalisées

| Zone | Changement |
|---|---|
| Schéma | Colonne `nodes.show_advanced` ; table `app_preferences` ; migration v10 |
| Paramètres | Interrupteur **Afficher les informations avancées par défaut** |
| Domaine | Lecture/écriture préférence ; snapshot à la création ; `updateShowAdvanced` |
| UI fiche | `InventoryAdvancedSection` branchée après les champs existants |
| Contenu avancé | Aucun champ métier ajouté (hors périmètre M4.1-A) |

## Comportement réellement observable

**Implémenté et observé sur émulateur**

- Paramètre global présent, activable, persisté (`app_preferences.show_advanced_by_default`).
- Création d’emplacement et de bien : champs existants inchangés (position, quantité, valorisation, nom, actions).
- Aucune section vide « Informations avancées » affichée (pas d’UI trompeuse).
- Bien créé avec préférence ON → `show_advanced = 1` en base.
- Emplacement → `show_advanced = 0`.
- Préférence ensuite remise à OFF → le bien conserve `show_advanced = 1`.
- Onglets Stock / À acheter s’ouvrent sans régression visible.

**Implémenté, non démontrable visuellement tant que M4.1-B n’ajoute pas de champs**

- Ouverture / fermeture de la section (widget prêt ; `children` vide ⇒ `SizedBox.shrink`).
- Persistance immédiate du toggle en édition (`updateShowAdvanced`) — câblée, sans contenu pour l’exercer.

**Encore à développer (mandats suivants)**

- Champs avancés (photo, document, code-barres, achat, objectifs) — M4.1-B / M4.2
- Inclusion des préférences dans la sauvegarde V2 — M5.2

## Persistance

- **Nouvelle** : `app_preferences` + `nodes.show_advanced` (schéma 10).
- Règle appliquée : préférence globale = état initial des **nouvelles** fiches uniquement ; ensuite état propre à la fiche.
- Fiches existantes à la migration : `show_advanced = 0` (indépendant de la préférence).
- Masquer ≠ supprimer : aucune donnée métier avancée n’existe encore ; refermer ne pourra pas les effacer.

## Décision documentée (création vs fiche enregistrée)

Comportement existant du formulaire conservé :

- **Création** : état local initialisé depuis la préférence globale au moment de l’ouverture ; figé sur le nœud à l’enregistrement.
- **Modification** : état lu depuis le nœud ; la préférence globale n’est plus consultée.

Aucune règle nouvelle inventée.

## Compilation et validation émulateur

| Étape | Résultat |
|---|---|
| `flutter analyze` (fichiers touchés) | OK |
| `flutter build apk --debug` | OK — `app-debug.apk` |
| Émulateur `Pixel_7a` (`emulator-5554`) | Démarré / actif |
| Installation | `adb install -r` du debug APK (données conservées après cette installation) |
| Lancement | `MainActivity` au premier plan |
| Version | Correspond aux modifications M4.1-A |

**Incident :** un premier `flutter install` a tenté un APK release absent et a désinstallé l’ancienne version (perte des données fictives antérieures de l’émulateur). Réinstallation debug effectuée ensuite ; l’émulateur reste ouvert avec l’app prête.

## Limites / réserves

1. Section avancée non visible tant qu’aucun contenu n’est fourni (conforme au mandat).
2. Ouverture/fermeture UI non observée — réservée à M4.1-B.
3. Préférences absentes de la sauvegarde V1 actuelle.
4. Données émulateur antérieures perdues lors de l’incident `flutter install`.

## Verdict

**VALIDÉ SOUS RÉSERVES** — infrastructure et préférence opérationnelles ; validation visuelle de la section collapsible reportée à l’arrivée des champs avancés.

**STOP** — ne pas démarrer M4.1-B sans nouveau mandat.
