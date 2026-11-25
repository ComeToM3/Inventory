# UX-01 — Simplification navigation et formulaires

**Verdict : VALIDÉ SOUS RÉSERVES**

Date : 2026-11-18  
Émulateur : `Pixel_7a` / `emulator-5554` (Android 14)  
Aucun commit ni push. Application laissée installée (debug) sur l’émulateur.

---

## 1. Verdict

Navigation inférieure visible pendant création/modification, conservation des formulaires par espace, Retour par étapes, entrée **Bien** unifiée avec interrupteur contenant, valorisation financière **0 $** par défaut, crayon aligné sous le `+`, clavier plus stable.

Réserve P2 : validation tactile au doigt non effectuée (ADB uniquement). Aucun P0/P1.

---

## 2. Modifications effectuées

| Exigence | Changement |
|----------|------------|
| Nav inférieure permanente | Navigateurs imbriqués par espace dans `IndexedStack` ; création/édition hors `rootNavigator` |
| Conservation formulaires | Pile locale par espace conservée au changement d’onglet |
| Retour arrière | Formulaire → sélecteur de type → arbre ; PopScope création sans abandon forcé |
| Bien / Contenant | Biens : Emplacement + **Bien** ; interrupteur **Est un contenant** |
| Valorisation défaut | Mode `$` + `0` à la création Biens ; vide → 0 $ |
| Crayon | Icône Modifier dans la colonne d’action, sous le `+` |
| Clavier | Nom remonté ; alignement haut si IME ouvert ; footer docké |

Schéma SQLite **v9** inchangé.

---

## 3. Composants réutilisés

- `InventoryCreationScreen`, `InventoryParentField`, `InventoryValuationField`, `InventoryThumbBody`
- `InventoryTreeScreen` / inline sheet
- `NavigationBar` unique de `MainNavigationScreen`
- Types internes `item` / `itemContainer` / `location`

---

## 4. Conservation des formulaires

- Un `Navigator` par espace ; `IndexedStack` conserve piles et états.
- Changement Biens ↔ Stock ↔ À acheter sans perdre la saisie.
- Pas de brouillon SQLite ; Annuler peut abandonner (dialog).

**Implémenté. Observé** (ADB) : « Lampe » conservé après aller-retour Stock.

---

## 5. Navigation inférieure

- Barre Biens / Stock / À acheter visible sur arbre, sélecteur de type et formulaire.
- Recherche / historique / réglages restent en `rootNavigator` (plein écran accepté hors mandat création).

**Observé** : barre présente sur picker et formulaire Biens, Stock, À acheter.

---

## 6. Retour arrière

- Création : Retour système / AppBar quitte le formulaire vers le picker (sans dialog).
- Second Retour : quitte le picker vers l’arbre.
- Modification : dialog d’abandon si changements.
- Annuler : conserve la confirmation d’abandon.

**Observé** (ADB) : formulaire → Ajouter (picker) → arbre Maison.

---

## 7. Formulaire Bien / Contenant

- Biens : plus d’entrée séparée Bien-contenant.
- Interrupteur **Est un contenant** → `item` / `itemContainer`.
- Stock / À acheter : trois choix inchangés (libellés contextualisés).

**Observé** : Lampe = Bien simple 0 $ ; Boite = Bien-contenant 0 $.

---

## 8. Valorisation par défaut

- Création bien Biens : mode financier + `0`.
- Champ vide en mode `$` → enregistre 0 $.
- Autres modes inchangés ; biens existants non migrés.

**Observé** : ligne `Lampe` affichée `0 $`.

---

## 9. Comportement du clavier

- `resizeToAvoidBottomInset: true`
- Nom placé après la position
- `InventoryThumbBody` : alignement haut si IME ouvert, bas sinon ; footer hors scroll

**Implémenté. Observé** partiellement (saisie ADB + fermeture IME). Essai doigt : non vérifié.

---

## 10. Alignement crayon / +

- Détails : résumé à gauche ; **Modifier** dans la colonne largeur `_actionColumnWidth`, même axe que `+` / niveau Stock.

**Observé** : `Modifier` à x≈996 sous `Ajouter dans Boite`.

---

## 11. Tests automatisés

| Commande | Résultat |
|----------|----------|
| `flutter analyze` | 1 info préexistante |
| `flutter test` | **82** passed |

Tests UI ajustés : `main_navigation_creation_test`, `dev32_conversion_test`.

---

## 12. Parcours observés (émulateur — simulation ADB)

| # | Scénario | Résultat |
|---|----------|----------|
| 1 | Nom + onglet Stock + retour | Formulaire Lampe conservé |
| 2 | Deux espaces | Piles indépendantes (IndexedStack) |
| 3 | Barre pendant création | Visible |
| 4 | Retour formulaire → picker → arbre | OK |
| 5 | Créer bien simple | Lampe, 0 $ |
| 6 | Contenant via interrupteur | Boite |
| 7 | Valorisation 0 $ | Affichée |
| 8 | Clavier | Saisie + dismiss ; pas de test doigt |
| 9 | Crayon sous + | Aligné |
| 10 | Stock / À acheter | Pickers opérationnels + barre |

Captures : `docs/rapport-v2/_ux01_shots/`.

---

## 13. Non-régression

Organiser, Stock 1/½/¼/0, acquisitions, historiques, recherche, schéma v9 : non régressés par les tests ; parcours Stock/À acheter smoke OK sur émulateur.

---

## 14. Réserves

| Id | Sévérité | Description |
|----|----------|-------------|
| — | P0/P1 | Aucun |
| R1 | P2 | Pas d’essai manuel au doigt |
| R2 | P2 | Retour formulaire → picker ne restaure pas les champs si on rouvre un nouveau formulaire (contexte parent/type oui ; pile onglet oui) |

---

## 15. Non développé (volontaire)

- Phase 4, sync, photos
- Brouillons persistants SQLite
- Refonte générale
- Commit / push / Motorola

**STOP UX-01.**
