import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';
import 'app_theme.dart';

/// Compact consultation sub-line: photo · documents · objective (UX-ARB-02).
///
/// Edit is usually placed by the parent in the trailing action column.
class InventoryInlineSheet extends StatefulWidget {
  const InventoryInlineSheet({
    super.key,
    required this.node,
    required this.pathLabel,
    this.onEdit,
    this.editLabel,
    this.showEditButton = true,
    this.loadHasDocuments,
  });

  final InventoryNode node;
  final String pathLabel;
  final VoidCallback? onEdit;
  final String? editLabel;

  /// When false, the parent places the edit control under the trailing `+`.
  final bool showEditButton;

  /// Goods items only; omitted → no document indicator.
  final Future<bool> Function()? loadHasDocuments;

  static bool hasMainPhoto(InventoryNode node) =>
      node.space == InventorySpace.goods &&
      node.type.isItem &&
      (node.photoRelPath?.trim().isNotEmpty ?? false);

  static String? objectiveLabel(InventoryNode node) {
    if (node.space != InventorySpace.goods || !node.type.isItem) {
      return null;
    }
    return switch (node.objective) {
      ItemObjective.sell || ItemObjective.repair =>
        AppStrings.labelForObjective(node.objective),
      ItemObjective.none => null,
    };
  }

  @override
  State<InventoryInlineSheet> createState() => _InventoryInlineSheetState();
}

class _InventoryInlineSheetState extends State<InventoryInlineSheet> {
  bool _hasDocuments = false;
  var _docsLoaded = false;

  @override
  void initState() {
    super.initState();
    _refreshDocuments();
  }

  @override
  void didUpdateWidget(covariant InventoryInlineSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.node.id != widget.node.id ||
        oldWidget.node.photoRelPath != widget.node.photoRelPath ||
        oldWidget.node.objective != widget.node.objective) {
      _refreshDocuments();
    }
  }

  Future<void> _refreshDocuments() async {
    final load = widget.loadHasDocuments;
    final eligible =
        widget.node.space == InventorySpace.goods && widget.node.type.isItem;
    if (!eligible || load == null) {
      if (mounted) {
        setState(() {
          _hasDocuments = false;
          _docsLoaded = true;
        });
      }
      return;
    }
    setState(() => _docsLoaded = false);
    try {
      final has = await load();
      if (!mounted) return;
      setState(() {
        _hasDocuments = has;
        _docsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasDocuments = false;
        _docsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = InventoryInlineSheet.hasMainPhoto(widget.node);
    final objective = InventoryInlineSheet.objectiveLabel(widget.node);
    final showDocs = _docsLoaded && _hasDocuments;

    final indicators = <Widget>[
      if (hasPhoto)
        const Icon(
          Icons.photo_outlined,
          size: 18,
          color: InventoryColors.petroleum,
        ),
      if (showDocs)
        const Icon(
          Icons.attach_file,
          size: 18,
          color: InventoryColors.petroleum,
        ),
      if (objective != null)
        Text(
          objective,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: InventoryColors.mutedText,
            fontSize: 13,
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: indicators.isEmpty
                ? const SizedBox.shrink()
                : Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 0,
                    children: indicators,
                  ),
          ),
          if (widget.showEditButton && widget.onEdit != null)
            IconButton(
              tooltip: widget.editLabel ?? AppStrings.edit,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: widget.onEdit,
              icon: Icon(
                widget.editLabel == null
                    ? Icons.edit_outlined
                    : Icons.drive_file_move_outline,
                size: 20,
                color: InventoryColors.petroleum,
              ),
            ),
        ],
      ),
    );
  }
}
