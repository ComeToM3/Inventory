import '../core/domain/inventory_models.dart';

abstract final class AppStrings {
  static const appTitle = 'Inventory';
  static const inventory = 'Inventaire';
  static const search = 'Recherche';
  static const history = 'Historique';
  static const settings = 'Paramètres';
  static const inventoryEmpty = 'Aucun emplacement pour le moment.';
  static const inventoryLoading = 'Chargement de l’inventaire…';
  static const inventoryReadError = 'Impossible de charger l’inventaire.';
  static const branchLoading = 'Chargement du contenu…';
  static const branchReadError = 'Impossible de charger ce contenu.';
  static const retry = 'Réessayer';
  static const locationType = 'Emplacement';
  static const containerType = 'Contenant';
  static const itemType = 'Bien';
  static const itemContainerType = 'Bien-contenant';
  static const add = 'Ajouter';
  static const addRootLocation = 'Ajouter un emplacement';
  static const addRootLocationTooltip = 'Ajouter un emplacement principal';
  static const addItem = 'Ajouter un bien';
  static const addContainer = 'Ajouter un contenant';
  static const chooseParent = 'Choisir un emplacement';
  static const chooseParentHelp =
      'Ouvrez une branche, puis choisissez un emplacement ou un contenant.';
  static const createTitle = 'Nouvel élément';
  static const rootLocation = 'Emplacement principal';
  static const nodeType = 'Type';
  static const nodeName = 'Nom';
  static const nameRequired = 'Saisissez un nom.';
  static const create = 'Créer';
  static const creating = 'Création…';
  static const cancel = 'Annuler';
  static const creationSuccess = 'Élément ajouté.';
  static const creationError = 'Impossible d’ajouter cet élément. Réessayez.';
  static const parentUnavailable =
      'Cet emplacement n’est plus disponible. '
      'Annulez et choisissez un autre emplacement.';
  static const discardTitle = 'Abandonner la création ?';
  static const discardMessage =
      'Les informations saisies ne seront pas enregistrées.';
  static const continueEditing = 'Continuer';
  static const discard = 'Abandonner';
  static const detailsTitle = 'Fiche';
  static const detailsLoading = 'Chargement de la fiche…';
  static const detailsReadError = 'Impossible de charger cette fiche.';
  static const nodeUnavailable = 'Cet élément n’est plus disponible.';
  static const edit = 'Modifier';
  static const editTitle = 'Modifier l’élément';
  static const nodeDescription = 'Description';
  static const nodeCondition = 'État';
  static const nodeQuantity = 'Quantité';
  static const nodeParent = 'Emplacement parent';
  static const nodePath = 'Chemin complet';
  static const nodeCategories = 'Catégories';
  static const categoriesLoading = 'Chargement des catégories…';
  static const categoriesReadError = 'Impossible de charger les catégories.';
  static const addCategory = 'Ajouter une catégorie';
  static const newCategoryName = 'Nom de la nouvelle catégorie';
  static const categoryNameRequired = 'Saisissez un nom de catégorie.';
  static const pendingCategoryName =
      'Ajoutez cette catégorie ou effacez son nom avant d’enregistrer.';
  static const categoryCreatedOnSave =
      'Les nouvelles catégories seront créées à l’enregistrement.';
  static const valuationMode = 'Mode de valorisation';
  static const financialMode = 'Financier';
  static const sentimentalMode = 'Sentimental';
  static const financialInput = 'Montant unitaire (CAD)';
  static const financialInvalid =
      'Saisissez un montant positif ou nul avec au plus deux décimales.';
  static const sentimentalInput = 'Note sentimentale';
  static const sentimentalRequired = 'Choisissez une note de 1 à 5.';
  static const valuationChangeNotice =
      'Seule la valeur du mode choisi sera conservée.';
  static const financialUnitValue = 'Valeur financière par unité';
  static const financialTotalValue = 'Total financier';
  static const sentimentalValue = 'Valeur sentimentale';
  static const quantityInvalid =
      'Saisissez un nombre entier supérieur ou égal à 1.';
  static const financialTotalOverflow = 'Le total financier est trop élevé.';
  static const editDiscardTitle = 'Abandonner les modifications ?';
  static const editSuccess = 'Modifications enregistrées.';
  static const editError =
      'Impossible d’enregistrer les modifications. Réessayez.';
  static const move = 'Déplacer';
  static const chooseDestination = 'Choisir la destination';
  static const destination = 'Destination';
  static const inventoryRoot = 'Racine de l’inventaire';
  static const parentLevel = 'Niveau précédent';
  static const currentDestination = 'Emplacement actuel';
  static const noMoveDestinations = 'Aucune autre destination disponible ici.';
  static const noChildDestinations = 'Aucun sous-emplacement ou contenant.';
  static const destinationReadError =
      'Impossible de charger les destinations. Réessayez.';
  static const moveHere = 'Déplacer ici';
  static const moving = 'Déplacement…';
  static const confirmMove = 'Confirmer le déplacement ?';
  static const moveWithContents =
      'Cet élément et tous ses descendants seront déplacés ensemble.';
  static const moveSuccess = 'Élément déplacé.';
  static const moveError = 'Impossible de déplacer cet élément. Réessayez.';
  static const invalidDestination =
      'Cette destination n’est plus disponible ou ne peut pas recevoir cet élément. '
      'Choisissez une autre destination.';
  static const cyclicDestination =
      'Un élément ne peut pas être déplacé dans lui-même ou dans son contenu.';
  static const searchByName = 'Rechercher par nom';
  static const clearSearch = 'Effacer la recherche';
  static const searchInitial = 'Saisissez un nom ou choisissez un filtre.';
  static const searchLoading = 'Recherche en cours…';
  static const searchEmpty = 'Aucun élément actif ne correspond.';
  static const searchReadError = 'Impossible d’effectuer la recherche.';
  static const searchFilters = 'Filtres';
  static const searchFiltersHelp = 'Les critères sélectionnés se combinent.';
  static const searchNoFilters = 'Tous les types, catégories et emplacements';
  static const allNodeTypes = 'Tous les types';
  static const allCategories = 'Toutes les catégories';
  static const allBranches = 'Tous les emplacements';
  static const chooseSearchBranch = 'Choisir une branche';
  static const searchBranchHelp =
      'La recherche inclut tous les descendants de la branche choisie.';
  static const searchHere = 'Rechercher dans cette branche';
  static const noSearchBranches = 'Aucun emplacement ou contenant à ce niveau.';
  static const searchBranchReadError = 'Impossible de charger cette branche.';
  static const searchBranchUnavailable =
      'La branche sélectionnée n’est plus disponible. '
      'Choisissez-en une autre ou réinitialisez les filtres.';
  static const searchCategoryUnavailable =
      'La catégorie sélectionnée n’est plus disponible. '
      'Choisissez-en une autre ou réinitialisez les filtres.';
  static const unavailableCategory = 'Catégorie indisponible';
  static const resetFilters = 'Réinitialiser les filtres';
  static const historyComingSoon =
      'Vous pourrez consulter les biens retirés ici prochainement.';
  static const settingsComingSoon =
      'Les paramètres seront disponibles prochainement.';

  static const screenTitle = 'Vérification locale';
  static const description =
      'Cette valeur sert uniquement à vérifier la persistance locale.';
  static const loading = 'Ouverture de la base locale…';
  static const databaseReady = 'Base locale prête.';
  static const databaseOpenError =
      'La base locale ne peut pas être ouverte. Fermez puis relancez '
      'l’application.';
  static const noSavedValue = 'Aucune valeur de vérification enregistrée.';
  static const savedValueLabel = 'Valeur enregistrée :';
  static const inputLabel = 'Valeur de vérification';
  static const save = 'Enregistrer';
  static const saving = 'Enregistrement…';
  static const saveSuccess = 'Valeur enregistrée.';
  static const saveError = 'La valeur n’a pas pu être enregistrée.';

  static String quantity(int value) => '× $value';
  static String addInside(String name) => 'Ajouter dans $name';
  static String chooseInside(String name) => 'Choisir $name';
  static String viewNode(String name) => 'Fiche de $name';
  static String parentName(String name) => 'Dans : $name';
  static String cad(int cents) =>
      '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')} \$ CAD';
  static String sentimentalRating(int rating) => '$rating / 5';
  static String removeCategory(String name) => 'Retirer la catégorie $name';
  static String categoryIdentity(String name, String id) => '$name · $id';
  static String searchResultDescription(
    NodeType type,
    int? count,
    String path,
  ) =>
      '${labelForNodeType(type)}${count != null && count > 1 ? ' · ${quantity(count)}' : ''}\n$path';
  static String moveTo(String name, String path) =>
      'Déplacer « $name » vers :\n$path';
  static String initialItemValues(int quantity, int cents) =>
      'Quantité initiale : $quantity\n'
      'Valeur financière initiale : ${cad(cents)}';

  static String labelForNodeType(NodeType type) => switch (type) {
    NodeType.location => locationType,
    NodeType.container => containerType,
    NodeType.item => itemType,
    NodeType.itemContainer => itemContainerType,
  };
}
