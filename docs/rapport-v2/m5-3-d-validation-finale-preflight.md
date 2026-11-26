# M5.3-D — Validation finale intégrée et préflight de livraison d'Inventory V2

**Date :** 25 novembre 2026  
**Addendum distant :** APK déposé hors domicile  
**Finalisation sur site :** Motorola reconnecté ADB  
**Appareil :** Moto G24 Power `ZT322P23HJ` (Android 14, arm64)  
**Émulateur :** non utilisé  
**Verdict :** **VALIDÉ SOUS RÉSERVES NON BLOQUANTES**

---

## 1. Résumé exécutif

Compilation post-assainissement **OK**. APK debug arm64 **6050** installé en mise à jour non destructive (`install -r`) sur le Motorola ; données conservées.

Parcours ADB/UI démontrés : démarrage, création Biens/Stock/À acheter, expansions indépendantes, cycle de niveaux Stock, persistance après force-stop, accès Paramètres/sauvegarde jusqu’au dialogue d’avertissement.

Réserves non bloquantes : acquisition « Acheté » non finalisée via ADB ; écriture SAF complète + restauration non abouties automatiquement ; caméra/docs/DnD doigt non rejoués ici.

Inventory laissé au **premier plan** (onglet Biens).

---

## 2. État du dépôt validé

| Élément | Valeur |
|---|---|
| Working tree | Inclut INTER-03-C |
| Commit distant | `1d6b69b` (+ changements locaux assainissement/rapports) |
| APK `dist/` | `C:\Users\ComeToM3\Dev\Inventory\dist\android\Inventory-v1.0.15-arm64-debug-vc6050.apk` |

---

## 3. Compilation et installation

| Champ | Résultat |
|---|---|
| Build | `build-number=4050` → arm64 `versionCode` **6050** / `1.0.15` |
| Avant install | versionCode **6049** |
| Commande | `adb -s ZT322P23HJ install -r dist/android/Inventory-v1.0.15-arm64-debug-vc6050.apk` |
| Résultat | **Success** |
| Après | versionCode **6050**, `lastUpdateTime=2026-11-25 18:43:46` |
| Wipe / uninstall | **Non** |
| Lancement | MainActivity topResumed |

Preuves : `_m53d/01-apres-install.png`, `02-home.png`.

---

## 4. Parcours Biens / Stock / À acheter

Légende : **Démo.** = observé UI/ADB sur Motorola · **N/V** = non vérifié dans ce mandat.

### Biens

| Étape | Statut | Preuve |
|---|---|---|
| Arborescence | Démo. | Inventaire / Papineau / chambre Joh |
| Création bien | Démo. | `M53DBien de` créé (`08-created`, `final-Biens.png`) |
| Qté / valorisation formulaire | N/V (ADB) | Création sans rejouer roulettes |
| Expansions enfants | Démo. | Chevron Support : Afficher → Masquer |
| Détails indépendants | Démo. | Marqueurs détails après tap ligne contenant |
| Déplacement DnD doigt | N/V | — |
| Photos / documents | N/V | UI non rejouée |
| Persistance | Démo. | Présent après force-stop (`persist_M53DBien`, `final-Biens.png`) |

### Stock

| Étape | Statut | Preuve |
|---|---|---|
| Création produit | Démo. | `M53DRiz` (`19-stock-created.png`, snackbar « Élément ajouté ») |
| Cycle niveaux 1→½→¼→0 | Démo. | Log `stock_level_0/1/2` |
| Niveau après relance | Démo. | `M53DRiz` visible (`final-Stock.png`) |
| Historique produit | N/V | Ouverture fiche Historique non capturée |
| Persistance | Démo. | `Stock {'M53DRiz': True}` post-relaunch |

### À acheter

| Étape | Statut | Preuve |
|---|---|---|
| Création besoins | Démo. | `M53DCafe`, `M53DCafe2` (`24-tobuy-created.png`, `final-À ache.png`) |
| Acquisition → Biens | N/V | Bouton « Acheté » non atteint via ADB |
| Acquisition → Stock + assoc. | N/V | Idem |
| Persistance besoins | Démo. | Présents après relance |

---

## 5. Sauvegarde / restauration

| Étape | Statut | Preuve |
|---|---|---|
| Paramètres → actions backup | Démo. | `32-settings.png` |
| Dialogue « Fichier non chiffré » | Démo. | `35-backup-saf.png` + actions Annuler / Choisir une destination |
| Création fichier `.invbackup` SAF | N/V | Sélecteur système non finalisé automatiquement |
| Restauration contrôlée | N/V | — |

Référence technique antérieure (émulateur) : M5.3-A — non substituée, mais rassure le mécanisme.

**À faire par l’utilisateur (court) :** Paramètres → Sauvegarder → choisir destination → vérifier le fichier → Restaurer une fois (données de test OK).

---

## 6. Persistance et intégrité

| Contrôle | Résultat |
|---|---|
| `am force-stop` + relance | App OK |
| Biens `M53DBien` | Présent |
| Stock `M53DRiz` | Présent |
| À acheter `M53DCafe` / `M53DCafe2` | Présents |
| Install `-r` 6049→6050 | Sans perte d’arbre existant (Papineau, CellierM53C, etc.) |

---

## 7. Validations physiques encore utiles (utilisateur)

1. Acquisition complète (Biens + Stock associé).  
2. Export `.invbackup` jusqu’au fichier + une restauration.  
3. Caméra / galerie / ouverture document.  
4. Un glisser-déposer appui long.  
5. Historique Stock depuis la fiche produit.

---

## 8. Anomalies

| ID | Classe | Constat |
|---|---|---|
| — | — | **Aucun P0 / P1 applicatif** constaté |
| B-01 | Environnement (clos) | ADB indisponible hors domicile — **levé** |
| R-01 | P2 | Acquisition / restore SAF non démontrés bout-en-bout via ADB |
| R-02 | P2 | Historique Stock / médias / DnD non rejoués |
| R-03 | P3 | Nom créé « M53DBien de » (saisie ADB) — cosmétique test |
| Analyze | Accepté | `unnecessary_null_comparison` préexistant |

---

## 9. Préflight release

| Élément | État |
|---|---|
| applicationId | `io.github.cometom3.inventory` |
| Debug installé | **6050** / `1.0.15` |
| keystore + `key.properties` | Présents (secrets non exposés) |
| Debug ≠ release (signature) | Install release future souvent **propre** |
| Schéma SQLite | **15** |
| Backup | format **2** / data **3** |
| APK release | Non généré (hors mandat) |

---

## 10. Versionnement recommandé

- versionName release proposé : **2.0.0** (à confirmer).  
- versionCode release : **> 6050**.

---

## 11. Conditions de livraison officielle

1. Réserves R-01/R-02 acceptées ou complétées manuellement.  
2. Arbitrage versionName/versionCode.  
3. Mandat livraison : APK **signé release**.  
4. Install release : probablement wipe Inventory (autorisé).

---

## Verdict

**VALIDÉ SOUS RÉSERVES NON BLOQUANTES**

Base **6050** stable sur Motorola pour engager la livraison officielle, sous réserve des compléments manuels listés §7 (surtout sauvegarde bout-en-bout et acquisition).

**STOP** — attendre décision de clôture / mandat livraison. App au premier plan sur le Motorola.
