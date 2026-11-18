# Rapport V2-00 — Consolidation du plan directeur

| Champ | Valeur |
| --- | --- |
| Date | 17 novembre 2026 |
| Mandat | Inventory V2 — V2-00 (documentation uniquement) |
| Verdict | **VALIDÉ** |
| Référence produit | `docs/Inventory-v2.md` |
| Référence Phase 0 | `docs/rapport-v2/spécification-technique-préliminaire-v2.md` |

## 1. Verdict

**VALIDÉ.** Les dix décisions produit et les corrections complémentaires sont intégrées sans ambiguïté dans le plan directeur unique. Aucune contradiction fonctionnelle résiduelle bloquante pour démarrer M1.1. Les choix d’implémentation restent explicitement hors décisions produit (§15 du plan).

## 2. Décisions intégrées (D01–D10)

| Id | Intégration |
| --- | --- |
| D01 | §3 — fractions 3 décimales, unités, pièce/portion entières, entier normalisé, zéro OK |
| D02 | §3 — conversions auto g↔kg / mL↔L seulement ; sinon quantité explicite |
| D03 | §4 — pas de fusion auto sur nom ; choix explicite produit ou création |
| D04 | §4 — Abandonner vs suppression définitive confirmée |
| D05 | §4 / §9 — contenu minimal historique d’achat ; partiel / complet |
| D06 | §4 — valorisation Biens libre ; prix payé ≠ valeur du bien |
| D07 | §6 — PDF/JPEG/PNG/WebP, 15 Mo ; facture = document |
| D08 | §6 — sélecteur Android, capture privée, pipeline WebP 1280/q80 |
| D09 | §7 — mode « Organiser » ; déplacement distinct ; ordre migré depuis V1 |
| D10 | §10 — `.invbackup` V2 + médias ; import V1 ; pas de plafond fixe 32 Mio |

## 3. Corrections supplémentaires effectuées

- Informations avancées : préférence globale = **défaut des nouvelles fiches seulement** ; état individuel ensuite ; masquage sans suppression (§5, statut DÉCIDÉ).
- Trois espaces : hiérarchies indépendantes, moteur partagé, recherche/création contextualisées, navigation inférieure, aucun transfert automatique (§1).
- Acquisition : destination, emplacement, quantité, prix réel optionnel, atomicité, partiels, retrait de liste si complet (§4).
- Icônes : auto locale + Paramètres ; pas de sélecteur en création (§8, inchangé sur le fond).

## 4. Sections du plan modifiées

En-tête et §0 (gouvernance + registre D01–D10) ; §1 ; §3 ; §4 ; §5 ; §6 ; §7 ; §9 ; §10 ; §11 (renvoi Phase 0) ; §12 (phases alignées) ; §13 (critères) ; §15 (points ouverts réduits). §2, §8, §14 préservés sur le fond.

## 5. Contradictions corrigées

| Avant | Après |
| --- | --- |
| Unités / précision Stock « RECOMMANDÉ / à définir » | D01–D02 DÉCIDÉ |
| Achat partiel et fusion « RECOMMANDÉ / à vérifier » | Partiel + D03 DÉCIDÉ |
| Préférence globale « ne modifie pas les fiches » RECOMMANDÉ | DÉCIDÉ + précision « nouvelles fiches seulement » |
| Documents « À AUDITER » | D07 DÉCIDÉ |
| Mode Organiser « recommandé si… » | D09 DÉCIDÉ |
| Limite backup 32 Mio implicitement héritée V1 | D10 : pas de plafond fixe produit |
| §15 « points à confirmer Phase 0 » encore ouverts | Remplacé par points réellement encore ouverts |

## 6. Contradictions / ouvertures résiduelles (non bloquantes)

- Priorité À acheter (basse/normale/haute) reste **RECOMMANDÉ**.
- Indépendance des états de navigation par onglet reste **RECOMMANDÉ**.
- Critères UI exacts d’un produit Stock « compatible » (au-delà de « pas le nom seul ») à préciser en Phase 2, sous contrainte D03.
- Choix techniques (échelle entière, libs, migrations, packaging restore) volontairement non tranchés ici.

Aucune contradiction fonctionnelle majeure détectée entre sections après consolidation.

## 7. Fichiers modifiés / créés

| Fichier | Action |
| --- | --- |
| `docs/Inventory-v2.md` | Mis à jour |
| `docs/rapport-v2/rapport-v2-00-consolidation-plan.md` | Créé (ce rapport) |

## 8. Intégrité V1

Aucun fichier source Flutter/Dart, schéma SQLite, migration, dépendance, sauvegarde ou donnée utilisateur modifié. Aucun test, compile, APK, émulateur, appareil, branche, commit ou push.

## 9. Disponibilité pour M1.1

Le plan directeur est **documentairement prêt** pour autoriser M1.1 (schéma d’espace + migration V1 → Biens), sous réserve d’une **autorisation explicite** de l’utilisateur. V2-00 n’exécute pas M1.1.
