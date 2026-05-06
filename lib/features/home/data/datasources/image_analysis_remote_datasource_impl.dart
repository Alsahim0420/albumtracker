import 'dart:convert';
import 'dart:io';

import 'package:albumtracker/features/home/data/datasources/image_analysis_remote_datasource.dart';
import 'package:albumtracker/features/home/domain/entities/ai_detected_sticker.dart';
import 'package:albumtracker/features/home/domain/entities/ai_image_analysis_result.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class ImageAnalysisRemoteException implements Exception {
  const ImageAnalysisRemoteException(this.message);
  final String message;
}

class ImageAnalysisRemoteDataSourceImpl implements ImageAnalysisRemoteDataSource {
  ImageAnalysisRemoteDataSourceImpl({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const Duration _requestTimeout = Duration(seconds: 30);
  static const String _multipartFieldName = 'image';
  static const int _maxUploadBytes = 2 * 1024 * 1024; // ~2MB
  static const int _targetUploadBytes = 1500 * 1024; // ~1.5MB
  static const int _maxSidePx = 1600;

  final http.Client _httpClient;

  @override
  Future<AiImageAnalysisResult> analyzeImage(String imagePath) async {
    final originalFile = File(imagePath);
    if (!await originalFile.exists()) {
      throw const ImageAnalysisRemoteException('La imagen no existe');
    }

    final baseUrlRaw =
        dotenv.env['IMAGE_ANALYSIS_API_BASE_URL']?.trim().isNotEmpty == true
        ? dotenv.env['IMAGE_ANALYSIS_API_BASE_URL']!.trim()
        : 'https://album-tracker-back.vercel.app';
    final baseUrl = baseUrlRaw.endsWith('/')
        ? baseUrlRaw.substring(0, baseUrlRaw.length - 1)
        : baseUrlRaw;
    final uri = Uri.parse('$baseUrl/api/analyze-image');
    final finalUrl = uri.toString();
    final prepared = await _prepareImageForAiUpload(originalFile, imagePath);

    final request = http.MultipartRequest('POST', uri);
    final filename = p.basename(prepared.file.path);
    request.files.add(
      http.MultipartFile(
        _multipartFieldName,
        prepared.file.openRead(),
        await prepared.file.length(),
        filename: filename,
        contentType: prepared.contentType,
      ),
    );
    http.StreamedResponse streamed;
    try {
      streamed = await _httpClient.send(request).timeout(_requestTimeout);
    } catch (e) {
      final message =
          'No se pudo conectar al backend de análisis. '
          'url=$finalUrl '
          'field=$_multipartFieldName '
          'timeout=${_requestTimeout.inSeconds}s '
          'error=$e';
      throw ImageAnalysisRemoteException(
        message,
      );
    } finally {
      await prepared.cleanup();
    }

    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ImageAnalysisRemoteException(
        'Error del backend. '
        'url=$finalUrl '
        'statusCode=${response.statusCode} '
        'body=${response.body}',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw ImageAnalysisRemoteException(
        'Respuesta JSON inválida. '
        'url=$finalUrl '
        'statusCode=${response.statusCode} '
        'body=${response.body} '
        'error=$e',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw ImageAnalysisRemoteException(
        'Respuesta inválida del backend. '
        'url=$finalUrl '
        'statusCode=${response.statusCode} '
        'body=${response.body}',
      );
    }
    if (decoded['success'] != true) {
      final message = decoded['message']?.toString() ?? 'Análisis no exitoso';
      throw ImageAnalysisRemoteException(
        'Análisis no exitoso. '
        'url=$finalUrl '
        'statusCode=${response.statusCode} '
        'message=$message '
        'body=${response.body}',
      );
    }

    final analysis = decoded['analysis'];
    if (analysis is! Map<String, dynamic>) {
      throw const ImageAnalysisRemoteException('Falta el objeto analysis');
    }

    final stickersJson = analysis['stickers'];
    final warningsJson = analysis['warnings'];

    final stickers = <AiDetectedSticker>[];
    if (stickersJson is List) {
      for (final item in stickersJson) {
        if (item is! Map<String, dynamic>) continue;
        stickers.add(
          AiDetectedSticker(
            stickerCode: item['stickerCode']?.toString(),
            countryCode: item['countryCode']?.toString(),
            number: _toInt(item['number']),
            type: item['type']?.toString() ?? 'unknown',
            playerName: item['playerName']?.toString(),
            teamName: item['teamName']?.toString(),
            rawText: item['rawText']?.toString(),
            confidence: _toDouble(item['confidence']),
          ),
        );
      }
    }

    final warnings = <String>[
      if (warningsJson is List)
        ...warningsJson.map((e) => e.toString()).where((e) => e.trim().isNotEmpty),
    ];
    return AiImageAnalysisResult(
      imageSide: analysis['imageSide']?.toString() ?? 'unknown',
      stickers: stickers,
      warnings: warnings,
    );
  }

  int? _toInt(Object? raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  double _toDouble(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.0;
  }

  MediaType _contentTypeFromExtension(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      default:
        throw ImageAnalysisRemoteException(
          'Formato no soportado localmente: $extension',
        );
    }
  }

  Future<_PreparedImageUpload> _prepareImageForAiUpload(
    File originalFile,
    String originalPath,
  ) async {
    final originalBytes = await originalFile.length();
    final extension = p.extension(originalPath).toLowerCase();
    final originalContentType = _contentTypeFromExtension(extension);
    final originalBytesData = await originalFile.readAsBytes();
    final decodedOriginal = img.decodeImage(originalBytesData);
    final originalWidth = decodedOriginal?.width;
    final originalHeight = decodedOriginal?.height;

    final shouldCompress =
        originalBytes > _maxUploadBytes ||
        ((originalWidth ?? 0) > _maxSidePx || (originalHeight ?? 0) > _maxSidePx);

    if (!shouldCompress || decodedOriginal == null) {
      if (originalBytes > _maxUploadBytes) {
        throw const ImageAnalysisRemoteException(
          'La imagen es demasiado grande. Intenta con una foto más ligera.',
        );
      }
      return _PreparedImageUpload(
        file: originalFile,
        contentType: originalContentType,
      );
    }

    try {
      final resized = _resizeKeepingAspect(decodedOriginal, _maxSidePx);
      var quality = 88;
      List<int> encoded = img.encodeJpg(resized, quality: quality);
      while (encoded.length > _targetUploadBytes && quality > 55) {
        quality -= 8;
        encoded = img.encodeJpg(resized, quality: quality);
      }
      if (encoded.length > _maxUploadBytes) {
        final alt = _resizeKeepingAspect(resized, 1280);
        encoded = img.encodeJpg(alt, quality: 78);
      }

      final tempPath = p.join(
        Directory.systemTemp.path,
        'ai_scan_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(encoded, flush: true);

      if (encoded.length > _maxUploadBytes) {
        await tempFile.delete().catchError((_) => tempFile);
        throw const ImageAnalysisRemoteException(
          'La imagen es demasiado grande. Intenta con una foto más ligera.',
        );
      }

      return _PreparedImageUpload(
        file: tempFile,
        contentType: MediaType('image', 'jpeg'),
        isTemporary: true,
      );
    } catch (_) {
      if (originalBytes > _maxUploadBytes) {
        throw const ImageAnalysisRemoteException(
          'La imagen es demasiado grande. Intenta con una foto más ligera.',
        );
      }
      return _PreparedImageUpload(
        file: originalFile,
        contentType: originalContentType,
      );
    }
  }

  img.Image _resizeKeepingAspect(img.Image source, int maxSide) {
    final width = source.width;
    final height = source.height;
    final largestSide = width > height ? width : height;
    if (largestSide <= maxSide) return source;
    final ratio = maxSide / largestSide;
    final targetWidth = (width * ratio).round();
    final targetHeight = (height * ratio).round();
    return img.copyResize(
      source,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }
}

class _PreparedImageUpload {
  const _PreparedImageUpload({
    required this.file,
    required this.contentType,
    this.isTemporary = false,
  });

  final File file;
  final MediaType contentType;
  final bool isTemporary;

  Future<void> cleanup() async {
    if (!isTemporary) return;
    if (!await file.exists()) return;
    await file.delete().catchError((_) => file);
  }
}
