# Rapport DEV-14 — Validation Android réelle (Moto G24 Power)

## Verdict

**VALIDÉ** : Inventory V1 a été installée et exécutée sur un **Motorola moto g24 power** physique (Android 14). Les parcours principaux, totaux financiers, recherche, historique, export `.invbackup` (« Export vérifié ») et restauration sécurisée (État B → restauration A, rejet de fichier invalide) ont été observés sur cet appareil. Aucun défaut **P0/P1** constaté.

**Décision : GO pour DEV-15.**

## Appareil et installation

| Élément | Valeur |
|---------|--------|
| Appareil | Motorola **moto g24 power** (`ZT322P23HJ`) |
| Produit / device | `fogorow_gp` / `fogorow` |
| Android | **14** (API 34), `arm64-v8a` |
| Écran | 720×1612 |
| Méthode | `flutter build apk --debug` + `adb install -r` |
| Package | `io.github.cometom3.inventory` `1.0.0+1` |

### Protection des données

- Application déjà présente (`inventory.sqlite` du 2026-11-13, 8192 o, schéma minimal sans table métier peuplée).
- **Aucun `pm clear`, aucune désinstallation.**
- Validation sur base isolée **`inventory_dev14.sqlite`** (`--dart-define=DEV14_SEED=true`) afin de ne pas écraser `inventory.sqlite`.
- Après essais : seed retiré du code, APK debug réinstallé sans clear ; `inventory.sqlite` toujours présent (8192 o, date inchangée) ; fichier de test `inventory_dev14` supprimé via `run-as`.

## Parcours exécutés (téléphone physique)

Données fictives seed : Maison DEV14 → Bureau → Armoire → Boîte à outils (+ Tournevis) / Lampe ; Salon → Livre rare (sentimental) ; Câble HDMI retiré (Vente).

| Domaine | Résultat observé |
|---------|------------------|
| Inventaire fermé / ouvert | Maison **102,00 $ CAD** fermée ; sous-totaux Bureau/Armoire/outils ; Salon **Sans valeur financière** |
| Compteurs `(n)` | Affichent les enfants **directs chargés** (ex. Maison `(2)`), pas le total exhaustif de descendants — montants eux indépendants de l’expansion |
| Consultation / modification | Fiche Lampe ; quantité 2→3 → totaux **127,00 $** |
| Déplacement | Lampe → Salon : Bureau/Armoire **52,00** ; Salon **75,00** ; Maison **127,00** |
| Recherche | « Lampe », 1 résultat, badge **3 × 25,00 $ CAD**, chemin Salon |
| Historique | Câble HDMI / Vente |
| Création | Cartes Emplacement / Contenant / Bien / Bien-contenant |
| Relance à froid | Totaux et structure persistants |
| Retour arrière-plan | Maison DEV14 toujours affichée après Home → reprise |
| Export SAF | Avertissement confidentialité → Téléchargements → **Export vérifié** ; fichier `inventory-20261114-174424.invbackup` (5406 o) |
| Restauration | État B (`EtatB`) → restauration A → message **Restauration effectuée** ; `EtatB` absent ; persistance après force-stop |
| Fichier invalide | `bad-dev14.invbackup` → **Fichier de sauvegarde invalide… L’inventaire actuel n’a pas été modifié** |

Scénarios `pending`/`committed` d’interruption : non rejoués physiquement ; preuves complémentaires = rapports DEV-13 + tests automatisés.

## Captures

[`docs/rapport/captures-dev-14/`](captures-dev-14/) — captures `adb screencap` sur le téléphone (ex. `01`–`12` inventaire/parcours, `13`–`16` export, `17`–`22` restauration/rejet, `23`–`24` reprise/persistance).

## Sauvegarde / restauration

1. **Export** : message « Export vérifié : le fichier a été écrit et relu avec succès. » ; fichier présent sous `/sdcard/Download/`.
2. **Restauration A** après ajout d’`EtatB` : confirmation « Remplacer » → « Restauration effectuée. L’inventaire a été remplacé. » → seul Maison DEV14 ; relance OK.
3. **Rejet** : fichier invalide sans modification de l’inventaire.

## Anomalies

| ID | Sévérité | Description | Décision |
|----|----------|-------------|----------|
| — | **P0** | Aucune | — |
| — | **P1** | Aucune | — |
| A1 | **P3** | Compteurs `(n)` = enfants directs déjà chargés, pas un total exhaustif de descendants (les **montants** CAD sont, eux, exhaustifs). Risque d’ambiguïté pédagogique. | Reporter (DEV-15+ / amélioration UX) ; pas bloquant |
| A2 | **P3** | Tap sur un bien ouvre la fiche (sélection sans navigation non séparée). | Reporter (connu DEV-13.5) |

Aucune correction de code dans DEV-14 (aucun P0/P1).

## Vérifications techniques

| Contrôle | Résultat |
|----------|----------|
| `flutter analyze lib` | Aucun problème |
| `flutter test test/app test/core` | **49** tests OK |
| Compilation APK debug | OK |
| `inventory.sqlite` utilisateur | Non altéré |

## Réserves

- Validation physique centrée sur un scénario fictif isolé ; inventaire personnel réel non exercé.
- Coupure d’alimentation pendant commit SQLite non rejouée (hors périmètre dangereux) ; couverture DEV-13 conservée.
- A1 (compteurs) reste une amélioration souhaitable avant ou après distribution, sans bloquer la signature.

## Décision DEV-15

**GO** pour DEV-15 — Distribution et signature.

Preuves : exécution réelle sur Moto G24 Power, parcours métier et backup/restore réussis, pas de P0/P1 ouverts.

---

**Arrêt** après DEV-14. Pas de DEV-15, pas de signature/publication, pas de commit/push sans instruction.
