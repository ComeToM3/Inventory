import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'inventory_tree_controller.dart';
import 'node_move_controller.dart';

class NodeMoveScreen extends StatefulWidget {
  const NodeMoveScreen({
    super.key,
    required this.inventory,
    required this.node,
    required this.onMoved,
    this.revealDestination = true,
  });

  final InventoryTreeController inventory;
  final InventoryNode node;
  final Future<void> Function() onMoved;
  final bool revealDestination;

  @override
  State<NodeMoveScreen> createState() => _NodeMoveScreenState();
}

class _NodeMoveScreenState extends State<NodeMoveScreen> {
  late final NodeMoveController _controller;
  bool _confirming = false;
  bool _finishing = false;

  bool get _busy => _controller.moving || _finishing;

  @override
  void initState() {
    super.initState();
    _controller = NodeMoveController(
      widget.inventory,
      widget.node,
      revealDestination: widget.revealDestination,
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmAndMove() async {
    if (_confirming || _busy || !_controller.canChoose) return;
    setState(() => _confirming = true);
    try {
      var answered = false;
      void answer(BuildContext dialogContext, bool value) {
        if (answered) return;
        answered = true;
        Navigator.pop(dialogContext, value);
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.confirmMove),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.moveTo(
                    widget.node.name,
                    _controller.destinationPath,
                  ),
                ),
                if (widget.node.type.canContain) ...[
                  const SizedBox(height: 16),
                  const Text(AppStrings.moveWithContents),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => answer(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => answer(context, true),
              child: const Text(AppStrings.move),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      final moved = await _controller.move();
      if (!mounted || !moved) return;
      setState(() => _finishing = true);
      await widget.onMoved();
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => PopScope<bool>(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(title: const Text(AppStrings.chooseDestination)),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    key: ValueKey(_controller.destinationPath),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        widget.node.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      const Text(AppStrings.destination),
                      Text(_controller.destinationPath),
                      if (_controller.isCurrentParent)
                        const Text(AppStrings.currentDestination),
                      if (_controller.canGoUp)
                        ListTile(
                          leading: const Icon(Icons.arrow_upward),
                          title: const Text(AppStrings.parentLevel),
                          onTap: _busy
                              ? null
                              : () => unawaited(_controller.goUp()),
                        ),
                      const Divider(),
                      if (_controller.loading)
                        const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: AppStrings.branchLoading,
                          ),
                        )
                      else if (_controller.readError case final error?) ...[
                        Text(error),
                        TextButton(
                          onPressed: () => unawaited(_controller.load()),
                          child: const Text(AppStrings.retry),
                        ),
                      ] else if (_controller.children.isEmpty)
                        Text(
                          _controller.canChoose
                              ? AppStrings.noChildDestinations
                              : AppStrings.noMoveDestinations,
                        )
                      else
                        for (final child in _controller.children)
                          ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title: Text(child.name),
                            subtitle: Text(
                              AppStrings.labelForNodeType(child.type),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: _busy
                                ? null
                                : () => unawaited(_controller.enter(child)),
                          ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_controller.moveError case final error?)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      FilledButton(
                        onPressed:
                            _busy || _confirming || !_controller.canChoose
                            ? null
                            : () => unawaited(_confirmAndMove()),
                        child: Text(
                          _busy ? AppStrings.moving : AppStrings.moveHere,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: const Text(AppStrings.cancel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
