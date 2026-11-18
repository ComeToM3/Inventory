import 'package:flutter/material.dart';

import '../core/domain/stock_quantity.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';

class StockHistoryScreen extends StatefulWidget {
  const StockHistoryScreen({
    super.key,
    required this.controller,
    this.nodeId,
  });

  final InventoryTreeController controller;

  /// When set, shows movements for one product; otherwise recent Stock-wide.
  final String? nodeId;

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  var _loading = true;
  String? _error;
  List<StockLedgerEntryNamed> _rows = const [];

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
      if (widget.nodeId != null) {
        final entries =
            await widget.controller.readStockMovements(widget.nodeId!);
        final node = await widget.controller.engine.getNode(widget.nodeId!);
        _rows = [
          for (final entry in entries)
            StockLedgerEntryNamed(
              entry: entry,
              productName: node.name,
            ),
        ];
      } else {
        _rows = await widget.controller.readRecentStockMovements();
      }
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
      return const Center(child: Text(AppStrings.stockHistoryEmpty));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final entry = row.entry;
        final when = AppStrings.formatDateTime(entry.createdAt);
        final change = entry.type == StockMovementType.initial
            ? entry.levelAfter.label
            : AppStrings.stockLevelChange(
                entry.levelBefore.label,
                entry.levelAfter.label,
              );
        return ListTile(
          title: Text(inventoryDisplayName(row.productName)),
          subtitle: Text(
            '${AppStrings.labelForStockMovement(entry.type)} · $change\n$when',
          ),
          isThreeLine: true,
        );
      },
    );
  }
}
