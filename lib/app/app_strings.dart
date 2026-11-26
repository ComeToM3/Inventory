import '../core/domain/inventory_models.dart';
import '../core/domain/purchase_models.dart';
import '../core/domain/stock_quantity.dart';

abstract final class AppStrings {
  static const appTitle = 'Inventory';
  static const inventory = 'Inventaire';
  static const spaceGoods = 'Biens';
  static const spaceStock = 'Stock';
  static const spaceToBuy = 'À acheter';
  static const search = 'Recherche';
  static const history = 'Historique';
  static const settings = 'Paramètres';
  static const advancedInformation = 'Informations avancées';
  static const showAdvancedByDefault =
      'Afficher les informations avancées par défaut';
  static const showAdvancedByDefaultHelp =
      'S’applique uniquement aux nouvelles fiches. '
      'Chaque fiche conserve ensuite son propre état.';
  static const barcodeOrReference = 'Référence ou code-barres';
  static const barcodeOrReferenceHint = 'Facultatif';
  static const purchaseDate = 'Date d’achat';
  static const purchaseDateHint = 'Facultatif';
  static const purchaseDateInvalid = 'Indiquez une date valide.';
  static const clearPurchaseDate = 'Effacer la date';
  static const purchasePrice = 'Prix payé';
  static const purchasePriceHint =
      'Facultatif — n’affecte pas la valorisation du bien';
  static const purchasePlace = 'Lieu ou vendeur';
  static const purchasePlaceHint = 'Facultatif';
  static const expandBranch = 'Afficher le contenu';
  static const collapseBranch = 'Masquer le contenu';
  static const itemObjective = 'Objectif';
  static const objectiveNone = 'Aucun';
  static const objectiveSell = 'Vendre';
  static const objectiveRepair = 'Réparer';

  static String labelForObjective(ItemObjective objective) =>
      switch (objective) {
        ItemObjective.none => objectiveNone,
        ItemObjective.sell => objectiveSell,
        ItemObjective.repair => objectiveRepair,
      };

  static const mainPhoto = 'Photo principale';
  static const photoAndDocument = 'Photo et document';
  static const addPhotoGallery = 'Galerie';
  static const addPhotoCamera = 'Caméra';
  static const replacePhoto = 'Remplacer';
  static const removePhoto = 'Supprimer la photo';
  static const removePhotoConfirmTitle = 'Supprimer la photo ?';
  static const removePhotoConfirmBody =
      'La suppression sera appliquée à l’enregistrement de la fiche.';
  static const photoProcessing = 'Optimisation de la photo…';
  static const photoError = 'Impossible de traiter cette photo.';
  static const photoPermissionDenied = 'Permission refusée pour la photo.';

  static const supportingDocuments = 'Documents justificatifs';
  static const supportingDocumentsEmpty = 'Aucun document pour le moment.';
  static const addDocument = 'Ajouter un document';
  static const documentAction = 'Reçus';
  static const removeDocument = 'Retirer';
  static const removeDocumentConfirmTitle = 'Retirer ce document ?';
  static const removeDocumentConfirmBody =
      'Le retrait sera appliqué à l’enregistrement de la fiche.';
  static const documentProcessing = 'Ajout du document…';
  static const documentError = 'Impossible d’ajouter ce document.';
  static const documentTooLarge = 'Ce fichier dépasse la limite de 15 Mo.';
  static const documentUnsupportedType =
      'Format non pris en charge. Utilisez PDF, JPEG, PNG ou WebP.';
  static const documentOpenError =
      'Aucune application compatible n’est disponible pour ouvrir ce fichier.';
  static const documentMissing = 'Ce document n’est plus disponible.';

  static const iconPickerTitle = 'Icône';
  static const iconPickerSearch = 'Rechercher une icône';
  static const iconAutomaticGeneric = 'Automatique (générique)';
  static const iconAutomaticHelp =
      'Suit le nom tant qu’aucune icône n’est choisie manuellement.';
  static const chooseIcon = 'Choisir l’icône';
  static const iconManual = 'Icône manuelle';

  static String iconAutomaticNamed(String key) => 'Automatique ($key)';

  static String documentSizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
  static const inventoryEmpty = 'Aucun emplacement pour le moment.';
  static const stockEmpty = 'Aucun produit en stock pour le moment.';
  static const toBuyEmpty = 'Aucun besoin à acheter pour le moment.';
  static const needType = 'Article à acheter';
  static const newNeedTitle = 'Nouvel article à acheter';
  static const desiredQuantity = 'Quantité souhaitée';
  static const remainingQuantity = 'Quantité restante';
  static const targetPrice = 'Prix cible';
  static const paidPrice = 'Prix payé';
  static const purchaseAction = 'Acheté';
  static const purchaseTitle = 'Confirmer l’achat';
  static const purchaseSuccess = 'Achat enregistré.';
  static const purchaseError = 'Impossible d’enregistrer cet achat.';
  static const abandonNeed = 'Abandonner';
  static const abandonNeedConfirmTitle = 'Abandonner ce besoin ?';
  static const abandonNeedConfirmBody =
      'Il quittera la liste active. Aucun bien ni produit Stock ne sera créé.';
  static const abandonSuccess = 'Besoin abandonné.';
  static const purchaseHistoryEmpty = 'Aucun achat ni abandon pour le moment.';
  static const purchaseDestination = 'Destination';
  static const destinationGoods = 'Biens';
  static const destinationStock = 'Stock';
  static const stockLinkMode = 'Produit Stock';
  static const stockCreateNew = 'Créer un nouveau produit';
  static const stockKeepLevel = 'Associer — conserver le niveau';
  static const stockResetLevel = 'Associer — remettre à 1';
  static const chooseStockProduct = 'Choisir un produit existant';
  static const purchaseQuantity = 'Quantité acquise';
  static const goodsValuationOnPurchase = 'Valorisation du bien';
  static String labelForPurchaseEvent(PurchaseEventType type) =>
      switch (type) {
        PurchaseEventType.acquire => 'Achat',
        PurchaseEventType.abandon => 'Abandon',
      };
  static const stockQuantity = 'Quantité de référence';
  static const stockReferenceInvalid = 'Indiquez un entier ≥ 1, ou laissez vide.';
  static const stockRemainingLevel = 'Niveau restant';
  static const stockMovements = 'Historique';
  static const stockHistoryEmpty = 'Aucun changement pour le moment.';
  static const stockProductType = 'Produit';
  static const newStockProductTitle = 'Nouveau produit';
  static const stockLevelUpdated = 'Niveau mis à jour.';
  static String stockLevelChange(String from, String to) => '$from → $to';
  static String labelForStockMovement(StockMovementType type) =>
      switch (type) {
        StockMovementType.initial => 'Création',
        StockMovementType.supply => 'Approvisionnement',
        StockMovementType.consume => 'Consommation',
        StockMovementType.correct => 'Changement de niveau',
      };

  static String emptyMessageForSpace(InventorySpace space) => switch (space) {
    InventorySpace.goods => inventoryEmpty,
    InventorySpace.stock => stockEmpty,
    InventorySpace.toBuy => toBuyEmpty,
  };

  static String labelForSpace(InventorySpace space) => switch (space) {
    InventorySpace.goods => spaceGoods,
    InventorySpace.stock => spaceStock,
    InventorySpace.toBuy => spaceToBuy,
  };
  static const inventoryLoading = 'Chargement de l’inventaire…';
  static const inventoryReadError = 'Impossible de charger l’inventaire.';
  static const branchLoading = 'Chargement du contenu…';
  static const branchReadError = 'Impossible de charger ce contenu.';
  static const retry = 'Réessayer';
  static const locationType = 'Emplacement';
  static const itemType = 'Bien simple';
  static const itemContainerType = 'Bien-contenant';
  /// Unified goods creation entry (UX-01); internal types unchanged.
  static const goodsItemType = 'Bien';
  static const goodsItemExample = 'Ex. : Livre, Câble, Armoire, Boîte';
  static const isContainerLabel = 'Contenant';
  static const add = 'Ajouter';
  static const addRootLocation = 'Ajouter un emplacement';
  static const addRootLocationTooltip = 'Ajouter un emplacement principal';
  static const chooseParent = 'Choisir un emplacement';
  static const chooseParentHelp =
      'Ouvrez une branche, puis choisissez un emplacement ou un bien-contenant.';
  static const createTitle = 'Ajouter';
  static const chooseTypeTitle = 'Choisir le type';
  static const newLocationTitle = 'Nouvel emplacement';
  static const newItemTitle = 'Nouveau bien';
  static const newItemContainerTitle = 'Nouveau bien';
  static const rootLocation = 'Emplacement principal';
  static const hierarchyPosition = 'Position';
  static const quickAddLocation = 'Créer un emplacement';
  static const createAndContinue = 'Enregistrer et ajouter un autre';
  static const setFinancialPrice = 'Renseigner un prix';
  static const nodeType = 'Type';
  static const nodeName = 'Nom';
  static const itemNameLabel = 'Nom du bien';
  static const nameRequired = 'Saisissez un nom.';
  static String nameTooLong(int max) =>
      'Le nom ne peut pas dépasser $max caractères.';
  static const itemKindLabel = 'Nature du bien';
  static const itemKindHelp =
      'Un bien-contenant garde sa propre valeur et peut recevoir d’autres biens.';
  static const cannotConvertWithChildren =
      'Retirez ou déplacez d’abord le contenu avant de passer en bien simple.';
  static const parentRequired = 'Choisissez une position.';
  static const amountInvalid = 'Saisissez un montant valide.';
  static const create = 'Créer';
  static const creating = 'Création…';
  static const cancel = 'Annuler';
  static const creationSuccess = 'Élément ajouté.';
  static const dismissMessage = 'Fermer le message';
  static const creationError = 'Impossible d’ajouter cet élément. Réessayez.';
  static const parentUnavailable =
      'Cet emplacement n’est plus disponible. '
      'Annulez et choisissez un autre emplacement.';
  static const discardTitle = 'Abandonner la création ?';
  static const discardMessage =
      'Les informations saisies ne seront pas enregistrées.';
  static const continueEditing = 'Continuer';
  static const discard = 'Abandonner';
  static const detailsTitle = 'Bien';
  static const detailsLoading = 'Chargement de la fiche…';
  static const detailsReadError = 'Impossible de charger cette fiche.';
  static const nodeUnavailable = 'Cet élément n’est plus disponible.';
  static const edit = 'Modifier';
  static const editTitle = 'Modifier le bien';
  static const financialValueLabel = 'Valeur financière';
  static const sentimentalValueLabel = 'Valeur sentimentale';
  static const financialModeCad = 'Financière (CAD)';
  static const filterAll = 'Tous';
  static const filterItems = 'Biens simples';
  static const filterItemContainers = 'Biens-contenants';
  static const filterLocations = 'Emplacements';
  static const moreFilters = 'Autres filtres';
  static const withdrawAction = 'Retirer…';
  static const nodeCondition = 'État';
  static const nodeQuantity = 'Quantité';
  static const decreaseQuantity = 'Diminuer la quantité';
  static const increaseQuantity = 'Augmenter la quantité';
  static String qtyShort(int quantity) => 'Qté : $quantity';
  static const nodeParent = 'Emplacement parent';
  static const nodePath = 'Chemin complet';
  static const valuationMode = 'Mode de valorisation';
  static const valuationNone = 'Aucune valorisation';
  static const financialMode = 'Financier';
  static const sentimentalMode = 'Sentimental';
  static const financialInput = 'Montant unitaire (CAD)';
  static const financialInvalid =
      'Saisissez un montant positif ou nul avec au plus deux décimales.';
  static const sentimentalInput = 'Note sentimentale';
  static const sentimentalRequired = 'Choisissez une note de 1 à 5.';
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
  static const destination = 'Destination';
  static const inventoryRoot = 'Racine de l’inventaire';
  static const parentLevel = 'Niveau précédent';
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
  static const searchNoFilters = 'Tous les types et emplacements';
  static const allNodeTypes = 'Tous les types';
  static const allBranches = 'Tous les emplacements';
  static const chooseSearchBranch = 'Choisir une branche';
  static const searchBranchHelp =
      'La recherche inclut tous les descendants de la branche choisie.';
  static const searchHere = 'Rechercher dans cette branche';
  static const noSearchBranches =
      'Aucun emplacement ou bien-contenant à ce niveau.';
  static const searchBranchReadError = 'Impossible de charger cette branche.';
  static const searchBranchUnavailable =
      'La branche sélectionnée n’est plus disponible. '
      'Choisissez-en une autre ou réinitialisez les filtres.';
  static const resetFilters = 'Réinitialiser les filtres';
  static const dropToRoot = 'Racine de l’inventaire';
  static const dragHint =
      'Ligne d’insertion = ordre. Sur un emplacement / contenant = y déposer.';
  static const moreActions = 'Plus d’actions';
  static const organizeReorderSuccess = 'Ordre mis à jour.';
  static const organizeReorderError = 'Impossible de modifier l’ordre.';
  static const withdrawFromInventory = 'Retirer de l’inventaire';
  static const deleteNode = 'Supprimer la fiche';
  static const chooseWithdrawalReason = 'Motif du retrait';
  static const withdrawalReasonRequired = 'Choisissez un motif de retrait.';
  static const continueAction = 'Continuer';
  static const confirmWithdraw = 'Confirmer le retrait ?';
  static const withdrawConfirmation =
      'Ce bien disparaîtra de l’inventaire actif et restera consultable '
      'dans l’historique avec son motif et sa date.';
  static const withdraw = 'Retirer';
  static const withdrawing = 'Retrait…';
  static const withdrawSuccess = 'Bien retiré de l’inventaire.';
  static const withdrawError = 'Impossible de retirer ce bien. Réessayez.';
  static const cannotWithdrawWithChildren =
      'Retirez d’abord le contenu de ce bien-contenant.';
  static const cannotDeleteWithChildren =
      'Supprimez d’abord le contenu de cet élément.';
  static const withdrawHasChildren =
      'Ce bien-contenant contient encore des éléments. '
      'Déplacez ou traitez d’abord son contenu, puis reprenez le retrait.';
  static const withdrawNotAllowed =
      'Seuls les biens et biens-contenants vides peuvent être retirés.';
  static const confirmDelete = 'Supprimer définitivement ?';
  static const deleteConfirmation =
      'Cette suppression est définitive. Aucun historique ne sera conservé.';
  static const delete = 'Supprimer';
  static const deleting = 'Suppression…';
  static const deleteSuccess = 'Fiche supprimée définitivement.';
  static const deleteError = 'Impossible de supprimer cette fiche. Réessayez.';
  static const permanentRootProtected =
      'L’emplacement Inventaire ne peut pas être supprimé ni déplacé.';
  static const deleteHasChildren =
      'Cet élément contient encore d’autres éléments. '
      'Déplacez ou traitez d’abord son contenu, puis reprenez la suppression.';
  static const historyLoading = 'Chargement de l’historique…';
  static const historyEmpty = 'Aucun bien n’a été retiré.';
  static const historyReadError =
      'Impossible de charger l’historique. Réessayez.';
  static const historyDetailsTitle = 'Fiche historique';
  static const historyDetailsLoading = 'Chargement de la fiche historique…';
  static const historyDetailsReadError =
      'Impossible de charger cette fiche historique.';
  static const historyUnavailable = 'Ce bien retiré n’est plus disponible.';
  static const withdrawalReason = 'Motif de retrait';
  static const withdrawnAt = 'Date de retrait';
  static const withdrawalReasonLoss = 'Perte';
  static const withdrawalReasonDonation = 'Don';
  static const withdrawalReasonBreakage = 'Bris';
  static const withdrawalReasonSale = 'Vente';

  static const saveInventory = 'Sauvegarder l’inventaire';
  static const backupPrivacyTitle = 'Fichier non chiffré';
  static const backupPrivacyMessage =
      'La sauvegarde contient l’inventaire complet : emplacements, biens, '
      'stock, besoins, valeurs, historiques, préférences, photos et '
      'documents associés. Le fichier n’est pas chiffré : toute personne y '
      'ayant accès pourrait consulter ces informations. Le fournisseur choisi '
      'peut aussi copier ou synchroniser le fichier. L’empreinte SHA-256 '
      'détecte une altération accidentelle ; ce n’est ni un chiffrement ni '
      'une preuve d’authenticité.';
  static const backupContinue = 'Choisir une destination';
  static const backupExporting = 'Préparation de la sauvegarde…';
  static const backupVerified =
      'Export vérifié : le fichier a été écrit et relu avec succès.';
  static const backupWrittenUnverified =
      'Export écrit, mais non vérifiable : l’écriture s’est terminée sans '
      'erreur, mais le fournisseur n’a pas permis de relire le contenu distant. '
      'La conservation ou la validité distante n’est pas garantie.';
  static const backupFailed =
      'Export échoué. L’inventaire actif n’a pas été modifié. '
      'Un fichier partiel peut subsister chez le fournisseur.';
  static const backupCancelled = 'Export annulé.';
  static const backupRetry = 'Réessayer';
  static const restoreInventory = 'Restaurer une sauvegarde';
  static const restoreHelp =
      'Choisissez un fichier .invbackup. Après validation, la restauration '
      'remplacera entièrement l’inventaire local. Il ne s’agit pas d’une fusion.';
  static const restoreConfirmTitle = 'Remplacer l’inventaire ?';
  static const restoreConfirmLead =
      'La restauration remplacera tout l’inventaire local actuel. '
      'Les données actuelles ne seront pas fusionnées avec la sauvegarde.';
  static const restoreConfirmAction = 'Remplacer';
  static const restoreValidating = 'Validation de la sauvegarde…';
  static const restoreApplying = 'Restauration en cours…';
  static const restoreSuccess =
      'Restauration effectuée. L’inventaire a été remplacé.';
  static const restoreCancelled = 'Restauration annulée.';
  static const restoreRejected =
      'Fichier de sauvegarde invalide ou incompatible. '
      'L’inventaire actuel n’a pas été modifié.';
  static const restoreIncompatible =
      'Fichier incompatible ou non reconnu. '
      'L’inventaire actuel n’a pas été modifié.';
  static const restoreCorrupted =
      'Fichier de sauvegarde corrompu ou incomplet. '
      'L’inventaire actuel n’a pas été modifié.';
  static const restoreMediaMissing =
      'Médias manquants ou incohérents dans la sauvegarde. '
      'L’inventaire actuel n’a pas été modifié.';
  static const restoreFailed =
      'La restauration a échoué. L’inventaire actuel n’a pas été modifié '
      'ou sera rétabli au prochain démarrage si une interruption a eu lieu.';
  static const restoreRetry = 'Réessayer';
  static const recoveryNotApplied =
      'La restauration n’a pas été appliquée. Votre inventaire précédent '
      'est conservé.';
  static const recoveryCompleted =
      'La restauration a été effectuée.';
  static const recoveryUnreliable =
      'L’inventaire n’a pas pu être vérifié. Les écritures sont bloquées. '
      'Conservez vos fichiers et restaurez depuis une sauvegarde valide.';
  static const recoveryAcknowledge = 'Continuer';

  static String restoreSummary({
    required String createdAtUtc,
    required int nodeCount,
    required int withdrawnCount,
  }) =>
      'Sauvegarde du $createdAtUtc\n'
      '$nodeCount élément(s), '
      '$withdrawnCount bien(s) retiré(s).';

  static const screenTitle = 'Vérification locale';
  static const persistenceCheckDescription =
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
  static String contentCount(int value) => '($value)';
  static String addInside(String name) => 'Ajouter dans $name';
  static String viewNode(String name) => 'Fiche de $name';
  static String parentName(String name) => 'Dans : $name';
  static String cad(int cents) =>
      '${cents ~/ 100},${(cents % 100).toString().padLeft(2, '0')} \$ CAD';
  static String compactFinancial(int quantity, int totalCents) =>
      '$quantity × ${cad(totalCents)}';
  static String compactSentimental(int quantity, int rating) =>
      '$quantity × ${sentimentalRating(rating)}';
  static const noFinancialTotal = 'Sans valeur financière';
  static const subtreeFinancialOverflowShort = 'Total hors limite';
  static String subtreeFinancialTotal(int cents) => cad(cents);
  static String sentimentalRating(int rating) => '$rating / 5';
  static String searchResultCount(int count) =>
      count <= 1 ? '$count résultat' : '$count résultats';
  static String searchResultDescription(
    NodeType type,
    int? count,
    String path,
  ) =>
      '${labelForNodeType(type)}${count != null && count > 1 ? ' · ${quantity(count)}' : ''}\n$path';
  static String initialItemValues(int quantity, int cents) =>
      'Quantité initiale : $quantity\n'
      'Valeur financière initiale : ${cad(cents)}';
  static String exampleForNodeType(NodeType type) => switch (type) {
    NodeType.location => 'Ex. : Appartement',
    NodeType.item => 'Ex. : Livre, Câble',
    NodeType.itemContainer => 'Ex. : Armoire, Boîte, Valise',
  };

  /// List trailing price, e.g. `25 $` or `1 250 $` (no decimals when whole).
  static String listPrice(int totalCents) {
    final dollars = totalCents ~/ 100;
    final formatted = dollars
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return '$formatted \$';
  }
  static String historyReasonDate(
    WithdrawalReason? reason,
    DateTime? withdrawnAt,
  ) {
    final parts = <String>[];
    if (reason != null) parts.add(labelForWithdrawalReason(reason));
    if (withdrawnAt != null) {
      final local = withdrawnAt.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      parts.add('$day/$month/${local.year}');
    }
    return parts.join(' · ');
  }

  static String labelForNodeType(NodeType type) => switch (type) {
    NodeType.location => locationType,
    NodeType.item => itemType,
    NodeType.itemContainer => itemContainerType,
  };

  static String labelForWithdrawalReason(WithdrawalReason reason) =>
      switch (reason) {
        WithdrawalReason.loss => withdrawalReasonLoss,
        WithdrawalReason.donation => withdrawalReasonDonation,
        WithdrawalReason.breakage => withdrawalReasonBreakage,
        WithdrawalReason.sale => withdrawalReasonSale,
      };

  static String formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  static String historyEntrySubtitle(
    NodeType type,
    WithdrawalReason? reason,
    DateTime? withdrawnAt,
  ) {
    final parts = <String>[labelForNodeType(type)];
    if (reason != null) parts.add(labelForWithdrawalReason(reason));
    if (withdrawnAt != null) parts.add(formatDateTime(withdrawnAt));
    return parts.join(' · ');
  }

  // —— Finition applicative (DEV-30) ——
  static const help = 'Aide';
  static const about = 'À propos';
  static const aboutTitle = 'À propos d’Inventory';
  static const aboutPublisher = 'ComeToM3';
  static const aboutDescription =
      'Inventory organise vos emplacements et vos biens sur cet appareil, '
      'sans compte et sans connexion requise pour l’usage quotidien.';
  static const aboutLocalTitle = 'Données et confidentialité';
  static const aboutLocalBody =
      'L’inventaire est stocké localement sur cet appareil. '
      'Vous contrôlez les sauvegardes et les restaurations via des fichiers '
      '.invbackup que vous choisissez. Conservez ces fichiers en lieu sûr : '
      'ils ne sont pas chiffrés par Inventory. '
      'La version distribuée ne demande pas de permission Internet pour '
      'fonctionner ; aucun compte ni synchronisation cloud n’est fourni.';
  static const aboutLicenses = 'Licences open source';
  static const aboutVersionUnavailable = 'Version indisponible';
  static String aboutVersionLine(String version, String build) =>
      'Version $version (build $build)';

  static const helpTitle = 'Aide';
  static const helpIntro =
      'Rappels courts pour utiliser Inventory. Les gestes ont été validés '
      'sur émulateur ; confirmez-les sur votre téléphone si besoin.';
  static const helpOrgTitle = 'Organisation';
  static const helpOrgBody =
      '• Emplacement : endroit (pièce, meuble…).\n'
      '• Bien simple : objet inventorié.\n'
      '• Bien-contenant : objet avec sa propre valeur éventuelle, '
      'qui peut aussi contenir d’autres biens.\n'
      'Tout s’organise en arbre : un parent reçoit des enfants.';
  static const helpBrowseTitle = 'Consultation';
  static const helpBrowseBody =
      'Le chevron d’un emplacement ou d’un bien-contenant ouvre ou ferme '
      'ses enfants. Sur un emplacement, toucher la ligne fait de même. '
      'Sur un bien (simple ou contenant), toucher la ligne ouvre ou ferme '
      'les informations complémentaires, sans changer l’état des enfants. '
      'Le crayon mène à la modification.';
  static const helpMoveTitle = 'Déplacement';
  static const helpMoveBody =
      'Appui long, maintenir, glisser, relâcher. Relâchez entre deux lignes '
      'pour changer l’ordre ; sur un emplacement ou un bien-contenant pour '
      'changer de parent. Un bandeau « Racine de l’inventaire » apparaît pour '
      'les éléments qui peuvent y revenir.';
  static const helpManageTitle = 'Gestion';
  static const helpManageBody =
      'Ajoutez depuis le bouton + ou le + d’une ligne. '
      'Modifiez depuis le résumé. '
      'Supprimez ou retirez un bien (avec motif) depuis l’écran de '
      'modification. L’historique liste les biens retirés.';
  static const helpBackupTitle = 'Sauvegarde';
  static const helpBackupBody =
      'Dans Paramètres : exportez un fichier .invbackup, puis conservez-le '
      'hors de l’application. La restauration remplace tout l’inventaire '
      'local (pas de fusion).';
}