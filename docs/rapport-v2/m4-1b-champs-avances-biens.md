# M4.1-B — Champs avancés Biens

**Date :** 21 novembre 2026  
**Verdict :** VALIDÉ

## Réutilisation et préservation de l’existant

1. **Réutilisé :** `InventoryCreationScreen`, `InventoryAdvancedSection`, `SettingsScreen` (préférence M4.1-A), `parseCadCents` / motifs `InputDecoration`, `InventoryEngine` / `InventoryTreeController` / `saveEditedNode` / `createNodeAt`, Drift `nodes` + migration additive.
2. **Créé :** colonnes SQLite avancées + enum `ItemObjective` uniquement — indispensables pour la persistance ; pas de nouvel écran, service ni formulaire dynamique.
3. **Préservé :** ordre/position des champs simples, clavier, navigation inférieure, sauvegarde unique Créer/Enregistrer, Stock / À acheter sans section avancée, valorisation inchangée (prix payé distinct).
4. **Solution plus simple ?** Champs directement dans la section existante = approche retenue. Une sous-page ou un modèle de métadonnées générique aurait été plus complexe et contraire à la directive.

## Modifications

| Zone | Détail |
|---|---|
| Schéma v11 | `barcode_ref`, `purchase_date`, `purchase_price_cents`, `purchase_place`, `objective` |
| UI Biens | Section **Informations avancées** : référence, date d’achat, prix payé CAD, lieu/vendeur, objectif Aucun/Vendre/Réparer |
| Persistance | Création + modification via le flux de sauvegarde existant |
| Stock / À acheter | Aucun champ avancé ajouté |

## Observé sur émulateur (`Pixel_7a`)

- Section visible sur fiche Bien ; champs existants avant la section.
- Saisie `ABC-123` + objectif **Vendre** → enregistrés (`objective=sell`, `barcode_ref=ABC-123`).
- Rechargement en modification : valeurs présentes.
- Formulaire Stock « Nouveau produit » : pas de section avancée.
- App au premier plan après installation `adb install -r` du debug APK M4.1-B.

## Non inclus (hors mandat)

Photos, caméra, documents, code-barres scanné, changements Stock/À acheter, sauvegarde V2.

## Verdict

**VALIDÉ** — champs avancés Biens dans la fiche existante, persistés, sans nouveau parcours.

**STOP.**
