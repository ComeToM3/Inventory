import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import '../core/domain/inventory_name.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'discard_changes_dialog.dart';
import 'inventory_action_bar.dart';
import 'inventory_parent_field.dart';
import 'inventory_thumb_layout.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';
import 'inventory_valuation_field.dart';
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
  });

  final InventoryTreeController controller;
  final NodeType type;
  final InventoryNode? initialParent;
  final InventoryNode? existing;

  @override
  State<InventoryCreationScreen> createState() =>
      _InventoryCreationScreenState();
}

class _InventoryCreationScreenState extends State<InventoryCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
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
  var _saving = false;
  var _createdOnce = false;
  var _ready = true;
  late NodeType _itemKind;
  late NodeType _initialItemKind;
  String? _errorMessage;

  bool get _isEdit => widget.existing != null;

  bool get _isStock => widget.controller.space == InventorySpace.stock;

  bool get _isItem => widget.type.isItem;

  bool get _isStockProduct =>
      _isStock &&
      (_isEdit ? widget.existing!.type == NodeType.item : widget.type == NodeType.item);

  bool get _supportsItemKind => _isItem && !_isStock;

  bool get _supportsQuickLocation => _isItem;

  bool get _supportsContinue => _isItem && !_isEdit;

  bool get _hasChanges {
    if (_isEdit) {
      return _nameController.text != _initialName ||
          _parent?.id != _initialParent?.id ||
          (_supportsItemKind && _itemKind != _initialItemKind) ||
          (_isStockProduct &&
              _stockReferenceController.text != _initialStockReference) ||
          (_isItem &&
              !_isStockProduct &&
              (_quantity != _initialQuantity ||
                  _valuationMode != _initialValuationMode ||
                  _valueController.text != _initialValue));
    }
    return _nameController.text.isNotEmpty ||
        _parent?.id != _baselineParent?.id ||
        (_isStockProduct && _stockReferenceController.text.isNotEmpty) ||
        (_isItem &&
            !_isStockProduct &&
            (_quantity != InventoryEngineDefaults.quantity ||
                _valuationMode != InventoryValuationMode.none ||
                _valueController.text.isNotEmpty));
  }

  String get _title {
    if (_isEdit) {
      if (_isStockProduct) {
        return '${AppStrings.edit} ${AppStrings.stockProductType}';
      }
      final type = _supportsItemKind ? _itemKind : widget.type;
      return '${AppStrings.edit} ${AppStrings.labelForNodeType(type)}';
    }
    if (_isStockProduct) return AppStrings.newStockProductTitle;
    return switch (widget.type) {
      NodeType.location => AppStrings.newLocationTitle,
      NodeType.item => AppStrings.newItemTitle,
      NodeType.itemContainer => AppStrings.newItemContainerTitle,
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
      if (node.type.isItem) {
        _itemKind = node.type;
        _initialItemKind = node.type;
      }
      _initialParent = path.length > 1 ? path[path.length - 2] : null;
      _parent = _initialParent;
      _baselineParent = _initialParent;
      if (node.isStockProduct) {
        _initialStockReference =
            node.stockReference == null ? '' : '${node.stockReference}';
        _stockReferenceController.text = _initialStockReference;
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
    _nameController.dispose();
    _valueController.dispose();
    _stockReferenceController.dispose();
    super.dispose();
  }

  int? get _parsedStockReference {
    final raw = _stockReferenceController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
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
      } else {
        _valuationMode = mode;
      }
      _valueController.clear();
      _errorMessage = null;
    });
  }

  NodeValuation? get _valuation {
    if (!_isItem || _valuationMode == InventoryValuationMode.none) return null;
    final raw = _valueController.text.trim();
    if (raw.isEmpty) return null;
    switch (_valuationMode) {
      case InventoryValuationMode.none:
        return null;
      case InventoryValuationMode.financial:
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
    if (!widget.type.canBeRoot && _parent == null) {
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
    if (!_isItem) return null;
    switch (_valuationMode) {
      case InventoryValuationMode.none:
        return null;
      case InventoryValuationMode.financial:
        if (_valueController.text.trim().isEmpty || _valuation == null) {
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
    try {
      final node = await widget.controller.createNodeAt(
        name: _nameController.text,
        type: widget.type,
        parentId: _parent?.id,
        quantity: _isItem && !_isStock ? _quantity : null,
        valuation: _isStock ? null : _valuation,
        stockReference: _isStockProduct ? _parsedStockReference : null,
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _createdOnce = true;
        });
      }
      return node;
    } on InventoryException catch (error) {
      if (!mounted) return null;
      setState(() {
        _saving = false;
        _errorMessage = _mapError(error, create: true);
      });
      return null;
    } catch (_) {
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
    try {
      final parentChanged = _parent?.id != _initialParent?.id;
      if (_isStockProduct) {
        await widget.controller.updateStockProduct(
          existing.id,
          name: _nameController.text,
          parentId: _parent?.id,
          stockReference: _parsedStockReference,
        );
      } else {
        final kindChanged =
            _supportsItemKind && _itemKind != _initialItemKind;
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
        );
      }
      if (mounted) setState(() => _saving = false);
      return true;
    } on InventoryException catch (error) {
      if (!mounted) return false;
      setState(() {
        _saving = false;
        _errorMessage = _mapError(error, create: false);
      });
      return false;
    } catch (_) {
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
    setState(() {
      _nameController.clear();
      _valueController.clear();
      _stockReferenceController.clear();
      _quantity = InventoryEngineDefaults.quantity;
      _valuationMode = InventoryValuationMode.none;
      _baselineParent = _parent;
      _errorMessage = null;
    });
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
      canPop: !_saving && !_hasChanges && !_createdOnce,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _saving) return;
        if (!_hasChanges && _createdOnce) {
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
                        if (_isEdit) ...[
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
                      Text(
                        AppStrings.hierarchyPosition,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      InventoryParentField(
                        controller: widget.controller,
                        allowRoot: widget.type.canBeRoot,
                        selected: _parent,
                        excludingSubtreeRootId: widget.existing?.id,
                        enabled: !_saving,
                        showQuickAdd: _supportsQuickLocation,
                        onQuickAdd: _quickCreateLocation,
                        onChanged: (next) => setState(() {
                          _parent = next;
                          _errorMessage = null;
                        }),
                      ),
                      if (_supportsItemKind && _isEdit) ...[
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.itemKindLabel,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        SegmentedButton<NodeType>(
                          segments: const [
                            ButtonSegment(
                              value: NodeType.item,
                              label: Text(AppStrings.itemType),
                              icon: Icon(Icons.view_in_ar_outlined),
                            ),
                            ButtonSegment(
                              value: NodeType.itemContainer,
                              label: Text(AppStrings.itemContainerType),
                              icon: Icon(Icons.luggage_outlined),
                            ),
                          ],
                          selected: {_itemKind},
                          onSelectionChanged: _saving
                              ? null
                              : (next) {
                                  if (next.isEmpty) return;
                                  setState(() {
                                    _itemKind = next.first;
                                    _errorMessage = null;
                                  });
                                },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.itemKindHelp,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: InventoryColors.mutedText),
                        ),
                      ],
                      if (_isStockProduct) ...[
                        const SizedBox(height: 14),
                        TextField(
                          controller: _stockReferenceController,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.stockQuantity,
                            helperText: AppStrings.stockReferenceHint,
                          ),
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                      ] else if (_isItem && !_isStock) ...[
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.nodeQuantity,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
                        InventoryQuantityStepper(
                          value: _quantity,
                          enabled: !_saving,
                          onChanged: (value) =>
                              setState(() => _quantity = value),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.valuationMode,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 6),
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
                      ],
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey('creation-name'),
                        controller: _nameController,
                        enabled: !_saving,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: _isEdit &&
                                _initialName.trim().length >
                                    InventoryName.maxLength
                            ? _initialName.trim().length
                            : InventoryName.maxLength,
                        decoration: InputDecoration(
                          labelText: _isStockProduct
                              ? AppStrings.stockProductType
                              : (_isItem
                                    ? AppStrings.itemNameLabel
                                    : AppStrings.nodeName),
                          counterText: '',
                        ),
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return AppStrings.nameRequired;
                          if (raw.length > InventoryName.maxLength &&
                              raw != _initialName.trim()) {
                            return AppStrings.nameTooLong(
                              InventoryName.maxLength,
                            );
                          }
                          return null;
                        },
                        onChanged: (_) {
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                        },
                      ),
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
