# 02 — Spécification fonctionnelle

Statut des informations : **Confirmé** = décidé dans le blueprint · **Recommandation** = proposition à valider · **Ouvert** = à trancher.

Ce document précise le comportement concret attendu pour chaque action possible sur un bien ou un contenant. Il ne décrit pas les mécanismes techniques internes (voir [03-technical-architecture.md](03-technical-architecture.md)).

**Recentrage V1 :** l'application est Android uniquement et fonctionne sans synchronisation ni second appareil. Les règles liées à la synchronisation concurrente ont été retirées de ce document.

## 1. Modèle de base

Tout élément de l'inventaire est un **nœud** (`Node`), de l'un des types suivants : *(Confirmé)*

| Type | Exemple | Peut contenir des éléments |
| --- | --- | --- |
| Emplacement | Appartement, bureau | Oui |
| Contenant | Armoire, boîte, tiroir | Oui |
| Bien simple | Livre, câble, outil | Non |
| Bien-contenant | Valise, boîte à outils | Oui |

Un bien peut changer de contenant sans jamais changer de catégorie : l'emplacement et le classement sont deux notions indépendantes. *(Confirmé)*

## 2. Création d'un bien ou d'un contenant

- Un nouveau nœud doit toujours avoir un contenant parent, sauf la racine de l'inventaire (un emplacement racine de type « Appartement », par exemple).
- Un bien simple ne peut recevoir aucun enfant : il n'est pas proposé comme destination lors d'un rangement.
- La création demande au minimum : un nom, un type de nœud, un emplacement parent. La catégorie et la quantité sont optionnelles mais recommandées.
- Un nouvel objet apparaît immédiatement dans l'arborescence, à l'endroit choisi.

## 3. Modification

- Le nom, la description, l'état (`condition`), la catégorie et la quantité d'un nœud peuvent être modifiés à tout moment.
- Modifier un bien ne change pas son historique de localisation antérieure ; seule sa position actuelle est affichée.

## 4. Classement par catégories

- Les catégories servent uniquement à classer les biens par nature (ex. « électronique », « outillage »).
- Les catégories ne dépendent jamais de l'emplacement physique : déplacer un bien ne modifie pas sa catégorie, et inversement.
- Un bien peut appartenir à une ou plusieurs catégories.

## 5. Rangement et déplacement

- Déplacer un contenant déplace logiquement tous ses descendants (biens et sous-contenants), sans exception.
- Un nœud ne peut jamais devenir son propre ancêtre : toute opération qui créerait une boucle hiérarchique est **refusée**, et les données existantes restent inchangées.
- Un bien simple ne peut pas devenir un contenant de destination.
- Toute opération de déplacement est transactionnelle : elle réussit entièrement, ou échoue entièrement sans modification partielle.

## 6. Recherche

- La recherche fonctionne par nom, par catégorie et par emplacement.
- Un résultat de recherche affiche le chemin physique complet jusqu'à l'objet (ex. *Appartement → Bureau → Armoire → Boîte électronique → Bloc EVGA*).

## 7. Quantités et objets uniques

- Les quantités concernent des lots d'objets interchangeables (ex. 4 câbles USB-C identiques), représentés par une seule fiche avec un nombre.
- Un objet unique possédant un numéro de série ou un historique individuel doit posséder sa propre fiche distincte, même si un objet similaire existe ailleurs.

## 8. Valeur financière et valeur sentimentale

- Chaque bien est valorisé selon **un seul des deux modes suivants, mutuellement exclusifs** : financier ou sentimental. *(Confirmé)*
- Mode financier (proposé par défaut) : montant en dollars canadiens (CAD), initialisé à 0 $. Une valeur de 0 $ est parfaitement valide et modifiable librement à tout moment ; elle n'est jamais traitée comme « non renseignée ».
- Mode sentimental : note de 1 à 5, sans commentaire ni note textuelle.
- L'utilisateur peut changer de mode à tout moment. Lors d'un changement de mode, l'ancienne valeur n'est plus active : elle n'est ni affichée, ni comptabilisée, ni conservée dans l'autre mode. Un bien ne peut jamais porter simultanément les deux modes.
- La valeur sentimentale n'est jamais convertie en montant financier, et inversement.
- Pour un lot d'objets identiques (quantité > 1) en mode financier, le montant saisi est le prix unitaire ; un total (quantité × prix unitaire) est affiché à titre indicatif.
- Le mode actif et sa valeur restent visibles et modifiables depuis l'écran de consultation et l'écran de modification d'un bien.

## 9. Retrait et suppression

- Une suppression ou un retrait ne doit jamais faire disparaître silencieusement les objets contenus dans un contenant.
- **Décision confirmée (D02) :** la suppression ou le retrait d'un contenant non vide est **bloqué**. *(Confirmé)*
- L'utilisateur doit déplacer ou traiter explicitement chaque élément du contenu avant de pouvoir retirer ou supprimer le contenant.
- Aucun déplacement automatique du contenu et aucune suppression en cascade ne sont effectués.
- **Retrait de l'inventaire actif (D07) :** un bien peut être retiré avec un motif obligatoire parmi perte, don, bris ou vente. Le bien retiré disparaît de l'inventaire actif, mais un historique minimal (nom, motif, date de retrait) est conservé sans être affiché dans les listes actives. *(Confirmé)*
- **Suppression définitive :** une fiche créée par erreur peut être supprimée définitivement, sans conserver d'historique. *(Confirmé)*
- Aucun système comptable, suivi de transactions, gestion d'assurance ou rapport financier avancé n'est introduit par le retrait ou la suppression.

## Points nécessitant une décision

Aucun point ouvert restant pour ce document. La règle de suppression (D02) s'applique également au retrait (D07), introduit dans la section 9.
