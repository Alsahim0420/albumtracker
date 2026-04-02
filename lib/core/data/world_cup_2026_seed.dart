// ignore_for_file: unused_local_variable

import 'dart:ui';

import '../models/group_model.dart';
import '../models/sticker_model.dart';
import '../models/team_model.dart';

/// Estructura estática del álbum World Cup 2026.
/// 12 grupos (A–L), 48 equipos, 20 laminas por equipo (1 badge, 1 team photo, 18 players).
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
    final primaryColor = data.primaryColor;
    final secondaryColor = data.secondaryColor;
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
      primaryColor: data.primaryColor,
      secondaryColor: data.secondaryColor,
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
    _TeamSeedData(
                  'MEX',
                  'Mexico',
                  'assets/flags/mx.svg',
                  const Color.fromARGB(255, 0, 99, 64),
                  const Color.fromARGB(255, 200, 16, 47),
                ),
    _TeamSeedData(
                  'KOR',
                  'South Korea',
                  'assets/flags/kr.svg',
                  const Color(0xFF000000),
                  const Color(0xFFFFFFFF)),
    _TeamSeedData(
                  'RSA',
                  'South Africa',
                  'assets/flags/za.svg',
                  const Color.fromARGB(255, 0, 119, 73),
                  const Color.fromARGB(255, 255, 183, 28),
                ),
    _TeamSeedData(
                  'CZE',
                  'Czech Republic',
                  'assets/flags/cz.svg',
                  const Color.fromARGB(255, 17, 69, 126),
                  const Color.fromARGB(255, 215, 20, 26),
                ),
    _TeamSeedData(
                  'CAN',
                  'Canada',
                  'assets/flags/ca.svg',
                  const Color.fromARGB(255, 216, 6, 34),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'SUI',
                  'Switzerland',
                  'assets/flags/ch.svg',
                  const Color.fromARGB(255, 218, 41, 28),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'QAT',
                  'Qatar',
                  'assets/flags/qa.svg',
                  const Color.fromARGB(255, 138, 21, 56),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'BIH',
                  'Bosnia and Herzegovina',
                  'assets/flags/ba.svg',
                  const Color.fromARGB(255, 0, 35, 149),
                  const Color.fromARGB(255, 254, 203, 0),
                ),
    _TeamSeedData(
                  'BRA',
                  'Brazil',
                  'assets/flags/br.svg',
                  const Color(0xFF009C3B),
                  const Color(0xFFFFDF00),
                  ),
    _TeamSeedData(
                  'MAR',
                  'Morocco',
                  'assets/flags/ma.svg',
                  const Color.fromARGB(255, 193, 39, 44),
                  const Color.fromARGB(255, 0, 98, 51),
                ),
    _TeamSeedData(
                  'SCO',
                  'Scotland',
                  'assets/flags/gb-sct.svg',
                  const Color.fromARGB(255, 0, 95, 184),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'HAI',
                  'Haiti',
                  'assets/flags/ht.svg',
                  const Color.fromARGB(255, 0, 32, 159),
                  const Color.fromARGB(255, 210, 16, 52),
                ),
    _TeamSeedData(
                  'USA',
                  'USA',
                  'assets/flags/us.svg',
                  const Color.fromARGB(255, 179, 25, 66),
                  const Color.fromARGB(255, 10, 49, 97),
                ),
    _TeamSeedData(
                  'PAR',
                  'Paraguay',
                  'assets/flags/py.svg',
                  const Color.fromARGB(255, 213, 42, 30),
                  const Color.fromARGB(255, 0, 56, 168),
                ),
    _TeamSeedData(
                  'AUS',
                  'Australia',
                  'assets/flags/au.svg',
                  const Color.fromARGB(255, 1, 32, 105),
                  const Color.fromARGB(255, 228, 0, 42),
                ),
    _TeamSeedData(
                  'TUR',
                  'Turkey',
                  'assets/flags/tr.svg',
                  const Color.fromARGB(255, 227, 10, 23),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'GER',
                  'Germany',
                  'assets/flags/de.svg',
                  const Color.fromARGB(255, 0, 0, 0),
                  const Color.fromARGB(255, 255, 204, 0),
                ),
    _TeamSeedData(
                  'ECU',
                  'Ecuador',
                  'assets/flags/ec.svg',
                  const Color.fromARGB(255, 255, 208, 0),
                  const Color.fromARGB(255, 0, 113, 206),
                ),
    _TeamSeedData(
                  'CIV',
                  'Ivory Coast',
                  'assets/flags/ci.svg',
                  const Color.fromARGB(255, 255, 132, 0),
                  const Color.fromARGB(255, 0, 154, 67),
                ),
    _TeamSeedData(
                  'CUW',
                  'Curaçao',
                  'assets/flags/cw.svg',
                  const Color.fromARGB(255, 0, 42, 127),
                  const Color.fromARGB(255, 249, 234, 20),
                ),
    _TeamSeedData(
                  'NED',
                  'Netherlands',
                  'assets/flags/nl.svg',
                  const Color.fromARGB(255, 200, 16, 47),
                  const Color.fromARGB(255, 0, 60, 165),
                ),
    _TeamSeedData(
                  'JPN',
                  'Japan',
                  'assets/flags/jp.svg',
                  const Color.fromARGB(255, 188, 0, 44),
                  const Color.fromARGB(255, 26, 32, 75),
                ),
    _TeamSeedData(
                  'TUN',
                  'Tunisia',
                  'assets/flags/tn.svg',
                  const Color.fromARGB(255, 200, 16, 47),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'SWE',
                  'Sweden',
                  'assets/flags/se.svg',
                  const Color.fromARGB(255, 0, 106, 167),
                  const Color.fromARGB(255, 254, 204, 0),
                ),
    _TeamSeedData(
                  'BEL',
                  'Belgium',
                  'assets/flags/be.svg',
                  const Color.fromARGB(255, 255, 204, 0),
                  const Color.fromARGB(255, 200, 16, 47),
                ),
    _TeamSeedData(
                  'IRN',
                  'Iran',
                  'assets/flags/ir.svg',
                  const Color.fromARGB(255, 35, 159, 64),
                  const Color.fromARGB(255, 218, 0, 0),
                ),
    _TeamSeedData(
                  'EGY',
                  'Egypt',
                  'assets/flags/eg.svg',
                  const Color.fromARGB(255, 200, 16, 47),
                  const Color.fromARGB(255, 192, 147, 0),
                ),
    _TeamSeedData(
                  'NZL',
                  'New Zealand',
                  'assets/flags/nz.svg',
                  const Color.fromARGB(255, 200, 16, 47),
                  const Color.fromARGB(255, 1, 32, 105),
                ),
    _TeamSeedData(
                  'ESP',
                  'Spain',
                  'assets/flags/es.svg',
                  const Color.fromARGB(255, 170, 21, 26),
                  const Color.fromARGB(255, 241, 193, 0),
                ),
    _TeamSeedData(
                  'URU',
                  'Uruguay',
                  'assets/flags/uy.svg',
                  const Color.fromARGB(255, 0, 21, 137),
                  const Color.fromARGB(255, 255, 204, 0),
                ),
    _TeamSeedData(
                  'KSA',
                  'Saudi Arabia',
                  'assets/flags/sa.svg',
                  const Color.fromARGB(255, 22, 93, 49),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'CPV',
                  'Cape Verde',
                  'assets/flags/cv.svg',
                  const Color.fromARGB(255, 0, 60, 165),
                  const Color.fromARGB(255, 239, 51, 63),
                ),
    _TeamSeedData(
                  'FRA',
                  'France',
                  'assets/flags/fr.svg',
                  const Color.fromARGB(255, 0, 0, 145),
                  const Color.fromARGB(255, 225, 0, 15),
                ),
    _TeamSeedData(
                  'SEN',
                  'Senegal',
                  'assets/flags/sn.svg',
                  const Color.fromARGB(255, 0, 133, 62),
                  const Color.fromARGB(255, 253, 240, 66),
                ),
    _TeamSeedData(
                  'NOR',
                  'Norway',
                  'assets/flags/no.svg',
                  const Color.fromARGB(255, 186, 12, 47),
                  const Color.fromARGB(255, 0, 32, 91),
                ),
    _TeamSeedData(
                  'IRQ',
                  'Iraq',
                  'assets/flags/iq.svg',
                  const Color.fromARGB(255, 205, 33, 42),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'ARG',
                  'Argentina',
                  'assets/flags/ar.svg',
                  const Color(0xFF74ACDF),
                  const Color(0xFFFFFFFF),
                ),
      _TeamSeedData(
                  'AUT',
                  'Austria',
                  'assets/flags/at.svg',
                  const Color.fromARGB(255, 239, 51, 63),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'ALG',
                  'Algeria',
                  'assets/flags/dz.svg',
                  const Color.fromARGB(255, 0, 102, 51),
                  const Color.fromARGB(255, 210, 16, 52),
                ),
    _TeamSeedData(
                  'JOR',
                  'Jordan',
                  'assets/flags/jo.svg',
                  const Color.fromARGB(255, 206, 17, 39),
                  const Color.fromARGB(255, 0, 122, 61),
                ),
    _TeamSeedData(
                  'POR',
                  'Portugal',
                  'assets/flags/pt.svg',
                  const Color.fromARGB(255, 4, 106, 57),
                  const Color.fromARGB(255, 218, 41, 28),
                ),
    _TeamSeedData(
                  'COL',
                  'Colombia',
                  'assets/flags/co.svg',
                  const Color.fromARGB(255, 255, 204, 0),
                  const Color.fromARGB(255, 0, 47, 135),
                ),
    _TeamSeedData(
                  'UZB',
                  'Uzbekistan',
                  'assets/flags/uz.svg',
                  const Color.fromARGB(255, 0, 113, 206),
                  const Color.fromARGB(255, 67, 176, 42),
                ),
    _TeamSeedData(
                  'COD',
                  'DR Congo',
                  'assets/flags/cd.svg',
                  const Color.fromARGB(255, 0, 127, 255),
                  const Color.fromARGB(255, 247, 214, 24),
                ),
    _TeamSeedData(
                  'ENG',
                  'England',
                  'assets/flags/gb-eng.svg',
                  const Color.fromARGB(255, 206, 17, 36),
                  const Color(0xFFFFFFFF),
                ),
    _TeamSeedData(
                  'CRO',
                  'Croatia',
                  'assets/flags/hr.svg',
                  const Color.fromARGB(255, 255, 0, 0),
                  const Color.fromARGB(255, 1, 32, 105),
                ),
    _TeamSeedData(
                  'PAN',
                  'Panama',
                  'assets/flags/pa.svg',
                  const Color.fromARGB(255, 218, 18, 25),
                  const Color.fromARGB(255, 7, 35, 87),
                ),
    _TeamSeedData(
                  'GHA',
                  'Ghana',
                  'assets/flags/gh.svg',
                  const Color.fromARGB(255, 239, 51, 63),
                  const Color.fromARGB(255, 255, 208, 0),
                ),
  ];
}

class _TeamSeedData {
  const _TeamSeedData(
    this.id,
    this.name,
    this.flagAssetPath,
    this.primaryColor,
    this.secondaryColor
    );
  final String id;
  final String name;
  final String flagAssetPath;
  final Color primaryColor;
  final Color secondaryColor;
}