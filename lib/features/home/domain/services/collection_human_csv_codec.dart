import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/core/models/team_model.dart';
import 'package:csv/csv.dart';

/// CSV reversible colección: columnas legibles + mismo formato en importación.
abstract final class CollectionHumanCsvCodec {
  /// Encabezados exportación (inglés).
  static const headerRowEnglish = [
    'Team name',
    'Sticker number',
    'Sticker code',
    'Quantity',
    'Type',
  ];

  /// Encabezados exportación (español).
  static const headerRowSpanish = [
    'Equipo',
    'Número de lámina',
    'Código de lámina',
    'Cantidad',
    'Tipo',
  ];

  /// Misma cadena en export/import para láminas FWC sin equipo en grupos.
  static const specialTeamDisplayName = 'Official album specials';

  /// BOM UTF-8 (U+FEFF): prefijo solo del **archivo** en export para Excel en Windows.
  /// La importación lo quita del texto y de cada etiqueta de cabecera ([normalizeHeaderLabel]).
  static const utf8Bom = '\uFEFF';

  static List<String> exportHeadersForLanguageCode(String languageCode) {
    return languageCode.toLowerCase().startsWith('es')
        ? headerRowSpanish
        : headerRowEnglish;
  }

  static List<List<String>> buildRows(
    Map<String, int> collection, {
    String languageCode = 'en',
  }) {
    final rows = <List<String>>[exportHeadersForLanguageCode(languageCode)];

    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        for (final s in t.stickers) {
          final q = collection[s.id] ?? 0;
          if (q <= 0) continue;
          rows.add(_teamStickerRow(t.name, s, q));
        }
      }
    }

    final specials = List<StickerModel>.from(WorldCup2026Seed.specialStickers)
      ..sort((a, b) => (a.globalNumber ?? 0).compareTo(b.globalNumber ?? 0));
    for (final s in specials) {
      final q = collection[s.id] ?? 0;
      if (q <= 0) continue;
      rows.add([
        specialTeamDisplayName,
        '${s.localNumber ?? ''}',
        s.displayCode,
        '$q',
        _typeToCsv(s.type),
      ]);
    }

    return rows;
  }

  static List<String> _teamStickerRow(String teamName, StickerModel s, int q) {
    return [
      teamName,
      '${s.localNumber ?? ''}',
      s.displayCode,
      '$q',
      _typeToCsv(s.type),
    ];
  }

  static String _typeToCsv(StickerType t) {
    switch (t) {
      case StickerType.player:
        return 'player';
      case StickerType.badge:
        return 'badge';
      case StickerType.team_photo:
        return 'team_photo';
      case StickerType.special:
        return 'special';
    }
  }

  static StickerType? _tryParseTypeHint(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'player':
        return StickerType.player;
      case 'badge':
        return StickerType.badge;
      case 'team_photo':
        return StickerType.team_photo;
      case 'special':
        return StickerType.special;
      case 'unknown':
      case '':
        return null;
      default:
        return null;
    }
  }

  /// Quita BOM y normaliza etiquetas de cabecera (minúsculas, sin tildes, espacios).
  static String normalizeHeaderLabel(String raw) {
    var s = raw.toString().trim();
    s = s.replaceFirst(RegExp('^${RegExp.escape(utf8Bom)}'), '').trim();
    s = s.toLowerCase();
    s = _foldLatinDiacritics(s);
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static String _foldLatinDiacritics(String s) {
    const map = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'ñ': 'n',
      'ç': 'c',
    };
    final sb = StringBuffer();
    for (final ch in s.split('')) {
      sb.write(map[ch] ?? ch);
    }
    return sb.toString();
  }

  /// True si el texto tiene cabecera de export de esta app (EN/ES) o formato legado `stickerId,count`.
  ///
  /// Usar cuando el picker no informa `.csv` en [PlatformFile.name] (p. ej. Drive/MIUI).
  static bool textLooksLikeAlbumTrackerCsv(String rawText) {
    final text = rawText
        .trimLeft()
        .replaceFirst(RegExp('^${RegExp.escape(utf8Bom)}'), '')
        .trimLeft();
    if (text.isEmpty) return false;
    const converter = CsvToListConverter(shouldParseNumbers: false);
    final rows = converter.convert(text);
    if (rows.isEmpty) return false;
    if (resolveHumanReadableColumnIndices(rows.first) != null) return true;
    final headerCells =
        rows.first.map((c) => normalizeHeaderLabel(c.toString())).toList();
    if (headerCells.length >= 2) {
      final h0 = headerCells[0];
      final h1 = headerCells[1];
      if ((h0 == 'stickerid' || h0 == 'sticker_id') && h1 == 'count') {
        return true;
      }
    }
    return false;
  }

  /// Mapa índice por columna lógica (`team_name`, `sticker_number`, …) o null si no aplica.
  static Map<String, int>? resolveHumanReadableColumnIndices(List<dynamic> headerRow) {
    final idx = <String, int>{};
    for (var i = 0; i < headerRow.length; i++) {
      final canonical = _canonicalColumnForNormalizedHeader(
        normalizeHeaderLabel(headerRow[i].toString()),
      );
      if (canonical != null) {
        idx[canonical] = i;
      }
    }
    if (!idx.containsKey('sticker_code') || !idx.containsKey('quantity')) {
      return null;
    }
    return idx;
  }

  static String? _canonicalColumnForNormalizedHeader(String n) {
    switch (n) {
      case 'team_name':
      case 'team name':
      case 'equipo':
        return 'team_name';
      case 'sticker_number':
      case 'sticker number':
      case 'numero de lamina':
        return 'sticker_number';
      case 'sticker_code':
      case 'sticker code':
      case 'codigo de lamina':
        return 'sticker_code';
      case 'quantity':
      case 'cantidad':
        return 'quantity';
      case 'type':
      case 'tipo':
        return 'type';
      default:
        return null;
    }
  }

  /// Parsea CSV humano o legado (`stickerId,count`). Acumula cantidades por fila repetida.
  static CollectionHumanCsvParseResult parse(String rawText) {
    final text = rawText
        .trimLeft()
        .replaceFirst(RegExp('^${RegExp.escape(utf8Bom)}'), '')
        .trimLeft();
    final warnings = <String>[];

    void warn(String m) {
      warnings.add(m);
    }

    if (text.isEmpty) {
      return CollectionHumanCsvParseResult(
        stickerCounts: {},
        warnings: warnings,
        format: CollectionCsvImportFormat.empty,
      );
    }

    const converter = CsvToListConverter(shouldParseNumbers: false);
    final rows = converter.convert(text);
    if (rows.isEmpty) {
      return CollectionHumanCsvParseResult(
        stickerCounts: {},
        warnings: warnings,
        format: CollectionCsvImportFormat.empty,
      );
    }

    final idx = resolveHumanReadableColumnIndices(rows.first);

    if (idx != null) {
      final merged = <String, int>{};
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final teamName = _cell(row, idx['team_name']);
        final stickerNumber = _cell(row, idx['sticker_number']);
        final stickerCode = _cell(row, idx['sticker_code']);
        final quantityRaw = _cell(row, idx['quantity']);
        final typeRaw = _cell(row, idx['type']);

        final q = int.tryParse(quantityRaw.trim());
        if (q == null || q < 0) {
          warn('Fila ${i + 1}: cantidad inválida "$quantityRaw", omitida.');
          continue;
        }
        if (q == 0) continue;

        final sticker = resolveStickerForImport(
          stickerCode: stickerCode,
          teamName: teamName,
          stickerNumber: stickerNumber,
        );
        if (sticker == null) {
          warn(
            'Fila ${i + 1}: lámina no encontrada en el álbum '
            '(code="$stickerCode" team="$teamName" num="$stickerNumber").',
          );
          continue;
        }

        final hint = _tryParseTypeHint(typeRaw);
        if (hint != null && hint != sticker.type) {
          warn(
            'Fila ${i + 1}: type CSV "$typeRaw" no coincide con ${sticker.id} '
            '(se usa la lámina resuelta por código/equipo).',
          );
        }

        merged[sticker.id] = (merged[sticker.id] ?? 0) + q;
      }

      return CollectionHumanCsvParseResult(
        stickerCounts: merged,
        warnings: warnings,
        format: CollectionCsvImportFormat.humanReadable,
      );
    }

    // Legado: stickerId / count
    final headerCells =
        rows.first.map((c) => normalizeHeaderLabel(c.toString())).toList();
    var start = 0;
    if (headerCells.length >= 2) {
      final h0 = headerCells[0];
      final h1 = headerCells[1];
      if ((h0 == 'stickerid' || h0 == 'sticker_id') && h1 == 'count') {
        start = 1;
      }
    }

    final merged = <String, int>{};
    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;
      final rawId = row[0].toString().trim();
      final countRaw = row[1].toString().trim();
      if (rawId.isEmpty) continue;
      final count = int.tryParse(countRaw);
      if (count == null || count < 0) continue;

      final sticker = WorldCup2026Seed.getStickerById(rawId) ??
          WorldCup2026Seed.getStickerByFlexibleIdentifier(rawId);
      if (sticker == null) {
        warn('Legado fila ${i + 1}: id/código no reconocido "$rawId".');
        continue;
      }
      merged[sticker.id] = count;
    }

    return CollectionHumanCsvParseResult(
      stickerCounts: merged,
      warnings: warnings,
      format: CollectionCsvImportFormat.legacyStickerId,
    );
  }

  /// Prioridad: [sticker_code] → fallback [team_name] + [sticker_number].
  static StickerModel? resolveStickerForImport({
    required String stickerCode,
    required String teamName,
    required String stickerNumber,
  }) {
    final code = stickerCode.trim();
    if (code.isNotEmpty) {
      final byCode = WorldCup2026Seed.getStickerByFlexibleIdentifier(code);
      if (byCode != null) return byCode;

      final normalizedSpace = code.replaceAll(RegExp(r'\s+'), ' ');
      for (final s in WorldCup2026Seed.specialStickers) {
        final d = s.displayCode.replaceAll(RegExp(r'\s+'), ' ');
        if (d.toUpperCase() == normalizedSpace.toUpperCase()) return s;
      }
    }

    final tn = teamName.trim();
    final numPart = stickerNumber.trim();
    if (tn.isEmpty || numPart.isEmpty) return null;

    if (tn.toLowerCase() == specialTeamDisplayName.toLowerCase()) {
      final n = int.tryParse(numPart);
      if (n == null) return null;
      for (final s in WorldCup2026Seed.specialStickers) {
        if (s.localNumber == n) return s;
      }
      return null;
    }

    final team = _findTeamByExportedName(tn);
    if (team == null) return null;

    final n = int.tryParse(numPart);
    if (n == null) return null;

    for (final s in team.stickers) {
      if (s.localNumber == n) return s;
    }
    return null;
  }

  static TeamModel? _findTeamByExportedName(String name) {
    final target = name.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        if (t.name.toLowerCase() == target) return t;
      }
    }
    return null;
  }

  static String _cell(List<dynamic> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].toString();
  }
}

enum CollectionCsvImportFormat {
  empty,
  humanReadable,
  legacyStickerId,
}

class CollectionHumanCsvParseResult {
  CollectionHumanCsvParseResult({
    required this.stickerCounts,
    required this.warnings,
    required this.format,
  });

  final Map<String, int> stickerCounts;
  final List<String> warnings;
  final CollectionCsvImportFormat format;
}
