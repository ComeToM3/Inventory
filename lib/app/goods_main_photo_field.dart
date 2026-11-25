import 'dart:io';

import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'inventory_ui.dart' show inventoryGoodsOutlinedStyle;
import 'inventory_valuation_field.dart' show valuationControlHeight;

/// Compact media actions for the goods fiche (M4.2-A / UX-CORR-06).
///
/// Single title « Photo et document » above Galerie · Caméra · Reçus.
class GoodsMainPhotoField extends StatelessWidget {
  const GoodsMainPhotoField({
    super.key,
    required this.previewFile,
    required this.enabled,
    required this.busy,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickDocument,
    required this.onRemove,
  });

  final File? previewFile;
  final bool enabled;
  final bool busy;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onPickDocument;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final file = previewFile;
    final canAct = enabled && !busy;
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.photoAndDocument, style: labelStyle),
        const SizedBox(height: 6),
        SizedBox(
          height: valuationControlHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: inventoryGoodsOutlinedStyle(),
                  onPressed: canAct ? onPickGallery : null,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(
                    file == null
                        ? AppStrings.addPhotoGallery
                        : AppStrings.replacePhoto,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: inventoryGoodsOutlinedStyle(),
                  onPressed: canAct ? onPickCamera : null,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text(
                    AppStrings.addPhotoCamera,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: inventoryGoodsOutlinedStyle(),
                  onPressed: canAct ? onPickDocument : null,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text(
                    AppStrings.documentAction,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (file != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(
                file,
                fit: BoxFit.cover,
                cacheWidth: 640,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: canAct ? onRemove : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text(AppStrings.removePhoto),
            ),
          ),
        ],
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
              Expanded(child: Text(AppStrings.photoProcessing)),
            ],
          ),
        ],
      ],
    );
  }
}
