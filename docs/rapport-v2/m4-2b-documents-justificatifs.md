# M4.2-B — Documents justificatifs

**Date :** 21 novembre 2026  
**Verdict :** VALIDÉ SOUS RÉSERVES

## 1. Composants existants réutilisés

- `InventoryCreationScreen` + `InventoryAdvancedSection` (Biens)
- Flux Créer / Enregistrer / Annuler / Supprimer / discard
- `InventoryEngine` / `InventoryTreeController` (extension locale)
- Principes M4.2-A : stockage privé, temp → promote, cleanup à l’annulation
- Sélecteur système Android (`FilePicker` / DocumentsUI) — pas d’accès stockage général

**Non réutilisé pour les docs :** `GoodsPhotoStore` (responsabilité photo/WebP distincte, non détournée).

## 2. Nouveaux composants indispensables

| Élément | Rôle |
|---|---|
| `file_picker` | Sélection PDF/JPEG/PNG/WebP |
| `open_filex` | Ouverture lecture seule via appli Android |
| `GoodsDocumentStore` | Copie fidèle temp → promote UUID, delete |
| `GoodsDocumentsField` | Liste compacte + ajouter / ouvrir / retirer |
| Table Drift `node_documents` (schéma **13**) | Métadonnées + `rel_path` uniquement |
| `NodeDocument` / `NodeDocumentWrite` | Modèles domaine |

Pas de bibliothèque documentaire, pas de lecteur PDF interne, pas de table médias commune.

## 3. Structure de persistance

- Schéma Drift **12 → 13** (additif) : table `node_documents`
  - `id`, `inventory_id`, `node_id`, `display_name`, `rel_path`, `mime_type`, `byte_size`, `sort_index`, `created_at`
  - FK composite `(inventory_id, node_id)` → `nodes` **ON DELETE CASCADE**
- Fichiers : `getApplicationSupportDirectory()/documents/<uuid>.<ext>`
- Temporaires : `documents/tmp/`
- SQLite : **références uniquement** — aucun BLOB / Base64

## 4. Gestion des fichiers et annulations

- **Création / édition :** copies en `tmp` jusqu’à enregistrement réussi ; `promoteTemp` puis `syncNodeDocuments`
- **Annuler :** `_discardPendingMedia()` attend la suppression des temps (photo + docs) avant `pop`
- **Retrait UI :** marquage local ; fichiers persistants effacés seulement après sync réussi
- **Suppression de bien :** chemins récupérés avant delete nœud, puis `GoodsDocumentStore.deleteRel`
- Échec d’enregistrement après promote : chemins promus nettoyés ; pas de refs invalides laissées volontairement

## 5. Formats et limites

- Autorisés : `.pdf`, `.jpg`, `.jpeg`, `.png`, `.webp`
- Taille max : **15 Mo** / document
- Contenu **non recompressé** (octets source = copie privée)
- Message observé si trop gros : « Ce fichier dépasse la limite de 15 Mo. »
- Formats hors liste : filtrés par le sélecteur + refus store (`documentUnsupportedType`)

## 6. Mesures réelles de stockage (émulateur)

| Document | Source | Copie privée | Égalité octets |
|---|---|---|---|
| `facture_m42b.pdf` | **45 o** | **45 o** (`documents/<uuid>.pdf`) | Oui (SHA identique) |
| `justificatif_m42b.png` | **74 o** | **74 o** (`documents/<uuid>.png`) | Oui (SHA identique) |
| `trop_gros_m42b.pdf` | **15 728 641 o** (> 15 Mo) | Non retenu | — |

| Contrôle | Résultat |
|---|---|
| Copies persistantes par doc joint | **1** |
| `documents/tmp` après save / delete réussi | **vide** (hors orphelin pré-correctif, nettoyé) |
| Binaire PDF/PNG dans SQLite | **Absent** (`user_version=13`, colonnes texte/entier seulement) |
| Compression | Non applicable (fidélité prioritaire) |

## 7. Parcours observés sur `Pixel_7a` (`emulator-5554`)

| # | Parcours | Statut |
|---|---|---|
| 1 | Création bien sans document (`DocTestM42B`) | **Observé** |
| 2 | Ajout PDF valide | **Observé** |
| 3 | Ajout image justificative PNG | **Observé** |
| 4 | Plusieurs docs sur le même bien | **Observé** |
| 5 | Enregistrement + réouverture | **Observé** (liste + fichiers) |
| 6 | Ouverture via appli Android | **Partiel** — tap effectué ; focus resté sur Inventory (viewer non confirmé) |
| 7 | Retrait d’un seul doc (PNG) sans toucher le PDF | **Observé** (UI + disque) |
| 8 | Annulation d’un ajout | **Observé** — temp du parcours nettoyé après correctif `_discardPendingMedia` |
| 9 | Annulation d’une suppression | **Implémenté** (marquage local + discard) — non rejoué bout-en-bout après correctif |
| 10 | Rejet > 15 Mo | **Observé** |
| 11 | Rejet format non autorisé | **Implémenté** (filtre sélecteur + store) — `.txt` non proposé par DocumentsUI |
| 12 | Suppression définitive + cleanup fichiers | **Observé** (dirs docs vides, table vide) |
| 13 | Redémarrage app | **Observé** (schéma 13, données Biens) |
| 14 | Photos principales toujours opérationnelles | **Observé** (code/store photos inchangés ; dossier `photos/` intact) |
| 15 | Stock / À acheter inchangés | **Observé** (écrans vides habituels, pas de section docs) |

## 8. Régressions éventuelles

- Aucune régression Stock / À acheter observée.
- Photo M4.2-A : store et colonne `photo_rel_path` non modifiés pour ce mandat.
- Données de test : nom de fiche pollué par saisie ADB (`DocMultiM42B ty fact…`) puis fiche supprimée ; `DocTestM42B` / `Lampem` / `Salonn` conservés. Valorisation Salon affichait `42 $` suite à saisie accidentelle en validation — hors code M4.2-B.

## 9. État final de l’émulateur

- APK : `build/app/outputs/flutter-apk/app-debug.apk` (debug M4.2-B)
- Install : `adb install -r` sur `emulator-5554` (**sans** `flutter install`, sans wipe)
- App `io.github.cometom3.inventory` au premier plan
- AVD : `Pixel_7a`

## 10. Réserves et verdict

| ID | Sévérité | Détail |
|---|---|---|
| R1 | P2 | Ouverture externe PDF/image : intent/tap OK côté app ; bascule viewer non confirmée sur cet AVD |
| R2 | P2 | Annulation d’une suppression déjà marquée : logique présente, non revalidée UI après correctif cancel |
| R3 | P2 | Inclusion docs dans sauvegarde complète → M5.2 |

**VALIDÉ SOUS RÉSERVES** — justificatifs multi-fichiers opérationnels dans « Informations avancées », stockage fidèle mesuré, cycle de vie aligné sur la fiche ; réserves viewer externe et quelques parcours secondaires.

**STOP** — ne pas démarrer M5.1.
