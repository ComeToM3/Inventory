# 06 — Spécification UX/UI d'Inventory V1 Android

## 1. Objectif et principes UX

Ce document décrit les parcours, écrans et états nécessaires à l'utilisation d'Inventory V1 sur Android. Il guide une future interface Flutter sans figer de maquette, de palette ou de dimensions visuelles. Le thème sombre bleu-vert mentionné dans la feuille de route n'est pas une décision utilisateur confirmée; le choix du thème reste ouvert.

Principes :

- Présenter l'inventaire comme une organisation physique, pas comme un outil comptable.
- Employer des libellés simples et des actions explicites, utilisables sans connaissance technique.
- Rendre visibles la localisation, la quantité et le mode de valorisation d'un bien.
- Préserver les données : demander confirmation pour les opérations irréversibles, refuser les opérations invalides et expliquer comment poursuivre.
- Afficher l'état enregistré sans délai après une modification réussie.
- Rester entièrement utilisable hors ligne, sans compte, service distant ou synchronisation.
- Ne pas inclure de photos, QR, suivi de vente, restauration individuelle des biens retirés ou autres fonctions hors V1.

Les éléments marqués **Confirmé** reprennent les décisions UX du mandat et les règles métier approuvées. Les éléments marqués **Recommandation** proposent une expérience cohérente lorsque les documents ne fixent pas le détail. Les **Points à arbitrer** identifient les choix qui ne peuvent pas être présentés comme approuvés.

## 2. Navigation générale et carte des écrans

### Navigation principale

La barre inférieure comporte trois destinations :

| Destination | Écran racine | Rôle |
| --- | --- | --- |
| Inventaire | Arborescence de l'inventaire actif | Parcourir emplacements, contenants et biens ; créer et gérer les nœuds. |
| Recherche | Recherche globale | Retrouver des biens par nom, catégorie ou emplacement. |
| Historique | Biens retirés | Consulter les biens retirés, leur motif et leur date, en lecture seule. |

**Confirmé :** Inventaire est l'écran principal à l'ouverture. Paramètres sont accessibles séparément de la barre inférieure et contiennent notamment les opérations de sauvegarde et de restauration locales.

### Carte des écrans

```text
Inventaire
├── Arborescence (emplacements / contenants / biens)
├── Fiche d'un bien
│   ├── Modifier (formulaire complet)
│   ├── Déplacer (sélecteur de destination)
│   └── Plus d'actions
│       ├── Retirer de l'inventaire
│       └── Supprimer la fiche
├── Ajouter (+)
│   ├── Ajouter un bien
│   └── Ajouter un contenant
└── Actions secondaires : création d'emplacement et catégories (recommandation)

Recherche
├── Critères : nom, catégorie, emplacement
└── Résultat → fiche du bien

Historique
└── Fiche historique en lecture seule (recommandation)

Paramètres (accès séparé)
├── Sauvegarder l'inventaire
└── Restaurer une sauvegarde
```

Le bouton flottant « + » est présent dans Inventaire, en bas à droite, au-dessus de la barre de navigation. Il ouvre un choix entre **Ajouter un bien** et **Ajouter un contenant**. Ses dimensions, couleurs et animations restent à concevoir.

**Recommandation :** ouvrir Paramètres depuis une action clairement identifiable de l'écran Inventaire (par exemple le menu de l'application), sans ajouter une quatrième destination principale.

Les écrans de détail, de formulaire et de déplacement s'ouvrent au-dessus de leur écran d'origine. Le retour Android ramène au contexte précédent. Lorsqu'un écran comporte des changements non enregistrés, le retour demande s'il faut abandonner ou continuer la modification.

## 3. Arborescence et navigation dans les contenants

### Écran Inventaire

L'écran présente l'arborescence physique de l'inventaire actif :

- Les emplacements et contenants peuvent être dépliés directement dans la liste.
- Plusieurs branches peuvent rester ouvertes en même temps.
- Les biens simples sont visuellement distincts des éléments qui peuvent contenir des enfants ; la distinction ne repose pas uniquement sur la couleur.
- Un élément indique son nom et, si pertinent, sa quantité. L'ouverture de la fiche complète se fait en touchant un bien.
- Un contenant ouvert montre ses enfants directs ; les descendants restent accessibles par dépliage des sous-contenants.
- Les biens retirés ne sont jamais présentés dans cette arborescence.

**Conservation d'état — Confirmé :** en ouvrant une fiche puis en revenant, l'application restaure les branches ouvertes et la position de défilement précédentes. Après une modification enregistrée, le nœud concerné et les éléments affectés sont rafraîchis immédiatement, sans réinitialiser cette position.

### Profondeur et largeur

**Confirmé :** l'indentation est limitée pour préserver la largeur de l'écran, sans réduire la profondeur réelle de l'arbre.

**Recommandation :** au-delà du niveau d'indentation visuel maximal, maintenir l'indentation à sa limite et conserver l'ordre parent-enfant par l'alignement, les contrôles de dépliage et la présentation des enfants sous leur parent. Ne jamais aplatir ni déplacer visuellement un descendant dans une autre branche. La fiche et les résultats de recherche donnent accès au chemin complet quand la profondeur rend le contexte moins évident.

Les lignes doivent rester lisibles sur un petit écran et avec un texte agrandi. Un long nom peut passer sur plusieurs lignes ou être tronqué avec un moyen d'en lire le texte complet ; la valeur et l'identité du bien ne doivent pas être remplacées par une abréviation ambiguë.

### États de l'écran

- **Inventaire vide :** expliquer qu'aucun élément n'a été ajouté et proposer les actions de création utiles. La création du premier emplacement racine doit être accessible.
- **Chargement :** afficher un indicateur discret uniquement si l'ouverture ou le rafraîchissement n'est pas immédiat.
- **Erreur de lecture :** présenter un message compréhensible et une action de réessai ; ne pas afficher l'état vide comme si les données avaient disparu.
- **Succès de création ou modification :** insérer ou actualiser la ligne à sa nouvelle place et confirmer brièvement l'enregistrement.

**Recommandation — création d'emplacements :** comme l'arbre possède des nœuds de type emplacement et que l'ajout flottant doit rester limité aux deux choix confirmés, proposer « Ajouter un emplacement » depuis l'état vide et une action secondaire clairement identifiable dans Inventaire. Un emplacement racine est créé sans parent ; tout autre emplacement doit respecter les règles de parentage du modèle.

## 4. Fiche détaillée d'un bien

### Accès et contenu

**Confirmé :** toucher un bien simple ouvre sa fiche complète sur un nouvel écran. Un bien pouvant contenir des enfants ouvre également une fiche de bien ; ses enfants restent consultables par l'arborescence.

La fiche affiche les informations disponibles du modèle, sans introduire de nouveau champ métier :

- nom ;
- emplacement actuel, présenté sous forme de chemin physique ;
- catégories, s'il y en a ;
- quantité ;
- valorisation active : montant en CAD ou note sentimentale ;
- description et état (`condition`), s'ils sont renseignés.

Un montant de 0 $ est affiché comme une valeur financière valide. Pour un lot en mode financier, distinguer clairement le montant unitaire du total informatif calculé à partir de la quantité. En mode sentimental, afficher la note de 1 à 5 sans commentaire.

Les catégories et la localisation sont indépendantes : changer l'un ne modifie pas l'autre.

### Actions

- **Modifier** ouvre le formulaire complet.
- **Déplacer** ouvre le sélecteur de destination, sans être confondu avec la modification des autres informations.
- **Plus d'actions** ouvre le menu de retrait ou de suppression définitive.

Après enregistrement, la fiche reflète immédiatement les nouvelles données. Après retour, l'arborescence revient à sa position antérieure. Si le bien a été déplacé, il est désormais visible dans sa nouvelle branche ; le retour conserve le contexte de navigation de départ autant que possible et ne simule pas que le bien est resté à son ancien emplacement.

**Recommandation :** lorsqu'une action réussie fait disparaître le bien de la branche consultée (déplacement, retrait ou suppression), afficher un bref message indiquant le résultat avant de revenir à l'arborescence.

## 5. Création rapide d'un bien ou d'un contenant

### Ajouter un bien

**Entrées :** bouton flottant « + », puis **Ajouter un bien** ; ou action d'ajout depuis un contenant.

Le formulaire rapide contient :

| Information | Comportement |
| --- | --- |
| Nom | Obligatoire ; ne peut être vide après suppression des espaces de début et de fin. |
| Emplacement | Obligatoire ; préselectionné si l'action part d'un contenant pouvant recevoir des enfants. Sinon, l'utilisateur choisit une destination. |
| Quantité | Initialisée à `1` ; entier strictement positif. |
| Valeur | Mode financier par défaut, montant initial `0 $ CAD`. |

**Confirmé :** les champs facultatifs sont accessibles sans être requis dans le parcours rapide. Ils peuvent être regroupés sous une section repliable « Informations facultatives » ou une action équivalente. Ils comprennent uniquement les propriétés prévues par le modèle, par exemple description, état, catégories ou mode sentimental.

Un bouton d'enregistrement explicite crée le bien. Le nouvel élément apparaît dans son emplacement immédiatement après réussite. Annuler revient à l'écran précédent sans créer de fiche. Si l'utilisateur a saisi des données, demander confirmation avant d'abandonner.

### Ajouter un contenant

**Entrées :** bouton flottant « + », puis **Ajouter un contenant** ; ou action contextuelle d'ajout depuis un parent.

Le formulaire demande le nom et l'emplacement parent, préselectionné lorsque l'action est contextuelle. L'emplacement parent doit être un emplacement ou un contenant actif qui peut contenir des enfants. Un bien simple ne peut pas être choisi.

**Recommandation pour le bien-contenant :** exposer dans le parcours d'ajout de bien une option simple indiquant si le bien peut aussi contenir d'autres éléments. Elle crée le type métier correspondant sans ajouter une propriété au modèle. Sa valeur par défaut devrait être désactivée pour conserver le parcours d'ajout courant d'un bien simple.

La création d'un emplacement racine est décrite à la section 3 et ne doit pas être confondue avec un contenant ordinaire.

### Validation et erreurs

- Nom vide : rester sur le formulaire, signaler le champ et demander un nom.
- Quantité invalide : expliquer qu'un nombre entier supérieur ou égal à 1 est requis.
- Destination supprimée, retirée ou devenue non valide : refuser l'enregistrement et demander une nouvelle destination.
- Échec d'enregistrement : conserver les valeurs saisies, afficher une erreur et permettre de réessayer ou d'annuler.
- Succès : fermer le formulaire et montrer le nouveau nœud dans la liste.

## 6. Modification d'un bien

### Parcours

Depuis la fiche, choisir **Modifier**. Un formulaire complet, sur un seul écran, regroupe les informations modifiables et enregistre uniquement après action explicite de l'utilisateur.

Sections recommandées :

1. **Informations** : nom, description et état, si ces informations sont utilisées.
2. **Catégories** : une ou plusieurs catégories existantes, avec accès simple à la création/gestion des catégories.
3. **Quantité** : entier positif.
4. **Valorisation** : choix exclusif entre Financier et Sentimental, valeur correspondante.

L'emplacement actuel est visible, mais n'est pas modifié dans ce formulaire : **Déplacer** est une action séparée. Le retrait et la suppression sont également séparés.

### Valorisation

- Le mode financier est sélectionné par défaut à la création et affiche `0 $ CAD`.
- Lorsqu'une quantité est supérieure à 1, libeller clairement le montant comme valeur par unité et montrer le total calculé à titre informatif.
- Le mode sentimental accepte seulement une note de 1 à 5, sans champ de texte associé.
- Le formulaire ne préremplit pas le nouveau mode avec l'ancienne valeur. Le changement de mode remplace l'ancienne valorisation conformément au modèle métier.
- Si l'utilisateur change de mode avant d'enregistrer, expliquer sobrement que seule la nouvelle valeur sera conservée. L'enregistrement de la nouvelle valeur et l'effacement de l'ancienne sont atomiques du point de vue utilisateur.

### Validation, enregistrement et annulation

- Le formulaire conserve les saisies si une validation ou un enregistrement échoue.
- Les erreurs sont affichées près du champ concerné et formulées sans jargon.
- Toute modification d'un lot met à jour immédiatement le total affiché ; un total qui ne peut être représenté correctement empêche l'enregistrement et est expliqué.
- Si l'enregistrement réussit, revenir à la fiche mise à jour et confirmer le succès.
- Si aucune valeur n'a changé, le retour ne demande pas de confirmation.
- Si des changements ne sont pas enregistrés, proposer **Continuer la modification** ou **Abandonner**. Abandonner revient à la fiche sans appliquer de changement.

Toutes les modifications soumises ensemble sont cohérentes et atomiques : l'utilisateur ne doit jamais voir une mise à jour partielle du nom, des catégories, de la quantité ou de la valeur.

## 7. Déplacement d'un bien ou d'un contenant

### Parcours

**Entrée :** action **Déplacer** depuis la fiche du bien ou du contenant.

1. Afficher l'arborescence de destination.
2. Permettre de déplier les emplacements et contenants pour choisir un parent.
3. Exclure les biens simples, les nœuds retirés et le nœud déplacé lui-même de la sélection.
4. Pour un contenant, exclure également tous ses descendants, afin d'empêcher un cycle.
5. Après sélection, afficher le chemin complet de destination.
6. Demander une confirmation qui précise que le contenant et tous ses descendants seront déplacés ensemble.
7. Enregistrer et afficher le résultat dans la nouvelle localisation.

Un bien simple peut être déplacé dans une destination qui peut contenir des éléments. Un bien-contenant ou contenant peut être déplacé comme un seul nœud parent ; son contenu suit sans altérer ses catégories, quantités ou valeurs.

### Annulation et erreurs

- Avant confirmation, l'utilisateur peut revenir à la sélection ou annuler sans modification.
- Si la destination est devenue invalide ou entraînerait une boucle, refuser l'opération, garder les données inchangées et expliquer la cause.
- Si l'écriture échoue, ne pas présenter le déplacement comme réussi ; permettre une nouvelle tentative.
- Après succès, actualiser la branche de départ et la destination. Ne pas obliger l'utilisateur à rouvrir l'application.

## 8. Retrait et suppression

Ces actions se trouvent dans **Plus d'actions** sur la fiche. Elles utilisent des parcours et confirmations distincts.

### Retirer de l'inventaire

1. Choisir **Retirer de l'inventaire**.
2. Sélectionner un motif obligatoire : **Perte**, **Don**, **Bris** ou **Vente**.
3. Afficher une confirmation explicite indiquant que le bien disparaîtra de l'inventaire actif et restera consultable dans l'historique avec son motif et sa date.
4. Confirmer le retrait.
5. Après succès, fermer la fiche et confirmer que le bien a été retiré.

Annuler à l'étape du motif ou de confirmation ne modifie aucune donnée. Aucun prix de transaction ou renseignement comptable n'est demandé.

### Supprimer la fiche

1. Choisir **Supprimer la fiche**.
2. Présenter un avertissement distinct : la suppression est définitive et aucun historique ne sera conservé.
3. Confirmer explicitement ou annuler.
4. En cas de succès, supprimer la fiche de l'inventaire et confirmer l'opération.

Cette action est réservée à une fiche créée par erreur. L'interface ne la présente pas comme une variante de retrait.

### Nœud contenant des enfants

La règle métier D02 s'applique autant au retrait qu'à la suppression : un contenant non vide ne peut subir ni l'une ni l'autre. Pour l'action concernée, expliquer qu'il faut d'abord déplacer ou traiter explicitement les éléments contenus. Ne déplacer ni supprimer automatiquement les descendants. Une fois le contenu traité, l'utilisateur peut reprendre l'action.

Les erreurs d'écriture ou de validation laissent l'élément dans son état initial et ne doivent jamais produire un message de succès.

## 9. Recherche

### Écran et critères

La recherche est une destination principale. Elle permet de retrouver des biens actifs :

- par nom ;
- par catégorie ;
- par emplacement, incluant les biens contenus à toute profondeur.

**Recommandation :** présenter un champ de recherche par nom, avec des filtres secondaires explicites pour catégorie et emplacement. Ne pas rendre les filtres obligatoires pour une recherche par nom.

### Résultats

Chaque résultat de bien présente assez d'information pour distinguer des noms similaires : nom, chemin physique complet, quantité si supérieure à un, catégories pertinentes et valeur active si l'espace le permet. Toucher le résultat ouvre la fiche.

Le chemin commence à l'emplacement racine et se termine au bien. Il est présenté de manière lisible sur petit écran, par exemple sur plusieurs lignes si nécessaire, sans masquer le nom de la destination.

### États

- **Avant saisie :** expliquer comment chercher et, si utile, proposer les filtres.
- **Résultats :** afficher les biens actifs correspondant aux critères ; supprimer les doublons créés par plusieurs catégories.
- **Aucun résultat :** indiquer qu'aucun bien actif ne correspond et permettre de modifier/effacer les critères.
- **Erreur :** signaler que la recherche n'a pas abouti et proposer de réessayer.
- Les biens retirés ne sont jamais mélangés aux résultats actifs ; ils se consultent dans Historique.

Au retour depuis une fiche, préserver la recherche, les filtres et la position des résultats.

## 10. Historique

L'écran Historique présente les biens retirés, séparés de l'inventaire actif.

Chaque entrée indique au minimum le nom, le motif de retrait et la date. Toucher une entrée peut ouvrir un détail en lecture seule avec les informations encore conservées par le modèle.

**Confirmé :** l'historique n'est pas un second inventaire modifiable. Aucun bouton de restauration individuelle, de réactivation ou de déplacement d'un bien retiré n'est ajouté sans décision explicite.

Le modèle ne conserve pas de chemin de localisation historique : le détail ne doit donc pas inventer ni reconstruire l'ancien emplacement d'un bien retiré.

États :

- **Historique vide :** expliquer qu'aucun bien n'a été retiré.
- **Historique disponible :** présenter les retraits de façon compréhensible, sans actions de gestion d'inventaire actif.
- **Erreur de lecture :** afficher une erreur et un réessai, distincts de l'état vide.

**Recommandation :** trier les éléments du plus récent au plus ancien ; ce tri est une convention d'affichage, pas une règle métier approuvée.

## 11. Paramètres, sauvegarde et restauration

Les paramètres sont accessibles séparément de la navigation principale. Leur périmètre V1 pertinent ici est la sauvegarde et la restauration locales.

### Sauvegarder

1. Choisir **Sauvegarder l'inventaire**.
2. Expliquer que la sauvegarde contient l'inventaire complet, y compris les catégories, valeurs et biens retirés.
3. Laisser l'utilisateur choisir une destination locale et lancer l'export.
4. Afficher un résultat correspondant à la preuve obtenue : export vérifié après relecture conforme, ou export écrit mais non vérifiable si le fournisseur ne permet pas la relecture. Ne jamais présenter ce dernier comme vérifié.

Les états sont **Export vérifié**, **Export écrit, mais non vérifiable**, **Export échoué** et **Export annulé**. Pour un export écrit mais non vérifiable, avertir explicitement que le contenu distant n'a pas été relu et que sa validité ou sa conservation n'est pas garantie. En cas d'annulation du sélecteur, aucun changement n'est fait. En cas d'échec d'écriture, de fermeture ou de relecture, signaler clairement l'échec et permettre de réessayer.

### Restaurer

1. Choisir **Restaurer une sauvegarde** et sélectionner un fichier local.
2. Vérifier la lisibilité et l'intégrité de la sauvegarde avant de modifier l'inventaire actif.
3. Avertir que la restauration remplacera entièrement les données actives de l'appareil.
4. Demander une confirmation explicite avant le remplacement.
5. Valider les données restaurées avant activation, conformément à l'architecture et au modèle de données.
6. Après commit confirmé et vérifications prévues, confirmer le remplacement et afficher le nouvel inventaire.

Annuler avant confirmation ou refuser un fichier invalide, incompatible ou illisible laisse l'inventaire courant inchangé. Si la transaction échoue avant commit et que le rollback est confirmé, l'ancien inventaire est conservé. Si le commit a réussi mais que l'application a été interrompue avant d'afficher la confirmation, le nouvel inventaire est actif; au redémarrage, vérifier l'issue à l'aide du journal de restauration et annoncer le résultat correspondant. Si l'issue du commit est incertaine ou la base ne peut pas être vérifiée, ne pas annoncer que l'ancien inventaire a été conservé ni lancer une autre restauration; bloquer les écritures et signaler que la récupération est en cours ou requise, conformément à [docs/09-backup-recovery.md](09-backup-recovery.md).

**Recommandation :** utiliser le sélecteur de fichiers Android pour désigner une destination ou source locale. Le choix de l'API et le comportement des fournisseurs de fichiers Android restent à confirmer par l'implémentation ; l'application ne doit pas ajouter de compte, service cloud ou synchronisation.

## 12. États d'interface et gestion des erreurs

Tous les écrans concernés doivent distinguer un état réellement vide d'un échec de lecture. Les états de chargement ne sont montrés que pendant une opération en cours ; les opérations longues, comme la restauration, affichent une progression et empêchent une seconde soumission accidentelle.

| Situation | Comportement attendu |
| --- | --- |
| État vide | Dire ce qui manque et proposer l'action pertinente, sans ressembler à une erreur. |
| Chargement | Indiquer l'action en cours et éviter les commandes en double. |
| Validation invalide | Garder les saisies, identifier le champ et dire comment corriger. |
| Échec de lecture/écriture | Expliquer le résultat réellement vérifié ; permettre de réessayer quand c'est sûr. Pour une restauration, ne pas annoncer la conservation de l'ancien inventaire avant d'avoir confirmé le rollback ou résolu le résultat après récupération SQLite. |
| Succès | Confirmer l'action et actualiser les écrans concernés. |
| Annulation | Revenir à l'écran précédent sans appliquer une action non confirmée. |
| Restauration non appliquée | Après échec avant commit et rollback vérifié, maintenir l'ancien inventaire, signaler qu'il a été conservé et permettre de choisir un autre fichier. |
| Restauration commise sans confirmation affichée | Après récupération SQLite et vérification du journal `committed`, charger le nouvel inventaire et signaler que la restauration a été effectuée. |
| Issue de restauration non vérifiable | Ne pas annoncer de succès ou d'échec ni prétendre que l'ancien inventaire est intact; bloquer les écritures, préserver les fichiers et expliquer que l'état doit être vérifié. |

Les messages ne doivent pas révéler d'erreur SQL ou de détail technique. Ils doivent nommer l'action concernée, décrire son résultat réel et donner une prochaine étape. L'application ne doit jamais afficher un succès si la transaction a échoué.

Les confirmations sont réservées aux actions destructives ou au remplacement complet de l'inventaire. Les formulaires ordinaires utilisent plutôt une validation claire et une confirmation d'abandon seulement en présence de changements non enregistrés.

## 13. Accessibilité et ergonomie Android

Recommandations d'implémentation :

- Employer les composants et conventions de navigation Android/Material 3 déjà retenus pour Flutter, sans figer ici un thème visuel.
- Prévoir des zones d'interaction confortables, des libellés accessibles et un ordre de focus cohérent.
- Rendre les contrôles de dépliage, les menus et le bouton flottant utilisables avec TalkBack et les commandes d'accessibilité Android.
- Ne pas distinguer un bien simple, un contenant ou un statut uniquement par la couleur ; combiner libellé, icône ou forme et texte accessible.
- Maintenir un contraste suffisant et respecter les tailles de texte système, y compris l'agrandissement.
- Éviter les gestes cachés comme unique moyen d'ouvrir une fiche ou d'exécuter une action importante.
- Présenter les chemins et les erreurs en texte lisible, sans exiger une interprétation d'icônes seules.
- Tenir compte du clavier Android : champs numériques appropriés pour quantité et valeur, bouton suivant cohérent et accès au bouton d'enregistrement sans défilement excessif.
- Garder visibles les actions principales sur un écran de téléphone ; les actions rares et destructives restent dans « Plus d'actions ».

Ces points sont des critères de qualité UX, pas une validation finale de conformité réglementaire ou de certification d'accessibilité.

## 14. Scénarios de validation utilisateur

Les scénarios suivants doivent être observables dans l'application réelle sur Android. Des tests automatisés peuvent les compléter, mais ne remplacent pas la validation manuelle des parcours.

### Scénario 1 — Création et navigation physique

1. Depuis un inventaire vide, créer un emplacement racine.
2. Ajouter un contenant, puis un second contenant imbriqué.
3. Ajouter un bien depuis ce contenant et vérifier la préselection de l'emplacement.
4. Ajouter un bien-contenant et y ranger un bien ou un sous-contenant.
5. Déplier plusieurs branches, ouvrir une fiche puis revenir.

**Résultat observable :** la hiérarchie reflète les parents choisis, les distinctions entre éléments sont compréhensibles, les branches ouvertes et le défilement sont restaurés.

### Scénario 2 — Ajout rapide et modification

1. Ajouter un bien avec seulement son nom et emplacement.
2. Vérifier quantité initiale 1 et valeur financière initiale 0 $ CAD.
3. Ouvrir la fiche, compléter description ou catégories, modifier la quantité et enregistrer.
4. Passer du mode financier au mode sentimental puis enregistrer.
5. Quitter un formulaire modifié sans enregistrer et choisir d'abandonner.

**Résultat observable :** les champs facultatifs ne bloquent pas la création, la valeur 0 $ reste explicite, le changement de mode ne conserve pas l'ancienne valeur et les modifications non enregistrées ne sont pas appliquées silencieusement.

### Scénario 3 — Catégories et recherche

1. Associer plusieurs catégories à un bien.
2. Retrouver ce bien par nom puis par catégorie.
3. Filtrer par emplacement.
4. Ouvrir un résultat dont le nom ressemble à un autre.

**Résultat observable :** le résultat est identifiable, présente le chemin complet et mène à la fiche correcte ; les catégories restent intactes après un déplacement.

### Scénario 4 — Déplacement et prévention d'une boucle

1. Déplacer un contenant imbriqué vers une autre branche.
2. Vérifier le chemin proposé avant confirmation.
3. Tenter de sélectionner l'un de ses descendants comme destination.
4. Vérifier les biens et sous-contenants après le déplacement valide.

**Résultat observable :** la destination invalide n'est pas sélectionnable ou est refusée ; le déplacement valide conserve toute la descendance, les catégories, quantités et valeurs, sans déplacement partiel.

### Scénario 5 — Retrait, suppression et historique

1. Retirer un bien en choisissant chacun des motifs requis au cours d'essais distincts.
2. Vérifier sa disparition de l'inventaire actif et de la recherche active.
3. Le retrouver dans Historique avec motif et date.
4. Supprimer définitivement une fiche créée par erreur.
5. Tenter de retirer et supprimer un contenant non vide.

**Résultat observable :** le retrait et la suppression sont clairement distincts ; l'historique est en lecture seule ; la suppression ne laisse pas de fiche historique ; les actions sur contenant non vide sont bloquées et aucun descendant ne disparaît.

### Scénario 6 — Sauvegarde et restauration

1. Créer un inventaire comprenant plusieurs niveaux, catégories, valeurs et au moins un bien retiré.
2. Exporter une sauvegarde locale.
3. Choisir une sauvegarde valide et confirmer le remplacement.
4. Essayer également un fichier invalide ou annuler avant confirmation.

**Résultat observable :** la sauvegarde restaurée conserve les relations et l'historique ; une restauration invalide ou annulée ne modifie pas l'inventaire actif ; les messages indiquent clairement succès ou échec.

### Scénario 7 — Fonctionnement hors ligne et persistance

1. Utiliser l'application sans connexion réseau.
2. Créer ou modifier un bien, fermer complètement puis rouvrir l'application.

**Résultat observable :** navigation, lecture, écriture et recherche restent disponibles ; les modifications persistent après redémarrage.

## 15. Décisions confirmées, recommandations et points à arbitrer

### Confirmé

- Application Android, locale, hors ligne ; aucune synchronisation, aucun compte ni cloud applicatif.
- Barre inférieure : Inventaire, Recherche, Historique ; Paramètres séparés ; Inventaire principal.
- Arbre dépliable directement, plusieurs branches ouvertes, indentation limitée, distinction entre contenants et biens, conservation du contexte au retour.
- Fiche complète d'un bien sur un nouvel écran ; informations issues du modèle ; changements enregistrés immédiatement visibles.
- Formulaire de modification complet sur un écran, enregistrement explicite, validation et atomicité du point de vue utilisateur.
- Création rapide : nom, emplacement, quantité initiale 1 et valeur financière initiale 0 $ CAD ; champs facultatifs accessibles ; emplacement préselectionné si l'ajout part d'un contenant.
- Bouton flottant « + » au-dessus de la barre inférieure avec les choix Ajouter un bien et Ajouter un contenant.
- Déplacement séparé, chemin complet avant confirmation, descendants conservés et cycles empêchés.
- Retrait avec motif obligatoire parmi perte, don, bris, vente, confirmation et conservation de l'historique minimal ; suppression définitive distincte et irréversible.
- Historique consultable, non modifiable, sans restauration individuelle ; sauvegarde et restauration locales avec confirmation et gestion d'erreur.

### Recommandations non approuvées comme décisions produit

- Accès à Paramètres par une action secondaire de l'écran Inventaire.
- Actions secondaires pour créer un emplacement racine et accéder à la gestion des catégories, sans ajouter d'onglet principal.
- Option d'ajout pour indiquer qu'un bien peut aussi contenir des éléments, avec choix simple par défaut.
- Indentation plafonnée visuellement ; tri de l'historique du plus récent au plus ancien.
- Sélecteur de fichiers Android pour les opérations locales, à valider avec les exigences de stockage Android retenues.

### Points à arbitrer

**Aucun conflit bloquant** n'a été détecté entre les décisions UX du présent mandat et les documents PRD, fonctionnel, architecture, modèle de données et validation.

Les recommandations ci-dessus ne sont pas des décisions approuvées. Les détails visuels (mise en page, palette, densité, dimensions exactes du bouton flottant) et les modalités précises du sélecteur de fichiers restent ouverts à la conception d'interface et à l'implémentation ; ils ne bloquent pas la spécification des parcours.

