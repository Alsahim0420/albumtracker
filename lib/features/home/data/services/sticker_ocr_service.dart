import 'package:flutter/foundation.dart';

class StickerOcrService {
  Future<String> extractText(String imagePath) async {
    if (kDebugMode) {
      final shortPath = imagePath.split(RegExp(r'[/\\]')).last;
      debugPrint('[StickerOCR] archivo: $shortPath');
      debugPrint(
        '[StickerOCR] OCR nativo temporalmente deshabilitado para compatibilidad de simulador iOS.',
      );
    }
    return '';
  }

  Future<void> dispose() async {}
}
