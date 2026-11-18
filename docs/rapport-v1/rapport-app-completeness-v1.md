# Rapport — Audit de maturité applicative Inventory V1

**Périmètre :** éléments périphériques uniquement (identité, confiance, navigation globale, aide, accessibilité transversale).  
**Hors périmètre :** parcours métier d’inventaire (déjà audités).  
**Méthode :** inspection code / ressources Android / docs produit · lecture seule.  
**Version inspectée :** `1.0.11+12`

---

## 1. Résumé exécutif

Inventory dispose d’un **cœur UX cohérent** (Material 3 clair, AppBar + menu, Paramètres backup avec textes de risque, hors ligne réel, pas de dépendance réseau/télémétrie dans `pubspec`).  

En revanche, la **finition « produit Android »** reste incomplète pour une distribution digne de ce nom : **icône Flutter par défaut**, splash blanc générique, **aucune page À propos / version visible**, pas d’aide compacte sur les gestes.  

Ces manques n’empêchent pas l’usage personnel, mais affaiblissent identité et confiance au premier contact.

**Verdict :** **FINITION V1 RECOMMANDÉE** — un mandat court de finition périphérique (icône + À propos/version + mini-aide + splash) avant de clore V1 pour distribution.

---

## 2. Inventaire des éléments périphériques existants

| Élément | Preuve | État |
|---|---|---|
| Nom lanceur / AppBar | `android:label="Inventory"` · `AppStrings.appTitle` | Présent et suffisant |
| Icône lanceur | `mipmap-*/ic_launcher.png` = **logo Flutter** | Présent mais insuffisant |
| Splash | `launch_background.xml` fond blanc, image commentée | Présent mais insuffisant |
| Thème clair Material 3 | `AppTheme.light` (pétrole / menthe) | Présent et suffisant pour V1 claire |
| Thème sombre Flutter | Absent (`theme:` seul ; night XML = shell Android) | Absent — V2 acceptable |
| Locale FR | `locale: Locale('fr')` | Présent et suffisant |
| Navigation Inventaire-centric | AppBar Recherche + ⋮ Historique/Paramètres/Ajouter (DEV-20) | Présent et suffisant |
| Paramètres backup/restore + avertissements | `SettingsScreen` + `backupPrivacyMessage` | Présent et suffisant (métier données) |
| Aide inline sauvegarde / recherche | Textes Paramètres + `searchFiltersHelp` | Présent mais partiel |
| Version dans l’UI | Non affichée (seulement `pubspec` / APK) | Absent et pertinent |
| Page À propos / éditeur | Absente | Absent et pertinent |
| FAQ / tutoriel | Absents | Absent — FAQ non nécessaire ; mini-aide pertinente |
| Bottom navigation | Retirée volontairement (DEV-20) ; doc UX 06 encore ancienne | Absent volontairement |
| Permissions runtime | Aucune permission dangereuse dans le manifeste | Présent et suffisant |
| Exclusion backup système | `allowBackup=false` + règles XML | Présent et suffisant |
| Dépendances réseau / analytics | Absentes du `pubspec` (flutter, drift, crypto, path_provider) | Cohérent hors ligne |
| Semantics / tooltips | Partiels (arbre, recherche, actions) | Présent mais améliorable |
| SafeArea / Retour prédictif / IME | `SafeArea`, `enableOnBackInvokedCallback`, `adjustResize`, `InventoryThumbBody` | Présent et suffisant |
| Doc confidentialité | `docs/07-security-privacy.md` (hors app) | Présent hors UI |

---

## 3. Matrice de complétude applicative

| Catégorie | Niveau | Commentaire |
|---|---|---|
| A. Identité visuelle | **Faible à moyen** | Palette app OK ; lanceur / splash = générique Flutter |
| B. Informations app | **Faible** | Pas de version ni éditeur dans l’UI |
| C. Aide | **Moyen** | Backup bien expliqué ; gestes peu documentés |
| D. Navigation globale | **Bon** | Une destination principale ; secondaires en menu |
| E. Paramètres généraux | **Minimal volontaire** | Backup seulement — cohérent si on y ajoute À propos |
| F. Accessibilité | **Moyen** | Bases OK ; couverture TalkBack non démontrée |
| G. Conventions Android | **Moyen** | Manifeste soigné ; splash/icône à finir |
| H. Confiance / confidentialité | **Bon en doc + backup UI** | Manque résumé « local / hors ligne » visible |
| I. Support / cycle de vie | **Faible** | Pas de canal support ni version affichée |

---

## 4. Lacunes pertinentes et conséquences

| Lacune | Conséquence utilisateur |
|---|---|
| Icône Flutter | Impression « démo / projet template » sur l’écran d’accueil |
| Splash blanc | Démarrage anonyme, rupture avec l’AppBar pétrole |
| Pas de version dans Paramètres | Impossible de dire quelle build est installée sans ADB |
| Pas d’À propos / éditeur | Moins de confiance pour une app personnelle sensible |
| Pas d’aide gestes (appui long, 4 clics) | Découverte lente des interactions non standard |
| Thème sombre absent | Inconfort en mode nuit système (acceptable V1 si annoncé clair-only) |

---

## 5. Analyse de la navigation inférieure

**Verdict : ne pas ajouter de Bottom Navigation Bar en V1.**

| Critère | Analyse |
|---|---|
| Destinations vraiment principales | **Une** : Inventaire. Recherche / Historique / Paramètres sont secondaires |
| Découverte actuelle | Recherche en AppBar (bonne) ; Historique/Paramètres sous ⋮ (acceptable) |
| Espace | Une barre basse **réduit** la zone d’arbre déjà contrainte (FAB + pouce) |
| Alignement Android | Bottom nav adaptée aux 3–5 destinations **égales** — ici non |
| Coût / risque | M : régression layout, conflit avec liste basse / FAB |
| Doc `06-ux-ui.md` | Propose encore 3 onglets — **supplantée** par décision DEV-20 validée en produit |

Amélioration éventuelle **sans** bottom nav : libellé « Aide » ou « À propos » dans le même menu ⋮ / Paramètres.

---

## 6. Analyse FAQ / À propos / aide / paramètres

| Question | Réponse |
|---|---|
| Page À propos ? | **Oui, légère**, intégrée à Paramètres (version, éditeur, hors ligne, stockage local). |
| FAQ intégrée ? | **Non en V1.** Trop lourde ; les doutes se limitent à 5–8 phrases. |
| Aide 1ʳᵉ utilisation ? | **Non** (pas d’onboarding multi-écrans). Une **page Aide courte** consultable suffit. |
| Bottom nav ? | **Non** (section 5). |
| Paramètres manquants ? | Version + À propos + lien Aide ; thème système = V2. |
| Identité visuelle aboutie ? | **UI oui / lanceur non.** |
| Confidentialité / support ? | Textes backup déjà bons ; ajouter 3–4 lignes « aucune collecte / hors ligne » + version. Support = email ou note locale optionnelle. |
| Accessibilité V1 ? | Vérifier TalkBack sur AppBar/menu/FAB ; pas de chantier a11y large. |
| Meilleur ROI ? | Icône + À propos/version + mini-aide + splash. |
| Livrer sans ça ? | **Usage perso oui** ; **distribution soignée : non** sans au moins icône + version. |

**Recommandation d’aide :** option **2 — une page d’aide courte** (pas 1 vide, pas 3 FAQ, pas 4 tutoriel).

---

## 7. Top 5 des améliorations V1 à faible effort

| # | Amélioration | État actuel | Valeur | Effort | Risque | Priorité | V1/V2 |
|---|---|---|---|---|---|---|---|
| 1 | Icône lanceur Inventory (remplacer Flutter) | Icône Flutter | Élevée | S | Faible | P1 finition | **V1** |
| 2 | Bloc À propos dans Paramètres (version/build, éditeur, hors ligne, local) | Absent | Élevée | S | Faible | P1 finition | **V1** |
| 3 | Page Aide courte (appui long, expansion, backup) | Partiel (backup seulement) | Élevée | S | Faible | P1 finition | **V1** |
| 4 | Splash aligné marque (fond pétrole + icône) | Blanc générique | Moyenne–élevée | XS–S | Faible | P2 | **V1** |
| 5 | Ligne « Aucune collecte / pas de réseau » sous Paramètres | Doc seule | Moyenne | XS | Faible | P2 | **V1** |

---

## 8. Améliorations facultatives (Groupe B)

| Amélioration | État actuel | Valeur | Effort | Risque | Priorité | V1/V2 |
|---|---|---|---|---|---|---|
| Adaptive icon / monochrome Android 13+ | PNG classiques | Moyenne | S | Faible | P3 | Facultatif / V1.1 |
| Licence OSS (écran licences Drift etc.) | Absent | Faible–moyenne | S | Faible | P3 | Facultatif |
| Notes de version dans À propos | Absent | Faible | XS | Faible | P3 | Facultatif |
| Email / « Signaler un problème » | Absent | Faible | XS | Faible | P3 | Facultatif |
| Passer revue Semantics TalkBack ciblée | Partiel | Moyenne | S–M | Faible | P3 | Facultatif |
| Harmoniser `06-ux-ui.md` (retirer bottom nav) | Doc obsolète | Doc | XS | Nul | — | Doc |

---

## 9. Backlog V2 périphérique (Groupe C)

| Amélioration | Valeur | Effort | Risque | Note |
|---|---|---|---|---|
| Thème clair / sombre / système | Moyenne | M | Moyen | Décision UX encore ouverte |
| Multilingue | Faible pour usage perso | M | Moyen | FR suffit V1 |
| Onboarding animé | Faible | M–L | Moyen | Contredit simplicité |
| Widgets écran d’accueil | Faible | L | Moyen | Hors besoin |
| Télémétrie / crash cloud | Contre-productif | — | — | À éviter |
| Compte / sync | Hors périmètre | — | — | Reporté historiquement |

---

## 10. Éléments volontairement inutiles pour Inventory

- Bottom Navigation Bar  
- FAQ longue ou chatbot  
- Tutoriel multi-étapes obligatoire  
- Paramètres de personnalisation visuelle excessifs  
- Notifications push  
- Compte, cloud, analytics, publicité  
- Drawer latéral à quatre destinations  
- « Centre d’aide » web dépendant du réseau  

---

## 11. Recommandation finale de clôture V1

### Verdict

**FINITION V1 RECOMMANDÉE**

Les fonctions métier et la confiance **technique** (local, backup, permissions) sont matures. La maturité **perçue** (icône, identité, version, aide minimale) manque encore pour une livraison soignée.

### Trois meilleures actions maintenant

1. **Icône Inventory** dédiée (plus de logo Flutter).  
2. **À propos + version/build** dans Paramètres.  
3. **Page Aide courte** (gestes + sauvegarde) + splash aux couleurs de la marque.

### Reporter à V2

Thème sombre/système, i18n, licences OSS avancées, canaux support élaborés.

### Abandonner

Bottom nav, onboarding lourd, FAQ encyclopédique, télémétrie, paramètres gadgets.

### Décision proposée

**Effectuer un dernier mandat de finition limité (Groupe A, ≤ 5 items)** avant de déclarer V1 « aboutie » pour distribution APK.  
**Livrer maintenant** uniquement si le destinataire accepte une app personnelle au look Flutter par défaut et sans version affichée.

---

## Réponses aux 10 questions (synthèse)

1. À propos : **oui, courte**.  
2. FAQ : **non**.  
3. Première utilisation : **non** ; aide consultable oui.  
4. Bottom nav : **non**.  
5. Paramètres manquants : version / à propos / aide (pas de thème obligatoire).  
6. Identité : UI OK, **lanceur non**.  
7. Confidentialité : textes backup OK + résumé local ; support minimal optionnel.  
8. A11y V1 : revue TalkBack légère, pas de refonte.  
9. ROI : icône → à propos/version → aide → splash.  
10. Livrer sans : **oui en privé** ; **non pour une image « produit fini »**.

---

**ARRÊT OBLIGATOIRE.** Aucune implémentation. Attendre la décision du propriétaire.
