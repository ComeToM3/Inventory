import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import '../core/icons/inventory_icon_catalog.dart';
import '../core/icons/inventory_icon_resolver.dart';
import 'app_strings.dart';
import 'app_theme.dart';
import 'inventory_ui.dart';

/// Compact bottom sheet to pick or clear a manual icon (no dedicated screen).
Future<String?> showInventoryIconPickerSheet({
  required BuildContext context,
  required String name,
  required NodeType type,
  String? currentManualKey,
}) {
  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _IconPickerBody(
        name: name,
        type: type,
        currentManualKey: currentManualKey,
      );
    },
  );
}

class _IconPickerBody extends StatefulWidget {
  const _IconPickerBody({
    required this.name,
    required this.type,
    required this.currentManualKey,
  });

  final String name;
  final NodeType type;
  final String? currentManualKey;

  @override
  State<_IconPickerBody> createState() => _IconPickerBodyState();
}

class _IconPickerBodyState extends State<_IconPickerBody> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final autoKey = InventoryIconResolver.resolveKey(
      name: widget.name,
      type: widget.type,
    );
    final autoIcon = inventoryIconForName(
      name: widget.name,
      type: widget.type,
    );
    final q = InventoryIconResolver.normalize(_query.text);
    final keys = InventoryIconCatalog.selectableKeys.where((key) {
      if (q.isEmpty) return true;
      return key.contains(q.replaceAll(' ', '_')) || key.contains(q);
    }).toList();

    final height = MediaQuery.sizeOf(context).height * 0.55;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                AppStrings.iconPickerTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _query,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: AppStrings.iconPickerSearch,
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            ListTile(
              leading: Icon(autoIcon, color: InventoryColors.petroleum),
              title: Text(
                autoKey == null
                    ? AppStrings.iconAutomaticGeneric
                    : AppStrings.iconAutomaticNamed(autoKey),
              ),
              subtitle: const Text(AppStrings.iconAutomaticHelp),
              trailing: widget.currentManualKey == null
                  ? const Icon(Icons.check, color: InventoryColors.petroleum)
                  : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            const Divider(height: 1),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: keys.length,
                itemBuilder: (context, index) {
                  final key = keys[index];
                  final icon = InventoryIconCatalog.byKey(key)!;
                  final selected = widget.currentManualKey == key;
                  return InkWell(
                    onTap: () => Navigator.pop(context, key),
                    borderRadius: BorderRadius.circular(10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: selected
                            ? InventoryColors.mintSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? InventoryColors.petroleum
                              : InventoryColors.mintSoft,
                        ),
                      ),
                      child: Icon(icon, color: InventoryColors.petroleum),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
