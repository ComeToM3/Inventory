# Rapport DEV-16 — Audit fonctionnel intégral et remise en état

## 1. Verdict

**VALIDÉ SOUS RÉSERVES**

Les parcours essentiels V1 (création depuis base vide, hiérarchie, modification/totaux, recherche, déplacement, retrait/historique, export/restauration, persistance) ont été **observés sur émulateur Android** avec le code source courant, **sans seed**. Des défauts réels de raccordement UX et de robustesse ont été corrigés.

**Réserves :**
- Moto G24 Power **non connecté** pendant DEV-16 → pas de revalidation physique release.
- Aucun nouvel APK **signé production** produit (volontaire).
- Quelques cas V1 restent **NON VÉRIFIÉS** sur appareil (bien-contenant de bout en bout, mode sentimental complet, suppression définitive, opérations interdites).
- Sauvegarde chiffrée indépendante du keystore toujours **non prouvée** (héritage DEV-15).

## 2. Résumé exécutif

Les rapports DEV-13→15 et les tests automatisés avaient créé une confiance excessive : ils valident surtout le moteur et des écrans isolés, souvent avec seed / base mémoire, rarement le câblage `MainNavigationScreen` → création.

**Constat sur le code + émulateur :** la création racine et imbriquée via bouton vide / ⊕ **fonctionne**. En revanche, le FAB « Emplacement » **créait toujours une racine** au lieu d’un emplacement imbriqué — comportement incorrect pour un inventaire déjà peuplé, facilement interprété comme « la création d’emplacements ne marche pas ».

Autres causes racines traitées : mapping d’erreurs SQLite via isolate Drift, formulaire bloqué sur « Création… » si `Error`, démarrage « unreliable » sans réessai, arbre blanc si `roots == null`.

**Maturité réelle :** utilisable de bout en bout sur le binaire debug reconstruit ; **pas encore** une nouvelle version distribuable signée validée sur téléphone.

## 3–4. Inventaire / matrice des fonctionnalités V1

Légende : **OPÉRATIONNELLE** = observée app réelle | **DÉFAILLANTE** corrigée si noté | **INCOMPLÈTE** | **ABSENTE** | **NON VÉRIFIÉE**

| Fonctionnalité | Entrée UI | Implémentation | Statique | Test réel | Gravité résiduelle | Statut |
|---|---|---|---|---|---|---|
| Premier lancement base vide | `InventoryApp` → empty state | DB `inventory` + inventaire défaut | OK | OK ému | — | **OPÉRATIONNELLE** |
| Création emplacement racine | Bouton vide / menu ⋮ | `MainNavigation._addRoot` → `createNode` | OK | OK ému | — | **OPÉRATIONNELLE** |
| Création emplacement imbriqué (⊕) | ⊕ parent | `_addChild` | OK | OK ému | — | **OPÉRATIONNELLE** |
| Création emplacement via FAB | FAB → type Emplacement | était `_openCreation(parent:null)` | **Bug** | Repro + fix | — | **OPÉRATIONNELLE** (après correctif) |
| Contenant / bien simple | ⊕ ou FAB+parent | `InventoryCreationScreen` | OK | OK ému | — | **OPÉRATIONNELLE** |
| Bien-contenant | idem | code présent | OK | non rejoué DEV-16 | — | **NON VÉRIFIÉE** |
| Expansion / compteurs `(n)` | arbre | enfants **chargés** seulement | OK | observé | P3 sémantique | **OPÉRATIONNELLE** (avec réserve P3) |
| Consultation / modification | fiche → Modifier | `NodeEditScreen` | OK | OK ému | — | **OPÉRATIONNELLE** |
| Quantité / valeur financière | stepper + montant | moteur + UI | OK | OK (2×25→50) | — | **OPÉRATIONNELLE** |
| Catégories | édition | create/associate | OK | OK « Eclairage » | — | **OPÉRATIONNELLE** |
| Valorisation sentimentale | radio Sentimental | code présent | OK | non rejoué | — | **NON VÉRIFIÉE** |
| Totaux branche | labels arbre | `getSubtreeFinancialTotals` | OK | OK | course cache P3 | **OPÉRATIONNELLE** |
| Recherche + badge | onglet Recherche | search controller | OK | OK chemin complet | — | **OPÉRATIONNELLE** |
| Déplacement | Déplacer | move screen | OK | OK → Salon | — | **OPÉRATIONNELLE** |
| Retrait + historique | Retirer… | withdraw + history | OK | OK Vente | — | **OPÉRATIONNELLE** |
| Suppression définitive | historique | code présent | OK | non rejoué | — | **NON VÉRIFIÉE** |
| Export `.invbackup` | Paramètres | SAF + verify | OK | Export vérifié | — | **OPÉRATIONNELLE** |
| Restauration valide | Paramètres | replace + refresh | OK | EtatB retiré | — | **OPÉRATIONNELLE** |
| Rejet restauration invalide | fichier corrompu | validation | OK | OK en DEV-15 ; non rejoué ici | — | **NON VÉRIFIÉE** (cette session) |
| Persistance cold start | force-stop | SQLite fichier | OK | OK | — | **OPÉRATIONNELLE** |
| Boot « unreliable » | recovery screen | `RestorationRecovery` | **sans réessai** | fix ajouté | — | **OPÉRATIONNELLE** (après correctif, non crash-testé) |

## 5. Causes racines

1. **FAB Emplacement = toujours racine** (`main_navigation_screen.dart`, `_quickAdd`) — UX trompeuse dès qu’un inventaire existe.
2. **Couverture de tests UI insuffisante** — `InventoryCreationScreen` testé hors `MainNavigationScreen` ; FAB / empty / ⊕ non couverts → défaut FAB invisible aux CI.
3. **Validations précédentes biaisées** — seeds DEV-11/14, bases isolées, émulateur/téléphone avec parcours assistés ; succès ≠ preuve du câblage quotidien.
4. **`DriftRemoteException`** non mappé dans `_run` — erreurs SQLite production (isolate) mal classées.
5. **Attrape `Exception` seulement** — `Error` laisse création/chargement dans un état muet.
6. **Recovery unreliable sans sortie** — blocage permanent des écritures sans bouton Réessayer.
7. **`roots == null` + pas de chargement** — ListView vide sans message (fenêtre après restore/race).

## 6. Pourquoi les tests précédents n’ont pas détecté l’échec perçu

- Les tests créent via `controller.createNode` / écran de création **injecté**, pas via FAB.
- Bases `NativeDatabase.memory()` : pas d’isolate Drift, pas de `DriftRemoteException`.
- Seeds et inventaires préremplis masquent le parcours « premier emplacement ».
- Les rapports VALIDÉ comptaient des observations ponctuelles, pas un audit de tous les points d’entrée « Ajouter ».

## 7. Corrections (fichiers)

| Correctif | Fichiers |
|---|---|
| FAB Emplacement → choix du parent (racines additionnelles = vide/⋮) | `lib/app/main_navigation_screen.dart` |
| Garde anti double ouverture création | idem |
| Mapping `DriftRemoteException` → codes métier | `lib/core/domain/inventory_engine.dart` |
| Catch large sur save création | `lib/app/inventory_creation_screen.dart` |
| Catch large load roots/enfants | `lib/app/inventory_tree_controller.dart` |
| Réessayer sur recovery unreliable | `lib/app/inventory_app.dart` |
| Auto-rechargement si `roots == null` | `lib/app/inventory_tree_screen.dart` |
| Tests ciblés FAB + self-heal arbre | `test/app/main_navigation_creation_test.dart` |

## 8. Preuves d’exécution réelle

- **Plateforme :** émulateur `Inventory_Moto_G24_API34` / `sdk_gphone64_x86_64` (Android 14). Téléphone physique **absent**.
- **Sans seed**, créations UI uniquement.
- Captures : `docs/rapport/captures-dev-16/` (empty → Maison → Bureau → Armoire → Lampe → totaux → catégories → recherche → Salon → move → withdraw → export → EtatB → restore → cold → FAB parent → Bureau via FAB).
- Export : `inventory-20261114-213150.invbackup` + message « Export vérifié ».
- Restauration : message « Restauration effectuée » ; `EtatB` absent après ; historique Lampe/Vente conservé.

## 9. Régression

- `flutter analyze` (fichiers touchés) : OK
- `flutter test test/app/main_navigation_creation_test.dart` : OK
- `flutter test test/app/inventory_creation_test.dart` : OK (avec la suite précédente)

## 10. Défauts restants

| ID | Sévérité | Description |
|----|----------|-------------|
| R1 | P2 | Compteurs `(n)` = enfants chargés, pas descendants totaux (déjà connu) |
| R2 | P3 | Course possible totaux financiers vs invalidation |
| R3 | P3 | Double tap théorique sur autres routes |
| R4 | P2 ops | Keystore : sauvegarde chiffrée indépendante non prouvée |
| R5 | P2 | Bien-contenant / sentimental / delete permanent non rejoués DEV-16 |
| R6 | P1 dist | Correctifs **non** livrés en APK release signé sur téléphone |

## 11. Risques données / distribution

- Clé production et `applicationId` **inchangés**.
- Aucune désinstallation téléphone, aucun `pm clear` appareil utilisateur, aucune publication.
- Install émulateur a réinstallé le **debug** (données ému perdues à chaque `uninstall` Flutter — acceptable hors prod).
- Prochaine livraison : **versionCode / versionName supérieur**, rebuild release signé, validation Moto G24 — **hors autorisation DEV-16**.

## 12. Décision distribution

**NO-GO** pour une **nouvelle** version distribuable tant que :
1. les correctifs ne sont pas emballés en APK release signé (version incrémentée),
2. le parcours n’est pas revalidé sur Moto G24 Power,
3. les items NON VÉRIFIÉS critiques pour votre usage ne sont pas bouclés si requis.

**GO** pour poursuivre le développement local / préparer un mandat de rebuild release (ex. DEV-17).

---

### Séparation des preuves

| Niveau | Exemple |
|---|---|
| Code inspecté | Chaînes création, boot, `_run`, FAB |
| Fonctionnalité implémentée | Moteur `createNode`, écrans, backup |
| Test auto réussi | `main_navigation_creation_test`, creation_test |
| Fonctionnement observé | Captures ému DEV-16 |
| Fonctionnalité réellement validée | Matrice ci-dessus (OPÉRATIONNELLE) |

**Arrêt DEV-16.** En attente de décision utilisateur (pas de commit, pas de publication, pas de nouveau mandat automatique).
