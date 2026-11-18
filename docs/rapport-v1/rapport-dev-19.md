# Rapport DEV-19 — Fiche de création compacte

## Verdict

**EN ATTENTE DE VALIDATION PHYSIQUE**

Corrections appliquées. APK release signé prêt (`1.0.2` / `versionCode 2003` arm64).  
**Moto G24 Power non connecté** au moment de l’install → installation non effectuée.

---

## 1. Corrections réalisées

- Ordre fiche bien : **Position → Quantité → Valorisation → Nom → Annuler | + | Créer**
- Position sur une ligne + `+` création rapide d’emplacement (biens / biens-contenants)
- Valorisation : ligne **`$` | `♡` | champ numérique** (toggle exclusif, re-tap = aucune)
- `+` central : enregistrer puis fiche vierge même type, position conservée
- Emplacement : Position + Nom + Annuler | Créer (sans qty / valorisation / + central)
- Titres : Nouveau bien simple / Nouveau bien-contenant / Nouvel emplacement

---

## 2. Fichiers modifiés

| Fichier | Rôle |
|---|---|
| `lib/app/inventory_creation_screen.dart` | UI et logique DEV-19 |
| `lib/app/app_strings.dart` | Libellés titres / actions |
| `lib/app/main_navigation_screen.dart` | Retour création = `Object?` (nœud ou `true`) |
| `pubspec.yaml` | `1.0.2+3` |

---

## 3. Ordre final des champs (bien)

1. Position (+ optionnel)  
2. Quantité  
3. Valorisation (`$` / cœur / valeur)  
4. Nom du bien  
5. Barre : Annuler | + | Créer  

---

## 4. Toggle `$` / cœur

- Un seul mode actif ; re-toucher désactive → aucune valorisation  
- Changement de mode efface le champ  
- Financier : CAD (y compris `0` saisi) ; vide ≠ 0 auto  
- Sentimental : entier 1–5 ; vide ≠ enregistrement  

---

## 5. `+` Position

Ouvre fiche emplacement → enregistre → revient → parent = nouvel emplacement ; données du bien conservées. Annulation sans effet.

---

## 6. `+` central

Mêmes validations que Créer → enregistre → attend succès → reset nom / qté 1 / valorisation aucune → garde position → reste sur la fiche. Échec : pas de reset.

---

## 7. Compilation / installation

| Élément | État |
|---|---|
| versionName | `1.0.2` |
| versionCode arm64 | `2003` (> `2002`) |
| APK | `dist/android/Inventory-v1.0.2-arm64-release.apk` |
| Signature | keystore production |
| Moto | **Absent** — brancher pour `adb install -r` sans clear données |

---

## 8. Limitations connues

- Fiche édition (modification) non retouchée (hors mandat)  
- Emplacement : pas de `+` central (ajout successif d’emplacements via parcours normal)  

---

## 9. À valider sur le Moto

1. Ordre des champs  
2. Toggle `$` / cœur  
3. `+` Position  
4. `+` central (série de biens)  
5. Créer / Annuler / persistance  
6. Bien-contenant aligné  
7. Ergonomie bas d’écran + clavier  

---

## Arrêt

**ARRÊT — attendre le retour du propriétaire.**  
Pas de tests auto. Pas de commit/push. Pas de nouveau mandat.
