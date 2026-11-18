import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_history_controller.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';
import 'withdrawn_node_details_screen.dart';

class InventoryHistoryScreen extends StatefulWidget {
  const InventoryHistoryScreen({
    super.key,
    required this.inventory,
    required this.active,
  });

  final InventoryTreeController inventory;
  final bool active;

  @override
  State<InventoryHistoryScreen> createState() => _InventoryHistoryScreenState();
}

class _InventoryHistoryScreenState extends State<InventoryHistoryScreen> {
  late final InventoryHistoryController _controller;
  final _scrollController = ScrollController();
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _controller = InventoryHistoryController(widget.inventory);
    if (widget.active) _activate();
  }

  @override
  void didUpdateWidget(covariant InventoryHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _activate();
  }

  void _activate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.active) return;
      unawaited(_controller.refresh());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openItem(InventoryNode node) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => WithdrawnNodeDetailsScreen(
            inventory: widget.inventory,
            nodeId: node.id,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        unawaited(_controller.refresh());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final error = _controller.readError;
        final items = _controller.items;
        if (_controller.loading && items.isEmpty && error == null) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: AppStrings.historyLoading,
            ),
          );
        }
        if (error != null && items.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => unawaited(_controller.refresh()),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          );
        }
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(AppStrings.historyEmpty, textAlign: TextAlign.center),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length + (error == null ? 0 : 1),
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (error != null && index == 0) {
                return ListTile(
                  title: Text(error),
                  trailing: TextButton(
                    onPressed: () => unawaited(_controller.refresh()),
                    child: const Text(AppStrings.retry),
                  ),
                );
              }
              final item = items[error == null ? index : index - 1];
              return ListTile(
                leading: Icon(
                  inventoryNodeIcon(item.type),
                  color: InventoryColors.petroleum,
                ),
                title: Text(
                  inventoryDisplayName(item.name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: InventoryColors.petroleumDark,
                  ),
                ),
                subtitle: Text(
                  AppStrings.historyReasonDate(
                    item.withdrawalReason,
                    item.withdrawnAt,
                  ),
                  style: const TextStyle(color: InventoryColors.mutedText),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: InventoryColors.mutedText,
                ),
                onTap: _opening ? null : () => unawaited(_openItem(item)),
              );
            },
          ),
        );
      },
    );
  }
}
