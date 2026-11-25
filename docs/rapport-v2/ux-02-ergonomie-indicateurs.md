# UX-02 — Ergonomie au pouce et indicateurs Stock

**Verdict : VALIDÉ SOUS RÉSERVES**

Date : 2026-11-18  
Émulateur : `Pixel_7a` / `emulator-5554`  
Aucun commit ni push. Aucun nouveau test automatisé. App laissée installée (debug).

---

## Composants modifiés

| Fichier | Changement |
|---------|------------|
| `lib/app/inventory_thumb_layout.dart` | Bande supérieure stable (~30 % hauteur pré-IME) pour centrer sélecteurs/formulaires au pouce |
| `lib/app/inventory_tree_screen.dart` | Cercle Stock en Zone B (comme le prix Biens) ; `+` en Zone C ; diamètre commun `_trailingCircleSize` (40) via `_TrailingCircleButton` |

Aucun moteur, SQLite, ni parcours métier modifié.

---

## Position formulaires / sélecteurs

- Contenu court : décalage vertical fixe calculé sur la hauteur **clavier fermé** (`maxHeight + viewInsets`).
- Pas de bascule bas↔haut (UX-01-C préservée).
- Trois espaces : même `InventoryThumbBody`.

**Observé (ADB)** : picker Biens cartes ≈ y 1079 / 1331 (milieu de la zone utile ≈ 1200).

---

## Stabilité clavier

| Formulaire | Position y fermé | ouvert | Δ |
|------------|------------------|--------|---|
| Emplacement | 938 | 755 | **−183** |

Le Δ résiduel vient surtout du scroll local vers le champ focusé (comportement Flutter), pas d’un réalignement bas→haut. Bien meilleur que le saut de plusieurs centaines de px corrigé en UX-01-C (−351 avec centrage dynamique précédent).

Barre inférieure : visible pendant création.

---

## Cercles Stock

| Contrôle | Taille sémantique (uiautomator) | cx |
|----------|----------------------------------|-----|
| Niveau `½` | 105 × 105 | 880 |
| `+` Cellier | 106 × 105 | 996 |

- Même diamètre extérieur (composant partagé 40 dp).
- Niveau immédiatement à **gauche** du `+` (Zone B / Zone C).
- Cycle 1 → ½ observé.

Captures : `docs/rapport-v2/_ux02_shots/`.

---

## Vérifications effectuées

1. Sélecteur Biens centré — oui  
2–4. Formulaires Emplacement / Bien / Stock / À acheter — corps partagé  
5. Clavier — Δ mesuré −183 (scroll focus)  
6. Nav inférieure — oui  
7–8. Diamètre et position cercles — oui  
9. Cycle Stock — oui  

Pas de suite `flutter test` (mandat : vérification visuelle ciblée).

---

## Réserves

| Id | Sévérité | Description |
|----|----------|-------------|
| — | P0/P1 | Aucun |
| R1 | P2 | Essai au doigt non fait (ADB) |
| R2 | P2 | Micro-décalage vertical à l’ouverture IME si scroll vers le champ actif |

**STOP UX-02.**
