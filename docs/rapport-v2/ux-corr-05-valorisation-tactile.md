# UX-CORR-05 — Valorisation tactile compacte

**Date :** 24 novembre 2026  
**Motorola :** `ZT322P23HJ` — versionCode **6026** (build Flutter **4026**, arm64 debug)  
**Pixel_7a :** non traité  
**Statut :** **EN ATTENTE DE VALIDATION UTILISATEUR**

---

## Synthèse

Remplacement des deux `TextField` de valorisation (Biens) par :

- Roulette financière tactile (montant unique visible, pas de 5 $).
- Échelle de cinq cœurs cliquables.

Hauteur fixe **48 px** (identique aux puces `$` / cœur) → aucun saut vertical au changement de mode. Pas de clavier.

---

## Composants initiaux → remplacés

| Avant | Après |
|---|---|
| `TextField` montant CAD | `_FinancialRoulette` (geste vertical) |
| `TextField` note 1–5 | `_SentimentalHearts` (5 `IconButton`) |

**Conservé :** puces mode `$` / cœur, `TextEditingController`, `parseCadCents`, validations, persistance, disposition UX-CORR-04.

---

## Fichier modifié

- `lib/app/inventory_valuation_field.dart`  
  (réutilisé aussi par l’écran d’acquisition vers Biens — même contrôle de saisie)

Aucun schéma SQLite, aucune migration, aucun commit.

---

## Défilement financier

- Affiche **uniquement** le montant courant (pas de voisins).
- Drag vertical + fling avec décélération ; pas de 500 ¢ (5 $).
- Min / défaut : 0 $.
- Plafond technique : `int` max (0x7FFFFFFFFFFFFFFF ¢), sans liste pré-générée.
- Anciennes valeurs non multiples de 5 $ : affichées telles quelles ; le premier geste va au cran 5 $ suivant/précédent selon le sens — **pas d’arrondi silencieux** à l’ouverture ni à l’enregistrement.

---

## Sentimentale

- Cinq cœurs horizontaux ; clic sur le n-ième → n/5 ; remplissage 1…n.
- Pas de compteur numérique ; défaut inchangé (aucune note tant que non choisie).

---

## Compacité

Les deux contrôles et l’état « aucune valorisation » partagent `valuationControlHeight = 48` — même hauteur que les puces mode.

---

## Captures Motorola

| | Fichier |
|---|---|
| Mode financier (`0 $`) | `docs/rapport-v2/_ux-corr-05/financier.png` |
| Mode sentimental (2/5) | `docs/rapport-v2/_ux-corr-05/sentimental.png` |

**Observé (UI + a11y) :** montant seul ; cinq cœurs ; 2/5 après un clic ; pas d’« Informations » ni clavier sur ces contrôles ; hauteur alignée.

**À confirmer au doigt :** fling vers 25 $/100 $, persistance enregistrement/réouverture, legacy non multiple de 5 $, non-régression arbre.

---

## Limitations

1. Validation tactile complète réservée à l’utilisateur.
2. Plafond = limite `int` Dart/SQLite déjà implicite (pas de plafond métier inventé).

---

## Verdict

**EN ATTENTE DE VALIDATION UTILISATEUR**

Inventory au premier plan sur Motorola, données conservées. **STOP.**
