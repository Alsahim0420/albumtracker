import '../models/group_model.dart';
import '../models/sticker_model.dart';
import '../models/team_model.dart';

/// Estructura estática del álbum World Cup 2026.
/// 12 grupos (A–L), 48 equipos, 20 pegatinas por equipo (1 badge, 1 team photo, 18 players).
/// Total: 960 team stickers. Extensible a stadiums, specials, etc.
class WorldCup2026Seed {
  WorldCup2026Seed._();

  static const int stickersPerTeam = 20;
  static const int totalTeams = 48;
  static const int totalTeamStickers = totalTeams * stickersPerTeam; // 960

  static List<GroupModel>? _groups;
  static Map<String, StickerModel>? _stickerById;
  static Map<int, StickerModel>? _stickerByGlobalNumber;

  static List<GroupModel> get groups {
    _groups ??= _buildGroups();
    return _groups!;
  }

  static Map<String, StickerModel> get stickerById {
    _stickerById ??= _buildStickerMaps().$1;
    return _stickerById!;
  }

  static Map<int, StickerModel> get stickerByGlobalNumber {
    _stickerByGlobalNumber ??= _buildStickerMaps().$2;
    return _stickerByGlobalNumber!;
  }

  static StickerModel? getStickerById(String id) => stickerById[id];
  static StickerModel? getStickerByGlobalNumber(int n) => stickerByGlobalNumber[n];
  static TeamModel? getTeamById(String id) {
    for (final g in groups) {
      for (final t in g.teams) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  static List<GroupModel> _buildGroups() {
    _globalCounter = 0;
    const groupNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
    final teamData = _teamData;
    int teamIndex = 0;
    return groupNames.map((letter) {
      final id = 'group_$letter';
      final name = 'Group $letter';
      final teams = <TeamModel>[];
      for (var i = 0; i < 4; i++) {
        final t = teamData[teamIndex++];
        teams.add(_teamFromData(t, id));
      }
      return GroupModel(id: id, name: name, teams: teams);
    }).toList();
  }

  static int _globalCounter = 0;

  static TeamModel _teamFromData(_TeamSeedData data, String groupId) {
    final stickers = <StickerModel>[];
    final prefix = data.id;
    final startGlobal = _globalCounter + 1;
    _globalCounter += stickersPerTeam;
    stickers.add(StickerModel(
      id: '$prefix-B-01',
      code: '$prefix-B-01',
      type: StickerType.badge,
      teamId: data.id,
      globalNumber: startGlobal,
    ));
    stickers.add(StickerModel(
      id: '$prefix-P-01',
      code: '$prefix-P-01',
      type: StickerType.team_photo,
      teamId: data.id,
      globalNumber: startGlobal + 1,
    ));
    for (var i = 1; i <= 18; i++) {
      final code = '$prefix-PL-${i.toString().padLeft(2, '0')}';
      stickers.add(StickerModel(
        id: code,
        code: code,
        type: StickerType.player,
        playerName: 'Player $i',
        teamId: data.id,
        globalNumber: startGlobal + 1 + i,
      ));
    }
    return TeamModel(
      id: data.id,
      name: data.name,
      groupId: groupId,
      flagAssetPath: data.flagAssetPath,
      stickers: stickers,
    );
  }

  static (Map<String, StickerModel>, Map<int, StickerModel>) _buildStickerMaps() {
    final byId = <String, StickerModel>{};
    final byNum = <int, StickerModel>{};
    for (final g in groups) {
      for (final t in g.teams) {
        for (final s in t.stickers) {
          byId[s.id] = s;
          if (s.globalNumber != null) byNum[s.globalNumber!] = s;
        }
      }
    }
    return (byId, byNum);
  }

  static List<_TeamSeedData> get _teamData => [
    _TeamSeedData('MEX', 'Mexico', 'assets/flags/mx.svg'),
    _TeamSeedData('KOR', 'South Korea', 'assets/flags/kr.svg'),
    _TeamSeedData('RSA', 'South Africa', 'assets/flags/za.svg'),
    _TeamSeedData('TBD1', 'UEFA Playoff D', ''),
    _TeamSeedData('CAN', 'Canada', 'assets/flags/ca.svg'),
    _TeamSeedData('SUI', 'Switzerland', 'assets/flags/ch.svg'),
    _TeamSeedData('QAT', 'Qatar', 'assets/flags/qa.svg'),
    _TeamSeedData('TBD2', 'UEFA Playoff A', ''),
    _TeamSeedData('BRA', 'Brazil', 'assets/flags/br.svg'),
    _TeamSeedData('MAR', 'Morocco', 'assets/flags/ma.svg'),
    _TeamSeedData('SCO', 'Scotland', 'assets/flags/gb-sct.svg'),
    _TeamSeedData('HAI', 'Haiti', 'assets/flags/ht.svg'),
    _TeamSeedData('USA', 'USA', 'assets/flags/us.svg'),
    _TeamSeedData('PAR', 'Paraguay', 'assets/flags/py.svg'),
    _TeamSeedData('AUS', 'Australia', 'assets/flags/au.svg'),
    _TeamSeedData('TBD3', 'UEFA Playoff C', ''),
    _TeamSeedData('GER', 'Germany', 'assets/flags/de.svg'),
    _TeamSeedData('ECU', 'Ecuador', 'assets/flags/ec.svg'),
    _TeamSeedData('CIV', 'Ivory Coast', 'assets/flags/ci.svg'),
    _TeamSeedData('CUW', 'Curaçao', 'assets/flags/cw.svg'),
    _TeamSeedData('NED', 'Netherlands', 'assets/flags/nl.svg'),
    _TeamSeedData('JPN', 'Japan', 'assets/flags/jp.svg'),
    _TeamSeedData('TUN', 'Tunisia', 'assets/flags/tn.svg'),
    _TeamSeedData('TBD4', 'UEFA Playoff B', ''),
    _TeamSeedData('BEL', 'Belgium', 'assets/flags/be.svg'),
    _TeamSeedData('IRN', 'Iran', 'assets/flags/ir.svg'),
    _TeamSeedData('EGY', 'Egypt', 'assets/flags/eg.svg'),
    _TeamSeedData('NZL', 'New Zealand', 'assets/flags/nz.svg'),
    _TeamSeedData('ESP', 'Spain', 'assets/flags/es.svg'),
    _TeamSeedData('URU', 'Uruguay', 'assets/flags/uy.svg'),
    _TeamSeedData('KSA', 'Saudi Arabia', 'assets/flags/sa.svg'),
    _TeamSeedData('CPV', 'Cape Verde', 'assets/flags/cv.svg'),
    _TeamSeedData('FRA', 'France', 'assets/flags/fr.svg'),
    _TeamSeedData('SEN', 'Senegal', 'assets/flags/sn.svg'),
    _TeamSeedData('NOR', 'Norway', 'assets/flags/no.svg'),
    _TeamSeedData('TBD5', 'Inter-confederation Playoff 2', ''),
    _TeamSeedData('ARG', 'Argentina', 'assets/flags/ar.svg'),
    _TeamSeedData('AUT', 'Austria', 'assets/flags/at.svg'),
    _TeamSeedData('ALG', 'Algeria', 'assets/flags/dz.svg'),
    _TeamSeedData('JOR', 'Jordan', 'assets/flags/jo.svg'),
    _TeamSeedData('POR', 'Portugal', 'assets/flags/pt.svg'),
    _TeamSeedData('COL', 'Colombia', 'assets/flags/co.svg'),
    _TeamSeedData('UZB', 'Uzbekistan', 'assets/flags/uz.svg'),
    _TeamSeedData('TBD6', 'Inter-confederation Playoff 1', ''),
    _TeamSeedData('ENG', 'England', 'assets/flags/gb-eng.svg'),
    _TeamSeedData('CRO', 'Croatia', 'assets/flags/hr.svg'),
    _TeamSeedData('PAN', 'Panama', 'assets/flags/pa.svg'),
    _TeamSeedData('GHA', 'Ghana', 'assets/flags/gh.svg'),
  ];
}

class _TeamSeedData {
  const _TeamSeedData(this.id, this.name, this.flagAssetPath);
  final String id;
  final String name;
  final String flagAssetPath;
}
