import 'package:flutter/material.dart';

import '../core/domain/inventory_models.dart';
import 'app_strings.dart';

/// Compact list of supporting documents in the goods advanced section
/// (M4.2-B / UX-CORR-03). Add action lives on the shared media row.
class GoodsDocumentsField extends StatelessWidget {
  const GoodsDocumentsField({
    super.key,
    required this.documents,
    required this.enabled,
    required this.busy,
    required this.onOpen,
    required this.onRemove,
  });

  final List<GoodsDocumentListItem> documents;
  final bool enabled;
  final bool busy;
  final ValueChanged<GoodsDocumentListItem> onOpen;
  final ValueChanged<GoodsDocumentListItem> onRemove;

  @override
  Widget build(BuildContext context) {
    // Title lives beside « Photo principale » on the shared media row (UX-CORR-06).
    // No empty-state caption — list appears only when documents exist.
    if (documents.isEmpty && !busy) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final doc in documents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              doc.mimeType == 'application/pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.insert_drive_file_outlined,
            ),
            title: Text(doc.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(AppStrings.documentSizeLabel(doc.byteSize)),
            trailing: IconButton(
              tooltip: AppStrings.removeDocument,
              onPressed: enabled && !busy ? () => onRemove(doc) : null,
              icon: const Icon(Icons.close),
            ),
            onTap: enabled && !busy ? () => onOpen(doc) : null,
          ),
        if (busy) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Expanded(child: Text(AppStrings.documentProcessing)),
            ],
          ),
        ],
      ],
    );
  }
}

/// UI row for either a saved [NodeDocument] or a pending local copy.
class GoodsDocumentListItem {
  const GoodsDocumentListItem({
    required this.key,
    required this.displayName,
    required this.mimeType,
    required this.byteSize,
    this.saved,
    this.pendingRelPath,
    this.pendingTempPath,
  });

  factory GoodsDocumentListItem.saved(NodeDocument doc) {
    return GoodsDocumentListItem(
      key: 'saved-${doc.id}',
      displayName: doc.displayName,
      mimeType: doc.mimeType,
      byteSize: doc.byteSize,
      saved: doc,
    );
  }

  final String key;
  final String displayName;
  final String mimeType;
  final int byteSize;
  final NodeDocument? saved;
  final String? pendingRelPath;
  final String? pendingTempPath;

  bool get isPending => saved == null;
}
