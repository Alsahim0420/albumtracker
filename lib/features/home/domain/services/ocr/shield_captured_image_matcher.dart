import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as im;

import 'package:albumtracker/core/data/shield_assets.dart';

class ShieldMatchResult {
  const ShieldMatchResult({
    required this.teamFifaCode,
    required this.similarity,
    required this.assetPath,
  });

  final String teamFifaCode;
  final double similarity;
  final String assetPath;
}

/// Compara la imagen de la lámina (insignia/badge) con assets de referencia.
class ShieldCapturedImageMatcher {
  ShieldCapturedImageMatcher();

  static final _refCache = <String, im.Image?>{};

  static const int _size = 64;
  static const _simThreshold = 0.85;

  /// Devuelve la mejor coincidencia si [similarity] ≥ 0,85, si no null.
  Future<ShieldMatchResult?> findBestMatch(String filePath) async {
    final best = await findBestCandidate(filePath);
    if (best == null) return null;
    if (kDebugMode) {
      debugPrint('[ShieldMatch] best=${best.similarity} for ${best.teamFifaCode} (threshold $_simThreshold)');
    }
    if (best.similarity < _simThreshold || best.teamFifaCode.isEmpty) {
      return null;
    }
    return best;
  }

  /// Devuelve siempre el mejor candidato, incluso por debajo del umbral.
  Future<ShieldMatchResult?> findBestCandidate(String filePath) async {
    im.Image? full;
    try {
      final f = File(filePath);
      if (!await f.exists()) return null;
      final bytes = await f.readAsBytes();
      full = im.decodeImage(bytes);
    } catch (_) {
      return null;
    }
    if (full == null) return null;
    if (full.width < 2 || full.height < 2) return null;
    im.Image? wide = full;
    {
      const maxSide = 1800.0;
      if (wide.width > maxSide || wide.height > maxSide) {
        final s = (wide.width > wide.height ? wide.width : wide.height) / maxSide;
        wide = im.copyResize(
          wide,
          width: (wide.width / s).round().clamp(1, 0x7fffffff),
          height: (wide.height / s).round().clamp(1, 0x7fffffff),
          interpolation: im.Interpolation.cubic,
        );
      }
    }
    late im.Image center;
    {
      final w0 = wide.width;
      final h0 = wide.height;
      const span = 0.62;
      final cw = (w0 * span).round().clamp(1, w0);
      final ch = (h0 * span).round().clamp(1, h0);
      final ox = (w0 - cw) ~/ 2;
      final oy = (h0 - ch) ~/ 2;
      center = im.copyCrop(
        wide,
        x: ox,
        y: oy,
        width: cw,
        height: ch,
      );
    }
    final pFull = _prepImage(wide);
    final pCenter = _prepImage(center);
    if (pFull == null && pCenter == null) return null;

    var bestCode = '';
    var best = 0.0;
    var bestPath = '';
    for (final e in allTeamShieldAssetEntries) {
      final ref = await _getRefImage(e.value);
      if (ref == null) continue;
      for (final probe in <im.Image?>[pCenter, pFull]) {
        if (probe == null) continue;
        final s = _similarityNcc(probe, ref);
        if (s > best) {
          best = s;
          bestCode = e.key;
          bestPath = e.value;
        }
      }
    }
    if (bestCode.isEmpty) {
      return null;
    }
    return ShieldMatchResult(
      teamFifaCode: bestCode,
      similarity: best,
      assetPath: bestPath,
    );
  }

  Future<im.Image?> _getRefImage(String asset) async {
    if (_refCache.containsKey(asset)) {
      return _refCache[asset];
    }
    try {
      final data = await rootBundle.load(asset);
      final raw = im.decodeImage(data.buffer.asUint8List());
      final p = _prepImage(raw);
      _refCache[asset] = p;
      return p;
    } catch (_) {
      _refCache[asset] = null;
      return null;
    }
  }

  im.Image? _prepImage(im.Image? src) {
    if (src == null) return null;
    try {
      return im.copyResize(
        im.grayscale(src),
        width: _size,
        height: _size,
        interpolation: im.Interpolation.cubic,
      );
    } catch (_) {
      return null;
    }
  }

  static double _luma(im.Image img, int x, int y) {
    final p = img.getPixel(x, y);
    return 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
  }

  /// R² entre luminancias 2D aplanadas; escala 0 (sin parecido) .. 1 (casi igual).
  static double _similarityNcc(im.Image a, im.Image b) {
    if (a.width != b.width || a.height != b.height) {
      return 0.0;
    }
    final w = a.width, h = a.height;
    final n = w * h;
    if (n < 1) {
      return 0.0;
    }
    double sumA = 0, sumA2 = 0, sumB = 0, sumB2 = 0, sumAb = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final fa = _luma(a, x, y);
        final fb = _luma(b, x, y);
        sumA += fa;
        sumA2 += fa * fa;
        sumB += fb;
        sumB2 += fb * fb;
        sumAb += fa * fb;
      }
    }
    final meanA = sumA / n;
    final meanB = sumB / n;
    var c = sumAb - n * meanA * meanB;
    var va = sumA2 - n * meanA * meanA;
    var vb = sumB2 - n * meanB * meanB;
    if (va < 1e-6 || vb < 1e-6) {
      return 0.0;
    }
    c /= math.sqrt(va * vb);
    final r2 = c * c;
    return r2.clamp(0.0, 1.0);
  }
}
