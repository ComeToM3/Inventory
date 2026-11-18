# Rapport DEV-28 — Ordre d’arborescence et préparation restauration

## Verdict

**VALIDÉ SOUS RÉSERVES**

- Ordre d’arborescence corrigé, installé et observé sur Moto.
- Remise à zéro (`pm clear`) **autorisée explicitement** puis exécutée.
- Restauration depuis `/sdcard/Download/inventory-20261115-201405.invbackup` **réussie** et persistante après force-stop.
- Réserves : confirmation tactile propriétaire encore utile (DnD, expansion 4 clics au doigt) ; GO production non déclaré ici.

---

## 1. Cause du problème d’arborescence

| Aspect | Constat |
|---|---|
| Relations `parent_id` | **Correctes** (biens sous Chambre, Garde-robe enfant de Chambre) |
| Présentation | **Incorrecte** — `getChildren` triait uniquement par **nom** (`_byName`) |
| Effet | Un sous-emplacement (ex. « Garde-robe ») s’intercalait alphabétiquement entre les biens directs |

**Erreur de présentation uniquement**, pas de corruption des liens parent-enfant.

---

## 2. Correction effectuée

Dans `InventoryEngine.getChildren` :

1. Biens simples (`node_type = 'item'`) en premier  
2. Puis emplacements / biens-contenants  
3. Tri alphabétique **dans** chaque groupe  
4. Aucune modification de `parent_id`  
5. Racines (`getRootLocations`) inchangées (emplacements seulement)

---

## 3. Composants réutilisés

- `InventoryEngine.getChildren` (seul point de lecture des enfants actifs)  
- Cache / rendu existants de `InventoryTreeController.visibleEntries`  
- Aucun nouvel écran, propriété de tri manuel, ni migration

---

## 4. Fichiers modifiés

| Fichier | Rôle |
|---|---|
| `lib/core/domain/inventory_engine.dart` | `_byTreeDisplay` + `orderBy` sur `getChildren` |
| `pubspec.yaml` | `1.0.11+12` |

---

## 5. Version et APK

| Élément | Valeur |
|---|---|
| versionName | `1.0.11` |
| versionCode (arm64 split) | `2012` |
| APK | `dist/android/Inventory-v1.0.11-arm64-release.apk` |
| SHA-256 | `0082e55ba6a26920ecbaae700b69563b3edf654d6e4c77ee70e8ce2422bf7994` |
| Signature | Production Inventory V1 (identique) |
| `flutter analyze` | No issues found |

---

## 6. Installation Moto G24 Power

| Contrôle | Résultat |
|---|---|
| Appareil | `ZT322P23HJ` / moto g24 power |
| Avant | `1.0.10` / versionCode `2011` |
| Commande | `adb -s ZT322P23HJ install -r …` |
| Après | `1.0.11` / versionCode `2012` |
| Données | **Préservées** (`MaisonDEV15`, `chambre`, totaux) |
| Désinstall / clear | **Non** |

---

## 7. Sauvegarde — emplacement et vérification

### Sur le téléphone (Download)

| Fichier | Taille | Note |
|---|---|---|
| `/sdcard/Download/inventory-20261115-201405.invbackup` | **5634 o** | Export récent (non vide) |
| `/sdcard/Download/inventory-20261114-182312.invbackup` | 1353 o | Ancien |
| `/sdcard/Download/inventory-20261114-174424.invbackup` | 5406 o | Ancien |
| `/sdcard/Download/bad-dev14.invbackup` | 1 o | Invalid / test — ne pas utiliser |

### Copie indépendante sur PC

`dist/android/backups-dev28/`

- `inventory-20261115-201405.invbackup` (5634 o)  
- `inventory-20261114-182312.invbackup` (1353 o)

**Preuve :** fichiers listés via ADB + pull PC (pas seulement une snackbar).

---

## 8. État des données avant toute remise à zéro

Inventaire actif observé après install `1.0.11` :

- Racine `MaisonDEV15` (total financier affiché)  
- Enfant `chambre`  
- Sous `chambre` (1er clic d’expansion) : **biens simples d’abord**, puis `Garde-robe`

Ordre observé sous chambre :

1. Ordinateur principal  
2. bureau assis debout à pompe  
3. clavier  
4. guitar godin concert 2  
5. haut-parleur FM sans fil  
6. souris d'ordinateur sans fils  
7. **Garde-robe** (emplacement)

Conforme à la règle demandée.

---

## 9. Restauration sur base vierge

| Étape | État |
|---|---|
| Autorisation propriétaire | **Oui** (« Jautorise d’effacer (pm clear ») |
| `adb -s ZT322P23HJ shell pm clear …` | **Success** — inventaire vide observé |
| Fichier choisi | `/sdcard/Download/inventory-20261115-201405.invbackup` |
| Dialogue | « 11 élément(s), 1 bien(s) retiré(s) » → Remplacer |
| Message app | « Restauration effectuée. L’inventaire a été remplacé. » |
| Après restore | `MaisonDEV15` / `chambre` / biens / `Garde-robe` |
| Historique | `LampeDEV15 · Vente · 14/11/2026` |
| Force-stop + relance | **Persistance confirmée** (même arbre + ordre) |

---

## 10. Parcours physiques / observés

| Parcours | Statut |
|---|---|
| Install `1.0.11` sans perte (avant clear) | **Observé** |
| Ordre biens puis Garde-robe sous chambre | **Observé** (avant et après restore) |
| `pm clear` → inventaire vide | **Observé** |
| Restore SAF depuis Download | **Observé** |
| Valorisations / totaux (`2 185 $`) | **Observé** |
| Historique retiré | **Observé** |
| Persistance après force-stop | **Observé** |
| Expansion 4 clics / DnD / création au doigt | Non rejoués ce complément |
| Confirmé propriétaire au doigt | Partiel (autorisation clear ; pas de checklist tactile complète) |

---

## 11. Anomalies restantes / V1

| ID | Gravité | Note |
|---|---|---|
| DnD au doigt | À confirmer | Correctifs `1.0.10` ; validation tactile propriétaire encore souhaitable |
| P3 | — | `bad-dev14.invbackup` (1 o) à ignorer / supprimer manuellement |

Critère PRD « une sauvegarde peut être restaurée sur une installation propre » : **démontré sur Moto** pour cette sauvegarde.

---

**ARRÊT** — aucun commit/push, aucun nouveau mandat. Attendre décision GO V1 du propriétaire.
