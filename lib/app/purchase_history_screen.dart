import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import '../core/domain/purchase_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key, required this.controller});

  final InventoryTreeController controller;

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  var _loading = true;
  String? _error;
  List<PurchaseLedgerEntryNamed> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _rows = await widget.controller.readRecentPurchaseEvents();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppStrings.historyReadError;
      });
    }
  }

  String _subtitle(PurchaseLedgerEntry entry) {
    final when = AppStrings.formatDateTime(entry.createdAt);
    final kind = AppStrings.labelForPurchaseEvent(entry.type);
    if (entry.type == PurchaseEventType.abandon) {
      return '$kind · ${AppStrings.quantity(entry.quantity)}\n$when';
    }
    final dest = entry.destinationSpace == InventorySpace.stock
        ? AppStrings.destinationStock
        : AppStrings.destinationGoods;
    final paid = entry.paidPriceCents == null
        ? ''
        : ' · ${AppStrings.listPrice(entry.paidPriceCents!)}';
    return '$kind · ${AppStrings.quantity(entry.quantity)} → $dest$paid\n$when';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            TextButton(onPressed: _load, child: const Text(AppStrings.retry)),
          ],
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(child: Text(AppStrings.purchaseHistoryEmpty));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = _rows[index];
        return ListTile(
          title: Text(inventoryDisplayName(row.needName)),
          subtitle: Text(_subtitle(row.entry)),
          isThreeLine: true,
        );
      },
    );
  }
}
