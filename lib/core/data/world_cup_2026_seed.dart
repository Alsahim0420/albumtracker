// ignore_for_file: unused_local_variable

import 'dart:ui';

import '../models/group_model.dart';
import '../models/sticker_model.dart';
import '../models/team_model.dart';
import 'sticker_identifier_aliases.dart';

/// Estructura estática del álbum de fútbol 2026.
/// 12 grupos (A–L), 48 equipos, 20 láminas por equipo: código `<TEAM> <1–20>` (id `TEAM-01`…`TEAM-20`).
/// Foto de equipo fija en el cupo 13; cupo 1 = escudo; el resto = plantel en orden.
/// Total: 960 team stickers. Extensible a stadiums, specials, etc.
class WorldCup2026Seed {
  WorldCup2026Seed._();

  static const int stickersPerTeam = 20;
  static const int totalTeams = 48;
  static const int totalTeamStickers = totalTeams * stickersPerTeam; // 960
  static const int totalSpecialStickers = 20;
  static const int totalAlbumStickers = totalTeamStickers + totalSpecialStickers; // 980
  static const String specialTeamCode = 'FWC';

  static List<GroupModel>? _groups;
  static List<StickerModel>? _specialStickers;
  static Map<String, StickerModel>? _stickerById;
  static Map<int, StickerModel>? _stickerByGlobalNumber;
  static Map<String, StickerModel>? _stickerByNormalizedIdentifier;

  static List<GroupModel> get groups {
    _groups ??= _buildGroups();
    return _groups!;
  }

  static Map<String, StickerModel> get stickerById {
    _stickerById ??= _buildStickerMaps().$1;
    return _stickerById!;
  }

  static List<StickerModel> get specialStickers {
    _specialStickers ??= _buildSpecialStickers();
    return _specialStickers!;
  }

  static Map<int, StickerModel> get stickerByGlobalNumber {
    _stickerByGlobalNumber ??= _buildStickerMaps().$2;
    return _stickerByGlobalNumber!;
  }

  static StickerModel? getStickerById(String id) => stickerById[id];
  static StickerModel? getStickerByGlobalNumber(int n) =>
      stickerByGlobalNumber[n];
  static StickerModel? getStickerByFlexibleIdentifier(String identifier) {
    final normalized = normalizeStickerIdentifier(identifier);
    if (normalized.isEmpty) return null;

    final aliasId = kStickerIdentifierAliases[normalized];
    if (aliasId != null && aliasId.isNotEmpty) {
      final byAlias = getStickerById(aliasId);
      if (byAlias != null) return byAlias;
    }

    final asGlobal = int.tryParse(normalized);
    if (asGlobal != null) {
      return getStickerByGlobalNumber(asGlobal);
    }

    _stickerByNormalizedIdentifier ??= _buildNormalizedIdentifierMap();
    return _stickerByNormalizedIdentifier![normalized];
  }

  static String normalizeStickerIdentifier(String value) {
    final upper = value.trim().toUpperCase();
    if (upper.isEmpty) return '';
    return upper.replaceAll(RegExp(r'[^A-Z0-9\-]'), '').replaceAll('_', '-');
  }

  /// Normaliza texto OCR para comparar con [StickerModel.playerName]: minúsculas,
  /// sin acentos y solo letras/espacios (nombres en lámina frontal / Qatar 2022, etc.).
  static String normalizeTextForPlayerNameMatch(String text) {
    var s = text.toLowerCase();
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
    s = s.replaceAll(RegExp(r'[^a-z\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static List<MapEntry<String, StickerModel>>? _playerNameSearchEntries;

  static void _ensurePlayerNameSearchList() {
    _playerNameSearchEntries ??= () {
      final out = <MapEntry<String, StickerModel>>[];
      for (final g in groups) {
        for (final t in g.teams) {
          for (final s in t.stickers) {
            if (s.type != StickerType.player) continue;
            final pn = s.playerName;
            if (pn == null || pn.isEmpty) continue;
            final key = normalizeTextForPlayerNameMatch(pn);
            if (key.length < 4) continue;
            out.add(MapEntry(key, s));
          }
        }
      }
      out.sort((a, b) => b.key.length.compareTo(a.key.length));
      return out;
    }();
  }

  /// Busca láminas de jugador cuyo nombre completo aparece en el texto OCR (foto del
  /// frente de la lámina con "LIONEL MESSI", etc.). Coincide con el plantel del seed
  /// actual (p. ej. Mundial 2026), no con otra edición salvo que el nombre sea igual.
  static List<StickerModel> findStickersByPlayerNamesInText(String rawOcrText) {
    final blob = normalizeTextForPlayerNameMatch(rawOcrText);
    if (blob.length < 4) return [];
    _ensurePlayerNameSearchList();
    final found = <String, StickerModel>{};
    for (final e in _playerNameSearchEntries!) {
      if (blob.contains(e.key)) {
        found[e.value.id] = e.value;
      }
    }
    return found.values.toList(growable: false);
  }

  static TeamModel? getTeamById(String id) {
    for (final g in groups) {
      for (final t in g.teams) {
        if (t.id == id) return t;
      }
    }
    return null;
  }

  /// Número de lámina visible: solo el entero global ascendente.
  static String stickerNumberLabel(String stickerId) {
    final s = getStickerById(stickerId);
    if (s != null) return s.displayCode;
    return stickerId;
  }

  /// Título en tarjetas (repetidas / faltantes): nombre del jugador; si no, el número global.
  static String stickerCaptionTitle(String stickerId) {
    final s = getStickerById(stickerId);
    if (s?.type == StickerType.player) {
      final n = s!.playerName;
      if (n != null && n.isNotEmpty) return n;
    }
    return stickerNumberLabel(stickerId);
  }

  static bool isPlayerStickerId(String stickerId) =>
      getStickerById(stickerId)?.type == StickerType.player;

  static bool isBadgeStickerId(String stickerId) =>
      getStickerById(stickerId)?.type == StickerType.badge;

  static bool isSpecialStickerId(String stickerId) =>
      getStickerById(stickerId)?.type == StickerType.special;

  static List<GroupModel> _buildGroups() {
    _globalCounter = 0;
    const groupNames = [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
    ];
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

  static const int _teamPhotoSlot = 13;

  static TeamModel _teamFromData(_TeamSeedData data, String groupId) {
    final stickers = <StickerModel>[];
    final prefix = data.id;
    final startGlobal = _globalCounter + 1;
    _globalCounter += stickersPerTeam;
    final players = data.playerNames;

    StickerModel slot(
      int teamSlot,
      StickerType type, {
      String? playerName,
    }) {
      final code = '$prefix $teamSlot';
      final id = '$prefix-${teamSlot.toString().padLeft(2, '0')}';
      return StickerModel(
        id: id,
        code: code,
        type: type,
        playerName: playerName,
        teamId: data.id,
        globalNumber: startGlobal + teamSlot - 1,
      );
    }

    stickers.add(slot(1, StickerType.badge));
    for (var i = 0; i < 11; i++) {
      stickers.add(slot(2 + i, StickerType.player, playerName: players[i]));
    }
    stickers.add(slot(_teamPhotoSlot, StickerType.team_photo));
    for (var i = 11; i < 18; i++) {
      stickers.add(slot(14 + (i - 11), StickerType.player, playerName: players[i]));
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

  static (Map<String, StickerModel>, Map<int, StickerModel>)
  _buildStickerMaps() {
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
    for (final s in specialStickers) {
      byId[s.id] = s;
      if (s.globalNumber != null) byNum[s.globalNumber!] = s;
    }
    return (byId, byNum);
  }

  static Map<String, StickerModel> _buildNormalizedIdentifierMap() {
    final map = <String, StickerModel>{};
    for (final sticker in stickerById.values) {
      final variants = <String>{
        normalizeStickerIdentifier(sticker.id),
        normalizeStickerIdentifier(sticker.code),
        normalizeStickerIdentifier(sticker.id.replaceAll('-', '')),
        normalizeStickerIdentifier(sticker.code.replaceAll('-', '')),
      };
      final idMatch = RegExp(r'^([A-Z]{2,4})-0*(\d+)$').firstMatch(sticker.id);
      if (idMatch != null) {
        final n = int.tryParse(idMatch.group(2)!);
        if (n != null) {
          final unpaddedId = '${idMatch.group(1)}-$n';
          variants.add(normalizeStickerIdentifier(unpaddedId));
        }
      }
      if (sticker.globalNumber != null) {
        variants.add(sticker.globalNumber.toString());
      }
      for (final variant in variants) {
        if (variant.isEmpty) continue;
        map.putIfAbsent(variant, () => sticker);
      }
    }
    for (final g in groups) {
      for (final t in g.teams) {
        final p = t.id;
        for (final s in t.stickers) {
          if (s.type == StickerType.badge) {
            map.putIfAbsent(
              normalizeStickerIdentifier('$p-B-01'),
              () => s,
            );
            break;
          }
        }
        for (final s in t.stickers) {
          if (s.type == StickerType.team_photo) {
            map.putIfAbsent(
              normalizeStickerIdentifier('$p-P-01'),
              () => s,
            );
            break;
          }
        }
        for (var k = 1; k <= 18; k++) {
          final newSlot = k <= 11 ? k + 1 : k + 2;
          final newId = '$p-${newSlot.toString().padLeft(2, '0')}';
          StickerModel? st;
          for (final s in t.stickers) {
            if (s.id == newId) {
              st = s;
              break;
            }
          }
          if (st != null) {
            final legacy = '$p-PL-${k.toString().padLeft(2, '0')}';
            map.putIfAbsent(
              normalizeStickerIdentifier(legacy),
              () => st!,
            );
          }
        }
      }
    }
    return map;
  }

  static List<StickerModel> _buildSpecialStickers() {
    final out = <StickerModel>[];
    final start = totalTeamStickers + 1;
    for (var i = 0; i < totalSpecialStickers; i++) {
      final id = '$specialTeamCode-${i.toString().padLeft(2, '0')}';
      final code = i == 0 ? '00' : '$specialTeamCode $i';
      out.add(
        StickerModel(
          id: id,
          code: code,
          type: StickerType.special,
          teamId: specialTeamCode,
          globalNumber: start + i,
        ),
      );
    }
    return out;
  }

  static List<_TeamSeedData> get _teamData => [
    _TeamSeedData(
      'MEX',
      'Mexico',
      'assets/flags/mx.svg',
      const Color.fromARGB(255, 0, 99, 64),
      const Color.fromARGB(255, 200, 16, 47),
      const [
      'Luis Malagón',
      'Johan Vásquez',
      'Jorge Sánchez',
      'César Montes',
      'Jesús Gallardo',
      'Israel Reyes',
      'Diego Lainez',
      'Carlos Rodríguez',
      'Edson Álvarez',
      'Orbelín Pineda',
      'Marcel Ruiz',
      'Erick Sánchez',
      'Hirving Lozano',
      'Santiago Giménez',
      'Raúl Jiménez',
      'Alexis Vega',
      'Roberto Alvarado',
      'César Huerta',
      ],
    ),
    _TeamSeedData(
      'KOR',
      'South Korea',
      'assets/flags/kr.svg',
      const Color(0xFF000000),
      const Color(0xFFFFFFFF),
      const [
  'Hyeonwoo Jo',
  'Seunggyu Kim',
  'Minjae Kim',
  'Yumin Cho',
  'Youngwoo Seol',
  'Hangbeom Lee',
  'Taeseok Lee',
  'Myungjae Lee',
  'Jaesung Lee',
  'Inbeom Hwang',
  'Kangin Lee',
  'Seungho Paik',
  'Jens Castrop',
  'Donggyeong Lee',
  'Guesung Cho',
  'Heungmin Son',
  'Heechan Hwang',
  'Hyeongyu Oh',
],
    ),
    _TeamSeedData(
      'RSA',
      'South Africa',
      'assets/flags/za.svg',
      const Color.fromARGB(255, 0, 119, 73),
      const Color.fromARGB(255, 255, 183, 28),
      const [
  'Ronwen Williams',
  'Sipho Chaine',
  'Aubrey Modiba',
  'Samukele Kabini',
  'Mbekezeli Mbokazi',
  'Khulumani Ndamane',
  'Siyabonga Ngezana',
  'Khuliso Mudau',
  'Nkosinathi Sibisi',
  'Teboho Mokoena',
  'Thalente Mbatha',
  'Bathusi Aubaas',
  'Yaya Sithole',
  'Sipho Mbule',
  'Lyle Foster',
  'Iqraam Rayners',
  'Mohau Nkota',
  'Oswin Appollis',
      ],
    ),
    _TeamSeedData(
      'CZE',
      'Czech Republic',
      'assets/flags/cz.svg',
      const Color.fromARGB(255, 17, 69, 126),
      const Color.fromARGB(255, 215, 20, 26),
      const [
  'Matěj Kovář',
  'Jindřich Staněk',
  'Ladislav Krejčí',
  'Vladimír Coufal',
  'Jaroslav Zelený',
  'Tomáš Holeš',
  'David Zima',
  'Michal Sadílek',
  'Lukáš Provod',
  'Lukáš Červ',
  'Tomáš Souček',
  'Pavel Šulc',
  'Matěj Vydra',
  'Václav Kušej',
  'Tomáš Chorý',
  'Václav Černý',
  'Adam Hložek',
  'Patrik Schick',
],
    ),
    _TeamSeedData(
      'CAN',
      'Canada',
      'assets/flags/ca.svg',
      const Color.fromARGB(255, 216, 6, 34),
      const Color(0xFFFFFFFF),
      const [
      'David St. Clair',
      'Alphonso Davies',
      'Alistair Johnston',
      'Samuel Adekugbe',
      'Richie Laryea',
      'Derek Cornelius',
      'Moïse Bombito',
      'Kamal Miller',
      'Stephen Eustáquio',
      'Ismaël Koné',
      'Jonathan Osorio',
      'Jacob Shaffelburg',
      'Mathieu Choinière',
      'Niko Sigur',
      'Tajon Buchanan',
      'Liam Millar',
      'Cyle Larin',
      'Jonathan David',
    ],
    ),
    _TeamSeedData(
      'SUI',
      'Switzerland',
      'assets/flags/ch.svg',
      const Color.fromARGB(255, 218, 41, 28),
      const Color(0xFFFFFFFF),
      const [
  'Gregor Kobel',
  'Yvon Mvogo',
  'Manuel Akanji',
  'Ricardo Rodríguez',
  'Nico Elvedi',
  'Aurèle Amenda',
  'Silvan Widmer',
  'Granit Xhaka',
  'Denis Zakaria',
  'Remo Freuler',
  'Fabian Rieder',
  'Ardon Jashari',
  'Johan Manzambi',
  'Michel Aebischer',
  'Breel Embolo',
  'Rubén Vargas',
  'Dan Ndoye',
  'Zeki Amdouni',
],
    ),
    _TeamSeedData(
      'QAT',
      'Qatar',
      'assets/flags/qa.svg',
      const Color.fromARGB(255, 138, 21, 56),
      const Color(0xFFFFFFFF),
      const [
  'Meshaal Barsham',
  'Sultan Al Brake',
  'Lucas Mendes',
  'Homam Ahmed',
  'Boualem Khoukhi',
  'Pedro Miguel',
  'Tarek Salman',
  'Mohammed Mannai',
  'Karim Boudiaf',
  'Assim Madibo',
  'Hamed Fatehi',
  'Mohammed Waad',
  'Abdulaziz Hatem',
  'Hassan Al-Haydos',
  'Edmilson Júnior',
  'Akram Hassan Afif',
  'Ahmed Al-Ganehi',
  'Almoez Ali',
],
    ),
    _TeamSeedData(
      'BIH',
      'Bosnia and Herzegovina',
      'assets/flags/ba.svg',
      const Color.fromARGB(255, 0, 35, 149),
      const Color.fromARGB(255, 254, 203, 0),
      const [
      'Nikola Vasilj',
      'Amar Dedić',
      'Sead Kolašinac',
      'Tarik Muharemović',
      'Nihad Mujakić',
      'Nikola Katić',
      'Amir Hadžiahmetović',
      'Benjamin Tahirović',
      'Armin Gigović',
      'Ivan Šunjić',
      'Ivan Bašić',
      'Dženis Burnić',
      'Esmir Bajraktarević',
      'Amar Memić',
      'Ermedin Demirović',
      'Edin Džeko',
      'Samed Baždar',
      'Haris Tabaković',
    ],
    ),
    _TeamSeedData(
      'BRA',
      'Brazil',
      'assets/flags/br.svg',
      const Color(0xFF009C3B),
      const Color(0xFFFFDF00),
      const [
  'Alisson',
  'Bento',
  'Marquinhos',
  'Éder Militão',
  'Gabriel Magalhães',
  'Danilo',
  'Wesley',
  'Lucas Paquetá',
  'Casemiro',
  'Bruno Guimarães',
  'Luiz Henrique',
  'Vinícius Júnior',
  'Rodrygo',
  'João Pedro',
  'Matheus Cunha',
  'Gabriel Martinelli',
  'Raphinha',
  'Estevão',
],
    ),
    _TeamSeedData(
      'MAR',
      'Morocco',
      'assets/flags/ma.svg',
      const Color.fromARGB(255, 193, 39, 44),
      const Color.fromARGB(255, 0, 98, 51),
      const [
  'Yassine Bounou',
  'Munir El Kajoui',
  'Achraf Hakimi',
  'Noussair Mazraoui',
  'Nayef Aguerd',
  'Romain Saïss',
  'Jawad El Yamiq',
  'Adam Masina',
  'Sofyan Amrabat',
  'Azzedine Ounahi',
  'Ilias Ben Seghir',
  'Bilal El Khannouss',
  'Ismael Saibari',
  'Youssef En-Nesyri',
  'Abde Ezzalzouli',
  'Sofiane Rahimi',
  'Brahim Díaz',
  'Ayoub El Kaabi',
],
    ),
    _TeamSeedData(
      'SCO',
      'Scotland',
      'assets/flags/gb-sct.svg',
      const Color.fromARGB(255, 0, 95, 184),
      const Color(0xFFFFFFFF),
      const [
  'Angus Gunn',
  'Jack Hendry',
  'Kieran Tierney',
  'Aaron Hickey',
  'Andrew Robertson',
  'Scott McKenna',
  'John Souttar',
  'Anthony Ralston',
  'Grant Hanley',
  'Scott McTominay',
  'Billy Gilmour',
  'Lewis Ferguson',
  'Ryan Christie',
  'Kenny McLean',
  'John McGinn',
  'Lyndon Dykes',
  'Che Adams',
  'Ben Gannon-Doak',
],
    ),
    _TeamSeedData(
      'HAI',
      'Haiti',
      'assets/flags/ht.svg',
      const Color.fromARGB(255, 0, 32, 159),
      const Color.fromARGB(255, 210, 16, 52),
      const [
  'Johny Placide',
  'Carlens Arcus',
  'Martin Expérience',
  'Jean-Kévin Duverne',
  'Ricardo Adé',
  'Duke Lacroix',
  'Garven Metusala',
  'Hannes Delcroix',
  'Leverton Pierre',
  'Danley Jean Jacques',
  'Jean-Ricner Bellegarde',
  'Christopher Attys',
  'Derrick Étienne Jr.',
  'Josué Casimir',
  'Ruben Providence',
  'Duckens Nazon',
  'Louicius Deedson',
  'Frantzdy Pierrot',
],
    ),
    _TeamSeedData(
      'USA',
      'USA',
      'assets/flags/us.svg',
      const Color.fromARGB(255, 179, 25, 66),
      const Color.fromARGB(255, 10, 49, 97),
      const [
  'Matt Freese',
  'Chris Richards',
  'Tim Ream',
  'Mark McKenzie',
  'Alex Freeman',
  'Antonee Robinson',
  'Tyler Adams',
  'Tanner Tessmann',
  'Weston McKennie',
  'Cristian Roldan',
  'Timothy Weah',
  'Diego Luna',
  'Malik Tillman',
  'Christian Pulisic',
  'Brenden Aaronson',
  'Ricardo Pepi',
  'Haji Wright',
  'Folarin Balogun',
],
    ),
    _TeamSeedData(
      'PAR',
      'Paraguay',
      'assets/flags/py.svg',
      const Color.fromARGB(255, 213, 42, 30),
      const Color.fromARGB(255, 0, 56, 168),
      const [
  'Roberto Fernández',
  'Orlando Gill',
  'Gustavo Gómez',
  'Fabián Balbuena',
  'Juan José Cáceres',
  'Omar Alderete',
  'Junior Alonso',
  'Mathías Villasanti',
  'Diego Gómez',
  'Damián Bobadilla',
  'Andrés Cubas',
  'Matías Galarza Fonda',
  'Julio Enciso',
  'Alejandro Romero Gamarra',
  'Miguel Almirón',
  'Ramón Sosa',
  'Ángel Romero',
  'Antonio Sanabria',
],
    ),
    _TeamSeedData(
      'AUS',
      'Australia',
      'assets/flags/au.svg',
      const Color.fromARGB(255, 1, 32, 105),
      const Color.fromARGB(255, 228, 0, 42),
      const [
  'Mathew Ryan',
  'Joe Gauci',
  'Harry Souttar',
  'Alessandro Circati',
  'Jordan Bos',
  'Aziz Behich',
  'Cameron Burgess',
  'Lewis Miller',
  'Milos Degenek',
  'Jackson Irvine',
  'Riley McGree',
  'Aiden O\'Neill',
  'Connor Metcalfe',
  'Patrick Yazbek',
  'Craig Goodwin',
  'Kusini Yengi',
  'Nestory Irankunda',
  'Mohamed Touré',
],
    ),
    _TeamSeedData(
      'TUR',
      'Turkey',
      'assets/flags/tr.svg',
      const Color.fromARGB(255, 227, 10, 23),
      const Color(0xFFFFFFFF),
      const [
  'Uğurcan Çakır',
  'Mert Müldür',
  'Zeki Çelik',
  'Abdülkerim Bardakcı',
  'Çağlar Söyüncü',
  'Merih Demiral',
  'Ferdi Kadıoğlu',
  'Kaan Ayhan',
  'İsmail Yüksek',
  'Hakan Çalhanoğlu',
  'Orkun Kökçü',
  'Arda Güler',
  'İrfan Can Kahveci',
  'Yunus Akgün',
  'Can Uzun',
  'Barış Alper Yılmaz',
  'Kerem Aktürkoğlu',
  'Kenan Yıldız',
],
    ),
    _TeamSeedData(
      'GER',
      'Germany',
      'assets/flags/de.svg',
      const Color.fromARGB(255, 0, 0, 0),
      const Color.fromARGB(255, 255, 204, 0),
      const [
  'Marc-André ter Stegen',
  'Jonathan Tah',
  'David Raum',
  'Nico Schlotterbeck',
  'Antonio Rüdiger',
  'Waldemar Anton',
  'Ridle Baku',
  'Maximilian Mittelstädt',
  'Joshua Kimmich',
  'Florian Wirtz',
  'Felix Nmecha',
  'Leon Goretzka',
  'Jamal Musiala',
  'Serge Gnabry',
  'Kai Havertz',
  'Leroy Sané',
  'Karim Adeyemi',
  'Nick Woltemade',
],
    ),
    _TeamSeedData(
      'ECU',
      'Ecuador',
      'assets/flags/ec.svg',
      const Color.fromARGB(255, 255, 208, 0),
      const Color.fromARGB(255, 0, 113, 206),
      const [
  'Hernán Galíndez',
  'Gonzalo Valle',
  'Piero Hincapié',
  'Pervis Estupiñán',
  'William Pacho',
  'Ángelo Preciado',
  'Joel Ordóñez',
  'Moisés Caicedo',
  'Alan Franco',
  'Kendry Páez',
  'Pedro Vite',
  'John Yeboah',
  'Leonardo Campana',
  'Gonzalo Plata',
  'Nilson Angulo',
  'Alan Minda',
  'Kevin Rodríguez',
  'Enner Valencia',
],
    ),
    _TeamSeedData(
      'CIV',
      'Ivory Coast',
      'assets/flags/ci.svg',
      const Color.fromARGB(255, 255, 132, 0),
      const Color.fromARGB(255, 0, 154, 67),
      const [
  'Yahia Fofana',
  'Ghislain Konan',
  'Wilfried Singo',
  'Odilon Kossounou',
  'Evan Ndicka',
  'Willy Boly',
  'Emmanuel Agbadou',
  'Ousmane Diomande',
  'Franck Kessié',
  'Seko Fofana',
  'Ibrahim Sangaré',
  'Jean-Philippe Gbamin',
  'Amad Diallo',
  'Sébastien Haller',
  'Simon Adingra',
  'Yvan Diomande',
  'Evann Guessand',
  'Oumar Diakité',
],
    ),
    _TeamSeedData(
      'CUW',
      'Curaçao',
      'assets/flags/cw.svg',
      const Color.fromARGB(255, 0, 42, 127),
      const Color.fromARGB(255, 249, 234, 20),
      const [
  'Eloy Room',
  'Armando Obispo',
  'Sherel Floranus',
  'Jurien Gaari',
  'Joshua Brenet',
  'Roshon van Eijma',
  'Sherandy Sambo',
  'Juninho Comenencia',
  'Godfried Roemeratoe',
  'Juninho Bacuna',
  'Leandro Bacuna',
  'Tahith Chong',
  'Kenji Gorré',
  'Jearl Margaritha',
  'Jürgen Locadia',
  'Jeremy Antonisse',
  'Gervane Kastaneer',
  'Sontje Hansen',
],
    ),
    _TeamSeedData(
      'NED',
      'Netherlands',
      'assets/flags/nl.svg',
      const Color.fromARGB(255, 200, 16, 47),
      const Color.fromARGB(255, 0, 60, 165),
      const [
  'Bart Verbruggen',
  'Virgil van Dijk',
  'Micky van de Ven',
  'Jurriën Timber',
  'Denzel Dumfries',
  'Nathan Aké',
  'Jeremie Frimpong',
  'Jan Paul van Hecke',
  'Tijjani Reijnders',
  'Ryan Gravenberch',
  'Teun Koopmeiners',
  'Frenkie de Jong',
  'Xavi Simons',
  'Justin Kluivert',
  'Memphis Depay',
  'Donyell Malen',
  'Wout Weghorst',
  'Cody Gakpo',
],
    ),
    _TeamSeedData(
      'JPN',
      'Japan',
      'assets/flags/jp.svg',
      const Color.fromARGB(255, 188, 0, 44),
      const Color.fromARGB(255, 26, 32, 75),
      const [
  'Zion Suzuki',
  'Henry Heroki Mochizuki',
  'Ayumu Seko',
  'Junnosuke Suzuki',
  'Shogo Taniguchi',
  'Tsuyoshi Watanabe',
  'Kaishu Sano',
  'Yuki Soma',
  'Ao Tanaka',
  'Daichi Kamada',
  'Takefusa Kubo',
  'Ritsu Doan',
  'Keito Nakamura',
  'Takumi Minamino',
  'Shuto Machino',
  'Junya Ito',
  'Koki Ogawa',
  'Ayase Ueda',
],
    ),
    _TeamSeedData(
      'TUN',
      'Tunisia',
      'assets/flags/tn.svg',
      const Color.fromARGB(255, 200, 16, 47),
      const Color(0xFFFFFFFF),
      const [
  'Bechir Ben Said',
  'Aymen Dahmen',
  'Yan Valery',
  'Montassar Talbi',
  'Yassine Meriah',
  'Ali Abdi',
  'Dylan Bronn',
  'Ellyes Skhiri',
  'Aissa Laidouni',
  'Ferjani Sassi',
  'Mohamed Ali Ben Romdhane',
  'Hannibal Mejbri',
  'Elias Achouri',
  'Elias Saad',
  'Hazem Mastouri',
  'Ismaël Gharbi',
  'Sayfallah Ltaief',
  'Naïm Sliti',
],
    ),
    _TeamSeedData(
      'SWE',
      'Sweden',
      'assets/flags/se.svg',
      const Color.fromARGB(255, 0, 106, 167),
      const Color.fromARGB(255, 254, 204, 0),
      const [
  'Viktor Johansson',
  'Isak Hien',
  'Gabriel Gudmundsson',
  'Emil Holm',
  'Victor Nilsson Lindelöf',
  'Gustaf Lagerbielke',
  'Lucas Bergvall',
  'Hugo Larsson',
  'Jesper Karlström',
  'Vasin Avari',
  'Mattias Svanberg',
  'Daniel Svensson',
  'Ken Sema',
  'Roony Bardghji',
  'Dejan Kulusevski',
  'Anthony Elanga',
  'Alexander Isak',
  'Viktor Gyökeres',
],
    ),
    _TeamSeedData(
      'BEL',
      'Belgium',
      'assets/flags/be.svg',
      const Color.fromARGB(255, 255, 204, 0),
      const Color.fromARGB(255, 200, 16, 47),
      const [
  'Thibaut Courtois',
  'Arthur Theate',
  'Timothy Castagne',
  'Zeno Debast',
  'Brandon Mechele',
  'Maxim De Cuyper',
  'Thomas Meunier',
  'Youri Tielemans',
  'Amadou Onana',
  'Nicolas Raskin',
  'Alexis Saelemaekers',
  'Hans Vanaken',
  'Kevin De Bruyne',
  'Jérémy Doku',
  'Charles De Ketelaere',
  'Leandro Trossard',
  'Loïs Openda',
  'Romelu Lukaku',
],
    ),
    _TeamSeedData(
      'IRN',
      'Iran',
      'assets/flags/ir.svg',
      const Color.fromARGB(255, 35, 159, 64),
      const Color.fromARGB(255, 218, 0, 0),
      const [
  'Alireza Beiranvand',
  'Morteza Pouraliganji',
  'Ehsan Hajsafi',
  'Milad Mohammadi',
  'Shojae Khalilzadeh',
  'Ramin Rezaeian',
  'Hossein Kanaani',
  'Sadegh Moharrami',
  'Saleh Hardani',
  'Saeed Ezatolahi',
  'Saman Ghoddos',
  'Omid Noorafkan',
  'Roozbeh Cheshmi',
  'Mohammad Mohebi',
  'Sardar Azmoun',
  'Mehdi Taremi',
  'Alireza Jahanbakhsh',
  'Ali Gholizadeh',
],
    ),
    _TeamSeedData(
      'EGY',
      'Egypt',
      'assets/flags/eg.svg',
      const Color.fromARGB(255, 200, 16, 47),
      const Color.fromARGB(255, 192, 147, 0),
      const [
  'Mohamed El Shenawy',
  'Mohamed Hany',
  'Mohamed Hamdy',
  'Yasser Ibrahim',
  'Khaled Sobhi',
  'Ramy Rabia',
  'Hossam Abdelmaguid',
  'Ahmed Fattouh',
  'Marwan Attia',
  'Zizo',
  'Hamdy Fathy',
  'Mohannad Lasheen',
  'Emam Ashour',
  'Osama Faisal',
  'Mohamed Salah',
  'Mostafa Mohamed',
  'Trezeguet',
  'Omar Marmoush',
],
    ),
    _TeamSeedData(
      'NZL',
      'New Zealand',
      'assets/flags/nz.svg',
      const Color.fromARGB(255, 200, 16, 47),
      const Color.fromARGB(255, 1, 32, 105),
      const [
  'Max Crocombe',
  'Alex Paulsen',
  'Michael Boxall',
  'Liberato Cacace',
  'Tim Payne',
  'Tyler Bindon',
  'Francis De Vries',
  'Finn Surman',
  'Joe Bell',
  'Sarpreet Singh',
  'Ryan Thomas',
  'Matthew Garbett',
  'Marko Stamenic',
  'Ben Old',
  'Chris Wood',
  'Elijah Just',
  'Callum McCowatt',
  'Kosta Barbarouses',
],
    ),
    _TeamSeedData(
      'ESP',
      'Spain',
      'assets/flags/es.svg',
      const Color.fromARGB(255, 170, 21, 26),
      const Color.fromARGB(255, 241, 193, 0),
      const [
  'Unai Simón',
  'Robin Le Normand',
  'Aymeric Laporte',
  'Dean Huijsen',
  'Pedro Porro',
  'Dani Carvajal',
  'Marc Cucurella',
  'Martín Zubimendi',
  'Rodri',
  'Pedri',
  'Fabián Ruiz',
  'Mikel Merino',
  'Lamine Yamal',
  'Dani Olmo',
  'Nico Williams',
  'Ferran Torres',
  'Álvaro Morata',
  'Mikel Oyarzabal',
],
    ),
    _TeamSeedData(
      'URU',
      'Uruguay',
      'assets/flags/uy.svg',
      const Color.fromARGB(255, 0, 21, 137),
      const Color.fromARGB(255, 255, 204, 0),
      const [
  'Sergio Rochet',
  'Santiago Mele',
  'Ronald Araújo',
  'José María Giménez',
  'Sebastián Cáceres',
  'Mathías Olivera',
  'Guillermo Varela',
  'Nahitan Nández',
  'Federico Valverde',
  'Giorgian De Arrascaeta',
  'Rodrigo Bentancur',
  'Manuel Ugarte',
  'Nicolás De La Cruz',
  'Maxi Araújo',
  'Darwin Núñez',
  'Federico Viñas',
  'Rodrigo Aguirre',
  'Facundo Pellistri',
],
    ),
    _TeamSeedData(
      'KSA',
      'Saudi Arabia',
      'assets/flags/sa.svg',
      const Color.fromARGB(255, 22, 93, 49),
      const Color(0xFFFFFFFF),
      const [
  'Nawaf Alaqidi',
  'Abdulrahman Alsanbi',
  'Saud Abdulhamid',
  'Nawaf Buwashl',
  'Jehad Thakri',
  'Motez Alharbi',
  'Hassan Altambakti',
  'Musab Aljuwayr',
  'Ziyad Aljohani',
  'Abdullah Alkhaibari',
  'Nasser Aldawsari',
  'Saleh Abu Alshamat',
  'Marwan Alshafai',
  'Salem Aldawsari',
  'Abdulrahman Alobud',
  'Feras Albrikan',
  'Saleh Alshehri',
  'Abdullah Alhamdan',
],
    ),
    _TeamSeedData(
      'CPV',
      'Cape Verde',
      'assets/flags/cv.svg',
      const Color.fromARGB(255, 0, 60, 165),
      const Color.fromARGB(255, 239, 51, 63),
      const [
  'Vozinha',

  'Logan Costa',
  'Pico',
  'Diney',
  'Steven Moreira',
  'Wagner Pina',
  'João Paulo',
  'Willy Semedo',
  'Kevin Pina',
  'Patrick Andrade',
  'Jamiro Monteiro',
  'Deroy Duarte',
  'Garry Rodrigues',
  'Jovane Cabral',
  'Ryan Mendes',
  'Dálcio Livramento',
  'Willy Semedo',
  'Bebé',
],
    ),
    _TeamSeedData(
      'FRA',
      'France',
      'assets/flags/fr.svg',
      const Color.fromARGB(255, 0, 0, 145),
      const Color.fromARGB(255, 225, 0, 15),
      const [
  'Mike Maignan',
  'Theo Hernández',
  'William Saliba',
  'Jules Koundé',
  'Ibrahima Konaté',
  'Dayot Upamecano',
  'Lucas Digne',
  'Aurélien Tchouaméni',
  'Eduardo Camavinga',
  'Manu Koné',
  'Adrien Rabiot',
  'Michael Olise',
  'Ousmane Dembélé',
  'Bradley Barcola',
  'Désiré Doué',
  'Kingsley Coman',
  'Hugo Ekitike',
  'Kylian Mbappé',
],
    ),
    _TeamSeedData(
      'SEN',
      'Senegal',
      'assets/flags/sn.svg',
      const Color.fromARGB(255, 0, 133, 62),
      const Color.fromARGB(255, 253, 240, 66),
      const [
  'Edouard Mendy',
  'Yehvann Diouf',
  'Moussa Niakhaté',
  'Abdoulaye Seck',
  'Ismail Jakobs',
  'El Hadji Malick Diouf',
  'Kalidou Koulibaly',
  'Idrissa Gana Gueye',
  'Pape Matar Sarr',
  'Pape Gueye',
  'Habib Diarra',
  'Lamine Camara',
  'Sadio Mané',
  'Ismaila Sarr',
  'Boulaye Dia',
  'Liman Ndiaye',
  'Nicolas Jackson',
  'Krêpin Diatta',
],
    ),
    _TeamSeedData(
      'NOR',
      'Norway',
      'assets/flags/no.svg',
      const Color.fromARGB(255, 186, 12, 47),
      const Color.fromARGB(255, 0, 32, 91),
      const [
  'Ørjan Nyland',
  'Julian Ryerson',
  'Leo Østigård',
  'Kristoffer Vassbakk Ajer',
  'Marcus Holmgren Pedersen',
  'David Møller Wolfe',
  'Torbjørn Heggem',
  'Morten Thorsby',
  'Martin Ødegaard',
  'Sander Berge',
  'Andreas Schjelderup',
  'Patrick Berg',
  'Erling Haaland',
  'Alexander Sørloth',
  'Aron Dønnum',
  'Jørgen Strand Larsen',
  'Antonio Nusa',
  'Oscar Bobb',
],
    ),
    _TeamSeedData(
      'IRQ',
      'Iraq',
      'assets/flags/iq.svg',
      const Color.fromARGB(255, 205, 33, 42),
      const Color(0xFFFFFFFF),
      const [
  'Jalal Hassan',
  'Rebin Sulaka',
  'Hussein Ali',
  'Akam Hashem',
  'Merchas Doski',
  'Zaid Tahseen',
  'Manaf Younis',
  'Zidane Iqbal',
  'Amir Al-Ammari',
  'Ibrahim Bayesh',
  'Ali Jasim',
  'Youssef Amyn',
  'Amar Sher',
  'Maro Faraj',
  'Osama Rashid',
  'Ali Al-Hamadi',
  'Aymen Hussein',
  'Mohannad Ali',
],
    ),
    _TeamSeedData(
      'ARG',
      'Argentina',
      'assets/flags/ar.svg',
      const Color(0xFF74ACDF),
      const Color(0xFFFFFFFF),
      const [
  'Emiliano Martínez',
  'Nahuel Molina',
  'Cristian Romero',
  'Nicolás Otamendi',
  'Nicolás Tagliafico',
  'Leonardo Balerdi',
  'Enzo Fernández',
  'Alexis Mac Allister',
  'Rodrigo De Paul',
  'Exequiel Palacios',
  'Leandro Paredes',
  'Nico Paz',
  'Franco Mastantuono',
  'Nico González',
  'Lionel Messi',
  'Lautaro Martínez',
  'Julián Álvarez',
  'Giuliano Simeone',
],
    ),
    _TeamSeedData(
      'AUT',
      'Austria',
      'assets/flags/at.svg',
      const Color.fromARGB(255, 239, 51, 63),
      const Color(0xFFFFFFFF),
      const [
  'Alexander Schlager',
  'Patrick Pentz',
  'David Alaba',
  'Kevin Danso',
  'Philipp Lienhart',
  'Stefan Posch',
  'Phillip Mwene',
  'Alexander Prass',
  'Xaver Schlager',
  'Marcel Sabitzer',
  'Konrad Laimer',
  'Florian Grillitsch',
  'Nicolas Seiwald',
  'Romano Schmid',
  'Patrick Wimmer',
  'Christoph Baumgartner',
  'Michael Gregoritsch',
  'Marko Arnautović',
      ],
    ),
    _TeamSeedData(
      'ALG',
      'Algeria',
      'assets/flags/dz.svg',
      const Color.fromARGB(255, 0, 102, 51),
      const Color.fromARGB(255, 210, 16, 52),
      const [
  'Alexis Guendouz',
  'Ramy Bensebaini',
  'Youcef Atal',
  'Rayan Aït-Nouri',
  'Mohamed Amine Tougai',
  'Aïssa Mandi',
  'Ismaël Bennacer',
  'Houssem Aouar',
  'Hicham Boudaoui',
  'Ramiz Zerrouki',
  'Nabil Bentaleb',
  'Farès Chaïbi',
  'Riyad Mahrez',
  'Saïd Benrahma',
  'Anis Hadj Moussa',
  'Amine Gouiri',
  'Baghdad Bounedjah',
  'Mohamed Amoura',
],
    ),
    _TeamSeedData(
      'JOR',
      'Jordan',
      'assets/flags/jo.svg',
      const Color.fromARGB(255, 206, 17, 39),
      const Color.fromARGB(255, 0, 122, 61),
      const [
  'Yazeed Abulaila',
  'Ihsan Haddad',
  'Mohammad Abu Hashish',
  'Yazan Al-Arab',
  'Abdallah Nasib',
  'Saleem Obaid',
  'Mohammad Abualnadi',
  'Ibrahim Saadeh',
  'Nizar Al-Rashdan',
  'Noor Al-Rawabdeh',
  'Mohannad Abu Taha',
  'Amer Jamous',
  'Mousa Al-Taamari',
  'Yazan Al-Naimat',
  'Mahmoud Al-Mardi',
  'Ali Olwan',
  'Mohammad Abu Zrayq',
  'Ibrahim Sabra',
],
    ),
    _TeamSeedData(
      'POR',
      'Portugal',
      'assets/flags/pt.svg',
      const Color.fromARGB(255, 4, 106, 57),
      const Color.fromARGB(255, 218, 41, 28),
      const [
  'Diogo Costa',
  'José Sá',
  'Rúben Dias',
  'João Cancelo',
  'Diogo Dalot',
  'Nuno Mendes',
  'Gonçalo Inácio',
  'Bernardo Silva',
  'Bruno Fernandes',
  'Rúben Neves',
  'Vitinha',
  'João Neves',
  'Cristiano Ronaldo',
  'Francisco Trincão',
  'João Félix',
  'Gonçalo Ramos',
  'Pedro Neto',
  'Rafael Leão',
],
    ),
    _TeamSeedData(
      'COL',
      'Colombia',
      'assets/flags/co.svg',
      const Color.fromARGB(255, 255, 204, 0),
      const Color.fromARGB(255, 0, 47, 135),
      const [
  'Camilo Vargas',
  'David Ospina',
  'Dávinson Sánchez',
  'Yerry Mina',
  'Daniel Muñoz',
  'Johan Mojica',
  'Jhon Lucumí',
  'Santiago Arias',
  'Jefferson Lerma',
  'Kevin Castaño',
  'Richard Ríos',
  'James Rodríguez',
  'Juan Fernando Quintero',
  'Jorge Carrascal',
  'Jhon Arias',
  'Jhon Córdoba',
  'Luis Suárez',
  'Luis Díaz',
],
    ),
    _TeamSeedData(
      'UZB',
      'Uzbekistan',
      'assets/flags/uz.svg',
      const Color.fromARGB(255, 0, 113, 206),
      const Color.fromARGB(255, 67, 176, 42),
      const [
  'Utkir Yusupov',
  'Farrukh Sayfiev',
  'Sherzod Nasrullaev',
  'Umar Eshmuradov',
  'Husniddin Aliqulov',
  'Rustam Ashurmatov',
  'Khojiakbar Alijonov',
  'Abdukodir Khusanov',
  'Odiljon Hamrobekov',
  'Otabek Shukurov',
  'Jamshid Iskanderov',
  'Azizbek Turgunboev',
  'Khojimat Erkinov',
  'Eldor Shomurodov',
  'Oston Urunov',
  'Jaloliddin Masharipov',
  'Igor Sergeev',
  'Abbosbek Fayzullaev',
],
    ),
    _TeamSeedData(
      'COD',
      'DR Congo',
      'assets/flags/cd.svg',
      const Color.fromARGB(255, 0, 127, 255),
      const Color.fromARGB(255, 247, 214, 24),
      const [
  'Lionel Mpasi',
  'Aaron Wan-Bissaka',
  'Axel Tuanzebe',
  'Arthur Masuaku',
  'Chancel Mbemba',
  'Joris Kayembe',
  'Charles Pickel',
  'Ngal’ayel Mukau',
  'Edo Kayembe',
  'Samuel Moutoussamy',
  'Noah Sadiki',
  'Théo Bongonda',
  'Meschack Elia',
  'Yoane Wissa',
  'Brian Cipenga',
  'Fiston Mayele',
  'Cédric Bakambu',
  'Nathanaël Mbuku',
],
    ),
    _TeamSeedData(
      'ENG',
      'England',
      'assets/flags/gb-eng.svg',
      const Color.fromARGB(255, 206, 17, 36),
      const Color(0xFFFFFFFF),
      const [
  'Jordan Pickford',
  'John Stones',
  'Marc Guéhi',
  'Ezri Konsa',
  'Trent Alexander-Arnold',
  'Reece James',
  'Dan Burn',
  'Jordan Henderson',
  'Declan Rice',
  'Jude Bellingham',
  'Cole Palmer',
  'Morgan Rogers',
  'Anthony Gordon',
  'Phil Foden',
  'Bukayo Saka',
  'Harry Kane',
  'Marcus Rashford',
  'Ollie Watkins',
],
    ),
    _TeamSeedData(
      'CRO',
      'Croatia',
      'assets/flags/hr.svg',
      const Color.fromARGB(255, 255, 0, 0),
      const Color.fromARGB(255, 1, 32, 105),
      const [
  'Dominik Livaković',
  'Duje Ćaleta-Car',
  'Joško Gvardiol',
  'Josip Stanišić',
  'Luka Vušković',
  'Joško Šutalo',
  'Kristijan Jakić',
  'Luka Modrić',
  'Mateo Kovačić',
  'Martin Baturina',
  'Lovro Majer',
  'Mario Pašalić',
  'Petar Sučić',
  'Ivan Perišić',
  'Marco Pašalić',
  'Ante Budimir',
  'Andrej Kramarić',
  'Franjo Ivanović',
],
    ),
    _TeamSeedData(
      'PAN',
      'Panama',
      'assets/flags/pa.svg',
      const Color.fromARGB(255, 218, 18, 25),
      const Color.fromARGB(255, 7, 35, 87),
      const [
  'Orlando Mosquera',
  'Luis Mejía',
  'Fidel Escobar',
  'Andrés Andrade',
  'Michael Amir Murillo',
  'Éric Davis',
  'José Córdoba',
  'César Blackman',
  'Cristian Martínez',
  'Aníbal Godoy',
  'Adalberto Carrasquilla',
  'Édgar Bárcenas',
  'Carlos Harvey',
  'Ismael Díaz',
  'José Fajardo',
  'Cecilio Waterman',
  'José Luis Rodríguez',
  'Alberto Quintero',
],
    ),
    _TeamSeedData(
      'GHA',
      'Ghana',
      'assets/flags/gh.svg',
      const Color.fromARGB(255, 239, 51, 63),
      const Color.fromARGB(255, 255, 208, 0),
      const [
  'Lawrence Ati-Zigi',
  'Tariq Lamptey',
  'Mohammed Salisu',
  'Alidu Seidu',
  'Alexander Djiku',
  'Gideon Mensah',
  'Caleb Ekuban',
  'Abdul Issahaku Fatawu',
  'Thomas Partey',
  'Salis Abdul Samed',
  'Kamaldeen Sulemana',
  'Mohammed Kudus',
  'Iñaki Williams',
  'Jordan Ayew',
  'André Ayew',
  'Joseph Paintsil',
  'Osman Bukari',
  'Antoine Semenyo',
],
    ),
  ];
}

class _TeamSeedData {
  const _TeamSeedData(
    this.id,
    this.name,
    this.flagAssetPath,
    this.primaryColor,
    this.secondaryColor,
    this.playerNames,
  );
  final String id;
  final String name;
  final String flagAssetPath;
  final Color primaryColor;
  final Color secondaryColor;
  final List<String> playerNames;
}
