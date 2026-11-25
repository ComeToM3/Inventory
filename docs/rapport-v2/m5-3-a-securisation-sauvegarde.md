# M5.3-A — Sécurisation et validation réelle de la sauvegarde/restauration

**Date :** 21 novembre 2026  
**Périmètre :** I-01, I-02, I-03, I-18  
**Verdict :** **VALIDÉ SOUS RÉSERVES**

---

## 1. Cause exacte du risque I-02

Avant correction, `BackupRestorer.apply` :

1. Écrivait `pending`
2. Remplaçait SQLite et passait le journal à **`committed` dans la même transaction**
3. Puis seulement activait / vérifiait les médias

Si l’app s’interrompait après l’étape 2, la base pointait déjà vers le nouvel inventaire alors que les fichiers `photos/` / `documents/` pouvaient être absents, partiels ou encore les anciens.  
`RestorationRecovery` traitait `committed` comme succès **sans contrôler les fichiers**.

Une transaction SQLite ne couvre pas le remplacement des répertoires médias.

## 2. Modifications minimales apportées

| Élément | Changement |
|---|---|
| Journal | Nouveau statut `db_ready` entre remplacement SQLite et validation médias |
| Schéma Drift | `schemaVersion` **15** + migration table journal (`pending` / `db_ready` / `committed`) |
| `BackupRestorer.apply` | `pending` → clear/insert → **`db_ready`** → activation+vérif médias → **`committed`** → nettoyage |
| Échec médias | Ne restaure plus les anciens médias sous la nouvelle base ; laisse `db_ready` pour reprise |
| `RestorationRecovery` | `db_ready` : tente `tryCompleteDbReady` (staging → live) ; sinon `unreliable`. `committed` : vérifie l’existence des fichiers référencés |
| Format `.invbackup` | **Inchangé** (V2 format 2 / data_schema 3) |
| UI Paramètres / SAF | **Inchangée** |

## 3. Transitions du journal (avant / après)

**Avant :** `pending` → `committed` (médias hors journal)

**Après :**

```
pending          # intention durable ; inventaire actif encore l’ancien
    ↓ (txn SQLite clear+insert)
db_ready         # nouvelle base écrite ; médias non confirmés
    ↓ (activation + verify live)
committed        # SQLite + médias cohérents
    ↓ (UI acknowledge)
(journal vide)
```

## 4. Garanties de récupération après interruption

| État au démarrage | Traitement |
|---|---|
| `pending` | Inventaire précédent conservé → message `notApplied` |
| `db_ready` + staging complet | Finalisation médias → `committed` → `completed` |
| `db_ready` irrécupérable | `unreliable` (écritures bloquées) |
| `committed` + fichiers OK | `completed` |
| `committed` + fichiers manquants | `unreliable` (plus de confiance aveugle en `committed`) |

Les temporaires / `restore_media_previous` ne sont nettoyés qu’après `committed`.

## 5. Scénarios de défaillance réellement vérifiés

| Scénario | Preuve | Résultat |
|---|---|---|
| Restauration médias normale | `backup_restore_media_interrupt_test` | **Testé techniquement** → `committed` + fichiers live |
| Échec avant remplacement SQLite | idem + tests restore V1 | **Testé techniquement** → ancien inventaire + `pending` / `notApplied` |
| Échec après `db_ready` avant médias | `debugAfterDbReady` + recovery | **Testé techniquement** → reprise depuis staging → `committed` |
| `committed` avec média manquant | suppression fichier puis `inspect` | **Testé techniquement** → `unreliable` |
| Suite backup unitaire existante | `test/core/backup/` | **Testé techniquement** — OK |

## 6. Parcours SAF réellement observés

Sur `Pixel_7a` (`emulator-5554`), APK debug x86_64 installé (`adb install -r`) :

| Étape | Statut |
|---|---|
| Paramètres → avertissement non chiffré → « Choisir une destination » | **Observé dans l’application** |
| SAF CREATE → `inventory-20261121-235637.invbackup` → SAVE | **Observé dans l’application** |
| Fichier créé `/sdcard/Download/…invbackup` (8621 o) | **Observé** |
| Intégrité / contenu (format 2, schéma 3, 3 espaces, médias, stock, achats, prefs) | **Testé techniquement** sur le fichier exporté |
| Paramètres → Restaurer → sélection SAF du fichier | **Observé dans l’application** |
| Dialogue « Remplacer l’inventaire ? » + résumé (8 éléments) | **Observé dans l’application** |
| Confirmation Remplacer | **Observé dans l’application** |
| Message snackbar de succès export | **Non démontré** (dump UI sans texte de statut visible au moment du dump) |

## 7. Données et médias restaurés

Inventaire fictif ajouté **sans supprimer** les 4 biens existants, puis restauré après mutation marqueur :

| Donnée | Après restauration |
|---|---|
| Biens | Salonn, Lampem, DocTestM42B, Ordinateur portable (plus de `_MUTATED`) |
| Stock | Cellier, Farine + 1 `stock_movements` — **Observé** dans l’onglet Stock |
| À acheter | Courses, Café + 1 `purchase_events` — **Observé** dans l’onglet |
| Photo WebP | `photos/m53a_photo.webp` présent, SHA-256 = seed |
| Documents PDF + PNG | présents, SHA-256 = seed |
| `icon_key` | `laptop` sur Ordinateur portable |
| Préférence | `show_advanced_by_default = 0` |

Ouverture viewer externe photo/PDF dans l’UI : **Non démontré** (fichiers et références vérifiés sur disque / SQL).

## 8. Préservation de l’inventaire initial

| Artefact | Rôle |
|---|---|
| `build/m5-3a-safety/files/inventory.sqlite` | Copie de sécurité **avant** seed (4 biens goods, schéma 14 au moment de la copie) |
| `build/m5-3a-safety-seeded/` | Copie après seed (3 espaces + médias) |
| Aucun wipe / désinstallation | Confirmé |

L’inventaire initial n’a pas été effacé sans filet ; la restauration a porté sur un état volontairement muté après sauvegarde de sécurité.

## 9. Compatibilité V1 (I-18) — décision

**Conservée telle quelle :**

- Import `format_version = 1` + `data_schema_version = 1–2` (JSON pur, sans médias)
- Normalisation legacy (`space` → `goods`, `container` → `item_container`)
- **Pas** de nouveau moteur de migration
- Export uniquement V2 (`format_version = 2`, `data_schema_version = 3`)

Limite documentée : une sauvegarde V1 ne transporte pas photos/documents/Stock étendu ; l’import reste utile pour la hiérarchie Biens V1.

## 10. Tests techniques complémentaires

- `flutter test test/core/backup/` — tous OK après correctif I-02
- Vérification du fichier SAF exporté (format, 3 espaces, ≥3 médias, mouvements, événements, prefs)
- Refus d’un export volontairement corrompu (bit retourné)

## 11. Limites / réserves restantes

| Prio | Réserve |
|---|---|
| — | **P0** : aucun |
| P2 | Ouverture viewer photo/document dans l’UI après restauration non rejouée |
| P2 | Texte de succès export non capturé dans le dump UI |
| P2 | Décodage encore entièrement en RAM (I-04 INTER-01) — hors périmètre |
| — | Groupe B (tactile, Moto, etc.) : **non traité** (STOP) |

## 12. État final de l’émulateur

- `Pixel_7a` / `emulator-5554` démarré
- Inventory debug installé (schéma **15**), **au premier plan**
- Inventaire courant = état restauré V2 (3 espaces + médias)
- Données initiales protégées via copies `build/m5-3a-safety*`
- Motorola non touché

## Synthèse des preuves

| Exigence de clôture | Statut |
|---|---|
| Export + restauration via SAF | **Observé** |
| Trois espaces + médias récupérés | **Observé** (UI + SQL + SHA fichiers) |
| Interruption sans incohérence irrécupérable SQLite/médias | **Implémenté** + **Testé techniquement** |
| Données initiales protégées | **Confirmé** (sauvegardes host) |
| App après redémarrage | **Observé** |

---

**Verdict : VALIDÉ SOUS RÉSERVES** — I-01/I-03 démontrés sur l’émulateur ; I-02 corrigé et prouvé en tests isolés ; I-18 tranché (import V1 conservé). Réserves P2 mineures (viewer UI, message export).

**STOP** — M5.3-B (Groupe B) non démarré.
