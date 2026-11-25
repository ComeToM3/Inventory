import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import '../core/domain/purchase_models.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_action_bar.dart';
import 'inventory_parent_field.dart';
import 'inventory_thumb_layout.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';
import 'inventory_valuation_field.dart';

/// Confirms a purchase for a to-buy need (partial or full).
class PurchaseAcquireScreen extends StatefulWidget {
  const PurchaseAcquireScreen({
    super.key,
    required this.toBuyController,
    required this.goodsController,
    required this.stockController,
    required this.need,
  });

  final InventoryTreeController toBuyController;
  final InventoryTreeController goodsController;
  final InventoryTreeController stockController;
  final InventoryNode need;

  @override
  State<PurchaseAcquireScreen> createState() => _PurchaseAcquireScreenState();
}

class _PurchaseAcquireScreenState extends State<PurchaseAcquireScreen> {
  final _paidController = TextEditingController();
  final _valueController = TextEditingController();
  late int _quantity;
  var _destination = InventorySpace.goods;
  var _stockMode = StockAcquireMode.createNew;
  InventoryNode? _destinationParent;
  InventoryNode? _existingStockProduct;
  var _valuationMode = InventoryValuationMode.none;
  var _saving = false;
  String? _errorMessage;
  List<InventoryNode> _stockProducts = const [];
  var _loadingProducts = false;

  int get _maxQuantity => widget.need.quantity ?? 1;

  @override
  void initState() {
    super.initState();
    _quantity = _maxQuantity;
  }

  @override
  void dispose() {
    _paidController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  InventoryTreeController get _destController =>
      _destination == InventorySpace.goods
          ? widget.goodsController
          : widget.stockController;

  Future<void> _ensureStockProducts() async {
    if (_loadingProducts || _stockProducts.isNotEmpty) return;
    setState(() => _loadingProducts = true);
    try {
      final roots = await widget.stockController.engine.getRootLocations(
        space: InventorySpace.stock,
      );
      final products = <InventoryNode>[];
      Future<void> walk(InventoryNode node) async {
        final children =
            await widget.stockController.engine.getChildren(node.id);
        for (final child in children) {
          if (child.isStockProduct) products.add(child);
          if (child.type.canContain) await walk(child);
        }
      }

      for (final root in roots) {
        await walk(root);
      }
      if (!mounted) return;
      setState(() {
        _stockProducts = products;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  int? _parseCents(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }

  NodeValuation? get _valuation {
    switch (_valuationMode) {
      case InventoryValuationMode.none:
        return null;
      case InventoryValuationMode.financial:
        final cents = _parseCents(_valueController.text);
        if (cents == null) return null;
        return FinancialValuation(cents);
      case InventoryValuationMode.sentimental:
        final rating = int.tryParse(_valueController.text.trim());
        if (rating == null ||
            rating < SentimentalValuation.minRating ||
            rating > SentimentalValuation.maxRating) {
          return null;
        }
        return SentimentalValuation(rating);
    }
  }

  String? _validate() {
    if (_quantity < 1 || _quantity > _maxQuantity) {
      return AppStrings.quantityInvalid;
    }
    final needsParent = _destination == InventorySpace.goods ||
        _stockMode == StockAcquireMode.createNew;
    if (needsParent && _destinationParent == null) {
      return AppStrings.parentRequired;
    }
    if (_destination == InventorySpace.stock &&
        _stockMode != StockAcquireMode.createNew &&
        _existingStockProduct == null) {
      return AppStrings.chooseStockProduct;
    }
    final paidRaw = _paidController.text.trim();
    if (paidRaw.isNotEmpty && _parseCents(paidRaw) == null) {
      return AppStrings.amountInvalid;
    }
    if (_destination == InventorySpace.goods) {
      switch (_valuationMode) {
        case InventoryValuationMode.none:
          break;
        case InventoryValuationMode.financial:
          if (_valuation == null) return AppStrings.amountInvalid;
        case InventoryValuationMode.sentimental:
          if (_valuation == null) return AppStrings.sentimentalRequired;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.toBuyController.acquireNeed(
        widget.need.id,
        quantity: _quantity,
        destinationSpace: _destination,
        destinationParentId: _destination == InventorySpace.goods ||
                _stockMode == StockAcquireMode.createNew
            ? _destinationParent?.id
            : null,
        existingStockProductId: _destination == InventorySpace.stock &&
                _stockMode != StockAcquireMode.createNew
            ? _existingStockProduct?.id
            : null,
        stockMode: _destination == InventorySpace.stock
            ? _stockMode
            : StockAcquireMode.createNew,
        paidPriceCents: _parseCents(_paidController.text),
        goodsValuation:
            _destination == InventorySpace.goods ? _valuation : null,
      );
      if (_destination == InventorySpace.goods) {
        widget.goodsController.resetAfterRestore();
      } else {
        widget.stockController.resetAfterRestore();
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on InventoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = switch (error.code) {
          InventoryErrorCode.invalidPurchaseQuantity ||
          InventoryErrorCode.invalidQuantity =>
            AppStrings.quantityInvalid,
          InventoryErrorCode.parentRequired ||
          InventoryErrorCode.parentNotFound ||
          InventoryErrorCode.parentInactive ||
          InventoryErrorCode.spaceMismatch =>
            AppStrings.parentUnavailable,
          InventoryErrorCode.invalidPurchaseDestination =>
            AppStrings.chooseStockProduct,
          InventoryErrorCode.invalidFinancialValue => AppStrings.amountInvalid,
          _ => AppStrings.purchaseError,
        };
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.purchaseError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.purchaseTitle)),
      body: InventoryThumbBody(
        footer: InventoryActionBar(
          errorMessage: _errorMessage,
          actions: [
            InventoryBarAction(
              label: AppStrings.purchaseAction,
              style: InventoryActionStyle.filled,
              onPressed: _saving ? null : () => unawaited(_submit()),
            ),
          ],
        ),
        children: [
          Text(
            inventoryDisplayName(widget.need.name),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${AppStrings.remainingQuantity} : $_maxQuantity',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: InventoryColors.mutedText,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.purchaseQuantity,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: valuationControlHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InventoryQuantityStepper(
                value: _quantity,
                enabled: !_saving,
                onChanged: (value) {
                  final next = value.clamp(1, _maxQuantity);
                  setState(() => _quantity = next);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.purchaseDestination,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: valuationControlHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: inventoryGoodsOutlinedStyle(
                      selected: _destination == InventorySpace.goods,
                    ),
                    onPressed: _saving
                        ? null
                        : () {
                            setState(() {
                              _destination = InventorySpace.goods;
                              _destinationParent = null;
                              _existingStockProduct = null;
                              _stockMode = StockAcquireMode.createNew;
                              _errorMessage = null;
                            });
                          },
                    child: const Text(AppStrings.destinationGoods),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: inventoryGoodsOutlinedStyle(
                      selected: _destination == InventorySpace.stock,
                    ),
                    onPressed: _saving
                        ? null
                        : () {
                            setState(() {
                              _destination = InventorySpace.stock;
                              _destinationParent = null;
                              _existingStockProduct = null;
                              _stockMode = StockAcquireMode.createNew;
                              _errorMessage = null;
                            });
                            unawaited(_ensureStockProducts());
                          },
                    child: const Text(AppStrings.destinationStock),
                  ),
                ),
              ],
            ),
          ),
          if (_destination == InventorySpace.stock) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.stockLinkMode,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<StockAcquireMode>(
              // ignore: deprecated_member_use
              value: _stockMode,
              items: const [
                DropdownMenuItem(
                  value: StockAcquireMode.createNew,
                  child: Text(AppStrings.stockCreateNew),
                ),
                DropdownMenuItem(
                  value: StockAcquireMode.keepLevel,
                  child: Text(AppStrings.stockKeepLevel),
                ),
                DropdownMenuItem(
                  value: StockAcquireMode.resetToFull,
                  child: Text(AppStrings.stockResetLevel),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _stockMode = value;
                        if (value == StockAcquireMode.createNew) {
                          _existingStockProduct = null;
                        }
                        _errorMessage = null;
                      });
                      if (value != StockAcquireMode.createNew) {
                        unawaited(_ensureStockProducts());
                      }
                    },
            ),
          ],
          if (_destination == InventorySpace.stock &&
              _stockMode != StockAcquireMode.createNew) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _existingStockProduct?.id,
              decoration: const InputDecoration(
                labelText: AppStrings.chooseStockProduct,
              ),
              items: [
                for (final product in _stockProducts)
                  DropdownMenuItem(
                    value: product.id,
                    child: Text(inventoryDisplayName(product.name)),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (id) {
                      setState(() {
                        _existingStockProduct = _stockProducts
                            .where((p) => p.id == id)
                            .firstOrNull;
                        _errorMessage = null;
                      });
                    },
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.hierarchyPosition,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            InventoryParentField(
              controller: _destController,
              allowRoot: false,
              selected: _destinationParent,
              enabled: !_saving,
              showQuickAdd: false,
              compactRoulette: true,
              onChanged: (next) => setState(() {
                _destinationParent = next;
                _errorMessage = null;
              }),
            ),
          ],
          if (_destination == InventorySpace.goods) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.goodsValuationOnPurchase,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            InventoryValuationField(
              mode: _valuationMode,
              controller: _valueController,
              enabled: !_saving,
              onModeChanged: (mode) => setState(() {
                _valuationMode = mode;
                _valueController.clear();
                _errorMessage = null;
              }),
              onChanged: () {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
          ],
          const SizedBox(height: 12),
          Text(
            AppStrings.paidPrice,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: valuationControlHeight,
            child: TextField(
              controller: _paidController,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
