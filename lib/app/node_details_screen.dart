import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';
import 'node_details_controller.dart';
import 'node_edit_screen.dart';
import 'node_move_screen.dart';

class NodeDetailsScreen extends StatefulWidget {
  const NodeDetailsScreen({
    super.key,
    required this.inventory,
    required this.nodeId,
    this.revealMovedNode = true,
  });

  final InventoryTreeController inventory;
  final String nodeId;
  final bool revealMovedNode;

  @override
  State<NodeDetailsScreen> createState() => _NodeDetailsScreenState();
}

class _NodeDetailsScreenState extends State<NodeDetailsScreen> {
  late final NodeDetailsController _controller;
  bool _actionRouteOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = NodeDetailsController(widget.inventory, widget.nodeId);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _edit(InventoryNodeDetails details) => _openAction(
    NodeEditScreen(controller: _controller, details: details),
    AppStrings.editSuccess,
  );

  Future<void> _move(InventoryNodeDetails details) => _openAction(
    NodeMoveScreen(
      inventory: widget.inventory,
      node: details.node,
      onMoved: _controller.load,
      revealDestination: widget.revealMovedNode,
    ),
    AppStrings.moveSuccess,
  );

  Future<void> _openAction(Widget screen, String successMessage) async {
    if (_actionRouteOpen) return;
    setState(() => _actionRouteOpen = true);
    try {
      final saved = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => screen));
      if (!mounted || saved != true) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    } finally {
      if (mounted) setState(() => _actionRouteOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final details = _controller.details;
        final error = _controller.readError;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.detailsTitle),
            actions: [
              if (details != null && error == null && !_controller.loading) ...[
                TextButton(
                  onPressed: _controller.saving || _actionRouteOpen
                      ? null
                      : () => unawaited(_edit(details)),
                  child: const Text(AppStrings.edit),
                ),
                TextButton(
                  onPressed: _controller.saving || _actionRouteOpen
                      ? null
                      : () => unawaited(_move(details)),
                  child: const Text(AppStrings.move),
                ),
              ],
            ],
          ),
          body: SafeArea(
            child: _controller.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: AppStrings.detailsLoading,
                    ),
                  )
                : error != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(error, textAlign: TextAlign.center),
                          TextButton(
                            onPressed: () => unawaited(_controller.load()),
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                : details == null
                ? const SizedBox.shrink()
                : _content(context, details),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, InventoryNodeDetails details) {
    final node = details.node;
    final path = details.path;
    final parent = path.length > 1
        ? path[path.length - 2].name
        : AppStrings.rootLocation;
    final valuation = _controller.valuationText(
      node.quantity?.toString() ?? '',
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SelectableText(
          node.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _DetailField(
          label: AppStrings.nodeType,
          value: AppStrings.labelForNodeType(node.type),
        ),
        _DetailField(label: AppStrings.nodeParent, value: parent),
        _DetailField(
          label: AppStrings.nodePath,
          value: path.map((part) => part.name).join(' → '),
        ),
        if (node.description case final description?)
          _DetailField(label: AppStrings.nodeDescription, value: description),
        if (node.condition case final condition?)
          _DetailField(label: AppStrings.nodeCondition, value: condition),
        if (node.type.isItem) ...[
          _DetailField(
            label: AppStrings.nodeQuantity,
            value: node.quantity.toString(),
          ),
          if (valuation != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SelectableText(valuation),
            ),
          if (details.categories.isNotEmpty)
            _DetailField(
              label: AppStrings.nodeCategories,
              value: details.categories
                  .map((category) => category.name)
                  .join('\n'),
            ),
        ],
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          SelectableText(value),
        ],
      ),
    );
  }
}
