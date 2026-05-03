import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum StickerScanInputAction {
  captureSingle,
  captureMultiple,
  gallerySingle,
  galleryMultiple,
  manualBulk,
}

class StickerScanOptionsSheet extends StatelessWidget {
  const StickerScanOptionsSheet({super.key, required this.onActionSelected});

  final ValueChanged<StickerScanInputAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('scanOptionCameraSingle'.tr()),
              onTap: () =>
                  onActionSelected(StickerScanInputAction.captureSingle),
            ),
            ListTile(
              leading: const Icon(Icons.camera_outlined),
              title: Text('scanOptionCameraMultiple'.tr()),
              onTap: () =>
                  onActionSelected(StickerScanInputAction.captureMultiple),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('scanOptionGallerySingle'.tr()),
              onTap: () =>
                  onActionSelected(StickerScanInputAction.gallerySingle),
            ),
            ListTile(
              leading: const Icon(Icons.collections_outlined),
              title: Text('scanOptionGalleryMultiple'.tr()),
              onTap: () =>
                  onActionSelected(StickerScanInputAction.galleryMultiple),
            ),
            ListTile(
              leading: const Icon(Icons.format_list_numbered),
              title: Text('scanOptionManual'.tr()),
              onTap: () => onActionSelected(StickerScanInputAction.manualBulk),
            ),
          ],
        ),
      ),
    );
  }
}
