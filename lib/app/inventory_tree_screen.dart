import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';

const _indentPerLevel = 16.0;
const _maxVisualIndent = 80.0;

class InventoryTreeScreen extends StatefulWidget {
  const InventoryTreeScreen({
    super.key,
    required this.controller,
    this.onAddRoot,
    this.onAddChild,
    this.onChooseParent,
    this.onOpenNode,
  });

  final InventoryTreeController controller;
  final VoidCallback? onAddRoot;
  final ValueChanged<InventoryNode>? onAddChild;
  final ValueChanged<InventoryNode>? onChooseParent;
  final ValueChanged<InventoryNode>? onOpenNode;

  @override
  State<InventoryTreeScreen> createState() => _InventoryTreeScreenState();
}

class _InventoryTreeScreenState extends State<InventoryTreeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final roots = controller.roots;
        if (controller.loadingRoots && roots == null) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: AppStrings.inventoryLoading,
            ),
          );
        }
        if (controller.rootError && (roots?.isEmpty ?? true)) {
          return _CenteredMessage(
            message: AppStrings.inventoryReadError,
            action: TextButton(
              onPressed: controller.loadRoots,
              child: const Text(AppStrings.retry),
            ),
          );
        }
        if (roots?.isEmpty ?? false) {
          return _CenteredMessage(
            message: AppStrings.inventoryEmpty,
            action: widget.onAddRoot == null
                ? null
                : FilledButton.icon(
                    onPressed: widget.onAddRoot,
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.addRootLocation),
                  ),
          );
        }

        final entries = controller.visibleEntries;
        return Column(
          children: [
            if (controller.rootError)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Expanded(child: Text(AppStrings.inventoryReadError)),
                    TextButton(
                      onPressed: controller.loadRoots,
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              )
            else
              const SizedBox.shrink(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final node = entry.node;
                  final expanded = controller.isExpanded(node.id);
                  final loading =
                      expanded && controller.isLoadingChildren(node.id);
                  final error = expanded && controller.hasChildError(node.id);
                  final quantity = node.quantity;
                  final indent = (entry.depth * _indentPerLevel).clamp(
                    0.0,
                    _maxVisualIndent,
                  );
                  return Padding(
                    padding: EdgeInsetsDirectional.only(start: indent),
                    child: Semantics(
                      expanded: node.type.canContain ? expanded : null,
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              child: node.type.canContain
                                  ? Icon(
                                      expanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.chevron_right,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _nodeIcon(node.type),
                              semanticLabel: AppStrings.labelForNodeType(
                                node.type,
                              ),
                            ),
                          ],
                        ),
                        title: Text(node.name),
                        subtitle: error
                            ? const Text(AppStrings.branchReadError)
                            : quantity != null && quantity > 1
                            ? Text(AppStrings.quantity(quantity))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (loading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  semanticsLabel: AppStrings.branchLoading,
                                ),
                              )
                            else if (error)
                              IconButton(
                                onPressed: () =>
                                    controller.retryChildren(node.id),
                                icon: const Icon(Icons.refresh),
                                tooltip: AppStrings.retry,
                              ),
                            if (widget.onOpenNode case final open?)
                              IconButton(
                                onPressed: () => open(node),
                                icon: const Icon(Icons.info_outline),
                                tooltip: AppStrings.viewNode(node.name),
                              ),
                            if (node.type.canContain &&
                                (widget.onChooseParent != null ||
                                    widget.onAddChild != null))
                              IconButton(
                                onPressed: () {
                                  final choose = widget.onChooseParent;
                                  if (choose != null) {
                                    choose(node);
                                  } else {
                                    widget.onAddChild!(node);
                                  }
                                },
                                icon: Icon(
                                  widget.onChooseParent != null
                                      ? Icons.check_circle_outline
                                      : Icons.add_circle_outline,
                                ),
                                tooltip: widget.onChooseParent != null
                                    ? AppStrings.chooseInside(node.name)
                                    : AppStrings.addInside(node.name),
                              ),
                          ],
                        ),
                        onTap: node.type.canContain
                            ? () => controller.toggle(node)
                            : widget.onOpenNode == null
                            ? null
                            : () => widget.onOpenNode!(node),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action case final button?) ...[
              const SizedBox(height: 16),
              button,
            ],
          ],
        ),
      ),
    );
  }
}

IconData _nodeIcon(NodeType type) => switch (type) {
  NodeType.location => Icons.home_work_outlined,
  NodeType.container => Icons.inventory_2_outlined,
  NodeType.item => Icons.view_in_ar_outlined,
  NodeType.itemContainer => Icons.luggage_outlined,
};
