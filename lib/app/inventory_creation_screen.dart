import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import '../core/domain/inventory_name.dart';
import '../core/domain/permanent_roots.dart';
import '../core/domain/stock_quantity.dart';
import '../core/media/goods_document_store.dart';
import '../core/media/goods_photo_store.dart';
import 'app_strings.dart';
import 'discard_changes_dialog.dart';
import 'goods_documents_field.dart';
import 'goods_main_photo_field.dart';
import 'inventory_action_bar.dart';
import 'inventory_icon_picker_sheet.dart';
import 'inventory_parent_field.dart';
import 'inventory_thumb_layout.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';
import 'inventory_valuation_field.dart';
import 'purchase_acquire_screen.dart';
import 'stock_history_screen.dart';

/// Creation and modification sheet (DEV-19 / DEV-25).
///
/// Pass [existing] to open the same UI in edit mode.
class InventoryCreationScreen extends StatefulWidget {
  const InventoryCreationScreen({
    super.key,
    required this.controller,
    required this.type,
    this.initialParent,
    this.existing,
    this.goodsController,
    this.stockController,
  });

  final InventoryTreeController controller;
  final NodeType type;
  final InventoryNode? initialParent;
  final InventoryNode? existing;
  final InventoryTreeController? goodsController;
  final InventoryTreeController? stockController;

  @override
  State<InventoryCreationScreen> createState() =>
      _InventoryCreationScreenState();
}

class _InventoryCreationScreenState extends State<InventoryCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();
  final _valueController = TextEditingController();
  late InventoryNode? _parent;
  late InventoryNode? _baselineParent;
  late InventoryNode? _initialParent;
  var _quantity = InventoryEngineDefaults.quantity;
  var _initialQuantity = InventoryEngineDefaults.quantity;
  var _valuationMode = InventoryValuationMode.none;
  var _initialValuationMode = InventoryValuationMode.none;
  var _initialName = '';
  var _initialValue = '';
  final _stockReferenceController = TextEditingController();
  var _initialStockReference = '';
  var _stockLevel = StockLevel.full;
  final _targetPriceController = TextEditingController();
  var _initialTargetPrice = '';
  /// Hidden legacy fields (UX-CORR-03): kept in memory so saves do not wipe them.
  String? _preservedBarcodeRef;
  String? _preservedPurchaseDate;
  int? _preservedPurchasePriceCents;
  String? _preservedPurchasePlace;
  var _objective = ItemObjective.none;
  var _initialObjective = ItemObjective.none;
  final _photoStore = GoodsPhotoStore();
  final _documentStore = GoodsDocumentStore();
  final _imagePicker = ImagePicker();
  String? _savedPhotoRelPath;
  String? _initialPhotoRelPath;
  File? _savedPhotoFile;
  File? _pendingTempPhoto;
  var _removeSavedPhoto = false;
  var _photoBusy = false;
  final _savedDocuments = <NodeDocument>[];
  final _pendingDocuments = <PendingDocumentCopy>[];
  final _removedDocumentIds = <String>{};
  var _documentsBusy = false;
  String? _manualIconKey;
  String? _initialIconKey;
  var _saving = false;
  var _createdOnce = false;
  var _ready = true;
  late NodeType _itemKind;
  late NodeType _initialItemKind;
  var _showAdvanced = false;
  String? _errorMessage;

  bool get _isEdit => widget.existing != null;

  bool get _isPermanentRoot =>
      _isEdit && PermanentRoots.isPermanentId(widget.existing!.id);

  bool get _isStock => widget.controller.space == InventorySpace.stock;

  bool get _isToBuy => widget.controller.space == InventorySpace.toBuy;

  bool get _isItem => widget.type.isItem;

  bool get _isStockProduct =>
      _isStock &&
      (_isEdit ? widget.existing!.type == NodeType.item : widget.type == NodeType.item);

  bool get _isToBuyNeed =>
      _isToBuy &&
      (_isEdit ? widget.existing!.type == NodeType.item : widget.type == NodeType.item);

  bool get _supportsItemKind => _isItem && !_isStock && !_isToBuy;

  bool get _supportsQuickLocation => _isItem;

  bool get _supportsContinue => _isItem && !_isEdit;

  /// Goods items/containers, stock products, to-buy needs — not locations
  /// or organisational Stock/À acheter containers.
  bool get _supportsAdvancedSection {
    if (_effectiveType == NodeType.location) return false;
    if (_isStock || _isToBuy) return _effectiveType == NodeType.item;
    return _effectiveType.isItem;
  }

  /// M4.1-B advanced fields are goods-only (no Stock / À acheter changes).
  bool get _supportsGoodsAdvancedFields =>
      !_isStock && !_isToBuy && _effectiveType.isItem;

  File? get _photoPreviewFile {
    if (_pendingTempPhoto != null) return _pendingTempPhoto;
    if (_removeSavedPhoto) return null;
    return _savedPhotoFile;
  }

  bool get _photoHasChanges =>
      _pendingTempPhoto != null ||
      _removeSavedPhoto ||
      _savedPhotoRelPath != _initialPhotoRelPath;

  bool get _documentsHasChanges =>
      _pendingDocuments.isNotEmpty || _removedDocumentIds.isNotEmpty;

  List<GoodsDocumentListItem> get _documentItems {
    final items = <GoodsDocumentListItem>[
      for (final doc in _savedDocuments)
        if (!_removedDocumentIds.contains(doc.id))
          GoodsDocumentListItem.saved(doc),
    ];
    for (var i = 0; i < _pendingDocuments.length; i++) {
      final pending = _pendingDocuments[i];
      items.add(
        GoodsDocumentListItem(
          key: 'pending-$i-${pending.tempFile.path}',
          displayName: pending.displayName,
          mimeType: pending.mimeType,
          byteSize: pending.byteSize,
          pendingTempPath: pending.tempFile.path,
        ),
      );
    }
    return items;
  }

  /// Goods item/container form (not Stock / À acheter / location).
  bool get _isGoodsItemForm => _supportsGoodsAdvancedFields;

  Widget _buildGoodsNameField() {
    return SizedBox(
      height: valuationControlHeight,
      child: TextFormField(
        key: const ValueKey('creation-name'),
        controller: _nameController,
        focusNode: _nameFocus,
        autofocus: !_isEdit,
        enabled: !_saving,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        maxLength: _isEdit &&
                _initialName.trim().length > InventoryName.maxLength
            ? _initialName.trim().length
            : InventoryName.maxLength,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          // Title sits above the field (UX-CORR-06) — same pattern as Position.
          counterText: '',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          prefixIconConstraints: const BoxConstraints(
            minWidth: valuationControlHeight,
            minHeight: valuationControlHeight,
            maxWidth: valuationControlHeight,
            maxHeight: valuationControlHeight,
          ),
          prefixIcon: IconButton(
            tooltip: _manualIconKey == null
                ? AppStrings.chooseIcon
                : AppStrings.iconManual,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(
              width: valuationControlHeight,
              height: valuationControlHeight,
            ),
            onPressed: _saving ? null : () => unawaited(_pickIcon()),
            icon: Icon(
              inventoryIconForName(
                name: _nameController.text,
                type: _effectiveType,
                manualKey: _manualIconKey,
              ),
            ),
          ),
        ),
        validator: (value) {
          final raw = value?.trim() ?? '';
          if (raw.isEmpty) return AppStrings.nameRequired;
          if (raw.length > InventoryName.maxLength &&
              raw != _initialName.trim()) {
            return AppStrings.nameTooLong(InventoryName.maxLength);
          }
          return null;
        },
        onChanged: (_) {
          setState(() {
            if (_errorMessage != null) {
              _errorMessage = null;
            }
          });
        },
      ),
    );
  }

  /// Trailing column width shared by Contenant and position `+` (UX-CORR-06).
  static const _goodsTrailingWidth = 88.0;

  static const _goodsLabelControlGap = 6.0;

  Widget _buildContainerToggle() {
    return SizedBox(
      width: _goodsTrailingWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.isContainerLabel,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: _goodsLabelControlGap),
          SizedBox(
            height: valuationControlHeight,
            width: _goodsTrailingWidth,
            child: Center(
              child: Switch(
                value: _itemKind == NodeType.itemContainer,
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _itemKind =
                              value ? NodeType.itemContainer : NodeType.item;
                          _errorMessage = null;
                        });
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectiveControl() {
    // Explicit exclusive choices — default remains [ItemObjective.none].
    return SizedBox(
      height: valuationControlHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final objective in ItemObjective.values) ...[
            if (objective != ItemObjective.values.first) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: inventoryGoodsOutlinedStyle(
                  selected: _objective == objective,
                ),
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _objective = objective;
                          _errorMessage = null;
                        }),
                child: Text(
                  AppStrings.labelForObjective(objective),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> get _goodsMediaChildren => [
        GoodsMainPhotoField(
          previewFile: _photoPreviewFile,
          enabled: !_saving,
          busy: _photoBusy || _documentsBusy,
          onPickGallery: () => unawaited(_pickPhoto(ImageSource.gallery)),
          onPickCamera: () => unawaited(_pickPhoto(ImageSource.camera)),
          onPickDocument: () => unawaited(_pickDocument()),
          onRemove: () => unawaited(_confirmRemovePhoto()),
        ),
        if (_documentItems.isNotEmpty || _documentsBusy) ...[
          const SizedBox(height: 12),
          GoodsDocumentsField(
            documents: _documentItems,
            enabled: !_saving,
            busy: _documentsBusy,
            onOpen: (item) => unawaited(_openDocument(item)),
            onRemove: (item) => unawaited(_confirmRemoveDocument(item)),
          ),
        ],
      ];

  /// Resolved type for goods item/container toggle (UX-01).
  NodeType get _effectiveType =>
      _supportsItemKind ? _itemKind : widget.type;

  bool get _advancedHasChanges =>
      _supportsGoodsAdvancedFields &&
      (_objective != _initialObjective ||
          _photoHasChanges ||
          _documentsHasChanges);

  bool get _iconHasChanges => _manualIconKey != _initialIconKey;

  bool get _hasChanges {
    if (_isEdit) {
      return _nameController.text != _initialName ||
          _parent?.id != _initialParent?.id ||
          (_supportsItemKind && _itemKind != _initialItemKind) ||
          (_isStockProduct &&
              _stockReferenceController.text != _initialStockReference) ||
          (_isToBuyNeed &&
              (_quantity != _initialQuantity ||
                  _targetPriceController.text != _initialTargetPrice)) ||
          (_isItem &&
              !_isStockProduct &&
              !_isToBuyNeed &&
              (_quantity != _initialQuantity ||
                  _valuationMode != _initialValuationMode ||
                  _valueController.text != _initialValue)) ||
          _advancedHasChanges ||
          _iconHasChanges;
    }
    return _nameController.text.isNotEmpty ||
        _parent?.id != _baselineParent?.id ||
        (_supportsItemKind && _itemKind != _initialItemKind) ||
        (_isStockProduct && _stockReferenceController.text.isNotEmpty) ||
        (_isToBuyNeed &&
            (_quantity != InventoryEngineDefaults.quantity ||
                _targetPriceController.text.isNotEmpty)) ||
        _iconHasChanges ||
        (_isItem &&
            !_isStockProduct &&
            !_isToBuyNeed &&
            (_quantity != InventoryEngineDefaults.quantity ||
                _valuationMode != _initialValuationMode ||
                _valueController.text != _initialValue)) ||
        _advancedHasChanges;
  }

  String get _title {
    if (_isEdit) {
      if (_isStockProduct) {
        return '${AppStrings.edit} ${AppStrings.stockProductType}';
      }
      if (_isToBuyNeed) {
        return '${AppStrings.edit} ${AppStrings.needType}';
      }
      return '${AppStrings.edit} ${AppStrings.labelForNodeType(_effectiveType)}';
    }
    if (_isStockProduct) return AppStrings.newStockProductTitle;
    if (_isToBuyNeed) return AppStrings.newNeedTitle;
    return switch (widget.type) {
      NodeType.location => AppStrings.newLocationTitle,
      NodeType.item || NodeType.itemContainer => AppStrings.newItemTitle,
    };
  }

  @override
  void initState() {
    super.initState();
    _parent = widget.initialParent;
    _baselineParent = widget.initialParent;
    _initialParent = widget.initialParent;
    _itemKind = widget.type.isItem ? widget.type : NodeType.item;
    _initialItemKind = _itemKind;
    if (_isEdit) {
      _ready = false;
      unawaited(_loadExisting());
    } else {
      if (_supportsItemKind) {
        // UX-01: financial mode with 0 $ by default for new goods.
        _valuationMode = InventoryValuationMode.financial;
        _initialValuationMode = InventoryValuationMode.financial;
        _valueController.text = '0';
        _initialValue = '0';
      }
      if (_supportsAdvancedSection) {
        _ready = false;
        unawaited(_loadCreateAdvancedPreference());
      } else {
        _scheduleNameFocus();
      }
    }
  }

  void _scheduleNameFocus() {
    if (_isEdit) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isEdit || !_ready) return;
      _nameFocus.requestFocus();
    });
  }

  Future<void> _loadCreateAdvancedPreference() async {
    try {
      final value =
          await widget.controller.engine.readShowAdvancedByDefault();
      if (!mounted) return;
      setState(() {
        _showAdvanced = value;
        _ready = true;
      });
      _scheduleNameFocus();
    } on Exception {
      if (!mounted) return;
      setState(() => _ready = true);
      _scheduleNameFocus();
    }
  }

  Future<void> _loadExisting() async {
    final existing = widget.existing!;
    try {
      final details = await widget.controller.readNodeDetails(existing.id);
      if (!mounted) return;
      final node = details.node;
      final path = details.path;
      _initialName = node.name;
      _nameController.text = _initialName;
      _initialIconKey = node.iconKey;
      _manualIconKey = node.iconKey;
      if (node.type.isItem) {
        _itemKind = node.type;
        _initialItemKind = node.type;
      }
      _initialParent = path.length > 1 ? path[path.length - 2] : null;
      _parent = _initialParent;
      _baselineParent = _initialParent;
      _showAdvanced = node.showAdvanced;
      if (_supportsGoodsAdvancedFields) {
        _preservedBarcodeRef = node.barcodeRef;
        _preservedPurchasePlace = node.purchasePlace;
        _preservedPurchasePriceCents = node.purchasePriceCents;
        _preservedPurchaseDate = node.purchaseDate;
        _initialObjective = node.objective;
        _objective = _initialObjective;
        _initialPhotoRelPath = node.photoRelPath;
        _savedPhotoRelPath = node.photoRelPath;
        _removeSavedPhoto = false;
        _pendingTempPhoto = null;
        _savedPhotoFile = await _photoStore.resolve(node.photoRelPath);
        final docs = await widget.controller.listNodeDocuments(node.id);
        if (!mounted) return;
        _savedDocuments
          ..clear()
          ..addAll(docs);
        _pendingDocuments.clear();
        _removedDocumentIds.clear();
      }
      if (node.isStockProduct) {
        _initialStockReference =
            node.stockReference == null ? '' : '${node.stockReference}';
        _stockReferenceController.text = _initialStockReference;
        _stockLevel = node.stockLevel ?? StockLevel.full;
      } else if (node.isToBuyNeed) {
        _initialQuantity = node.quantity ?? InventoryEngineDefaults.quantity;
        _quantity = _initialQuantity;
        final target = node.targetPriceCents;
        if (target == null) {
          _initialTargetPrice = '';
        } else {
          _initialTargetPrice =
              '${target ~/ 100},${(target % 100).toString().padLeft(2, '0')}';
        }
        _targetPriceController.text = _initialTargetPrice;
      } else {
        _initialQuantity = node.quantity ?? InventoryEngineDefaults.quantity;
        _quantity = _initialQuantity;
        switch (node.valuation) {
          case FinancialValuation(:final unitCents):
            _initialValuationMode = InventoryValuationMode.financial;
            _initialValue =
                '${unitCents ~/ 100},${(unitCents % 100).toString().padLeft(2, '0')}';
          case SentimentalValuation(:final rating):
            _initialValuationMode = InventoryValuationMode.sentimental;
            _initialValue = '$rating';
          case null:
            _initialValuationMode = InventoryValuationMode.none;
            _initialValue = '';
        }
        _valuationMode = _initialValuationMode;
        _valueController.text = _initialValue;
      }
      setState(() => _ready = true);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _errorMessage = AppStrings.detailsReadError;
      });
    }
  }

  @override
  void dispose() {
    unawaited(_photoStore.deleteTemp(_pendingTempPhoto));
    for (final pending in _pendingDocuments) {
      unawaited(_documentStore.deleteTemp(pending.tempFile));
    }
    _nameController.dispose();
    _nameFocus.dispose();
    _valueController.dispose();
    _stockReferenceController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _onStockLevelChanged(StockLevel next) async {
    if (_saving) return;
    final previous = _stockLevel;
    setState(() {
      _stockLevel = next;
      _errorMessage = null;
    });
    final existing = widget.existing;
    if (existing == null || !existing.isStockProduct) return;
    try {
      await widget.controller.setStockLevel(existing.id, next);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _stockLevel = previous;
        _errorMessage = AppStrings.saveError;
      });
    }
  }

  Future<void> _pickIcon() async {
    if (_saving) return;
    final selected = await showInventoryIconPickerSheet(
      context: context,
      name: _nameController.text,
      type: _effectiveType,
      currentManualKey: _manualIconKey,
    );
    if (!mounted || selected == null) return;
    setState(() {
      _manualIconKey = selected.isEmpty ? null : selected;
      _errorMessage = null;
    });
  }

  Future<void> _pickDocument() async {
    if (_saving || _documentsBusy || !_supportsGoodsAdvancedFields) return;
    setState(() {
      _documentsBusy = true;
      _errorMessage = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: GoodsDocumentStore.allowedExtensions.toList(),
      );
      if (!mounted) return;
      if (file == null) {
        setState(() => _documentsBusy = false);
        return;
      }
      final displayName = file.name.trim().isEmpty
          ? 'document'
          : file.name.trim();
      final ext =
          GoodsDocumentStore.normalizeExtension(file.extension) ??
          GoodsDocumentStore.normalizeExtension(displayName);
      if (ext == null) {
        setState(() {
          _documentsBusy = false;
          _errorMessage = AppStrings.documentUnsupportedType;
        });
        return;
      }
      final knownSize = file.lengthSync() ?? await file.length();
      final path = file.path;
      final PendingDocumentCopy pending;
      if (path != null && path.isNotEmpty) {
        pending = await _documentStore.copyToTemp(
          sourcePath: path,
          displayName: displayName,
          extension: ext,
        );
      } else {
        pending = await _documentStore.copyStreamToTemp(
          bytes: file.readAsByteStream(),
          displayName: displayName,
          extension: ext,
          knownSize: knownSize,
        );
      }
      if (!mounted) {
        await _documentStore.deleteTemp(pending.tempFile);
        return;
      }
      setState(() {
        _pendingDocuments.add(pending);
        _documentsBusy = false;
      });
    } on GoodsDocumentException catch (error) {
      if (!mounted) return;
      setState(() {
        _documentsBusy = false;
        _errorMessage = switch (error.code) {
          GoodsDocumentError.tooLarge => AppStrings.documentTooLarge,
          GoodsDocumentError.unsupportedType =>
            AppStrings.documentUnsupportedType,
          _ => AppStrings.documentError,
        };
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _documentsBusy = false;
        _errorMessage = AppStrings.documentError;
      });
    }
  }

  Future<void> _openDocument(GoodsDocumentListItem item) async {
    try {
      final File? file;
      if (item.saved != null) {
        file = await _documentStore.resolve(item.saved!.relPath);
      } else if (item.pendingTempPath != null) {
        file = File(item.pendingTempPath!);
      } else {
        file = null;
      }
      if (file == null || !await file.exists()) {
        if (!mounted) return;
        setState(() => _errorMessage = AppStrings.documentMissing);
        return;
      }
      final result = await OpenFilex.open(file.path, type: item.mimeType);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        setState(() => _errorMessage = AppStrings.documentOpenError);
      }
    } on Exception {
      if (!mounted) return;
      setState(() => _errorMessage = AppStrings.documentOpenError);
    }
  }

  Future<void> _confirmRemoveDocument(GoodsDocumentListItem item) async {
    if (_saving || _documentsBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removeDocumentConfirmTitle),
        content: const Text(AppStrings.removeDocumentConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.removeDocument),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    if (item.saved != null) {
      setState(() {
        _removedDocumentIds.add(item.saved!.id);
        _errorMessage = null;
      });
      return;
    }
    PendingDocumentCopy? removed;
    setState(() {
      final index = _pendingDocuments.indexWhere(
        (pending) => pending.tempFile.path == item.pendingTempPath,
      );
      if (index >= 0) {
        removed = _pendingDocuments.removeAt(index);
      }
      _errorMessage = null;
    });
    final discarded = removed;
    if (discarded != null) {
      await _documentStore.deleteTemp(discarded.tempFile);
    }
  }

  Future<List<NodeDocumentWrite>> _commitDocumentsForSave() async {
    final writes = <NodeDocumentWrite>[];
    for (final doc in _savedDocuments) {
      if (_removedDocumentIds.contains(doc.id)) continue;
      writes.add(
        NodeDocumentWrite(
          existingId: doc.id,
          displayName: doc.displayName,
          relPath: doc.relPath,
          mimeType: doc.mimeType,
          byteSize: doc.byteSize,
        ),
      );
    }
    for (final pending in List<PendingDocumentCopy>.from(_pendingDocuments)) {
      final relPath = await _documentStore.promoteTemp(pending);
      writes.add(
        NodeDocumentWrite(
          displayName: pending.displayName,
          relPath: relPath,
          mimeType: pending.mimeType,
          byteSize: pending.byteSize,
        ),
      );
    }
    _pendingDocuments.clear();
    return writes;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_saving || _photoBusy || !_supportsGoodsAdvancedFields) return;
    setState(() {
      _photoBusy = true;
      _errorMessage = null;
    });
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        // Bound early so we never decode a multi-megapixel original ourselves.
        maxWidth: GoodsPhotoStore.maxLongSide.toDouble(),
        maxHeight: GoodsPhotoStore.maxLongSide.toDouble(),
        imageQuality: 95,
        requestFullMetadata: false,
      );
      if (!mounted || picked == null) {
        if (mounted) setState(() => _photoBusy = false);
        return;
      }
      final optimized = await _photoStore.optimizeToTemp(picked.path);
      if (!mounted) {
        await _photoStore.deleteTemp(optimized);
        return;
      }
      final previousPending = _pendingTempPhoto;
      setState(() {
        _pendingTempPhoto = optimized;
        _removeSavedPhoto = false;
        _photoBusy = false;
      });
      await _photoStore.deleteTemp(previousPending);
    } on Exception catch (error) {
      if (!mounted) return;
      final denied = error.toString().toLowerCase().contains('permission');
      setState(() {
        _photoBusy = false;
        _errorMessage =
            denied ? AppStrings.photoPermissionDenied : AppStrings.photoError;
      });
    }
  }

  Future<void> _confirmRemovePhoto() async {
    if (_saving || _photoBusy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.removePhotoConfirmTitle),
        content: const Text(AppStrings.removePhotoConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.removePhoto),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final pending = _pendingTempPhoto;
    setState(() {
      _pendingTempPhoto = null;
      _removeSavedPhoto = true;
      _errorMessage = null;
    });
    await _photoStore.deleteTemp(pending);
  }

  Future<String?> _commitPhotoForSave({required String? previousRelPath}) async {
    if (!_supportsGoodsAdvancedFields) return null;
    if (_pendingTempPhoto != null) {
      final promoted = await _photoStore.promoteTemp(_pendingTempPhoto!);
      _pendingTempPhoto = null;
      return promoted;
    }
    if (_removeSavedPhoto) return null;
    return previousRelPath ?? _savedPhotoRelPath;
  }

  int? get _parsedStockReference {
    final raw = _stockReferenceController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  int? get _parsedTargetPriceCents {
    final raw = _targetPriceController.text.trim();
    if (raw.isEmpty) return null;
    return parseCadCents(raw);
  }

  Future<void> _discardPendingMedia() async {
    final photo = _pendingTempPhoto;
    _pendingTempPhoto = null;
    await _photoStore.deleteTemp(photo);
    final docs = List<PendingDocumentCopy>.from(_pendingDocuments);
    _pendingDocuments.clear();
    for (final pending in docs) {
      await _documentStore.deleteTemp(pending.tempFile);
    }
  }

  Future<void> _cancel() async {
    if (_saving) return;
    if (_hasChanges) {
      final discard = await confirmDiscardChanges(
        context,
        title: _isEdit ? AppStrings.editDiscardTitle : AppStrings.discardTitle,
      );
      if (!mounted || !discard) return;
    }
    await _discardPendingMedia();
    if (mounted) Navigator.pop(context, _isEdit ? false : _createdOnce);
  }

  Future<void> _quickCreateLocation() async {
    if (_saving) return;
    final created = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => InventoryCreationScreen(
          controller: widget.controller,
          type: NodeType.location,
          initialParent: _parent,
        ),
      ),
    );
    if (!mounted || created is! InventoryNode) return;
    setState(() {
      _parent = created;
      _errorMessage = null;
    });
  }

  void _toggleValuation(InventoryValuationMode mode) {
    setState(() {
      if (_valuationMode == mode) {
        _valuationMode = InventoryValuationMode.none;
        _valueController.clear();
      } else {
        _valuationMode = mode;
        if (mode == InventoryValuationMode.financial) {
          if (_valueController.text.trim().isEmpty) {
            _valueController.text = '0';
          }
        } else {
          _valueController.clear();
        }
      }
      _errorMessage = null;
    });
  }

  NodeValuation? get _valuation {
    if (!_isItem || _valuationMode == InventoryValuationMode.none) return null;
    final raw = _valueController.text.trim();
    switch (_valuationMode) {
      case InventoryValuationMode.none:
        return null;
      case InventoryValuationMode.financial:
        // UX-01: empty amount stores 0 $.
        if (raw.isEmpty) return const FinancialValuation(0);
        final cents = parseCadCents(raw);
        if (cents != null) return FinancialValuation(cents);
        final normalized = raw.replaceAll(',', '.');
        final parts = normalized.split('.');
        final whole = int.tryParse(parts[0]);
        if (whole == null || whole < 0) return null;
        var parsedCents = whole * 100;
        if (parts.length > 1) {
          final frac = parts[1].padRight(2, '0').substring(0, 2);
          final parsed = int.tryParse(frac);
          if (parsed == null) return null;
          parsedCents += parsed;
        }
        return FinancialValuation(parsedCents);
      case InventoryValuationMode.sentimental:
        if (raw.isEmpty) return null;
        final rating = int.tryParse(raw);
        if (rating == null ||
            rating < SentimentalValuation.minRating ||
            rating > SentimentalValuation.maxRating) {
          return null;
        }
        return SentimentalValuation(rating);
    }
  }

  String? _validateBeforeSave() {
    if (!_formKey.currentState!.validate()) {
      final raw = _nameController.text.trim();
      if (raw.isEmpty) return AppStrings.nameRequired;
      if (raw.length > InventoryName.maxLength && raw != _initialName.trim()) {
        return AppStrings.nameTooLong(InventoryName.maxLength);
      }
      return AppStrings.nameRequired;
    }
    if (_parent == null && !_isPermanentRoot) {
      return AppStrings.parentRequired;
    }
    if (_isStockProduct) {
      final raw = _stockReferenceController.text.trim();
      if (raw.isNotEmpty &&
          (_parsedStockReference == null || _parsedStockReference! < 1)) {
        return AppStrings.stockReferenceInvalid;
      }
      return null;
    }
    if (_isToBuyNeed) {
      final raw = _targetPriceController.text.trim();
      if (raw.isNotEmpty && _parsedTargetPriceCents == null) {
        return AppStrings.amountInvalid;
      }
      return null;
    }
    if (!_isItem) return null;
    switch (_valuationMode) {
      case InventoryValuationMode.none:
        return null;
      case InventoryValuationMode.financial:
        if (_valuation == null) {
          return AppStrings.amountInvalid;
        }
        return null;
      case InventoryValuationMode.sentimental:
        if (_valueController.text.trim().isEmpty || _valuation == null) {
          return AppStrings.sentimentalRequired;
        }
        return null;
    }
  }

  Future<InventoryNode?> _persistCreate() async {
    final validationError = _validateBeforeSave();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return null;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    String? promotedPhoto;
    final promotedDocPaths = <String>[];
    try {
      promotedPhoto = await _commitPhotoForSave(previousRelPath: null);
      final node = await widget.controller.createNodeAt(
        name: _nameController.text,
        type: _effectiveType,
        parentId: _parent?.id,
        quantity: _isItem && !_isStock ? _quantity : null,
        valuation: _isStock || _isToBuy ? null : _valuation,
        stockReference: _isStockProduct ? _parsedStockReference : null,
        targetPriceCents: _isToBuyNeed ? _parsedTargetPriceCents : null,
        showAdvanced: _supportsAdvancedSection ? _showAdvanced : false,
        barcodeRef: null,
        purchaseDate: null,
        purchasePriceCents: null,
        purchasePlace: null,
        objective: _supportsGoodsAdvancedFields
            ? _objective
            : ItemObjective.none,
        photoRelPath: promotedPhoto,
        iconKey: _manualIconKey,
      );
      if (_isStockProduct && _stockLevel != StockLevel.full) {
        await widget.controller.setStockLevel(node.id, _stockLevel);
      }
      if (_supportsGoodsAdvancedFields) {
        final writes = await _commitDocumentsForSave();
        for (final write in writes) {
          if (write.existingId == null) {
            promotedDocPaths.add(write.relPath);
          }
        }
        if (writes.isNotEmpty) {
          await widget.controller.syncNodeDocuments(
            node.id,
            documents: writes,
          );
        }
        final refreshed = await widget.controller.listNodeDocuments(node.id);
        _savedDocuments
          ..clear()
          ..addAll(refreshed);
        _removedDocumentIds.clear();
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _createdOnce = true;
          _savedPhotoRelPath = promotedPhoto;
          _initialPhotoRelPath = promotedPhoto;
          _removeSavedPhoto = false;
          _initialIconKey = _manualIconKey;
        });
      }
      return node;
    } on InventoryException catch (error) {
      await _photoStore.deleteRel(promotedPhoto);
      for (final path in promotedDocPaths) {
        await _documentStore.deleteRel(path);
      }
      if (!mounted) return null;
      setState(() {
        _saving = false;
        _errorMessage = _mapError(error, create: true);
      });
      return null;
    } catch (_) {
      await _photoStore.deleteRel(promotedPhoto);
      for (final path in promotedDocPaths) {
        await _documentStore.deleteRel(path);
      }
      if (!mounted) return null;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.creationError;
      });
      return null;
    }
  }

  Future<bool> _persistEdit() async {
    final validationError = _validateBeforeSave();
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return false;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final existing = widget.existing!;
    String? promotedPhoto;
    final previousPhoto = _initialPhotoRelPath;
    final promotedDocPaths = <String>[];
    try {
      final parentChanged = _parent?.id != _initialParent?.id;
      if (_isStockProduct) {
        await widget.controller.updateStockProduct(
          existing.id,
          name: _nameController.text,
          parentId: _parent?.id,
          stockReference: _parsedStockReference,
          iconKey: _manualIconKey,
        );
      } else if (_isToBuyNeed) {
        await widget.controller.updateToBuyNeed(
          existing.id,
          name: _nameController.text,
          parentId: _parent?.id,
          remainingQuantity: _quantity,
          targetPriceCents: _parsedTargetPriceCents,
          iconKey: _manualIconKey,
        );
      } else {
        final kindChanged =
            _supportsItemKind && _itemKind != _initialItemKind;
        promotedPhoto = await _commitPhotoForSave(
          previousRelPath: previousPhoto,
        );
        await widget.controller.saveEditedNode(
          nodeId: existing.id,
          name: _nameController.text,
          condition: existing.condition,
          quantity: _isItem ? _quantity : null,
          valuation: !_isItem || _valuationMode == InventoryValuationMode.none
              ? null
              : _valuation,
          isItem: _isItem,
          itemKind: kindChanged ? _itemKind : null,
          newParentId: _parent?.id,
          move: parentChanged,
          barcodeRef: _supportsGoodsAdvancedFields
              ? _preservedBarcodeRef
              : null,
          purchaseDate: _supportsGoodsAdvancedFields
              ? _preservedPurchaseDate
              : null,
          purchasePriceCents: _supportsGoodsAdvancedFields
              ? _preservedPurchasePriceCents
              : null,
          purchasePlace: _supportsGoodsAdvancedFields
              ? _preservedPurchasePlace
              : null,
          objective: _supportsGoodsAdvancedFields
              ? _objective
              : ItemObjective.none,
          photoRelPath: promotedPhoto,
          iconKey: _manualIconKey,
        );
        if (previousPhoto != null && previousPhoto != promotedPhoto) {
          await _photoStore.deleteRel(previousPhoto);
        }
        if (_supportsGoodsAdvancedFields) {
          final writes = await _commitDocumentsForSave();
          for (final write in writes) {
            if (write.existingId == null) {
              promotedDocPaths.add(write.relPath);
            }
          }
          final removedPaths = await widget.controller.syncNodeDocuments(
            existing.id,
            documents: writes,
          );
          for (final path in removedPaths) {
            await _documentStore.deleteRel(path);
          }
          final refreshed =
              await widget.controller.listNodeDocuments(existing.id);
          _savedDocuments
            ..clear()
            ..addAll(refreshed);
          _removedDocumentIds.clear();
        }
      }
      if (mounted) {
        setState(() {
          _saving = false;
          _savedPhotoRelPath = promotedPhoto;
          _initialPhotoRelPath = promotedPhoto;
          _removeSavedPhoto = false;
          _initialIconKey = _manualIconKey;
        });
      }
      return true;
    } on InventoryException catch (error) {
      if (promotedPhoto != null && promotedPhoto != previousPhoto) {
        await _photoStore.deleteRel(promotedPhoto);
      }
      for (final path in promotedDocPaths) {
        await _documentStore.deleteRel(path);
      }
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _errorMessage = _mapError(error, create: false);
      });
      return false;
    } catch (_) {
      if (promotedPhoto != null && promotedPhoto != previousPhoto) {
        await _photoStore.deleteRel(promotedPhoto);
      }
      for (final path in promotedDocPaths) {
        await _documentStore.deleteRel(path);
      }
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.saveError;
      });
      return false;
    }
  }

  String _mapError(InventoryException error, {required bool create}) {
    return switch (error.code) {
      InventoryErrorCode.emptyName => AppStrings.nameRequired,
      InventoryErrorCode.nameTooLong =>
        AppStrings.nameTooLong(InventoryName.maxLength),
      InventoryErrorCode.parentRequired => AppStrings.parentRequired,
      InventoryErrorCode.invalidQuantity => AppStrings.quantityInvalid,
      InventoryErrorCode.invalidStockUnit => AppStrings.stockReferenceInvalid,
      InventoryErrorCode.parentNotFound ||
      InventoryErrorCode.parentInactive ||
      InventoryErrorCode.parentCannotContain ||
      InventoryErrorCode.inventoryMismatch ||
      InventoryErrorCode.invalidHierarchy ||
      InventoryErrorCode.cycleDetected => AppStrings.parentUnavailable,
      InventoryErrorCode.nodeHasChildren =>
        AppStrings.cannotConvertWithChildren,
      InventoryErrorCode.invalidFinancialValue => AppStrings.amountInvalid,
      InventoryErrorCode.invalidSentimentalValue =>
        AppStrings.sentimentalRequired,
      _ => create ? AppStrings.creationError : AppStrings.saveError,
    };
  }

  Future<void> _createAndClose() async {
    if (_saving) return;
    final node = await _persistCreate();
    if (!mounted || node == null) return;
    Navigator.pop(context, node);
  }

  Future<void> _saveEdit() async {
    if (_saving) return;
    final ok = await _persistEdit();
    if (!mounted || !ok) return;
    Navigator.pop(context, true);
  }

  Future<void> _createAndContinue() async {
    if (_saving || !_supportsContinue) return;
    final node = await _persistCreate();
    if (!mounted || node == null) return;
    final leftoverPending = _pendingTempPhoto;
    final leftoverDocs = List<PendingDocumentCopy>.from(_pendingDocuments);
    setState(() {
      _nameController.clear();
      _stockReferenceController.clear();
      _targetPriceController.clear();
      _preservedBarcodeRef = null;
      _preservedPurchaseDate = null;
      _preservedPurchasePriceCents = null;
      _preservedPurchasePlace = null;
      _objective = ItemObjective.none;
      _initialObjective = ItemObjective.none;
      _pendingTempPhoto = null;
      _savedPhotoRelPath = null;
      _initialPhotoRelPath = null;
      _savedPhotoFile = null;
      _removeSavedPhoto = false;
      _pendingDocuments.clear();
      _savedDocuments.clear();
      _removedDocumentIds.clear();
      _manualIconKey = null;
      _initialIconKey = null;
      _quantity = InventoryEngineDefaults.quantity;
      if (_supportsItemKind) {
        _valuationMode = InventoryValuationMode.financial;
        _valueController.text = '0';
      } else {
        _valuationMode = InventoryValuationMode.none;
        _valueController.clear();
      }
      _baselineParent = _parent;
      _errorMessage = null;
    });
    await _photoStore.deleteTemp(leftoverPending);
    for (final pending in leftoverDocs) {
      await _documentStore.deleteTemp(pending.tempFile);
    }
    _formKey.currentState?.reset();
  }

  Future<void> _openStockHistory() async {
    final existing = widget.existing;
    if (existing == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text(AppStrings.stockMovements)),
          body: StockHistoryScreen(
            controller: widget.controller,
            nodeId: existing.id,
          ),
        ),
      ),
    );
  }

  Future<void> _openAcquire() async {
    final existing = widget.existing;
    final goods = widget.goodsController;
    final stock = widget.stockController;
    if (existing == null || goods == null || stock == null || _saving) return;
    final need = await widget.controller.engine.getNode(existing.id);
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PurchaseAcquireScreen(
          toBuyController: widget.controller,
          goodsController: goods,
          stockController: stock,
          need: need,
        ),
      ),
    );
    if (!mounted || ok != true) return;
    Navigator.pop(context, 'acquired');
  }

  Future<void> _abandon() async {
    final existing = widget.existing;
    if (existing == null || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.abandonNeedConfirmTitle),
        content: const Text(AppStrings.abandonNeedConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.abandonNeed),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.controller.abandonNeed(existing.id);
      if (!mounted) return;
      Navigator.pop(context, 'abandoned');
    } on InventoryException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.saveError;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.saveError;
      });
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null || _saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmDelete),
        content: Text(
          '${AppStrings.deleteConfirmation}\n\n'
          '« ${inventoryDisplayName(existing.name)} »',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _saving = true);
    try {
      await widget.controller.deleteNodePermanently(existing.id);
      if (!mounted) return;
      Navigator.pop(context, 'deleted');
    } on InventoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = switch (error.code) {
          InventoryErrorCode.nodeHasChildren =>
            AppStrings.cannotDeleteWithChildren,
          InventoryErrorCode.permanentRootProtected =>
            AppStrings.permanentRootProtected,
          InventoryErrorCode.nodeNotFound ||
          InventoryErrorCode.nodeInactive => AppStrings.nodeUnavailable,
          _ => AppStrings.deleteError,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.deleteError;
      });
    }
  }

  Future<WithdrawalReason?> _pickWithdrawalReason() {
    return showDialog<WithdrawalReason>(
      context: context,
      builder: (context) {
        WithdrawalReason? selected;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(AppStrings.chooseWithdrawalReason),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final reason in WithdrawalReason.values)
                    ListTile(
                      title: Text(AppStrings.labelForWithdrawalReason(reason)),
                      leading: Icon(
                        selected == reason
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected == reason
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      onTap: () => setDialogState(() => selected = reason),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppStrings.cancel),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(context, selected),
                  child: const Text(AppStrings.continueAction),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _withdraw() async {
    final existing = widget.existing;
    if (existing == null || !_isItem || _saving) return;
    final reason = await _pickWithdrawalReason();
    if (!mounted || reason == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.confirmWithdraw),
        content: Text(
          '${AppStrings.withdrawConfirmation}\n\n'
          '« ${inventoryDisplayName(existing.name)} » · '
          '${AppStrings.labelForWithdrawalReason(reason)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.withdraw),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _saving = true);
    try {
      await widget.controller.withdrawItem(existing.id, reason);
      if (!mounted) return;
      Navigator.pop(context, 'withdrawn');
    } on InventoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = switch (error.code) {
          InventoryErrorCode.nodeHasChildren =>
            AppStrings.cannotWithdrawWithChildren,
          InventoryErrorCode.requiresItem => AppStrings.withdrawNotAllowed,
          InventoryErrorCode.nodeNotFound ||
          InventoryErrorCode.nodeInactive => AppStrings.nodeUnavailable,
          _ => AppStrings.withdrawError,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.withdrawError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // UX-01: create flow returns to the type picker on Back without a
      // discard prompt; Annuler still confirms. Edit keeps discard guard.
      canPop: !_saving &&
          (!_isEdit || (!_hasChanges && !_createdOnce)),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        if (!_isEdit && _createdOnce) {
          Navigator.pop(context, true);
          return;
        }
        unawaited(_cancel());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(_title)),
        body: SafeArea(
          child: !_ready
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: InventoryThumbBody(
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InventoryActionBar(
                          errorMessage: _errorMessage,
                          actions: [
                            InventoryBarAction(
                              label: AppStrings.cancel,
                              style: InventoryActionStyle.text,
                              expanded: true,
                              onPressed: _saving
                                  ? null
                                  : () => unawaited(_cancel()),
                            ),
                            if (_supportsContinue)
                              InventoryBarAction(
                                icon: Icons.add,
                                tooltip: AppStrings.createAndContinue,
                                style: InventoryActionStyle.tonalIcon,
                                expanded: false,
                                onPressed: _saving
                                    ? null
                                    : () => unawaited(_createAndContinue()),
                              ),
                            InventoryBarAction(
                              label: _isEdit
                                  ? (_saving
                                        ? AppStrings.saving
                                        : AppStrings.save)
                                  : (_saving
                                        ? AppStrings.creating
                                        : AppStrings.create),
                              style: InventoryActionStyle.filled,
                              onPressed: _saving
                                  ? null
                                  : () => unawaited(
                                      _isEdit
                                          ? _saveEdit()
                                          : _createAndClose(),
                                    ),
                            ),
                          ],
                        ),
                        if (_isEdit && !_isPermanentRoot) ...[
                          const SizedBox(height: 10),
                          if (_isStockProduct)
                            InventoryActionBar(
                              actions: [
                                InventoryBarAction(
                                  label: AppStrings.stockMovements,
                                  style: InventoryActionStyle.outlined,
                                  onPressed: _saving
                                      ? null
                                      : () => unawaited(_openStockHistory()),
                                ),
                                InventoryBarAction(
                                  label: AppStrings.delete,
                                  style: InventoryActionStyle.destructive,
                                  onPressed: _saving
                                      ? null
                                      : () => unawaited(_delete()),
                                ),
                              ],
                            )
                          else if (_isToBuyNeed)
                            InventoryActionBar(
                              actions: [
                                InventoryBarAction(
                                  label: AppStrings.purchaseAction,
                                  style: InventoryActionStyle.filled,
                                  onPressed: _saving
                                      ? null
                                      : () => unawaited(_openAcquire()),
                                ),
                                InventoryBarAction(
                                  label: AppStrings.abandonNeed,
                                  style: InventoryActionStyle.outlined,
                                  onPressed: _saving
                                      ? null
                                      : () => unawaited(_abandon()),
                                ),
                                InventoryBarAction(
                                  label: AppStrings.delete,
                                  style: InventoryActionStyle.destructive,
                                  onPressed: _saving
                                      ? null
                                      : () => unawaited(_delete()),
                                ),
                              ],
                            )
                          else
                            InventoryActionBar(
                              actions: [
                                if (_isItem)
                                  InventoryBarAction(
                                    label: AppStrings.withdrawFromInventory,
                                    style: InventoryActionStyle.outlined,
                                    onPressed: _saving
                                        ? null
                                        : () => unawaited(_withdraw()),
                                  ),
                                InventoryBarAction(
                                  label: AppStrings.delete,
                                  style: InventoryActionStyle.destructive,
                                  onPressed: _saving
                                      ? null
                                      : () => unawaited(_delete()),
                                ),
                              ],
                            ),
                        ],
                      ],
                    ),
                    children: [
                      if (_isGoodsItemForm) ...[
                        // L1 — Nom | Contenant (titres alignés)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppStrings.itemNameLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge,
                                  ),
                                  const SizedBox(height: _goodsLabelControlGap),
                                  _buildGoodsNameField(),
                                ],
                              ),
                            ),
                            if (_supportsItemKind) ...[
                              const SizedBox(width: 12),
                              _buildContainerToggle(),
                            ],
                          ],
                        ),
                        if (!_isPermanentRoot) ...[
                          const SizedBox(height: 12),
                          // L2 — Position (roulette) + ajout aligné
                          Text(
                            AppStrings.hierarchyPosition,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: _goodsLabelControlGap),
                          InventoryParentField(
                            controller: widget.controller,
                            allowRoot: false,
                            selected: _parent,
                            excludingSubtreeRootId: widget.existing?.id,
                            enabled: !_saving,
                            showQuickAdd: _supportsQuickLocation,
                            onQuickAdd: _quickCreateLocation,
                            compactRoulette: true,
                            trailingWidth: _supportsItemKind
                                ? _goodsTrailingWidth
                                : null,
                            onChanged: (next) => setState(() {
                              _parent = next;
                              _errorMessage = null;
                            }),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // L3 — Quantité (séparée de l’objectif pour éviter un tap « Vendre »)
                        Text(
                          AppStrings.nodeQuantity,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: _goodsLabelControlGap),
                        SizedBox(
                          height: valuationControlHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InventoryQuantityStepper(
                              value: _quantity,
                              enabled: !_saving,
                              onChanged: (value) =>
                                  setState(() => _quantity = value),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // L3b — Objectif (rangée pleine largeur ; défaut = Aucun)
                        Text(
                          AppStrings.itemObjective,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: _goodsLabelControlGap),
                        _buildObjectiveControl(),
                        const SizedBox(height: 12),
                        // L4 — Valorisation
                        Text(
                          AppStrings.valuationMode,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: _goodsLabelControlGap),
                        InventoryValuationField(
                          mode: _valuationMode,
                          controller: _valueController,
                          enabled: !_saving,
                          onModeChanged: _toggleValuation,
                          onChanged: () {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        // L5 — Photo / documents
                        ..._goodsMediaChildren,
                      ] else ...[
                        // Nom — même coquille que Biens (titre + h=48)
                        Text(
                          _isStockProduct
                              ? AppStrings.stockProductType
                              : (_isToBuyNeed
                                    ? AppStrings.needType
                                    : AppStrings.nodeName),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: _goodsLabelControlGap),
                        _buildGoodsNameField(),
                        if (!_isPermanentRoot) ...[
                          const SizedBox(height: 12),
                          // Position — roulette Biens
                          Text(
                            AppStrings.hierarchyPosition,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: _goodsLabelControlGap),
                          InventoryParentField(
                            controller: widget.controller,
                            allowRoot: false,
                            selected: _parent,
                            excludingSubtreeRootId: widget.existing?.id,
                            enabled: !_saving,
                            showQuickAdd: _supportsQuickLocation,
                            onQuickAdd: _quickCreateLocation,
                            compactRoulette: true,
                            onChanged: (next) => setState(() {
                              _parent = next;
                              _errorMessage = null;
                            }),
                          ),
                        ],
                        if (_isStockProduct) ...[
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.stockRemainingLevel,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: _goodsLabelControlGap),
                          SizedBox(
                            height: valuationControlHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InventoryStockLevelStepper(
                                level: _stockLevel,
                                enabled: !_saving,
                                onChanged: (next) =>
                                    unawaited(_onStockLevelChanged(next)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.stockQuantity,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: _goodsLabelControlGap),
                          SizedBox(
                            height: valuationControlHeight,
                            child: TextField(
                              controller: _stockReferenceController,
                              enabled: !_saving,
                              keyboardType: TextInputType.number,
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                          ),
                        ] else if (_isToBuyNeed) ...[
                          const SizedBox(height: 12),
                          Text(
                            _isEdit
                                ? AppStrings.remainingQuantity
                                : AppStrings.desiredQuantity,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: _goodsLabelControlGap),
                          SizedBox(
                            height: valuationControlHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: InventoryQuantityStepper(
                                value: _quantity,
                                enabled: !_saving,
                                onChanged: (value) =>
                                    setState(() => _quantity = value),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppStrings.targetPrice,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: _goodsLabelControlGap),
                          SizedBox(
                            height: valuationControlHeight,
                            child: TextField(
                              controller: _targetPriceController,
                              enabled: !_saving,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: Theme.of(context).textTheme.bodyLarge,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onChanged: (_) {
                                if (_errorMessage != null) {
                                  setState(() => _errorMessage = null);
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

abstract final class InventoryEngineDefaults {
  static const quantity = 1;
}
