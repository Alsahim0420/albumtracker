import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class StickerOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final text = recognizedText.text;
    if (kDebugMode) {
      final shortPath = imagePath.split(RegExp(r'[/\\]')).last;
      debugPrint('[StickerOCR] archivo: $shortPath');
      debugPrint('[StickerOCR] texto crudo (${text.length} caracteres):');
      debugPrint(text);
    }
    return text;
  }

  Future<void> dispose() async {
    await _textRecognizer.close();
  }
}
