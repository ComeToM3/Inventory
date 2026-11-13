import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/domain/inventory_exception.dart';
import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'discard_changes_dialog.dart';
import 'node_details_controller.dart';

class NodeEditScreen extends StatefulWidget {
  const NodeEditScreen({
    super.key,
    required this.controller,
    required this.details,
  });

  final NodeDetailsController controller;
  final InventoryNodeDetails details;

  @override
  State<NodeEditScreen> createState() => _NodeEditScreenState();
}

class _NodeEditScreenState extends State<NodeEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _condition;
  late final TextEditingController _quantity;
  final _newCategory = TextEditingController();
  late final TextEditingController _amount;
  late final bool _initialFinancial;
  late final String _initialAmount;
  late final int? _initialRating;
  late final Set<String> _initialCategories;
  late final Set<String> _selectedCategories;
  final _newCategories = <String>[];
  List<InventoryCategory> _categories = [];
  bool _loadingCategories = false;
  bool _categoryReadError = false;
  String? _categoryInputError;
  late bool _financial;
  int? _rating;
  bool _modeChanged = false;
  bool _saving = false;
  String? _errorMessage;

  bool get _hasChanges {
    final node = widget.details.node;
    return _name.text != node.name ||
        _description.text != (node.description ?? '') ||
        _condition.text != (node.condition ?? '') ||
        (node.type.isItem &&
            (_quantity.text != node.quantity.toString() ||
                _financial != _initialFinancial ||
                (_financial
                    ? _amount.text != _initialAmount
                    : _rating != _initialRating) ||
                !setEquals(_selectedCategories, _initialCategories) ||
                _newCategories.isNotEmpty ||
                _newCategory.text.isNotEmpty));
  }

  NodeValuation? get _editedValuation {
    if (_financial) {
      final cents = widget.controller.financialFeedback(_amount.text).cents;
      return cents == null ? null : FinancialValuation(cents);
    }
    return _rating == null ? null : SentimentalValuation(_rating!);
  }

  @override
  void initState() {
    super.initState();
    final node = widget.details.node;
    _name = TextEditingController(text: node.name);
    _description = TextEditingController(text: node.description);
    _condition = TextEditingController(text: node.condition);
    _quantity = TextEditingController(text: node.quantity?.toString());
    final valuation = node.valuation;
    _initialFinancial = valuation is FinancialValuation;
    _financial = _initialFinancial;
    _initialAmount = valuation is FinancialValuation
        ? '${valuation.unitCents ~/ 100},${(valuation.unitCents % 100).toString().padLeft(2, '0')}'
        : '';
    _amount = TextEditingController(text: _initialAmount);
    _initialRating = valuation is SentimentalValuation
        ? valuation.rating
        : null;
    _rating = _initialRating;
    _initialCategories = widget.details.categories
        .map((category) => category.id)
        .toSet();
    _selectedCategories = {..._initialCategories};
    if (node.type.isItem) unawaited(_loadCategories());
  }

  Future<void> _loadCategories() async {
    if (_loadingCategories) return;
    setState(() {
      _loadingCategories = true;
      _categoryReadError = false;
    });
    try {
      final categories = await widget.controller.readCategories();
      if (mounted) setState(() => _categories = categories);
    } on Exception {
      if (mounted) setState(() => _categoryReadError = true);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _condition.dispose();
    _quantity.dispose();
    _newCategory.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _changed(String _) => setState(() => _errorMessage = null);

  void _addCategory() {
    final name = _newCategory.text.trim();
    setState(() {
      if (name.isEmpty) {
        _categoryInputError = AppStrings.categoryNameRequired;
      } else {
        _newCategories.add(name);
        _newCategory.clear();
        _categoryInputError = null;
        _errorMessage = null;
      }
    });
  }

  void _changeMode(bool financial) {
    if (_financial == financial) return;
    setState(() {
      _financial = financial;
      _amount.text = financial ? '0,00' : '';
      _rating = null;
      _modeChanged = true;
      _errorMessage = null;
    });
  }

  Future<void> _cancel() async {
    if (_saving) return;
    if (_hasChanges) {
      final discard = await confirmDiscardChanges(
        context,
        title: AppStrings.editDiscardTitle,
      );
      if (!mounted || !discard) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save() async {
    if (_saving ||
        _loadingCategories ||
        _categoryReadError ||
        !_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.controller.save(
        name: _name.text,
        description: _description.text,
        condition: _condition.text,
        quantity: widget.details.node.type.isItem
            ? widget.controller.quantityFeedback(_quantity.text).value
            : null,
        valuation: widget.details.node.type.isItem ? _editedValuation : null,
        categoryIds: widget.details.node.type.isItem
            ? _selectedCategories
            : null,
        newCategoryNames: _newCategories,
      );
      if (mounted) Navigator.pop(context, true);
    } on InventoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = switch (error.code) {
          InventoryErrorCode.emptyName => AppStrings.nameRequired,
          InventoryErrorCode.invalidQuantity => AppStrings.quantityInvalid,
          InventoryErrorCode.financialTotalOverflow =>
            AppStrings.financialTotalOverflow,
          InventoryErrorCode.nodeNotFound ||
          InventoryErrorCode.nodeInactive => AppStrings.nodeUnavailable,
          InventoryErrorCode.categoryNotFound => AppStrings.categoriesReadError,
          _ => AppStrings.editError,
        };
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.editError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.details.node;
    final editedValuation = _editedValuation;
    final valuation = editedValuation == null
        ? null
        : widget.controller.valuationText(
            _quantity.text,
            valuation: editedValuation,
          );
    return PopScope<bool>(
      canPop: !_saving && !_hasChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) unawaited(_cancel());
      },
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.editTitle)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(AppStrings.labelForNodeType(node.type)),
                  const SizedBox(height: 8),
                  Text(
                    widget.details.path.map((part) => part.name).join(' → '),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: AppStrings.nodeName,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    onChanged: _changed,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? AppStrings.nameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: AppStrings.nodeDescription,
                    ),
                    minLines: 2,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _changed,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _condition,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: AppStrings.nodeCondition,
                    ),
                    textInputAction: node.type.isItem
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onChanged: _changed,
                  ),
                  if (node.type.isItem) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantity,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: AppStrings.nodeQuantity,
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      onChanged: _changed,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 1) {
                          return AppStrings.quantityInvalid;
                        }
                        if (editedValuation == null) return null;
                        return widget.controller
                            .quantityFeedback(
                              value ?? '',
                              valuation: editedValuation,
                            )
                            .error;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.nodeCategories,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_loadingCategories)
                      const Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: AppStrings.categoriesLoading,
                        ),
                      )
                    else if (_categoryReadError) ...[
                      const Text(AppStrings.categoriesReadError),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => unawaited(_loadCategories()),
                        child: const Text(AppStrings.retry),
                      ),
                    ] else ...[
                      for (final category in _categories)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(category.name),
                          value: _selectedCategories.contains(category.id),
                          onChanged: _saving
                              ? null
                              : (selected) => setState(() {
                                  if (selected == true) {
                                    _selectedCategories.add(category.id);
                                  } else {
                                    _selectedCategories.remove(category.id);
                                  }
                                  _errorMessage = null;
                                }),
                        ),
                      for (
                        var index = 0;
                        index < _newCategories.length;
                        index++
                      )
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(_newCategories[index]),
                          trailing: IconButton(
                            tooltip: AppStrings.removeCategory(
                              _newCategories[index],
                            ),
                            onPressed: _saving
                                ? null
                                : () => setState(() {
                                    _newCategories.removeAt(index);
                                  }),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        ),
                      TextFormField(
                        controller: _newCategory,
                        enabled: !_saving,
                        decoration: InputDecoration(
                          labelText: AppStrings.newCategoryName,
                          errorText: _categoryInputError,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {
                          _categoryInputError = null;
                          _errorMessage = null;
                        }),
                        onFieldSubmitted: (_) => _addCategory(),
                        validator: (value) => (value ?? '').trim().isNotEmpty
                            ? AppStrings.pendingCategoryName
                            : null,
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : _addCategory,
                        icon: const Icon(Icons.add),
                        label: const Text(AppStrings.addCategory),
                      ),
                      if (_newCategories.isNotEmpty)
                        const Text(AppStrings.categoryCreatedOnSave),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<bool>(
                      initialValue: _financial,
                      decoration: const InputDecoration(
                        labelText: AppStrings.valuationMode,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: true,
                          child: Text(AppStrings.financialMode),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text(AppStrings.sentimentalMode),
                        ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value != null) _changeMode(value);
                            },
                    ),
                    if (_modeChanged) ...[
                      const SizedBox(height: 8),
                      const Text(AppStrings.valuationChangeNotice),
                    ],
                    const SizedBox(height: 16),
                    if (_financial)
                      TextFormField(
                        controller: _amount,
                        enabled: !_saving,
                        decoration: const InputDecoration(
                          labelText: AppStrings.financialInput,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: _changed,
                        validator: (value) => widget.controller
                            .financialFeedback(value ?? '')
                            .error,
                      )
                    else
                      DropdownButtonFormField<int>(
                        key: ValueKey(_financial),
                        initialValue: _rating,
                        decoration: const InputDecoration(
                          labelText: AppStrings.sentimentalInput,
                        ),
                        items: [
                          for (var rating = 1; rating <= 5; rating++)
                            DropdownMenuItem(
                              value: rating,
                              child: Text(AppStrings.sentimentalRating(rating)),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() {
                                _rating = value;
                                _errorMessage = null;
                              }),
                        validator: (value) => value == null
                            ? AppStrings.sentimentalRequired
                            : null,
                      ),
                    if (valuation != null) ...[
                      const SizedBox(height: 16),
                      Text(valuation),
                    ],
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
                    onPressed:
                        _saving ||
                            _loadingCategories ||
                            _categoryReadError ||
                            !_hasChanges
                        ? null
                        : () => unawaited(_save()),
                    child: Text(_saving ? AppStrings.saving : AppStrings.save),
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
