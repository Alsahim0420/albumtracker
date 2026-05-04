import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Codificación base64 fuera del hilo UI (imágenes grandes bloquean el ticker).
String _isolateBase64Encode(Uint8List bytes) => base64Encode(bytes);

/// Cliente OpenAI: visión sobre la foto del sticker → texto plano para el pipeline existente.
///
/// La clave se lee de [dotenv] (`assets/.env`). Nunca hardcodear.
class OpenAIService {
  OpenAIService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _responsesUrl = 'https://api.openai.com/v1/responses';
  static const _model = 'gpt-4.1-mini';
  static const _maxImageBytes = 20 * 1024 * 1024;
  /// Por encima de esto, [base64Encode] va a otro isolate para no congelar la animación.
  static const _base64IsolateThresholdBytes = 96000;
  static const _requestTimeout = Duration(seconds: 45);

  static const _visionPrompt =
      'Eres un transcriptor de láminas de álbum de fútbol (Panini / FIFA World Cup). '
      'Mira la imagen y escribe TODO el texto legible tal como aparecería en un OCR limpio: '
      'nombres de jugadores, códigos tipo POR 11 o RSA 12, pie FIFA WORLD CUP 2026, insignias, etc. '
      'Si hay varias láminas/cartas visibles en la misma foto (rejilla, varias en mesa, etc.), '
      'cuenta cada carta física: recorre fila por fila (izquierda a derecha, luego la fila de abajo) '
      'y escribe UNA línea de texto por cada carta, aunque repita el mismo jugador o club. '
      'Ejemplo: 10 cartas visibles → 10 líneas; si 3 son el mismo jugador, escribe su nombre 3 veces en 3 líneas. '
      'No agrupes, no resumas en "x3" y no omitas copias. '
      'Conserva saltos de línea entre cartas. No añadas comentarios ni explicaciones; solo el texto.';

  final http.Client _http;

  /// Hay clave configurada (no vacía ni placeholder de ejemplo).
  bool get isConfigured {
    final k = dotenv.env['OPENAI_API_KEY']?.trim() ?? '';
    if (k.isEmpty) return false;
    if (k == 'YOUR_API_KEY') return false;
    return true;
  }

  /// Envía la imagen a GPT (visión) y devuelve texto plano para [StickerOcrResolver].
  /// Si falla la petición o la respuesta está vacía, devuelve cadena vacía (el llamador puede usar ML Kit).
  Future<String> extractStickerTextFromImage(String imagePath) async {
    if (!isConfigured) return '';

    final file = File(imagePath);
    if (!await file.exists()) return '';

    final Uint8List bytes = await file.readAsBytes();
    if (bytes.isEmpty || bytes.length > _maxImageBytes) {
      if (kDebugMode) {
        debugPrint(
          '[OpenAIService] imagen vacía o demasiado grande (${bytes.length} bytes, máx $_maxImageBytes)',
        );
      }
      return '';
    }

    final mime = _mimeTypeFromPath(imagePath);
    final String b64 = bytes.lengthInBytes >= _base64IsolateThresholdBytes
        ? await compute(_isolateBase64Encode, bytes)
        : base64Encode(bytes);
    final dataUrl = 'data:$mime;base64,$b64';

    final key = dotenv.env['OPENAI_API_KEY']!.trim();
    final body = jsonEncode({
      'model': _model,
      'input': [
        {
          'role': 'user',
          'content': [
            {'type': 'input_text', 'text': _visionPrompt},
            {
              'type': 'input_image',
              'image_url': dataUrl,
              'detail': 'low',
            },
          ],
        },
      ],
    });

    try {
      final res = await _http
          .post(
            Uri.parse(_responsesUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(_requestTimeout);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint(
            '[OpenAIService] vision HTTP ${res.statusCode} body=${res.body.length > 300 ? "${res.body.substring(0, 300)}…" : res.body}',
          );
        }
        return '';
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return '';

      final err = decoded['error'];
      if (err != null) {
        if (kDebugMode) {
          debugPrint('[OpenAIService] API error: $err');
        }
        return '';
      }

      final text = _extractOutputText(decoded).trim();
      if (text.length < 2) return '';
      return text;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[OpenAIService] extractStickerTextFromImage failed: $e\n$st');
      }
      return '';
    }
  }

  static String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    return 'image/jpeg';
  }

  static String _extractOutputText(Map<String, dynamic> root) {
    final top = root['output_text'];
    if (top is String && top.trim().isNotEmpty) return top;

    final out = root['output'];
    if (out is! List) return '';
    final buf = StringBuffer();
    for (final item in out) {
      if (item is Map<String, dynamic>) {
        _collectOutputText(item, buf);
      }
    }
    return buf.toString().trim();
  }

  static void _collectOutputText(Map<String, dynamic> node, StringBuffer buf) {
    final type = node['type'];
    if (type == 'output_text' && node['text'] is String) {
      final t = node['text'] as String;
      if (t.isNotEmpty) {
        if (buf.isNotEmpty) buf.writeln();
        buf.write(t);
      }
    }
    final content = node['content'];
    if (content is List) {
      for (final part in content) {
        if (part is Map<String, dynamic>) {
          _collectOutputText(part, buf);
        }
      }
    }
  }
}
