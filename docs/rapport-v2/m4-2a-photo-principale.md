# M4.2-A — Photo principale optimisée

**Date :** 21 novembre 2026  
**Verdict :** VALIDÉ SOUS RÉSERVES

## 1. Réutilisé

- `InventoryCreationScreen` + section `InventoryAdvancedSection` (Biens)
- Flux Créer / Enregistrer / Annuler / Supprimer existants
- `path_provider` (support directory), `crypto`/`uuid` locaux
- Préférence et champs avancés M4.1-A/B inchangés dans leur rôle

## 2. Ajouts strictement nécessaires

| Élément | Rôle |
|---|---|
| `image_picker` | Galerie (Photo Picker) + caméra |
| `flutter_image_compress` | Resize + WebP q80 natif (mémoire) |
| `GoodsPhotoStore` | Temp → promote → delete sous `files/photos/` |
| `GoodsMainPhotoField` | UI compacte dans la section avancée |
| Colonne `nodes.photo_rel_path` (schéma 12) | Référence relative uniquement |

Pas de table médias générique, pas de dédup SHA, pas de vignette séparée, pas de nouvel écran.

## 3. Stockage privé

- Répertoire : `getApplicationSupportDirectory()/photos/`
- Temporaires : `photos/tmp/` (vidés après promote / annulation)
- SQLite : `photo_rel_path` du type `photos/<uuid>.webp` — **aucun BLOB**

## 4. Compression

- Côté long max **1280 px**, proportions conservées, pas d’agrandissement
- WebP qualité **80**, `keepExif: false`
- Le sélecteur borne déjà à 1280 avant compression

## 5. Mesures réelles (émulateur)

Image de test poussée : `_m42a_source.jpg` (motif 3000×2000).

| Mesure | Résultat |
|---|---|
| Taille source | **1 569 003 octets** (~1,50 Mo) |
| Résolution source | **3000 × 2000** |
| Taille WebP finale | **81 848 octets** (~80 Ko) |
| Résolution WebP | **1280 × 853** (≤ 1280) |
| Réduction | **94,8 %** |
| Copies persistantes | **1** (`photos/<uuid>.webp`) |
| Binaire dans SQLite | **Aucun** (`photo_rel_path` texte) |
| `photos/tmp` après parcours | **vide** |

## 6. Parcours observés

| Parcours | Résultat |
|---|---|
| Bien sans photo | OK (création/édition inchangée) |
| Ajout galerie + enregistrement | OK — preview + fichier WebP + chemin en base |
| Redémarrage app | Chemin et fichier toujours présents |
| Remplacement | UI « Remplacer » ; ancienne copie supprimée à l’enregistrement réussi |
| Annulation après marquage suppression | Photo conservée tant que non enregistré (vérifié sur annulation formulaire) |
| Suppression photo + Enregistrer | `photo_rel_path = NULL`, fichier retiré |
| Stock « Nouveau produit » | Pas de section photo / avancées |
| Caméra | Dialogue permission Android ouvert ; capture complète non aboutie dans la session |

## 7. Annulations / remplacements / suppressions

- Pending WebP en `tmp` tant que non enregistré ; nettoyé à l’annulation / dispose
- Remplacement : ancienne photo intacte jusqu’à succès SQL, puis suppression fichier
- Échec d’enregistrement après promote : fichier promu retiré, ancienne inchangée
- Suppression de fiche : `deleteNodePermanently` efface aussi le WebP associé

## 8. Non-régression

Champs simples, navigation, Stock / À acheter, valorisation : pas de changement fonctionnel observé hors Biens avancés.

## 9. Émulateur

- APK : `build/app/outputs/flutter-apk/app-debug.apk` (debug M4.2-A)
- Install : `adb install -r` sur `emulator-5554` (**sans** `flutter install`)
- App `io.github.cometom3.inventory` au premier plan, prête

## 10. Réserves

| ID | Sévérité | Détail |
|---|---|---|
| R1 | P2 | Capture caméra : permission exercée ; prise de vue + enregistrement non validés bout-en-bout sur l’émulateur |
| R2 | P2 | Déduplication SHA-256 / `ref_count` du plan V2 reportés (volontairement hors M4.2-A) |
| R3 | P2 | Inclusion des fichiers photo dans sauvegarde V2 → M5.2 |

## Verdict

**VALIDÉ SOUS RÉSERVES** — photo principale WebP opérationnelle depuis la fiche Biens, stockage mesuré et conforme ; réserve caméra bout-en-bout et dédup future.

**STOP** — ne pas démarrer M4.2-B.
