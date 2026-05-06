import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/core/models/team_model.dart';
import 'package:albumtracker/core/repository/album_repository.dart';
import 'package:albumtracker/features/home/presentation/pages/team_detail_page.dart';

/// Búsqueda global sobre el catálogo local ([WorldCup2026Seed]) + estado en colección
/// ([AlbumRepository.getStickerCount]). No escribe en Hive.
///
/// Navegación al tocar un resultado:
/// - Equipos del álbum: `TeamDetailPage` con el grupo del seed.
/// - Láminas especiales (FWC): no hay vista de detalle equivalente en rutas actuales;
///   solo se cierra el delegate. Para enlazar después, usar `groupName != null` como
///   condición de navegación y añadir una ruta dedicada si se define en la app.
class StickerSearchDelegate extends SearchDelegate<void> {
  StickerSearchDelegate({
    required BuildContext parentContext,
    required String searchHint,
  })  : _parentContext = parentContext,
        super(
          searchFieldLabel: searchHint,
          textInputAction: TextInputAction.search,
        );

  final BuildContext _parentContext;

  late final List<_StickerSearchEntry> _entries =
      _StickerSearchEntry.buildAll(_parentContext);

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    final tokens = parseSearchCompactTokens(query);
    if (tokens.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'stickerSearchTypePrompt'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final seenIds = <String>{};
    final matches = <_StickerSearchEntry>[];
    for (final e in _entries) {
      if (!e.matchesAnyCompactTokens(tokens)) continue;
      if (!seenIds.add(e.sticker.id)) continue;
      matches.add(e);
    }
    matches.sort((a, b) {
      final ga = a.sticker.globalNumber ?? 0;
      final gb = b.sticker.globalNumber ?? 0;
      final byGlobal = ga.compareTo(gb);
      if (byGlobal != 0) return byGlobal;
      return a.sticker.id.compareTo(b.sticker.id);
    });

    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'stickerSearchEmpty'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: matches.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
      ),
      itemBuilder: (context, index) {
        final entry = matches[index];
        final count = AlbumRepository.getStickerCount(entry.sticker.id);
        return ListTile(
          title: Text(
            entry.sticker.displayCode,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.subtitleLine()),
                const SizedBox(height: 2),
                Text(
                  entry.teamLine(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(count),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: count > 0
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          onTap: () => _onResultTap(context, entry),
        );
      },
    );
  }

  String _statusLabel(int count) {
    if (count <= 0) return 'stickerSearchStatusMissing'.tr();
    if (count == 1) return 'stickerSearchStatusOwnedOne'.tr();
    return 'stickerSearchStatusOwnedMany'.tr(args: [count.toString()]);
  }

  void _onResultTap(BuildContext context, _StickerSearchEntry entry) {
    close(context, null);
    final groupName = entry.groupName;
    if (groupName == null || groupName.isEmpty) return;

    Navigator.of(_parentContext).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TeamDetailPage(teamId: entry.sticker.teamId, groupName: groupName),
      ),
    );
  }
}

/// Parte la consulta en tokens compactos ([compactSearchForm]) para búsqueda simple o múltiple.
///
/// **Multi-query** (varios códigos en una lista, unión de coincidencias):
/// - Separadores entre códigos: coma, punto y coma, saltos de línea (`[,;\r\n]+`).
/// - Dentro de cada trozo, también se pueden separar códigos por espacios si cada parte
///   parece un código de lámina (`[a-z]{2,4}\d{1,3}` o solo dígitos cortos).
/// - Se fusionan pares `ABC` + `13` → `ABC13` antes de compactar (equivale a `ABC 13`).
///
/// **Consulta simple** (un solo token): textos como jugadores o países no cumplen el
/// patrón “todo código” en un segmento y se compacta el segmento entero (comportamiento anterior).
///
/// Tokens sin ningún match se ignoran; los duplicados en la lista de resultados se omiten por `id`.
List<String> parseSearchCompactTokens(String rawQuery) {
  final trimmed = rawQuery.trim();
  if (trimmed.isEmpty) return [];

  final segments = trimmed
      .split(RegExp(r'[,;\r\n]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  final out = <String>[];
  for (final segment in segments) {
    out.addAll(_compactTokensFromSegment(segment));
  }

  final seen = <String>{};
  final unique = <String>[];
  for (final t in out) {
    if (t.isEmpty || !seen.add(t)) continue;
    unique.add(t);
  }
  return unique;
}

List<String> _compactTokensFromSegment(String segment) {
  final rawParts =
      segment.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (rawParts.isEmpty) return [];

  final merged = _mergeLetterDigitPairs(rawParts);
  final compactPieces =
      merged.map(compactSearchForm).where((c) => c.isNotEmpty).toList();

  if (compactPieces.length <= 1) {
    final single = compactSearchForm(segment);
    return single.isEmpty ? [] : [single];
  }

  final allBulkLike = compactPieces.every(_isBulkStickerStyleToken);
  if (allBulkLike) {
    return compactPieces;
  }

  final single = compactSearchForm(segment);
  return single.isEmpty ? [] : [single];
}

/// Código tipo `cze13`, `esp7`, `col1` o número global corto para modo lista.
bool _isBulkStickerStyleToken(String compact) {
  return RegExp(r'^[a-z]{2,4}\d{1,3}$').hasMatch(compact) ||
      RegExp(r'^\d{1,4}$').hasMatch(compact);
}

List<String> _mergeLetterDigitPairs(List<String> parts) {
  final out = <String>[];
  for (var i = 0; i < parts.length; i++) {
    final p = parts[i];
    if (i + 1 < parts.length &&
        RegExp(r'^[A-Za-z]{2,4}$').hasMatch(p) &&
        RegExp(r'^\d{1,3}$').hasMatch(parts[i + 1])) {
      out.add('$p${parts[i + 1]}');
      i++;
    } else {
      out.add(p);
    }
  }
  return out;
}

/// Normaliza texto para comparar consulta y catálogo: minúsculas, sin tildes y solo
/// [a-z0-9], eliminando espacios y otros símbolos (ej. `CZE 13` y `CZE13` → `cze13`).
String compactSearchForm(String input) {
  var s = input.toLowerCase().trim();
  if (s.isEmpty) return '';
  s = _stripLatinDiacritics(s);
  return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

String _stripLatinDiacritics(String s) {
  const accents = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
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
    'ñ': 'n',
    'ç': 'c',
    'ý': 'y',
    'ÿ': 'y',
    'ć': 'c',
    'č': 'c',
    'š': 's',
    'ž': 'z',
    'đ': 'd',
    'ł': 'l',
    'ń': 'n',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
  };
  for (final e in accents.entries) {
    s = s.replaceAll(e.key, e.value);
  }
  return s;
}

class _StickerSearchEntry {
  _StickerSearchEntry({
    required this.sticker,
    required this.team,
    required this.groupName,
    required this.compactHaystack,
  });

  final StickerModel sticker;
  final TeamModel? team;
  final String? groupName;
  final String compactHaystack;

  bool matchesAnyCompactTokens(List<String> compactTokens) {
    if (compactTokens.isEmpty) return false;
    for (final t in compactTokens) {
      if (t.isNotEmpty && compactHaystack.contains(t)) return true;
    }
    return false;
  }

  String subtitleLine() {
    switch (sticker.type) {
      case StickerType.player:
        final name = (sticker.playerName ?? '').trim();
        if (name.isNotEmpty) return name;
        break;
      case StickerType.badge:
      case StickerType.team_photo:
      case StickerType.special:
        break;
    }
    return sticker.displayLabel.tr();
  }

  String teamLine() {
    if (team != null) {
      return team!.name.tr();
    }
    return 'homeTabSpecials'.tr();
  }

  static List<_StickerSearchEntry> buildAll(BuildContext context) {
    final out = <_StickerSearchEntry>[];
    for (final g in WorldCup2026Seed.groups) {
      for (final t in g.teams) {
        for (final s in t.stickers) {
          out.add(_fromTeamSticker(sticker: s, team: t, groupName: g.name));
        }
      }
    }
    for (final s in WorldCup2026Seed.specialStickers) {
      out.add(_fromSpecial(context, sticker: s));
    }
    return out;
  }

  static _StickerSearchEntry _fromTeamSticker({
    required StickerModel sticker,
    required TeamModel team,
    required String groupName,
  }) {
    final parts = <String>{
      compactSearchForm(sticker.id.replaceAll('-', ' ')),
      compactSearchForm(sticker.code),
      compactSearchForm(sticker.displayCode),
      compactSearchForm(team.id),
      compactSearchForm(team.name),
      compactSearchForm(team.name.tr()),
    };
    if (sticker.globalNumber != null) {
      parts.add(compactSearchForm(sticker.globalNumber.toString()));
    }
    final pn = sticker.playerName;
    if (pn != null && pn.trim().isNotEmpty) {
      parts.add(compactSearchForm(pn));
      parts.add(
        compactSearchForm(
          WorldCup2026Seed.normalizeTextForPlayerNameMatch(pn),
        ),
      );
    }
    parts.removeWhere((e) => e.isEmpty);
    return _StickerSearchEntry(
      sticker: sticker,
      team: team,
      groupName: groupName,
      compactHaystack: parts.join('|'),
    );
  }

  static _StickerSearchEntry _fromSpecial(
    BuildContext context, {
    required StickerModel sticker,
  }) {
    final parts = <String>{
      compactSearchForm(sticker.id.replaceAll('-', ' ')),
      compactSearchForm(sticker.code),
      compactSearchForm(sticker.displayCode),
      compactSearchForm(WorldCup2026Seed.specialTeamCode),
      compactSearchForm('special'),
      compactSearchForm('fwc'),
      compactSearchForm('homeTabSpecials'.tr()),
    };
    if (sticker.globalNumber != null) {
      parts.add(compactSearchForm(sticker.globalNumber.toString()));
    }
    parts.removeWhere((e) => e.isEmpty);
    return _StickerSearchEntry(
      sticker: sticker,
      team: null,
      groupName: null,
      compactHaystack: parts.join('|'),
    );
  }
}
