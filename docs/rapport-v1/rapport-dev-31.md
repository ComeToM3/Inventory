# Rapport DEV-31 — Validation physique finale Motorola Moto G24 Power

## 1. Résumé exécutif

Validation produit réelle sur **Motorola Moto G24 Power** (`ZT322P23HJ`, Android 14, arm64-v8a).

- APK candidate `1.0.12` (versionCode **2013**) installée en **mise à jour** (`adb install -r`) sans destruction de données.
- Données préexistantes (**MaisonDEV15**, total **2 185 $**, historique **LampeDEV15**) **préservées**.
- Parcours essentiels D1–D4, D6–D11 observés sur le Moto (gestes ADB + UI).
- Export `.invbackup` réel : `inventory-DEV31.invbackup` (**7000 o**).
- **Aucun P0 / P1** constaté.
- Glisser-déposer : **non confirmé au doigt** par le propriétaire dans ce mandat.
- Restauration bout-en-bout : **non exécutée** (interdit sans plan de récupération).

**Décision : GO SOUS RÉSERVES — V1 utilisable avec limites documentées.**

## 2. Identification du Moto G24 Power

| Champ | Valeur |
|---|---|
| Modèle | `moto g24 power` |
| Serial ADB | `ZT322P23HJ` |
| Android | 14 |
| ABI | `arm64-v8a` |
| État ADB | `device` (autorisé) |
| Ciblage | Toutes commandes avec `-s ZT322P23HJ` |
| Émulateur | Non utilisé pour l’acceptation |

## 3. Préflight APK et signature

| Contrôle | Résultat |
|---|---|
| Fichier | `dist/android/Inventory-v1.0.12-arm64-release.apk` présent |
| SHA-256 APK | `b11006c39991c08a0fc9bf9800d8553edaab84355bbc4ad30d4bba2444bdfbd8` — **conforme** |
| Package | `io.github.cometom3.inventory` |
| versionName / versionCode | `1.0.12` / `2013` |
| Architecture | arm64 — compatible Moto |
| Certificat APK | DN `CN=Inventory V1, OU=Personal, O=ComeToM3…` — SHA-256 `30d16cbe…81b998b0` |
| Certificat installé (APK base appareil) | **identique** `30d16cbe…81b998b0` |
| dumpsys signatures | `a163acac` (stable avant/après) |
| Espace | Suffisant (~164 Go libres côté stockage utilisateur observé) |
| Risque migration destructive | Aucun identifié (même package, même certificat, versionCode supérieur) |

## 4. Version initialement installée

| Champ | Avant DEV-31 |
|---|---|
| versionName | `1.0.11` (référence session / versionCode 2012) |
| versionCode | **2012** |
| Package | `io.github.cometom3.inventory` |
| Données visibles | Arbre avec **MaisonDEV15** (2 185 $), structure chambre, historique existant |

État de référence non sensible : présence de **MaisonDEV15** et total affiché **2 185 $** ; sauvegardes `.invbackup` déjà présentes dans Téléchargements (non écrasées).

## 5. Résultat de l’installation

```
adb -s ZT322P23HJ install -r dist/android/Inventory-v1.0.12-arm64-release.apk
→ Success
```

| Après install | Valeur |
|---|---|
| versionName | `1.0.12` |
| versionCode | `2013` |
| lastUpdateTime | `2026-11-15 19:46:22` |
| firstInstallTime | `2026-11-14 13:18:20` (inchangé) |
| Options destructives | Non utilisées (`-d`, uninstall, `pm clear` absents) |

## 6. Préservation des données

| Contrôle | Résultat |
|---|---|
| MaisonDEV15 après install | Présente |
| Total 2 185 $ | Conservé |
| Historique LampeDEV15 (Vente · 14/11/2026) | Conservé |
| Disparition inattendue | **Non** |
| Jeu de test DEV31_* | Créé puis nettoyé (suppression uniquement des éléments de test) |
| État final arbre | MaisonDEV15 + chambre ; **aucun** DEV31_* restant |

## 7. Tableau des validations D1 à D11

| Parcours | Test réalisé | Preuve | Résultat | Réserve |
|---|---|---|---|---|
| D1 — Identité | Observation Moto : lanceur, splash pétrole, ouverture sans crash | `03_launcher.png`, `02_splash.png`, `01_after_install_tree.png` | **OK** | — |
| D2 — Arbre | Observation Moto : emplacements/biens, indentation, expansion, Modifier, totaux | `01_…`, `07_tree_with_item.png`, `08_item_info.png` | **OK** | — |
| D3 — Création | Observation Moto + gestes ADB : Loc / Box / Item, parent DropdownMenu, qty, valorisation | `04`–`07`, `05_parent_menu.png` | **OK** | Saisie ADB ≠ confort clavier humain |
| D4 — Modification | Observation Moto : nom, qty, valorisation, persistance immédiate | `09_after_edit.png` | **OK** | — |
| D5 — DnD | Non validé au doigt ; pas de campagne synthétique présentée comme preuve tactile | — | **En attente** | **Validation tactile humaine requise** |
| D6 — Recherche | Observation Moto : recherche test, chips/filtres, chemin | `10_search.png`, `11_chips.png` | **OK** | — |
| D7 — Retrait | Observation Moto : motifs Perte/Don/Bris/Vente ; retrait Don sur DEV31Item ; historique | `20`–`24_historique.png`, `34_historique_final.png` | **OK** | Uniquement bien de test |
| D8 — Suppression | Observation Moto : confirmation ; blocage contenant non vide ; suppression Box puis Loc vides | `25`–`29_*.png` | **OK** | Message blocage après confirm |
| D9 — Sauvegarde | Export réel SAF → `inventory-DEV31.invbackup` 7000 o ; restauration ouverte puis annulée | `16_saf_picker.png`, `17_after_backup.png`, `33_restore_entry.png` | **Export OK** | **Restauration E2E non validée** |
| D10 — Finition | Aide, À propos, confidentialité, Paramètres, banners | `13_about.png`, `14_help.png`, `32_about.png` | **OK** | Build affiché = 2013 (voir §10) |
| D11 — Persistance | `am force-stop` puis relance : MaisonDEV15 + total + historique conservés | `30_persist_relaunch.png`, `34_historique_final.png` | **OK** | — |

Légende des preuves : **Observation réelle sur Moto** (UI + captures) ; interactions = **geste ADB synthétique** sauf mention contraire. **Geste humain au doigt : non vérifié** pour D5.

## 8. Résultats des gestes tactiles

| Geste | Statut |
|---|---|
| Lancement / navigation / création / édition / recherche / retrait / suppression / sauvegarde | Observés via **gestes ADB synthétiques** sur Moto — fonctionnels |
| Appui long + glisser-déposer (emplacement / contenant / refus / cycles) | **Non confirmé au doigt** |
| Confort et fiabilité « au pouce » | **Non déclarés validés** |

### Procédure courte pour le propriétaire (D5)

1. Créer temporairement `TEST_DnD_A` (emplacement) et `TEST_DnD_B` (bien simple sous A).
2. Appui long sur `TEST_DnD_B` → déplacer vers un autre emplacement réel **vide de test** ou un bien-contenant de test.
3. Vérifier dépôt valide, refus d’une cible invalide (ex. descendant), conservation des enfants.
4. Supprimer uniquement les éléments `TEST_DnD_*`.
5. Répondre : utilisable au doigt ? (oui / non / partiel).

## 9. Sauvegarde et limites de restauration

| Point | Constat |
|---|---|
| Accès Paramètres → Sauvegarder | OK |
| Fichier créé | `/sdcard/Download/inventory-DEV31.invbackup` |
| Taille | **7000 octets** (non nulle) |
| Écrasement | Non — nom dédié DEV31 |
| Parcours Restaurer | Ouvre le sélecteur de fichiers ; annulation → « Restauration annulée. » |
| Restauration réelle | **Non exécutée** — hors autorisation de ce mandat |
| Verdict restauration | **Non validée** |

## 10. Anomalies constatées

### P3 — À propos : « build 2013 » au lieu de build Flutter 13

- **Repro :** Paramètres → À propos sur APK release installée.
- **Attendu (pubspec / DEV-30 émulateur) :** `Version 1.0.12 (build 13)`.
- **Observé :** `Version 1.0.12 (build 2013)` (`32_about.png`).
- **Preuve :** `package_info` release expose le `versionCode` arm64 (2013) comme `buildNumber`.
- **Impact :** Cosmétique / identification ; `versionName` correct ; dumpsys confirme 1.0.12 / 2013.
- **Gravité :** **P3**.
- **Reco minimale :** Clarifier le libellé (build Flutter vs versionCode) si le propriétaire le souhaite — **hors DEV-31**.

Aucune autre anomalie P0–P2 confirmée sur Moto dans ce mandat.

## 11. Réserves restantes

1. **DnD tactile humain** non confirmé (bloquant pour un GO plein au sens du mandat).
2. **Restauration E2E** non exécutée sur la base propriétaire.
3. **Build À propos** = 2013 (P3).
4. Interactions de validation principalement **ADB**, pas une session « doigt jour entier ».
5. Distribution publique : **non autorisée** par ce rapport.

## 12. État final de l’application sur Moto

| Élément | État |
|---|---|
| Package | `io.github.cometom3.inventory` |
| Version | `1.0.12` (versionCode **2013**) |
| Signature | Production ComeToM3 (`30d16cbe…`) |
| Données réelles | MaisonDEV15 intacte |
| Jeu DEV31 | Nettoyé (Loc/Box/Item) ; retrait DEV31Item reste en **historique** (Don · 15/11/2026) |
| Sauvegarde DEV31 | Conservée dans Téléchargements (7000 o) |

## 13. Décision GO / GO SOUS RÉSERVES / NO-GO

### **GO SOUS RÉSERVES — V1 utilisable avec limites documentées.**

Justification : installation et préservation OK ; parcours essentiels fonctionnels sur Moto ; export sauvegarde réel ; pas de P0/P1 ; réserves DnD doigt + restauration E2E explicitement documentées et compatibles avec un usage personnel contrôlé.

Critère « GO — V1 livrable » non atteint uniquement faute de **confirmation tactile DnD par le propriétaire**.

## 14. Recommandation au propriétaire

1. Exécuter la procédure D5 (§8) au doigt ; si OK → le statut peut passer à **GO — V1 livrable** sans nouveau cycle de développement.
2. Conserver `inventory-DEV31.invbackup` (et les sauvegardes antérieures) hors appareil si possible.
3. Ne pas restaurer sur la base réelle sans sauvegarde récente + acceptation du risque d’écrasement.
4. Accepter ou ignorer le P3 « build 2013 » dans À propos.
5. Usage personnel contrôlé : **autorisé sous les réserves ci-dessus**. Publication / distribution large : **non couverte**.

---

## Réponses obligatoires

1. **Inventory `1.0.12` est-elle installée sur le Moto G24 Power ?** Oui (`versionCode` 2013).
2. **Les données préexistantes ont-elles été préservées ?** Oui (MaisonDEV15 / 2 185 $ / historique antérieur).
3. **Les parcours essentiels fonctionnent-ils réellement ?** Oui sur Moto (création, modification, arbre, recherche, retrait, suppression test, persistance, export).
4. **Le glisser-déposer est-il confirmé au doigt ou seulement par simulation ?** **Non confirmé au doigt** — en attente propriétaire.
5. **La sauvegarde est-elle réellement exportable ?** Oui — fichier 7000 o créé.
6. **Existe-t-il un défaut P0 ou P1 ?** Non.
7. **Quelles réserves nécessitent une décision du propriétaire ?** Confirmation DnD au doigt ; politique de restauration E2E ; acceptation P3 build ; éventuelle distribution.
8. **La V1 peut-elle être considérée comme terminée ?** **Oui pour usage personnel contrôlé sous réserves** ; **pas** un GO plein tant que le DnD doigt n’est pas confirmé.

---

**ARRÊT OBLIGATOIRE.** Aucune correction, aucun commit, aucun push, aucune publication, aucun mandat suivant proposé.

Captures : `docs/rapport/_dev31_shots/`.
