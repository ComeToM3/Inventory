# Rapport DEV-13.5 — Alignement UX/UI fidèle à la maquette

## Verdict

**VALIDÉ SOUS RÉSERVES** : les six écrans principaux ont été alignés sur la maquette (palette pétrole/menthe, navigation à trois onglets, arbre compact, fiches, formulaire, cartes de création, recherche et historique), observés sur émulateur Android avec captures réelles. Des écarts ergonomiques mineurs subsistent (libellés d’onglets, ouverture d’un bien au tap, filtres Recherche plus riches que la maquette). Aucun invariant métier ni contrat de sauvegarde/restauration n’a été modifié.

## Maquette de référence

- Fichier : [`docs/Maquette d’interface de Inventory.png`](../Maquette%20d’interface%20de%20Inventory.png)
- Six écrans : Inventaire (arbre), consultation d’un bien, modification, création (cartes de type), recherche, historique.
- Palette retenue : pétrole `#0B3D3A`, accent menthe `#76ADA4`, surfaces claires, cartes bordées discrètes.

Aucune autre maquette concurrente n’a été utilisée pour ce mandat.

## Écarts initiaux identifiés

Avant alignement, l’application s’écartait notablement du prototype :

1. **Thème** : Material générique, sans pétrole/menthe ni hiérarchie visuelle de la maquette.
2. **Navigation** : Paramètres traité comme destination principale plutôt que menu supérieur ; onglets peu fidèles.
3. **Inventaire** : arbre peu compact, sélection/valorisation/compteurs/icônes de type insuffisamment marqués.
4. **Consultation / modification** : valorisation, pastilles et actions secondaires peu mises en évidence.
5. **Création** : choix de type sans cartes icône / exemple / chevron.
6. **Recherche / historique** : chrome et cartes/listes éloignés du prototype (filtres DEV-10 déjà présents mais présentation hétérogène).

## Modifications apportées

Couche présentation uniquement (Flutter) ; `InventoryEngine`, Drift/SQLite et contrats backup inchangés.

| Zone | Fichiers | Contenu |
|------|----------|---------|
| Thème / design system | `lib/app/app_theme.dart`, `lib/app/inventory_ui.dart` | `InventoryColors`, `AppTheme.light`, cartes de type, chips filtres, icônes de nœud, pastilles |
| Navigation | `lib/app/main_navigation_screen.dart` | 3 onglets Inventaire / Recherche / Historique ; Paramètres via menu « Plus d’actions » |
| Inventaire | `lib/app/inventory_tree_screen.dart` | indentation, icônes, compteurs, sélection, résumé de valorisation, FAB menthe |
| Consultation | `lib/app/node_details_screen.dart` | en-tête chemin, bandeau valorisation, pastilles, actions Déplacer / Retirer |
| Modification | `lib/app/node_edit_screen.dart` | formulaire libellé, stepper quantité, valorisation exclusive, catégories |
| Création | `lib/app/inventory_creation_screen.dart` | cartes Emplacement / Contenant / Bien simple / Bien-contenant |
| Recherche | `lib/app/inventory_search_screen.dart` | champ haut, chips, compteur, cartes compactes ; filtres DEV-10 conservés (« Autres filtres ») |
| Historique | `lib/app/inventory_history_screen.dart` | liste nom / motif / date / icône / chevron |
| Paramètres | `lib/app/settings_screen.dart` | Scaffold + AppBar pétrole (export / restauration inchangés) |
| Chaînes | `lib/app/app_strings.dart` | libellés UX alignés |

Tests UI adaptés aux nouveaux libellés/sémantique (`test/app/*`). Seed temporaire `DEV135_SEED` utilisé uniquement pour peupler l’émulateur, puis retiré ; APK debug réinstallé sans seed, données d’app effacées.

## Comparaison des six écrans (référence → résultat)

| Écran | Fidélité constatée | Commentaire |
|-------|--------------------|-------------|
| **A. Inventaire** | Élevée | Arbre indenté, icônes par type, compteurs `(n)`, chevrons, sélection grise, résumé `1 × 120,00 $ CAD`, FAB menthe, AppBar pétrole + 3 onglets. |
| **B. Consultation** | Élevée | Titre « Bien », chemin, bandeau valorisation menthe, propriétés, pastilles catégories, Déplacer / Retirer. |
| **C. Modification** | Élevée | Nom, type non éditable métier, stepper quantité, radios financière/sentimentale, montant, catégories, description ; validation via icône Enregistrer. |
| **D. Création** | Élevée | Quatre cartes icône + titre + exemple + chevron ; contexte « Dans : Bureau » conservé. |
| **E. Recherche** | Bonne | Champ, chips (Tous/Biens/Contenants/Emplacements), « Autres filtres », « 1 résultat », carte chemin. Maquette montre aussi « Catégories » en chip ; l’app conserve les filtres avancés DEV-10. |
| **F. Historique** | Bonne | Ligne Clavier USB / Vente · date / icône / chevron. Maquette sans barre d’onglets (écrans poussés) ; l’app garde les 3 onglets + accès Recherche en AppBar. |

## Captures réelles Android

Émulateur **Inventory_Moto_G24_API34** (Android 14), APK debug, seed représentatif (Appartement → Bureau → Boîte électronique → Bloc d’alimentation EVGA ; Salon ; Clavier USB retiré).

Emplacement : [`docs/rapport/captures-dev-13-5/`](captures-dev-13-5/)

| Fichier | Écran |
|---------|--------|
| `01-inventaire.png` | Arbre expansé avec EVGA sélectionné et valorisation |
| `02-consultation.png` | Fiche du bien EVGA |
| `03-modification.png` | Formulaire « Modifier le bien » |
| `04-creation.png` | Cartes de choix de type (depuis Bureau) |
| `05-recherche.png` | Recherche « EVGA », 1 résultat |
| `06-historique.png` | Liste des retraits (Clavier USB) |
| `07-parametres.png` | Paramètres (sauvegarde / restauration) — hors maquette, harmonisé |

## Vérifications fonctionnelles

Parcours observé sur l’émulateur avec données seed :

- Arbre : expansion progressive, compteurs, FAB / « Ajouter dans… », ouverture de fiche.
- Consultation → modification (champs, valorisation, catégories) → retour.
- Création : affichage des quatre cartes selon le parent (Bureau).
- Recherche : saisie EVGA, compteur et carte ; chips de type.
- Historique : entrée consultable (retrait Vente).
- Paramètres accessibles via le menu supérieur (export / restauration présents).

Automatisé : `flutter analyze lib/app` sans issue ; `flutter test test/app` — 19 tests OK.

Aucun changement de schéma, d’`InventoryEngine`, ni des contrats `.invbackup` / restauration DEV-12–13.

## Réserves et différences restantes

1. **Onglets** : maquette avec pastilles libellées ; app avec icônes + indicateur pétrole/menthe (Paramètres hors barre, comme demandé).
2. **Tap sur un bien** : ouvre la fiche (comportement existant) ; la sélection visuelle reste visible au retour. La maquette montre une sélection sans navigation immédiate.
3. **Recherche** : chips « Emplacements » + panneau « Autres filtres » (DEV-10) au lieu d’un chip « Catégories » seul ; résultat sans pastille $ dans la carte (valorisation visible en fiche / arbre).
4. **Historique** : reste dans la coque à 3 onglets ; maquette en écran poussé « retour ».
5. **Check Enregistrer** : contraste parfois faible sur AppBar pétrole (état désactivé Material).
6. **Pas d’appareil physique** ; validation limitée à l’AVD Moto G24 API 34.

Ces écarts sont perceptibles mais n’annulent pas l’alignement structurel et chromatique principal.

## Risques pour DEV-14

Aucun risque bloquant identifié pour DEV-14 : pas de dette métier introduite, pas de schéma touché, sauvegarde/restauration toujours accessibles. Point d’attention UX seulement : documenter ou ajuster plus tard le geste « sélection vs ouverture » de l’arbre si le produit exige une sélection sans navigation.

---

**Arrêt** : mandat DEV-13.5 terminé (validation UX/UI + rapport). Pas de DEV-14, pas de commit/push.
