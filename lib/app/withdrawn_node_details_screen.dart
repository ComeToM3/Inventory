import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';
import 'inventory_ui.dart';
import 'withdrawn_node_details_controller.dart';

class WithdrawnNodeDetailsScreen extends StatefulWidget {
  const WithdrawnNodeDetailsScreen({
    super.key,
    required this.inventory,
    required this.nodeId,
  });

  final InventoryTreeController inventory;
  final String nodeId;

  @override
  State<WithdrawnNodeDetailsScreen> createState() =>
      _WithdrawnNodeDetailsScreenState();
}

class _WithdrawnNodeDetailsScreenState
    extends State<WithdrawnNodeDetailsScreen> {
  late final WithdrawnNodeDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WithdrawnNodeDetailsController(
      widget.inventory,
      widget.nodeId,
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final node = _controller.node;
        final error = _controller.readError;
        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.historyDetailsTitle)),
          body: SafeArea(
            child: _controller.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: AppStrings.historyDetailsLoading,
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
                : node == null
                ? const SizedBox.shrink()
                : _content(context, node),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, InventoryNode node) {
    final valuation = _controller.valuationText();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SelectableText(
          inventoryDisplayName(node.name),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _DetailField(
          label: AppStrings.nodeType,
          value: AppStrings.labelForNodeType(node.type),
        ),
        if (node.withdrawalReason case final reason?)
          _DetailField(
            label: AppStrings.withdrawalReason,
            value: AppStrings.labelForWithdrawalReason(reason),
          ),
        if (node.withdrawnAt case final withdrawnAt?)
          _DetailField(
            label: AppStrings.withdrawnAt,
            value: AppStrings.formatDateTime(withdrawnAt),
          ),
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
