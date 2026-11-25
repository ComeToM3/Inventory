# UX-CORR-03 — Simplification du formulaire Biens (Informations avancées)

**Date :** 23 novembre 2026  
**Appareil :** Pixel_7a (`emulator-5554`)  
**Motorola :** non installé (hors périmètre)  
**APK :** `app-x86_64-debug.apk` (`--build-number=4021`) — `adb -s emulator-5554 install -r`  
**Verdict :** **VALIDÉ SOUS RÉSERVES**

---

## Synthèse

Section « Informations avancées » Biens allégée : aides permanentes retirées, champs hors besoin retirés de l’UI, actions média sur **une ligne** Galerie / Caméra / Document. Colonnes SQLite et `.invbackup` inchangés ; valeurs legacy préservées à l’enregistrement.

---

## État initial

Dans les avancées Biens :

- Textes d’aide permanents (`Facultatif — une seule photo…`, aide documents / formats / 15 Mo).
- Boutons Galerie / Caméra / Document empilés (photo puis document).
- Champs : Référence ou code-barres, Date d’achat, Prix payé, Lieu ou vendeur (+ Objectif, photo, documents).

---

## Corrections

### Commentaires retirés
- `mainPhotoHelp`
- `supportingDocumentsHelp`

Conservés : libellés fonctionnels (Photo principale, Documents justificatifs, Galerie, Caméra, Document) et messages d’erreur / traitement.

### Ligne horizontale
`GoodsMainPhotoField` : une `Row` de trois `OutlinedButton.icon` Expanded — Galerie (ou Remplacer) / Caméra / Document.  
`GoodsDocumentsField` : liste seule (plus de bouton Ajouter séparé).

### Champs retirés de l’UI
Référence / code-barres, date d’achat, prix payé, lieu/vendeur.

**Préservation :** chargés en `_preserved*` à l’édition et renvoyés tels quels à `saveEditedNode` (pas d’écrasement involontaire). Création : `null` pour ces champs.

Conservés dans l’UI avancée : photo, documents, objectif.

### Fichiers
- `lib/app/goods_main_photo_field.dart`
- `lib/app/goods_documents_field.dart`
- `lib/app/inventory_creation_screen.dart`
- `lib/app/app_strings.dart`

Aucun schéma SQLite, aucune migration, aucun commit.

---

## Preuves Pixel_7a

| Critère | Résultat | Nature |
|---|---|---|
| Champs retirés absents (création / édition) | Aucun libellé Référence, date, prix, lieu | Observé (uiautomator) |
| Aides « Facultatif / 15 Mo / optimisée » absentes | Aucune | Observé |
| Ligne Galerie / Caméra / Document | Même Y ; bounds dans l’écran | Observé après scroll |
| Objectif + listes photo/documents | Présents | Observé |
| Bouton Document | Ouvre le sélecteur SAF (Downloads / PDF…) | Observé |
| Enregistrement édition ItemC | `barcode_ref=LEGACY-UX03`, `purchase_place=MagasinX`, date et prix inchangés | Observé (SQLite après Enregistrer) |
| Photo + document bout-en-bout + réouverture | Non finalisé sous ADB (parcours flaky hors app) | Non observé E2E |

Dumps : `build/ux-corr-03/` (`visual.json`, `results.json`, XML).

---

## Réserves

1. Ajout photo/document jusqu’à sauvegarde + réouverture non démontré E2E dans cette session ADB (le sélecteur Document a bien été ouvert).  
2. Pas de réception Motorola.  
3. Validation tactile au doigt non faite.

---

## Verdict

**VALIDÉ SOUS RÉSERVES**

Simplification UI et préservation des données legacy démontrées sur Pixel_7a. Réserve : E2E média complet.

**STOP** — Inventory au premier plan sur Pixel_7a ; données conservées ; pas de Motorola.
