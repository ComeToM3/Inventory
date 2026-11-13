import 'dart:async';

import 'package:flutter/material.dart';

import '../core/domain/inventory_engine.dart';
import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'discard_changes_dialog.dart';
import 'inventory_tree_controller.dart';

class InventoryCreationScreen extends StatefulWidget {
  const InventoryCreationScreen({
    super.key,
    required this.controller,
    required this.parent,
    required this.allowedTypes,
    required this.initialType,
  });

  final InventoryTreeController controller;
  final InventoryNode? parent;
  final List<NodeType> allowedTypes;
  final NodeType initialType;

  @override
  State<InventoryCreationScreen> createState() =>
      _InventoryCreationScreenState();
}

class _InventoryCreationScreenState extends State<InventoryCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late NodeType _selectedType;
  bool _saving = false;
  String? _errorMessage;

  bool get _hasChanges =>
      _nameController.text.isNotEmpty || _selectedType != widget.initialType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_saving) return;
    if (_hasChanges) {
      final discard = await confirmDiscardChanges(
        context,
        title: AppStrings.discardTitle,
      );
      if (!mounted || !discard) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await widget.controller.createNode(
        name: _nameController.text,
        type: _selectedType,
        parentId: widget.parent?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } on InventoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = switch (error.code) {
          InventoryErrorCode.emptyName => AppStrings.nameRequired,
          InventoryErrorCode.parentNotFound ||
          InventoryErrorCode.parentInactive ||
          InventoryErrorCode.parentCannotContain ||
          InventoryErrorCode.inventoryMismatch ||
          InventoryErrorCode.invalidHierarchy => AppStrings.parentUnavailable,
          _ => AppStrings.creationError,
        };
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.creationError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.parent;
    return PopScope<bool>(
      canPop: !_saving && !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) unawaited(_cancel());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.createTitle)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    parent == null
                        ? AppStrings.rootLocation
                        : AppStrings.parentName(parent.name),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  if (widget.allowedTypes.length == 1)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: AppStrings.nodeType,
                      ),
                      child: Text(AppStrings.labelForNodeType(_selectedType)),
                    )
                  else
                    DropdownButtonFormField<NodeType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: AppStrings.nodeType,
                      ),
                      items: [
                        for (final type in widget.allowedTypes)
                          DropdownMenuItem(
                            value: type,
                            child: Text(AppStrings.labelForNodeType(type)),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (type) {
                              if (type == null) return;
                              setState(() {
                                _selectedType = type;
                                _errorMessage = null;
                              });
                            },
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_saving,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: AppStrings.nodeName,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AppStrings.nameRequired
                        : null,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onFieldSubmitted: (_) => unawaited(_save()),
                  ),
                  if (_selectedType.isItem) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.initialItemValues(
                        InventoryEngine.defaultItemQuantity,
                        InventoryEngine.defaultFinancialCents,
                      ),
                    ),
                  ],
                  if (_errorMessage case final message?) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : () => unawaited(_save()),
                    child: Text(
                      _saving ? AppStrings.creating : AppStrings.create,
                    ),
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => unawaited(_cancel()),
                    child: const Text(AppStrings.cancel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
