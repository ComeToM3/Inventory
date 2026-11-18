# Rapport DEV-17 — Simplification fonctionnelle, fiches complètes et ergonomie mobile

## 1. Verdict

**VALIDÉ SOUS RÉSERVES**

Les décisions produit DEV-17 sont **implémentées** dans le code, **couvertes par les tests unitaires/widget (51/51)** et **démontrées sur émulateur Android** (captures manuelles + `integration_test/dev17_android_smoke_test.dart` vert).

**Réserves :**
- Pas de revalidation sur téléphone physique (Moto) ni APK signé production (volontaire).
- Balayage retour : `enableOnBackInvokedCallback` + `PopScope` avec garde modifications — **implémenté**, **non mesuré** comme geste utilisateur distinct sur tous les parcours (navigation pile OK via intégration `maybePop`).
- Export/restauration `.invbackup` : compatibilité legacy **testée automatiquement** ; **non rejouée** manuellement en DEV-17.
- Colonnes SQLite `description` / tables `categories` conservées vides pour la forme des sauvegardes — abandon fonctionnel, pas drop physique des tables.

**Recommandation release :** **GO sous réserves** (debug validé ; pas de publication sans autorisation).

---

## 2. Inventaire des changements

| Zone | Changement | Statut |
|---|---|---|
| Types | `NodeType` = location / item / itemContainer uniquement | Implémenté + testé + observé |
| Création | FAB → 3 choix → fiche complète immédiate | Idem |
| Position | Champ Position dans fiche création/édition + sélecteur parent | Idem |
| Catégories | APIs moteur, UI, filtres, modèle applicatif retirés | Implémenté + testé |
| Description | Champ applicatif retiré ; colonne DB vidée | Implémenté + testé |
| Liste | Plus d’ⓘ ; prix `N $` si valorisation financière ; rien sinon | Idem |
| Tap ligne | Ouvre fiche | Observé (intégration) |
| Ergonomie | `InventoryThumbBody` : contenu vers le bas si viewport haut | Observé (captures) |
| Navigation | Predictive back Android + `PopScope` anti-perte | Implémenté |
| Schéma | `schemaVersion = 4` + `_migrateToV4` | Testé auto |
| Backup | `normalizeLegacyNode` (container→item_container, 0 $→unset) | Testé auto |

---

## 3. Analyse des dépendances supprimées

**Contenant autonome**
- Retiré de `NodeType`, CHECK SQL, libellés, type picker.
- Anciens `container` → `item_container` (migration + backup).

**Catégories**
- Supprimé : `InventoryCategory`, `createCategory` / assign / filtres recherche, chips UI, chaînes menus.
- Tables `categories` / `node_categories` : vidées à la migration ; payload backup accepte encore les listes puis les ignore (listes vides).

**Description**
- Supprimé du modèle `InventoryNode` et des formulaires.
- Colonne SQLite conservée, forcée à `NULL` (migration + écritures).

---

## 4. Modifications du modèle de données

- **Schéma v4** : CHECK `node_type IN ('location','item','item_container')` ; valorisation item autorise `value_mode IS NULL` (prix non renseigné).
- **Défaut création item** : quantité 1, **pas** de `FinancialValuation(0)`.
- Distinction prix : `valuation == null` → aucun affichage ; `FinancialValuation(n)` (y compris 0 explicite) → affichage.

---

## 5. Stratégie et résultats de migration

`_migrateToV4` :
1. `container` → `item_container` (qté 1, valorisation nulle).
2. `financial` + `0` cents → unset (évite faux « 0 $ » hérités du défaut).
3. `description = NULL` pour tous.
4. `DELETE` catégories / associations.
5. Reconstruction table `nodes` avec nouveaux CHECK.

**Résultat tests :** migration base réelle v1→courante OK ; contraintes refusent encore `container`.

---

## 6. Compatibilité des sauvegardes

| Cas | Résultat |
|---|---|
| Export nouveau modèle | Listes catégories vides | Testé auto |
| Restore nouveau modèle | OK | Testé auto |
| Legacy `container` dans payload | Normalisé en `item_container` | Testé auto |
| Anciennes catégories dans fichier | Ignorées (vidées) | Testé auto |
| Restore manuelle UI Paramètres | Non rejouée DEV-17 | Non vérifié |

---

## 7. Modifications des fiches

- **Création** : nom, position, quantité/prix (biens) ; actions Créer/Annuler en bas ; `PopScope` si dirty.
- **Édition** : sans description/catégories ; sentimental conservé en modification.
- **Consultation** : plus de blocs catégorie/description.

---

## 8. Modifications de navigation

- `AndroidManifest` : `android:enableOnBackInvokedCallback="true"`.
- Formulaires : `canPop` false si modifications → dialogue abandon.
- Pile Navigator inchangée (pas de geste custom inversé).

---

## 9. Ergonomie bas d’écran

`InventoryThumbBody` : si hauteur > 520 et clavier fermé → contenu aligné bas ; sinon défilement naturel ; padding clavier respecté.

**Observé :** état vide + type picker + fiche création (captures `02`, `03`, `04`, `12`).

---

## 10. Preuves de fonctionnement Android

| Preuve | Moyen | Résultat |
|---|---|---|
| Inventaire vide, CTA bas | Capture `02-empty-inventory.png` | Observé |
| Exactement 3 types, pas Contenant | Capture `03-type-picker.png` + dump UI | Observé |
| Fiche complète immédiate + Position | Captures `04` / `12` | Observé |
| Création Maison persistée | Capture + dump après Créer | Observé |
| Parcours Maison→Bureau→Livre→Cable(25 $)→Armoire | `integration_test` sur `emulator-5554` | Observé (intégration device) |
| Livre sans prix : pas de montant trompeur | Intégration (assert avant prix) | Observé |
| Cable : `25 $` en liste (+ total parent) | Intégration | Observé |
| Fiche sans Catégorie/Description | Intégration | Observé |
| Saisie adb manuel (IME Flutter) | adb keyevents/text | Fragile — contourné par intégration |

Captures : `docs/rapport/captures-dev-17/`.

---

## 11. Tests automatisés complémentaires

- `flutter test` : **51 passed**.
- `flutter analyze lib integration_test` : **No issues**.
- Intégration Android : **1 passed** (`dev17_android_smoke_test.dart`).
- Couverture ajoutée : valorisation unset, `normalizeLegacyNode`, schéma v4, FAB 3 types.

---

## 12. Défauts résiduels

| ID | Gravité | Description |
|---|---|---|
| R1 | P2 | Geste balayage non filmé parcours par parcours (code prêt). |
| R2 | P2 | Restore/export UI non rejoués manuellement en DEV-17. |
| R3 | P3 | Tables catégories encore en schéma (vides) — dette de forme backup. |
| R4 | P3 | Colonne `description` encore en schéma (toujours NULL). |
| R5 | P3 | Création ne propose pas le mode sentimental (édition oui). |

**Aucun P0/P1 connu** après DEV-17.

---

## 13. Risques prochaine release

- Bases/users avec beaucoup de `financial=0` « implicites » verront leurs prix disparaître (voulu).
- Sauvegardes très anciennes : dépendent de `normalizeLegacyNode` à la lecture.
- Publication APK / signature : hors mandat.

---

## 14. Recommandation GO / NO-GO

**GO sous réserves** pour une build debug / validation propriétaire.

**NO-GO publication** tant que : téléphone physique non rejoué, APK signé non produit (sur demande), et réserves R1–R2 acceptées ou levées.

---

## Matrice d’exigence (rappel)

| # | Critère | Implémenté | Auto | Android | Non vérifié |
|---|---|---|---|---|---|
| 1 | 3 types seuls | ✓ | ✓ | ✓ | |
| 2 | Fiche complète immédiate | ✓ | ✓ | ✓ | |
| 3 | Position dans fiche | ✓ | ✓ | ✓ | |
| 4 | Plus catégories/descriptions | ✓ | ✓ | ✓ | |
| 5 | Anciens contenants | ✓ | ✓ | | UI manuelle |
| 6 | Prix remplace ⓘ | ✓ | ✓ | ✓ | |
| 7 | Pas de texte si sans prix | ✓ | ✓ | ✓ | |
| 8 | Tap → fiche | ✓ | ✓ | ✓ | |
| 9 | Balayage retour | ✓ | partiel | | geste filmé |
| 10–12 | Ergonomie bas | ✓ | ✓ | ✓ | tous écrans secondaires |
| 13 | Sauvegardes | ✓ | ✓ | | UI manuelle |
| 14 | Sans seed | ✓ | | ✓ (intégration + captures) | |
| 15 | Pas P0/P1 | ✓ | ✓ | ✓ | |

---

## Arrêt

Aucun APK publié. Aucun commit/push. Mandat suivant non démarré. En attente de décision du propriétaire du produit.
