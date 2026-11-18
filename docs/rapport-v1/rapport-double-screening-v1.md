# Rapport — Double screening qualité produit Inventory V1

**Mandat :** audit UI/UX de finition uniquement (Screening A + contre-expertise B).  
**Hors périmètre :** existence des fonctions métier, architecture, correctifs.  
**Version inspectée :** `1.0.11+12` (debug sur `emulator-5554`, 720×1612).  
**Preuves visuelles :** `docs/rapport/_screening_shots/` (`01` … `11`).  
**Gouvernance :** lecture / observation seulement — aucun correctif, commit, push, ni install Moto.

---

# Partie I — Screening A

## 1. Méthode et couverture réelle

1. Inventaire des surfaces via `lib/app/*.dart` (écrans, champs, dialogues, menus, barres).
2. Exécution réelle sur émulateur (`flutter run -d emulator-5554`).
3. Captures + hiérarchie UI Automator pour ancrage / bornes / sémantique.
4. Création contrôlée d’un bien `cable_usb` (minuscules) pour vérifier persistance et affichage.
5. Contre-lecture code pour causes (`InventoryParentField`, `_normalizeName`, `InventoryThumbBody`, arbre, snackbars).

**Non observés visuellement dans ce mandat :** fiche retrait (`WithdrawnNodeDetails`), historique peuplé, dialogues de confirmation backup/retrait/suppression, DnD long-press, orientation paysage, police système XXL, appareil physique.

## 2. Matrice des écrans et composants

| Surface | Composants clés | Observé ? | Notes qualité |
|---|---|---|---|
| Arbre inventaire | Lignes, chevrons, `+`, totaux, FAB, AppBar | Oui (`01`, `07`) | Alignement bas volontaire ; double prix sur biens valorisés |
| Menu overflow | `PopupMenuButton` Ajouter / Historique / Paramètres | Oui (`10`) | Correct ; « Ajouter » redondant avec FAB |
| Sélecteur de type | `InventoryTypeChoiceCard` + thumb body | Oui (`02`) | Cartes bas ; espace haut vide |
| Création / édition | Parent, quantité, valorisation, nom, barre d’actions | Oui (`03`–`05`) | Nom en bas (IME) ; parent problématique |
| Menu parent | `DropdownButtonFormField` + chemins `→` | Oui (`04`) | Décalage / recouvrement label / plat |
| Recherche | Champ, chips, ExpansionTile, cartes résultat | Oui (`08`–`09`) | Chip « Emplacements » tronqué ; chemin redondant |
| Paramètres | Textes backup + 2 boutons filled | Oui (`11`) | Thumb bas ; pas de version / À propos |
| Historique | `ListTile` | Non peuplé ici | Structure lue en code |
| Inline sheet | Résumé + crayon | Partiel (code + sémantique) | Compact |
| Dialogues | Discard / delete / withdraw / backup | Code seul | Material standard |
| SnackBar haut | `showInventoryMessage` | Oui (`06`) | Ancrage haut ; zone sémantique large |
| Système Android | Status / gesture bar | Oui | Cohérent |

## 3. Défauts visuels

### UI-001 — Sélecteur d’emplacement peu soigné
- **Écran :** Nouveau bien / édition — `InventoryParentField`.
- **Observé :** menu ouvert recouvre le libellé « Position » ; largeur limitée au champ (le `+` reste dehors) ; liste plate `Ess26 → Boite` sans retrait de profondeur (`04`).
- **Attendu :** menu ancré proprement, hiérarchie lisible, alignement avec le champ.
- **Cause :** `DropdownButtonFormField` + items `Text(pathLabel)` plats (`inventory_parent_field.dart`) ; layout thumb bas pousse le menu vers le haut.
- **Gravité :** P1 qualité · Effort **S–M** · Preuve **démontrée**.

### UI-002 — Double affichage financier sur une ligne d’arbre
- **Écran :** Arbre — bien `Wer`.
- **Observé :** sous-titre `1 × 20,00 $ CAD` **et** trailing `20 $` (`07`).
- **Attendu :** une seule expression de valeur sur la ligne.
- **Cause :** `inventoryCompactValuation` ≠ `inventoryListPrice` → la garde `subtitle != price` laisse les deux (`inventory_tree_screen.dart` ~639–683).
- **Gravité :** P2 · Effort **XS** · Preuve **démontrée**.

### UI-003 — Chip « Emplacements » visuellement coupé
- **Écran :** Recherche.
- **Observé :** dernier chip tronqué (`Emp…` / bounds coupés à droite) (`09`).
- **Attendu :** scroll horizontal clair ou chip entièrement lisible.
- **Cause :** `SingleChildScrollView` horizontal sans padding de fin assez marqué / 4 chips denses sur 720 px.
- **Gravité :** P3 · Effort **XS** · Preuve **démontrée**.

### UI-004 — Chemin de recherche redondant
- **Écran :** Carte résultat.
- **Observé :** titre `cable_usb` + chemin `Ess26 → Boite → cable_usb` (`09`).
- **Attendu :** chemin = ancêtres uniquement (`Ess26 → Boite`).
- **Cause :** CTE `paths` initialise `full_path` avec `m.name` (`inventory_engine.dart` ~244–250).
- **Gravité :** P3 · Effort **XS** · Preuve **démontrée**.

## 4. Défauts d’interaction

### UI-005 — SnackBar « haut » à zone sémantique excessive
- **Écran :** Retour après création.
- **Observé :** message « Élément ajouté. » ; nœud sémantique borné quasi plein écran (`06`, dump UI).
- **Attendu :** bandeau compact sous l’AppBar, sans monopoliser l’accessibilité / hit-test.
- **Cause :** `bottomMargin ≈ hauteur − topGap − 56` dans `inventory_messages.dart`.
- **Gravité :** P2 · Effort **XS** · Preuve **démontrée** (bornes) / impact tactile **probable**.

### UI-006 — Stepper quantité sans labels accessibles
- **Écran :** Création bien.
- **Observé :** boutons `−` / `+` avec `content-desc` vide (dump UI).
- **Attendu :** labels « Diminuer / Augmenter la quantité ».
- **Cause :** `IconButton` sans `tooltip` dans `_StepButton` (`inventory_ui.dart`).
- **Gravité :** P3 · Effort **XS** · Preuve **démontrée** (a11y).

## 5. Défauts de saisie et de présentation

### UI-007 — Noms sans capitalisation initiale persistée
- **Écran :** Création → arbre → recherche.
- **Observé :** saisie `cable_usb` enregistrée et affichée telle quelle (`05`, `07`, `09`).
- **Attendu (propriétaire) :** cohérence visuelle type « phrase » / initiale majuscule.
- **Cause :** `_normalizeName` = `trim` seul ; UI a `TextCapitalization.sentences` (suggestion clavier, non forcée) ; restauration / import conservent le littéral.
- **Analyse :**
  - Normalisation **nécessaire** : trim + refus vide (déjà fait).
  - Capitale initiale : **préférence de présentation**, pas règle métier.
  - Mutation auto (1ʳᵉ lettre) **peut altérer** iPhone, eBay, macOS, codes (`cable_usb`), acronymes.
- **Recommandation A :** ne pas muter en base pendant V1 ; garder `TextCapitalization.sentences`.
- **Si correction désirée :** capitaliser **uniquement** à la validation UI le premier caractère *lettre minuscule* **latine**, sans Title Case global, sans toucher les noms déjà majuscules / non-lettres ; documenter l’exception marques. Préférer **saisie**, pas affichage fantôme.
- **Gravité :** P3 (préférence) · Effort **S** si soft-cap · Preuve **démontrée**.

### UI-008 — Formats CAD hétérogènes (liste vs compact)
- **Observé :** trailing `20 $` vs compact `20,00 $ CAD` sur la même fiche (`07`).
- **Attendu :** famille de formats cohérente (ou un seul emplacement d’affichage — lié à UI-002).
- **Cause :** `listPrice` vs `cad` / `compactFinancial` (`app_strings.dart`).
- **Gravité :** P3 (avec UI-002) · Effort **XS–S** · Preuve **démontrée**.

## 6. Cas limites et accessibilité

| Cas | Résultat |
|---|---|
| Peu de nœuds / thumb bas | Grand vide haut — **volontaire** (`Align.bottomCenter`) |
| Hiérarchie 3 niveaux | Indentation 14 px lisible (`07`) |
| Menu parent près du bas | Ouvre vers le haut, recouvre le label (UI-001) |
| Nom long / underscore | Affiché sans ellipse sur ligne courte ; OK ici |
| Clavier ouvert (création / recherche) | Formulaire se compacte ; recherche reste utilisable |
| Police XXL / paysage / liste très longue | Non testés |
| TalkBack | Non session complète ; indices via content-desc (UI-005, UI-006) |

## 7. Preuves disponibles et limites

- Captures `01`–`11` + dumps UI Automator sur émulateur.
- Causes citées avec fichiers sources.
- **Limite :** qualité visuelle non validée sur Moto G24 ; certains dialogues / historique / DnD non rejoués ici.
- **Donnée de test :** bien `cable_usb` créé sur l’émulateur pour l’observation (non nettoyé — audit).

---

# Partie II — Screening B

## 8. Critique du screening A

Le screening A a correctement ciblé le sélecteur parent et la casse, mais a tendance à **sur-interpréter le vide haut** (arbre, type picker, paramètres, formulaires) comme un défaut d’alignement. Ce motif est **intentionnel** (`InventoryThumbBody`, arbre `Alignment.bottomCenter`) pour la zone pouce — le contester comme « inachevé » serait une erreur de produit.

Il a aussi sous-estimé le **double prix** (immédiatement visible) et le **snackbar** (impact a11y / confiance), tout en risquant de **sur-corriger** la casse des noms.

## 9. Défauts confirmés

| ID | Verdict B | Commentaire |
|---|---|---|
| UI-001 | **Confirmé P1** | Perceptible immédiatement ; interaction centrale création/édition |
| UI-002 | **Confirmé P2** | Visible sur biens valorisés ; confiance / finition |
| UI-005 | **Confirmé P2** | Preuve bornes ; risque de gêne temporaire |
| UI-003 | Confirmé P3 | Scroll existe ; gênant mais mineur |
| UI-004 | Confirmé P3 | Redondance lisible, pas bloquante |
| UI-006 | Confirmé P3 | TalkBack |
| UI-007 | Confirmé comme **préférence** | Ne pas forcer mutation V1 |
| UI-008 | Fusionné avec UI-002 | Traiter via unicité d’affichage |

## 10. Défauts rejetés ou reclassés

| Hypothèse A | Décision B |
|---|---|
| « Liste collée en bas = bug » | **Rejeté** — design thumb validé |
| « Nom en bas du formulaire = erreur » | **Rejeté** — IME / pouce |
| « Remplacer le dropdown par un autre paradigme » | **Rejeté** — corriger config / items / ancrage du composant actuel |
| « Capitaliser automatiquement tous les noms » | **Rejeté** — risque de corruption de données volontaires |
| « Harmoniser Title Case partout » | **Rejeté** — hors sujet (pas Title Case) |
| Icône Flutter / pas de version UI | **Hors screening composants** mais rappel : déjà dans `rapport-app-completeness-v1.md` (périphérie) |

## 11. Défauts supplémentaires découverts

- **UI-002 / UI-008** : incohérence formats monétaires sur la même ligne (A a noté UI-002 ; B insiste sur le lien format).
- **UI-004** : chemin recherche inclut le nœud courant (manqué comme priorité par A).
- **UI-009 (P3)** : menu ⋮ « Ajouter » redondant avec FAB — préférence, ne pas corriger V1.
- **UI-010 (P3)** : Paramètres — deux `FilledButton` de même poids (Sauvegarder / Restaurer) ; Restaurer gagnerait un style outlined — esthétique, V2 acceptable.

## 12. Risques de régression des corrections

| Correctif | Risque |
|---|---|
| Indentation / `selectedItemBuilder` / `menuMaxHeight` sur dropdown actuel | **Faible** si on ne change pas le modèle `parent_id` |
| Remplacer par bottom sheet / écran dédié | **Moyen–élevé** (parcours déjà validés) |
| Soft-capitalize à la persistance | **Moyen** (marques, imports, backups existants) |
| Dedup prix ligne arbre | **Faible** |
| Recalcul margin SnackBar | **Faible** (vérifier position sous AppBar + FAB) |
| Changer CTE path recherche | **Faible** si tests manuels recherche OK |

---

# Partie III — Décision produit

## 13–14. Liste consolidée et classement

| ID | Écran / composant | Défaut | Preuve | Gravité | Effort | Risque | Décision |
|---|---|---|---|---|---|---|---|
| UI-001 | Parent `DropdownButtonFormField` | Menu décalé, plat, recouvre « Position » | `04` + code | P1 | S–M | Faible* | **V1** |
| UI-002 | Ligne arbre bien valorisé | Double prix (compact + trailing) | `07` | P2 | XS | Faible | **V1** |
| UI-005 | SnackBar haut | Zone sémantique / marge extrême | `06` + dump | P2 | XS | Faible | **V1** |
| UI-003 | Chips recherche | « Emplacements » tronqué | `09` | P3 | XS | Faible | V2 / optionnel |
| UI-004 | Carte résultat | Chemin répète le nom | `09` + SQL | P3 | XS | Faible | V2 / optionnel |
| UI-006 | Stepper quantité | Pas de tooltip / semantics | dump UI | P3 | XS | Faible | V2 |
| UI-007 | Noms | Minuscule initiale persistée | `05`/`07`/`09` | P3 préf. | S | Moyen si auto | **Ne pas muter** ; clavier OK |
| UI-008 | Formats CAD | `20 $` vs `20,00 $ CAD` | `07` | P3 | XS | Faible | Traité avec UI-002 |
| UI-009 | Menu ⋮ | « Ajouter » redondant FAB | `10` | P3 | XS | Faible | Ne pas corriger |
| UI-010 | Paramètres | 2 filled égaux | `11` | P3 | XS | Faible | V2 |

\*Risque faible **si** correction locale du dropdown ; élevé si refonte du parcours parent.

**Légende preuve :** UI-001/002/003/004/005/006/007 = **démontrés** · impact tactile UI-005 = **probable** · UI-009/010 = **préférence esthétique**.

**Aucun P0** (pas de perte de données / action dangereuse liée à la finition UI dans ce screening).

## 15. Top corrections à fort impact / faible effort

1. **UI-001** — Soigner le sélecteur parent *sans* changer de composant de famille : indentation par profondeur, libellé fermé court (`selectedItemBuilder`), `isExpanded`, hauteur menu, alignement vertical du `+`.
2. **UI-002 (+ UI-008)** — Une seule valeur financière sur la ligne arbre (trailing **ou** sous-titre, pas les deux).
3. **UI-005** — Marges SnackBar réalistes (hauteur réelle du snack, pas quasi plein écran).

## 16. Reporter à V2

- UI-003, UI-004, UI-006, UI-010.
- Soft-capitalize optionnel **uniquement** si le propriétaire l’exige après arbitrage marques.
- Finition périphérique déjà listée (icône, splash, À propos/version) — hors ce double screening mais toujours pertinente pour distribution.

## 17. Ne pas corriger

- Inverser l’alignement pouce (arbre / formulaires / paramètres).
- Remplacer le dropdown parent par un flux navigationnel nouveau « parce que plus moderne ».
- Title Case / capitalisation forcée de tous les mots.
- Mutation irréversible des noms à l’import / restore.
- Retirer « Ajouter » du menu ⋮ sans besoin clairement exprimé.

## 18. Recommandation finale de clôture V1

**VALIDÉ SOUS RÉSERVES — Corrections ciblées recommandées avant clôture.**

Le cœur métier et le design system pétrole/menthe tiennent. La finition professionnelle bute surtout sur le **sélecteur d’emplacement** (parcours quotidien) et deux micro-défauts très visibles (double prix, snackbar). Après UI-001 / UI-002 / UI-005, la finition *composants* peut s’arrêter ; la distribution publique reste conditionnée aux points périphériques de l’audit de complétude (icône, version).

---

## Verdict

**VALIDÉ SOUS RÉSERVES — Corrections ciblées recommandées avant clôture.**

### Réponses au propriétaire

1. **Immédiatement visibles :** sélecteur parent « décalé » / plat ; double affichage `1 × 20,00 $ CAD` + `20 $` ; noms en minuscules si saisis ainsi ; grand vide haut (souvent *voulu*).
2. **Échappés aux audits précédents :** qualité concrète du dropdown parent ; dedup prix ligne ; zone SnackBar ; redondance chemin recherche ; truncature chip.
3. **Meilleur ROI :** UI-001 (local), UI-002 (XS), UI-005 (XS).
4. **Rejetées :** refonte dropdown ; inversion thumb layout ; capitalisation auto obligatoire ; Title Case.
5. **Nécessaires avant livraison qualité V1 :** **3** (UI-001, UI-002, UI-005). Le reste est facultatif.
6. **Arrêter la finition composants après ces 3 ?** **Oui.** (La finition *périphérique* icône/À propos reste un arbitrage distribution séparé.)

---

**ARRÊT OBLIGATOIRE.** Aucune correction engagée. Attendre la décision explicite du propriétaire.
