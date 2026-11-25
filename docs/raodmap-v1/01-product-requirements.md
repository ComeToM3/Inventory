# 01 — Product Requirements Document (PRD)

Statut des informations : **Confirmé** = décidé dans le blueprint · **Recommandation** = proposition à valider · **Ouvert** = à trancher.

**Recentrage V1 :** la V1 est désormais une application **Android exclusivement**, locale et hors ligne. La synchronisation entre appareils et l'application Windows sont retirées du périmètre V1 (voir [blueprint.md](blueprint.md), section 6, pour l'historique).

## 1. Finalité du produit

Inventory est une application personnelle Android permettant d'inventorier, classer, localiser et retrouver ses biens physiques, avec une valorisation financière ou sentimentale. *(Confirmé)*

L'application répond à quatre besoins :

| Besoin de l'utilisateur | Réponse de l'application |
| --- | --- |
| Qu'est-ce que je possède ? | Inventaire exhaustif des biens |
| Où se trouve cet objet ? | Localisation dans une arborescence de contenants |
| Qu'y a-t-il dans ce contenant ? | Consultation du contenu direct et indirect |
| Comment retrouver un objet rapidement ? | Recherche par nom, catégorie et emplacement |

## 2. Utilisateur et contexte d'usage

- Un seul utilisateur, usage strictement personnel, aucun compte ni multi-utilisateur. *(Confirmé)*
- Utilisation sur un téléphone Android, sans connexion Internet ni dépendance à un service distant. *(Confirmé)*
- Doit rester utilisable hors ligne en permanence. *(Confirmé)*

## 3. Fonctionnalités essentielles de la V1

| Fonctionnalité | Description |
| --- | --- |
| Inventaire | Créer, modifier, consulter les biens |
| Contenants imbriqués | Un contenant peut héberger des biens ou d'autres contenants, sur plusieurs niveaux |
| Catégories | Classification indépendante de l'emplacement physique |
| Recherche | Par nom, catégorie et emplacement, avec chemin physique complet |
| Déplacement | D'un bien seul ou d'un contenant avec tout son contenu |
| Quantités | Gestion de lots d'objets interchangeables |
| Valeur financière ou sentimentale | Un seul mode à la fois, mutuellement exclusifs : montant en dollars canadiens (CAD), 0 $ par défaut et parfaitement valide, ou note de 1 à 5 |
| Sortie d'inventaire | Retrait d'un bien (perte, don, bris, vente) avec historique minimal, ou suppression définitive d'une fiche créée par erreur |
| Mode hors ligne | Lecture et modification complètes, toujours disponible |
| Sauvegarde | Export et restauration locales |

## 4. Parcours utilisateurs principaux

| Parcours | Déroulé |
| --- | --- |
| A — Ajouter un bien | Choisir un contenant, saisir nom, catégorie, quantité et un mode de valorisation (financier à 0 $ par défaut, ou sentimental), enregistrer. L'objet apparaît immédiatement au bon emplacement. |
| B — Créer un contenant | Créer une boîte/armoire, lui donner un emplacement parent, puis y ranger des biens ou d'autres contenants. |
| C — Retrouver un objet | Rechercher par nom ou catégorie, obtenir le chemin physique complet jusqu'à l'objet. |
| D — Déplacer un contenant | Choisir un nouvel emplacement ; le contenant et tout son contenu suivent. |
| E — Retirer ou supprimer un bien | Retirer un bien de l'inventaire actif avec un motif (perte, don, bris, vente), ou le supprimer définitivement s'il a été créé par erreur. Un contenant non vide ne peut être ni retiré ni supprimé. |

## 5. Limites explicites de la V1

Hors périmètre V1 : comptabilité, amortissement, achats, garanties, assurance, statistiques patrimoniales avancées, reconnaissance automatique d'objets, intelligence artificielle, accès distant, gestion multi-utilisateur, application Windows, synchronisation entre appareils. *(Confirmé)*

## 6. Critères de réussite du point de vue utilisateur

L'application est réussie si l'utilisateur peut confirmer chacun des points suivants :

- Elle fonctionne réellement sur Android.
- Les biens et contenants persistent après fermeture de l'application.
- Les contenants peuvent être imbriqués sur plusieurs niveaux.
- Un déplacement conserve tout le contenu du contenant déplacé.
- La recherche retrouve un objet et affiche son chemin complet.
- Un bien est valorisé selon un seul mode à la fois (financier ou sentimental), sans report de l'ancienne valeur lors d'un changement de mode.
- Un bien peut être retiré de l'inventaire actif (perte, don, bris, vente) ou supprimé définitivement s'il a été créé par erreur.
- Une suppression ou un retrait ne fait jamais disparaitre silencieusement un contenu : un contenant non vide ne peut être ni retiré ni supprimé.
- Une sauvegarde peut être restaurée sur une installation propre.

## Décision confirmée — D01 : photos et codes QR

**Décision (D01) :** les photos et codes QR sont **exclus de la V1**. *(Confirmé)*

Ils pourront être envisagés dans une version ultérieure.

## Décision confirmée — D06 : exclusivité des modes de valorisation

**Décision (D06) :** un bien ne peut porter qu'**un seul mode de valorisation à la fois**, financier ou sentimental. *(Confirmé)*

Le mode financier est proposé par défaut avec un montant de 0 $, qui est une valeur valide. 0 $ n'est jamais traité comme « non renseigné ». Le changement de mode ne conserve pas l'ancienne valeur.

## Décision confirmée — D07 : sortie d'inventaire

**Décision (D07) :** un bien peut être **retiré** de l'inventaire actif avec un motif (perte, don, bris, vente), conservant un historique minimal sans être affiché dans l'inventaire actif, ou **supprimé définitivement** s'il s'agit d'une fiche créée par erreur. *(Confirmé)*

Aucun système comptable, suivi de transactions, gestion d'assurance ou rapport financier n'est introduit. La règle D02 (contenant non vide non supprimable) s'applique également au retrait.

## Points nécessitant une décision

Aucun point ouvert restant pour ce document.
