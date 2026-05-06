import '../data/world_cup_2026_seed.dart';
import '../models/group_model.dart';
import '../models/team_model.dart';
import '../storage/hive_storage.dart' as hive;
import '../../features/home/presentation/models/group_team_item.dart';

/// Estadísticas globales del álbum.
class GlobalAlbumStats {
  const GlobalAlbumStats({
    required this.totalStickers,
    required this.collectedStickers,
    required this.missingStickers,
    required this.duplicateStickers,
    required this.globalPercentage,
  });

  final int totalStickers;
  final int collectedStickers;
  final int missingStickers;
  final int duplicateStickers;
    final double globalPercentage;
}

/// Progreso de un equipo (para UI).
class TeamProgressView {
  const TeamProgressView({
    required this.team,
    required this.collected,
    required this.total,
    required this.duplicates,
    required this.percent,
  });

  final TeamModel team;
  final int collected;
  final int total;
  final int duplicates;
  final double percent;

  bool get isComplete => total > 0 && collected >= total;
}

/// Progreso de un grupo (para UI).
class GroupProgressView {
  const GroupProgressView({
    required this.group,
    required this.total,
    required this.collected,
    required this.percent,
  });

  final GroupModel group;
  final int total;
  final int collected;
  final int percent;
}

/// Repositorio que combina estructura (seed) y progreso (Hive).
class AlbumRepository {
  AlbumRepository._();

  static Map<String, int> get _collection => hive.collectedStickersMap;
  static const Map<String, List<String>> _visualTeamOrderByGroup = {
    'Group A': ['Mexico', 'South Africa', 'South Korea', 'Czech Republic'],
    'Group B': ['Canada', 'Bosnia and Herzegovina', 'Qatar', 'Switzerland'],
    'Group C': ['Brazil', 'Morocco', 'Haiti', 'Scotland'],
    'Group D': ['USA', 'Paraguay', 'Australia', 'Turkey'],
    'Group E': ['Germany', 'Curaçao', 'Ivory Coast', 'Ecuador'],
    'Group F': ['Netherlands', 'Japan', 'Sweden', 'Tunisia'],
    'Group G': ['Belgium', 'Egypt', 'Iran', 'New Zealand'],
    'Group H': ['Spain', 'Cape Verde', 'Saudi Arabia', 'Uruguay'],
    'Group I': ['France', 'Senegal', 'Iraq', 'Norway'],
    'Group J': ['Argentina', 'Argelia', 'Austria', 'Jordan'],
    'Group K': ['Portugal', 'DR Congo', 'Uzbekistan', 'Colombia'],
    'Group L': ['England', 'Croatia', 'Ghana', 'Panama'],
  };

  static GlobalAlbumStats getGlobalStats() {
    final total = WorldCup2026Seed.totalAlbumStickers;
    int collected = 0;
    int duplicates = 0;
    for (final entry in _collection.entries) {
      final c = entry.value;
      if (c > 0) {
        collected += 1;
        if (c > 1) duplicates += c - 1;
      }
    }
    final missing = total - collected;
    final percent = total > 0 ? (collected / total) * 100 : 0.0;
    return GlobalAlbumStats(
      totalStickers: total,
      collectedStickers: collected,
      missingStickers: missing,
      duplicateStickers: duplicates,
      globalPercentage: percent,
    );
  }

  static TeamProgressView getTeamProgress(TeamModel team) {
    final total = team.totalStickers;
    int collected = 0;
    int duplicates = 0;
    for (final s in team.stickers) {
      final c = _collection[s.id] ?? 0;
      if (c > 0) {
        collected += 1;
        if (c > 1) duplicates += c - 1;
      }
    }
    final percent = total > 0 ? (collected / total).clamp(0.0, 1.0) : 0.0;
    return TeamProgressView(
      team: team,
      collected: collected,
      total: total,
      duplicates: duplicates,
      percent: percent,
    );
  }

  static GroupProgressView getGroupProgress(GroupModel group) {
    int total = 0;
    int collected = 0;
    for (final t in group.teams) {
      final p = getTeamProgress(t);
      total += p.total;
      collected += p.collected;
    }
    final percent = total > 0 ? (collected / total * 100).round() : 0;
    return GroupProgressView(
      group: group,
      total: total,
      collected: collected,
      percent: percent,
    );
  }

  /// Lista de grupos con equipos y progreso, para HomePage (compatible con GroupWithTeams/TeamProgress).
  static List<GroupWithTeams> getGroupsWithProgress() {
    return WorldCup2026Seed.groups.map((g) {
      final teams = g.teams.map((t) {
        final p = getTeamProgress(t);
        return TeamProgress(
          name: t.name,
          collected: p.collected,
          total: p.total,
          flagCode: t.flagAssetPath?.isNotEmpty ?? false ? t.flagAssetPath : null,
        );
      }).toList()
        ..sort((a, b) {
          final groupOrder = _visualTeamOrderByGroup[g.name];
          if (groupOrder == null) return 0;
          final aIndex = groupOrder.indexOf(a.name);
          final bIndex = groupOrder.indexOf(b.name);
          final safeA = aIndex == -1 ? 999 : aIndex;
          final safeB = bIndex == -1 ? 999 : bIndex;
          return safeA.compareTo(safeB);
        });
      return GroupWithTeams(name: g.name, teams: teams);
    }).toList();
  }

  static TeamModel? getTeamById(String teamId) => WorldCup2026Seed.getTeamById(teamId);

  static int getStickerCount(String stickerId) => _collection[stickerId] ?? 0;

  /// Añade laminas por números globales (bulk).
  static Future<void> addStickersBulk(Iterable<int> globalNumbers) async {
    await addStickersByGlobalNumbers(globalNumbers);
  }

  static Future<void> updateStickerCount(String stickerId, int count) async {
    await hive.setStickerCount(stickerId, count);
  }

  /// Añade laminas por números globales (bulk add).
  static Future<void> addStickersByGlobalNumbers(Iterable<int> globalNumbers) async {
    await hive.addStickersByGlobalNumbers(globalNumbers);
  }

  /// Obtiene el teamId para abrir TeamDetailPage (por nombre de grupo y nombre de equipo).
  static String? getTeamIdByGroupAndTeamName(String groupName, String teamName) {
    for (final g in WorldCup2026Seed.groups) {
      if (g.name != groupName) continue;
      for (final t in g.teams) {
        if (t.name == teamName) return t.id;
      }
    }
    return null;
  }
}
