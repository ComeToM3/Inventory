# UX-03 — Consolidation ergonomie (arborescence, indicateurs, navigation, organisation)

**Verdict : VALIDÉ SOUS RÉSERVES**

Date : 2026-11-21  
Émulateur : `Pixel_7a` / `emulator-5554`  
Aucun commit ni push. Aucune installation Motorola. Aucun nouveau test automatisé.

---

## 1. Modifications réalisées

| Zone | Changement |
|------|------------|
| Expansion | Expansion initiale unique de tous les emplacements et contenants |
| Cercles | Diamètre visible ramené à **28 dp** (touch 40 dp), partagé `+` / Stock / cœur |
| Sentimental | Cœur à remplissage bas→haut (1–5) en Zone B |
| Onglet actif | Ramène à l’arborescence ; formulaire garé en mémoire (pas SQLite) |
| Swipe | Biens ↔ Stock ↔ À acheter, circulaire, garde-fou bord système |
| Organisation | Mode Organiser retiré ; **Déplacer vers…** + choix de position |
| Persistance ordre | Réutilisation `moveNode` + `reorderSiblings` via `relocateNode` |

---

## 2. Composants réutilisés

- `InventoryTreeController` / `InventoryEngine.moveNode` / `reorderSiblings`
- `listContainmentCandidates` (sélecteur parent)
- `InventoryInlineSheet` + crayon Modifier
- `IndexedStack` trois espaces + barre inférieure
- `_TrailingCircleButton` (taille compacte)

---

## 3. Expansion initiale

- Au premier chargement réussi des racines : BFS sur tous les nœuds `canContain`.
- Pas de réouverture auto des fiches (phase info).
- Après interaction utilisateur : replis/déplis respectés.
- Changement d’onglet : état conservé (`IndexedStack`).
- Pas de persistance additionnelle.

**Observé** : cold start Biens — Maisonn déplié avec Photo / Salon / Chambre ; Stock — Cellier déplié avec Riz.

---

## 4. Dimensions des indicateurs

- Visible : **28 dp** ; zone tactile : **40 dp**.
- Stock : niveau immédiatement à gauche du `+` du parent ; même composant.
- Biens : prix financier texte inchangé ; cœur sentimental dans le même cercle.

**Observé (uiautomator)** : niveau `1` et `+` Cellier ≈ 105×105 px (même touch target).

---

## 5. Affichage sentimental

- `SentimentalHeartIndicator` : contour toujours visible, remplissage progressif.
- Uniquement si valorisation sentimentale enregistrée.
- Pas de doublon texte « n / 5 » sur la ligne de détail.

**Observé** : Photo — sémantique `5 / 5` + cœur en Zone B.

---

## 6. Retour par onglet actif

- Arbre hors Navigator ; formulaires dans Navigator par espace.
- Onglet actif → `parked` (Offstage) sans `pop` → saisie conservée.
- FAB / nouvelle création : reprend la pile si encore présente.
- Retour Android par étapes : inchangé (`PopScope` + `maybePop`).

**Observé** : picker → onglet Biens → arbre vide ; FAB → picker restauré.

---

## 7. Navigation circulaire

- Balayage horizontal corps ; seuil vitesse ; ignore bords ≤ 28 px et drag long-press.

**Observé** : Biens→Stock→À acheter→Biens ; inverse Biens←À acheter.

---

## 8. Organisation simplifiée

- Menu **Organiser**, bannière, Monter/Descendre, DnD réordre : retirés.
- Détails : **Déplacer vers…** + **Modifier**.
- Parcours : parent (y compris actuel) → position (En premier / Après… / En dernier) → `relocateNode`.
- Long-press vers un contenant : déplacement de parent inchangé.

**Observé** : Photo sous Maisonn → position « En premier » → ordre Photo, Salon, Chambre ; conservé après redémarrage.

---

## 9. Vérifications sur émulateur

| Critère | Résultat |
|---------|----------|
| Expansion initiale 3 espaces | OK (Biens, Stock créés ; À acheter vide) |
| Branche / onglet sans reset | OK (IndexedStack) |
| Cercles compacts + alignement Stock | OK |
| Cœur 5/5 | OK (sémantique + rendu) |
| Onglet actif → arbre + reprise form | OK |
| Swipe + boucle circulaire | OK |
| Retour système | Non exercé exhaustivement (mécanisme inchangé) |
| Déplacer autre parent / même parent + ordre | OK (même parent + position) |
| Ordre après redémarrage | OK |

Captures : `docs/rapport-v2/_ux03_shots/`.

---

## 10. Réserves

1. Remplissage cœur très petit : lisible, mais le rendu 1/5 vs 5/5 mérite un contrôle tactile humain.
2. Retour système Android non rejoué scénario par scénario dans cette session.
3. Données d’émulateur reseedées manuellement (ADB) ; pas de parcours tactile doigt réel.
4. Collapse volontaire puis retour d’onglet : non isolé comme cas ADB distinct (mécanisme présent).

---

**STOP** — Phase 4 non lancée.
