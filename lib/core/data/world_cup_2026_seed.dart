// ignore_for_file: unused_local_variable

import 'dart:ui';

import '../models/group_model.dart';
import '../models/sticker_model.dart';
import '../models/team_model.dart';
import 'sticker_identifier_aliases.dart';

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
  static Map<String, StickerModel>? _stickerByNormalizedIdentifier;

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
    final g = getStickerById(stickerId)?.globalNumber;
    if (g != null) return g.toString();
    return stickerId;
  }

  /// Título en tarjetas (repetidas / faltantes): nombre del jugador en PL-*; si no, el número global.
  static String stickerCaptionTitle(String stickerId) {
    if (stickerId.contains('-PL-')) {
      final n = getStickerById(stickerId)?.playerName;
      if (n != null && n.isNotEmpty) return n;
    }
    return stickerNumberLabel(stickerId);
  }

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

  static TeamModel _teamFromData(_TeamSeedData data, String groupId) {
    final primaryColor = data.primaryColor;
    final secondaryColor = data.secondaryColor;
    final stickers = <StickerModel>[];
    final prefix = data.id;
    final startGlobal = _globalCounter + 1;
    _globalCounter += stickersPerTeam;
    stickers.add(
      StickerModel(
        id: '$prefix-B-01',
        code: '$prefix-B-01',
        type: StickerType.badge,
        teamId: data.id,
        globalNumber: startGlobal,
      ),
    );
    stickers.add(
      StickerModel(
        id: '$prefix-P-01',
        code: '$prefix-P-01',
        type: StickerType.team_photo,
        teamId: data.id,
        globalNumber: startGlobal + 1,
      ),
    );
    for (var i = 1; i <= 18; i++) {
      final code = '$prefix-PL-${i.toString().padLeft(2, '0')}';
      stickers.add(
        StickerModel(
          id: code,
          code: code,
          type: StickerType.player,
          playerName: data.playerNames[i - 1],
          teamId: data.id,
          globalNumber: startGlobal + 1 + i,
        ),
      );
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
      if (sticker.globalNumber != null) {
        variants.add(sticker.globalNumber.toString());
      }
      for (final variant in variants) {
        if (variant.isEmpty) continue;
        map.putIfAbsent(variant, () => sticker);
      }
    }
    return map;
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
        'Guillermo Ochoa',
        'Jesús Gallardo',
        'César Montes',
        'Israel Reyes',
        'Jorge Sánchez',
        'Johan Vásquez',
        'Gerardo Arteaga',
        'Edson Álvarez',
        'Luis Chávez',
        'Marcel Ruiz',
        'Orbelín Pineda',
        'Erik Lira',
        'Roberto Alvarado',
        'Santiago Giménez',
        'Hirving Lozano',
        'Alexis Vega',
        'Julián Quiñones',
      ],
    ),
    _TeamSeedData(
      'KOR',
      'South Korea',
      'assets/flags/kr.svg',
      const Color(0xFF000000),
      const Color(0xFFFFFFFF),
      const [
        'Kim Seung-gyu',
        'Jo Hyeon-woo',
        'Kim Min-jae',
        'Kim Young-gwon',
        'Lee Han-beom',
        'Seol Young-woo',
        'Lee Ki-je',
        'Hwang Mun-ki',
        'Hwang In-beom',
        'Lee Kang-in',
        'Jung Woo-young',
        'Baek Seung-ho',
        'Lee Jae-sung',
        'Hong Hyun-seok',
        'Son Heung-min',
        'Oh Hyeon-gyu',
        'Hwang Hee-chan',
        'Cho Gue-sung',
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
        'Veli Mothwa',
        'Siyanda Xulu',
        'Khuliso Mudau',
        'Aubrey Modiba',
        'Mothobi Mvala',
        'Maphosa Modiba',
        'Grant Kekana',
        'Teboho Mokoena',
        'Sphephelo Sithole',
        'Thabang Monare',
        'Jayden Adams',
        'Njabulo Blom',
        'Oswin Andries',
        'Lyle Foster',
        'Evidence Makgopa',
        'Thapelo Maseko',
        'Mihlali Mayambela',
      ],
    ),
    _TeamSeedData(
      'CZE',
      'Czech Republic',
      'assets/flags/cz.svg',
      const Color.fromARGB(255, 17, 69, 126),
      const Color.fromARGB(255, 215, 20, 26),
      const [
        'Jindřich Staněk',
        'Tomáš Vaclík',
        'Tomáš Holeš',
        'David Zima',
        'David Jurásek',
        'Jan Bořil',
        'Václav Jemelka',
        'Robin Hranáč',
        'Vladimír Coufal',
        'Ladislav Krejčí',
        'Antonín Barák',
        'Jakub Jankto',
        'Ondřej Lingr',
        'Tomáš Souček',
        'Patrik Schick',
        'Tomáš Chorý',
        'Jan Kuchta',
        'Adam Hložek',
      ],
    ),
    _TeamSeedData(
      'CAN',
      'Canada',
      'assets/flags/ca.svg',
      const Color.fromARGB(255, 216, 6, 34),
      const Color(0xFFFFFFFF),
      const [
        'Milan Borjan',
        'Dayne St. Clair',
        'Kamal Miller',
        'Derek Cornelius',
        'Alistair Johnston',
        'Richie Laryea',
        'Alphonso Davies',
        'Moïse Bombito',
        'Stephen Eustáquio',
        'Ismaël Koné',
        'Jonathan Osorio',
        'Mark-Anthony Kaye',
        'Samuel Piette',
        'Liam Fraser',
        'Jonathan David',
        'Cyle Larin',
        'Tajon Buchanan',
        'Jacen Russell-Rowe',
      ],
    ),
    _TeamSeedData(
      'SUI',
      'Switzerland',
      'assets/flags/ch.svg',
      const Color.fromARGB(255, 218, 41, 28),
      const Color(0xFFFFFFFF),
      const [
        'Yann Sommer',
        'Gregor Kobel',
        'Manuel Akanji',
        'Nico Elvedi',
        'Ricardo Rodríguez',
        'Silvan Widmer',
        'Fabian Schär',
        'Edmilson Fernandes',
        'Remo Freuler',
        'Granit Xhaka',
        'Michel Aebischer',
        'Denis Zakaria',
        'Ruben Vargas',
        'Vincent Sierro',
        'Dan Ndoye',
        'Breel Embolo',
        'Kwadwo Duah',
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
        'Saad Al Sheeb',
        'Meshaal Barsham',
        'Pedro Miguel',
        'Bassam Al Rawi',
        'Tarek Salman',
        'Homam Ahmed',
        'Almahdi Ali',
        'Abdelkarim Hassan',
        'Hassan Al Haydos',
        'Akram Afif',
        'Mohammed Waad',
        'Ali Asad',
        'Karim Boudiaf',
        'Assim Madibo',
        'Almoez Ali',
        'Ahmed Alaaeldin',
        'Yusuf Abdurisag',
        'Ismaeel Mohammad',
      ],
    ),
    _TeamSeedData(
      'BIH',
      'Bosnia and Herzegovina',
      'assets/flags/ba.svg',
      const Color.fromARGB(255, 0, 35, 149),
      const Color.fromARGB(255, 254, 203, 0),
      const [
        'Ibrahim Šehić',
        'Nikola Vasilj',
        'Sead Kolašinac',
        'Ermin Bičakčić',
        'Amar Dedić',
        'Adrian Leon Barišić',
        'Benjamin Tahirović',
        'Nikola Katić',
        'Miralem Pjanić',
        'Gojko Cimirot',
        'Denis Huseinbašić',
        'Dino Peranović',
        'Haris Hajradinović',
        'Amar Ćatić',
        'Edin Džeko',
        'Ermedin Demirović',
        'Smail Prevljak',
        'Dženis Burnić',
      ],
    ),
    _TeamSeedData(
      'BRA',
      'Brazil',
      'assets/flags/br.svg',
      const Color(0xFF009C3B),
      const Color(0xFFFFDF00),
      const [
        'Alisson Becker',
        'Ederson Moraes',
        'Danilo Luiz',
        'Marquinhos',
        'Gabriel Magalhães',
        'Lucas Beraldo',
        'Guilherme Arana',
        'Wendell Nascimento',
        'Bruno Guimarães',
        'Carlos Casemiro',
        'Lucas Paquetá',
        'André Santos',
        'Raphinha Dias',
        'Gerson Santos',
        'Vinícius Júnior',
        'Rodrigo Silva',
        'Gabriel Jesus',
        'Evanilson Barros',
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
        'Munir Mohamedi',
        'Achraf Hakimi',
        'Nayef Aguerd',
        'Romain Saïss',
        'Noussair Mazraoui',
        'Chadi Riad',
        'Yunis Abdelhamid',
        'Sofyan Amrabat',
        'Azzedine Ounahi',
        'Amine Harit',
        'Salim Amallah',
        'Ismaël Saibari',
        'Bilal El Khannous',
        'Youssef En-Nesyri',
        'Sofiane Boufal',
        'Abde Ezzalzouli',
        'Munir El Haddadi',
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
        'Liam Kelly',
        'Grant Hanley',
        'Andrew Robertson',
        'John Souttar',
        'Scott McKenna',
        'Aaron Hickey',
        'Nathan Patterson',
        'Scott McTominay',
        'John McGinn',
        'Callum McGregor',
        'Billy Gilmour',
        'Lewis Ferguson',
        'Kenny McLean',
        'Che Adams',
        'Lawrence Shankland',
        'Ryan Christie',
        'Ben Doak',
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
        'Alexandre Pierre',
        'Carlens Arcus',
        'Ricardo Adé',
        'Garven Metusala',
        'Martin Expérience',
        'Duke Lacroix',
        'Jean-Kévin Duverne',
        'Carl-Fred Sainte',
        'Leverton Pierre',
        'Mikaël Cantave',
        'Danley Jean Jacques',
        'Belmar Joseph',
        'Christopher Attys',
        'Duckens Nazon',
        'Mondy Prunier',
        'Carnejy Antoine',
        'Steeven Saba',
      ],
    ),
    _TeamSeedData(
      'USA',
      'USA',
      'assets/flags/us.svg',
      const Color.fromARGB(255, 179, 25, 66),
      const Color.fromARGB(255, 10, 49, 97),
      const [
        'Matt Turner',
        'Ethan Horvath',
        'Sergiño Dest',
        'Antonee Robinson',
        'Tim Ream',
        'Chris Richards',
        'Mark McKenzie',
        'Miles Robinson',
        'Tyler Adams',
        'Weston McKennie',
        'Yunus Musah',
        'Giovanni Reyna',
        'Malik Tillman',
        'Brenden Aaronson',
        'Christian Pulisic',
        'Folarin Balogun',
        'Haji Wright',
        'Ricardo Pepi',
      ],
    ),
    _TeamSeedData(
      'PAR',
      'Paraguay',
      'assets/flags/py.svg',
      const Color.fromARGB(255, 213, 42, 30),
      const Color.fromARGB(255, 0, 56, 168),
      const [
        'Carlos Coronel',
        'Antony Silva',
        'Gustavo Gómez',
        'Omar Alderete',
        'Júnior Alonso',
        'Matías Rojas',
        'Blas Riveros',
        'Fabián Balbuena',
        'Miguel Almirón',
        'Diego Gómez',
        'Mathías Villasanti',
        'Richard Sánchez',
        'Andrés Cubas',
        'Cristhian Paredes',
        'Antonio Sanabria',
        'Gabriel Avalos',
        'Ángel Romero',
        'Óscar Romero',
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
        'Kye Rowles',
        'Aziz Behich',
        'Jordan Bos',
        'Nathaniel Atkinson',
        'Thomas Deng',
        'Jackson Irvine',
        'Aiden O\'Neill',
        'Connor Metcalfe',
        'Keanu Baccus',
        'Patrick Yazbek',
        'Riley McGree',
        'Mitchell Duke',
        'Sam Silvera',
        'Brandon Borrello',
        'John Iredale',
      ],
    ),
    _TeamSeedData(
      'TUR',
      'Turkey',
      'assets/flags/tr.svg',
      const Color.fromARGB(255, 227, 10, 23),
      const Color(0xFFFFFFFF),
      const [
        'Mert Günok',
        'Uğurcan Çakır',
        'Merih Demiral',
        'Çağlar Söyüncü',
        'Ferdi Kadıoğlu',
        'Zeki Çelik',
        'Abdülkerim Bardakcı',
        'Samet Akaydın',
        'Hakan Çalhanoğlu',
        'Orkun Kökçü',
        'İsmail Yüksek',
        'Kaan Ayhan',
        'Salih Özcan',
        'İrfan Kahveci',
        'Kerem Aktürkoğlu',
        'Barış Alper Yılmaz',
        'Kenan Yıldız',
        'Cenk Tosun',
      ],
    ),
    _TeamSeedData(
      'GER',
      'Germany',
      'assets/flags/de.svg',
      const Color.fromARGB(255, 0, 0, 0),
      const Color.fromARGB(255, 255, 204, 0),
      const [
        'Manuel Neuer',
        'Marc-André ter Stegen',
        'Benjamin Henrichs',
        'Antonio Rüdiger',
        'Jonathan Tah',
        'David Raum',
        'Nico Schlotterbeck',
        'Waldemar Anton',
        'Joshua Kimmich',
        'Aleksandar Pavlović',
        'Robert Andrich',
        'Florian Wirtz',
        'Jamal Musiala',
        'Pascal Groß',
        'Serge Gnabry',
        'Kai Havertz',
        'Nicklas Füllkrug',
        'Deniz Undav',
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
        'Moisés Ramírez',
        'Piero Hincapié',
        'Félix Torres',
        'William Pacho',
        'Ángelo Preciado',
        'Pervis Estupiñán',
        'Diego Palacios',
        'Moisés Caicedo',
        'José Cifuentes',
        'Kendry Páez',
        'Alan Franco',
        'Joao Ortiz',
        'Carlos Gruezo',
        'Enner Valencia',
        'Jerónimo Rodríguez',
        'Kevin Rodríguez',
        'Janner Corozo',
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
        'Badra Ali Sangaré',
        'Wilfried Singo',
        'Evan Ndicka',
        'Odilon Kossounou',
        'Ousmane Diomande',
        'Willy Boly',
        'Ghislain Konan',
        'Franck Kessié',
        'Ibrahim Sangaré',
        'Jean Seri',
        'Max Gradel',
        'Nicolas Pépé',
        'Lazare Amani',
        'Sébastien Haller',
        'Simon Adingra',
        'Jonathan Bamba',
        'Karim Konaté',
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
        'Tyrick Bodak',
        'Sherel Floranus',
        'Roshon van Eijma',
        'Juriën Gaari',
        'Leandro Bacuna',
        'Shurandy Sambo',
        'Livano Comenencia',
        'Godfried Roemeratoe',
        'Juninho Bacuna',
        'Tahith Chong',
        'Gervane Kastaneer',
        'Kenji Gorré',
        'Jarchinio Antonia',
        'Rangelo Janga',
        'Jürgen Locadia',
        'Gevon Janga',
        'Elson Hooi',
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
        'Justin Bijlow',
        'Virgil van Dijk',
        'Nathan Aké',
        'Denzel Dumfries',
        'Jeremie Frimpong',
        'Matthijs de Ligt',
        'Stefan de Vrij',
        'Frenkie de Jong',
        'Xavi Simons',
        'Tijjani Reijnders',
        'Cody Gakpo',
        'Teun Koopmeiners',
        'Joey Veerman',
        'Memphis Depay',
        'Wout Weghorst',
        'Brian Brobbey',
        'Donyell Malen',
      ],
    ),
    _TeamSeedData(
      'JPN',
      'Japan',
      'assets/flags/jp.svg',
      const Color.fromARGB(255, 188, 0, 44),
      const Color.fromARGB(255, 26, 32, 75),
      const [
        'Shuichi Gonda',
        'Zion Suzuki',
        'Takehiro Tomiyasu',
        'Ko Itakura',
        'Ayumu Seko',
        'Yukinari Sugawara',
        'Hiroki Ito',
        'Koki Machida',
        'Wataru Endo',
        'Hidemasa Morita',
        'Kaoru Mitoma',
        'Junya Ito',
        'Ritsu Doan',
        'Reo Hatate',
        'Takefusa Kubo',
        'Ayase Ueda',
        'Daizen Maeda',
        'Daichi Kamada',
      ],
    ),
    _TeamSeedData(
      'TUN',
      'Tunisia',
      'assets/flags/tn.svg',
      const Color.fromARGB(255, 200, 16, 47),
      const Color(0xFFFFFFFF),
      const [
        'Aymen Dahmen',
        'Farouk Ben Mustapha',
        'Dylan Bronn',
        'Yassine Meriah',
        'Mohamed Ali Ben Romdhane',
        'Mohamed Dräger',
        'Ali Maâloul',
        'Bilel Ifa',
        'Aïssa Laïdouni',
        'Anis Ben Slimane',
        'Hannibal Mejbri',
        'Ellyes Skhiri',
        'Ghailene Chaalali',
        'Firas Ben Larbi',
        'Youssef Msakni',
        'Seifeddine Jaziri',
        'Elias Achouri',
        'Taha Khenissi',
      ],
    ),
    _TeamSeedData(
      'SWE',
      'Sweden',
      'assets/flags/se.svg',
      const Color.fromARGB(255, 0, 106, 167),
      const Color.fromARGB(255, 254, 204, 0),
      const [
        'Robin Olsen',
        'Viktor Johansson',
        'Victor Lindelöf',
        'Ludwig Augustinsson',
        'Isak Hien',
        'Gabriel Gudmundsson',
        'Jens Cajuste',
        'Gustaf Lagerbielke',
        'Emil Forsberg',
        'Dejan Kulusevski',
        'Mattias Svanberg',
        'Kristoffer Olsson',
        'Sebastian Larsson',
        'Hugo Larsson',
        'Alexander Isak',
        'Viktor Gyökeres',
        'Anthony Elanga',
        'Jordan Larsson',
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
        'Koen Casteels',
        'Timothy Castagne',
        'Arthur Theate',
        'Jan Vertonghen',
        'Wout Faes',
        'Thomas Meunier',
        'Zeno Debast',
        'Kevin De Bruyne',
        'Youri Tielemans',
        'Amadou Onana',
        'Arthur Vermeeren',
        'Hans Vanaken',
        'Axel Witsel',
        'Romelu Lukaku',
        'Jeremy Doku',
        'Lois Openda',
        'Leandro Trossard',
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
        'Hossein Hosseini',
        'Milad Mohammadi',
        'Shouja Khalilzadeh',
        'Morteza Pouraliganji',
        'Hossein Kanaanizadegan',
        'Sadegh Moharrami',
        'Saleh Hardani',
        'Alireza Jahanbakhsh',
        'Saman Ghoddos',
        'Mehdi Torabi',
        'Mehdi Ghayedi',
        'Omid Ebrahimi',
        'Ahmad Nourollahi',
        'Mehdi Taremi',
        'Sardar Azmoun',
        'Karim Ansarifard',
        'Allahyar Sayyadmanesh',
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
        'Mohamed Abou Gabal',
        'Ahmed Hegazi',
        'Mohamed Abdelmonem',
        'Mohamed Hany',
        'Mohamed Hamdy',
        'Ali Gabr',
        'Omar Gaber',
        'Mohamed Elneny',
        'Hamdy Fathy',
        'Emam Ashour',
        'Omar Marmoush',
        'Trézéguet',
        'Ahmed Sayed Zizo',
        'Mohamed Salah',
        'Mostafa Mohamed',
        'Mohamed Sherif',
        'Ibrahim Adel',
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
        'Oliver Sail',
        'Nando Pijnaker',
        'Tim Payne',
        'Tommy Smith',
        'Michael Boxall',
        'Francis De Vries',
        'Callum McCowatt',
        'Joe Bell',
        'Marko Stamenic',
        'Clayton Lewis',
        'Sarpreet Singh',
        'Matthew Garbett',
        'Alex Greive',
        'Chris Wood',
        'Dane Ingham',
        'Logan Rogerson',
        'Elijah Just',
      ],
    ),
    _TeamSeedData(
      'ESP',
      'Spain',
      'assets/flags/es.svg',
      const Color.fromARGB(255, 170, 21, 26),
      const Color.fromARGB(255, 241, 193, 0),
      const [
        'David Raya',
        'Unai Simón',
        'Aymeric Laporte',
        'Dani Carvajal',
        'Robin Le Normand',
        'Marc Cucurella',
        'Jesús Navas',
        'Pau Cubarsí',
        'Rodri Hernández',
        'Pedri González',
        'Fabián Ruiz',
        'Dani Olmo',
        'Alejandro Garnacho',
        'Álex Baena',
        'Álvaro Morata',
        'Lamine Yamal',
        'Nico Williams',
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
        'Franco Israel',
        'Ronald Araújo',
        'José Giménez',
        'Sebastián Coates',
        'Matías Viña',
        'Guillermo Varela',
        'Martín Cáceres',
        'Federico Valverde',
        'Rodrigo Bentancur',
        'Rodrigo De Paul',
        'Manuel Ugarte',
        'Nicolás de la Cruz',
        'Giorgian de Arrascaeta',
        'Darwin Núñez',
        'Luis Suárez',
        'Agustín Canobbio',
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
        'Mohammed Al Owais',
        'Mohamed Al Yami',
        'Yasser Al Shahrani',
        'Ali Al Bulaihi',
        'Hassan Tambakti',
        'Saud Abdulhamid',
        'Abdullah Al Hamdan',
        'Ahmed Hassan',
        'Salem Al Dawsari',
        'Mohamed Kanno',
        'Abdulelah Al Malki',
        'Nasser Al Dawsari',
        'Sami Al Najei',
        'Ali Al Hassan',
        'Feras Al Brikan',
        'Saleh Al Shehri',
        'Abdullah Radif',
        'Firas Al Buraikan',
      ],
    ),
    _TeamSeedData(
      'CPV',
      'Cape Verde',
      'assets/flags/cv.svg',
      const Color.fromARGB(255, 0, 60, 165),
      const Color.fromARGB(255, 239, 51, 63),
      const [
        'Vozinha Dias',
        'Márcio Rosa',
        'Stopira Borges',
        'Roberto Lopes',
        'Steven Fortès',
        'Diney Borges',
        'Dylan Tavares',
        'Keny Rocha',
        'Jamiro Monteiro',
        'Ryan Mendes',
        'Kevin Lenini',
        'Deroy Duarte',
        'Kenny Santos',
        'João Paulo',
        'Garry Rodrigues',
        'Júlio Tavares',
        'Willy Semedo',
        'Hélder Tavares',
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
        'Lucas Chevalier',
        'Jules Koundé',
        'Dayot Upamecano',
        'William Saliba',
        'Lucas Hernández',
        'Theo Hernández',
        'Benjamin Pavard',
        'Aurélien Tchouaméni',
        'Eduardo Camavinga',
        'Adrien Rabiot',
        'Warren Zaïre-Emery',
        'Youssouf Fofana',
        'Manu Koné',
        'Kylian Mbappé',
        'Olivier Giroud',
        'Ousmane Dembélé',
        'Bradley Barcola',
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
        'Mory Diaw',
        'Kalidou Koulibaly',
        'Abdou Diallo',
        'Bouna Sarr',
        'Fodé Ballo-Touré',
        'Abdoulaye Seck',
        'Youssouf Sabaly',
        'Idrissa Gueye',
        'Cheikhou Kouyaté',
        'Pape Matar Sarr',
        'Nampalys Mendy',
        'Lamine Camara',
        'Pathé Ciss',
        'Sadio Mané',
        'Ismaïla Sarr',
        'Boulaye Dia',
        'Nic Jackson',
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
        'Egil Selvik',
        'Kristoffer Ajer',
        'Leo Østigård',
        'Julian Ryerson',
        'Birger Meling',
        'Andreas Hanche-Olsen',
        'David Wolfe',
        'Martin Ødegaard',
        'Sander Berge',
        'Morten Thorsby',
        'Kristian Thorstvedt',
        'Fredrik Aursnes',
        'Patrick Berg',
        'Erling Haaland',
        'Alexander Sørloth',
        'Jørgen Larsen',
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
        'Ameer Ali',
        'Ahmed Ibrahim',
        'Ali Adnan',
        'Mustafa Mohammed',
        'Saad Natiq',
        'Rebin Sulaka',
        'Ahmed Yasin',
        'Ali Haim',
        'Amjed Attwan',
        'Bashar Resan',
        'Ibrahim Bayesh',
        'Mohammed Qasim',
        'Mohammed Abbood',
        'Aymen Hussein',
        'Mohanad Ali',
        'Alaa Abbas',
        'Ali Jasim',
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
        'Walter Benítez',
        'Nahuel Molina',
        'Cristian Romero',
        'Nicolás Otamendi',
        'Nicolás Tagliafico',
        'Marcos Acuña',
        'Germán Pezzella',
        'Enzo Fernández',
        'Rodrigo De Paul',
        'Alexis Mac Allister',
        'Leandro Paredes',
        'Giovani Lo Celso',
        'Thiago Almada',
        'Lionel Messi',
        'Julián Álvarez',
        'Lautaro Martínez',
        'Ángel Di María',
      ],
    ),
    _TeamSeedData(
      'AUT',
      'Austria',
      'assets/flags/at.svg',
      const Color.fromARGB(255, 239, 51, 63),
      const Color(0xFFFFFFFF),
      const [
        'Patrick Pentz',
        'Alexander Schlager',
        'David Alaba',
        'Maximilian Wöber',
        'Kevin Danso',
        'Stefan Posch',
        'Philipp Lienhart',
        'Gernot Trauner',
        'Conor Laimer',
        'Marcel Sabitzer',
        'Florian Grillitsch',
        'Xaver Schlager',
        'Florian Kainz',
        'Nicolas Seiwald',
        'Marko Arnautović',
        'Michael Gregoritsch',
        'Maximilian Entrup',
        'Sasa Kalajdzic',
      ],
    ),
    _TeamSeedData(
      'ALG',
      'Algeria',
      'assets/flags/dz.svg',
      const Color.fromARGB(255, 0, 102, 51),
      const Color.fromARGB(255, 210, 16, 52),
      const [
        'Anthony Mandrea',
        'Raïs Mbolhi',
        'Youcef Atal',
        'Ramy Bensebaini',
        'Aïssa Mandi',
        'Mohamed Tougai',
        'Abdelkader Bedrane',
        'Jaouen Hadjam',
        'Ismaël Bennacer',
        'Nabil Bentaleb',
        'Houssem Aouar',
        'Hicham Boudaoui',
        'Adem Zorgane',
        'Sofiane Feghouli',
        'Riyad Mahrez',
        'Baghdad Bounedjah',
        'Amine Gouiri',
        'Amoura Mohamed',
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
        'Youssef Hassan',
        'Yazan Al-Arab',
        'Bader Al-Sulaiman',
        'Mahmoud Mardi',
        'Anas Bani Yaseen',
        'Ibrahim Al-Zaatreh',
        'Mohammed Zraiq',
        'Noor Al-Rawabdeh',
        'Musa Al-Taamari',
        'Rajaei Ayesh',
        'Ihsan Haddad',
        'Anas Al-Awadat',
        'Nizar Al-Rashdan',
        'Mahmoud Shawkat',
        'Yazan Al-Naimat',
        'Ali Olwan',
        'Hamza Al-Dardour',
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
        'João Cancelo',
        'Rúben Dias',
        'Nuno Mendes',
        'Kepler Lima',
        'Gonçalo Inácio',
        'Danilo Pereira',
        'Bruno Fernandes',
        'Bernardo Silva',
        'Vitinha Ferreira',
        'João Palhinha',
        'João Neves',
        'Otávio Monteiro',
        'Cristiano Ronaldo',
        'Rafael Leão',
        'João Félix',
        'Gonçalo Ramos',
      ],
    ),
    _TeamSeedData(
      'COL',
      'Colombia',
      'assets/flags/co.svg',
      const Color.fromARGB(255, 255, 204, 0),
      const Color.fromARGB(255, 0, 47, 135),
      const [
        'David Ospina',
        'Álvaro Montero',
        'Yerry Mina',
        'Davinson Sánchez',
        'Daniel Muñoz',
        'Jhon Lucumí',
        'Santiago Arias',
        'Frank Fabra',
        'James Rodríguez',
        'Jefferson Lerma',
        'Jorge Carrascal',
        'Jhon Arias',
        'Richard Ríos',
        'Mateus Uribe',
        'Luis Díaz',
        'Rafael Borré',
        'Jhon Córdoba',
        'Miguel Borja',
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
        'Abduvohid Nematov',
        'Rustam Ashurmatov',
        'Farrukh Sayfiev',
        'Khojimat Erkinov',
        'Sherzod Nasrullaev',
        'Abdukodir Khusanov',
        'Umar Eshmurodov',
        'Otabek Shukurov',
        'Jamshid Iskanderov',
        'Abbosbek Fayzullaev',
        'Azizbek Turgunboev',
        'Jaloliddin Masharipov',
        'Odiljon Hamrobekov',
        'Eldor Shomurodov',
        'Igor Sergeev',
        'Bobur Ashurmatov',
        'Ozodbek Uktamov',
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
        'Baggio Siadi',
        'Chancel Mbemba',
        'Arthur Masuaku',
        'Joris Kayembe',
        'Henrik Mabuya',
        'Rocky Balanta',
        'Gédéon Kalulu',
        'Samuel Moutoussamy',
        'Gaël Kakuta',
        'Théo Bongonda',
        'Grady Diangana',
        'Charles Pickel',
        'Aaron Tshibola',
        'Cédric Bakambu',
        'Meschack Elia',
        'Yannick Bolasie',
        'Fiston Mayele',
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
        'Aaron Ramsdale',
        'Kyle Walker',
        'John Stones',
        'Harry Maguire',
        'Ezri Konsa',
        'Luke Shaw',
        'Reece James',
        'Declan Rice',
        'Jude Bellingham',
        'Phil Foden',
        'Cole Palmer',
        'Kobbie Mainoo',
        'Kalvin Phillips',
        'Harry Kane',
        'Bukayo Saka',
        'Ollie Watkins',
        'Ivan Toney',
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
        'Ivica Ivušić',
        'Joško Gvardiol',
        'Josip Juranović',
        'Dejan Lovren',
        'Domagoj Vida',
        'Borna Sosa',
        'Josip Šutalo',
        'Luka Modrić',
        'Mateo Kovačić',
        'Marcelo Brozović',
        'Mario Pašalić',
        'Nikola Vlašić',
        'Lovro Majer',
        'Andrej Kramarić',
        'Marko Livaja',
        'Ivan Perišić',
        'Bruno Petković',
      ],
    ),
    _TeamSeedData(
      'PAN',
      'Panama',
      'assets/flags/pa.svg',
      const Color.fromARGB(255, 218, 18, 25),
      const Color.fromARGB(255, 7, 35, 87),
      const [
        'Luis Mejía',
        'Orlando Mosquera',
        'Eric Davis',
        'Harold Cummings',
        'Fidel Escobar',
        'Álvaro Andrade',
        'Gilberto Hernández',
        'Michael Murillo',
        'Adalberto Carrasquilla',
        'Alberto Quintero',
        'Aníbal Godoy',
        'José Rodríguez',
        'Martín Gómez',
        'Cristian Martínez',
        'Gabriel Torres',
        'José Fajardo',
        'Ismael Díaz',
        'Rolando Blackburn',
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
        'Richard Ofori',
        'Daniel Amartey',
        'Alexander Djiku',
        'Gideon Mensah',
        'Alidu Seidu',
        'Joseph Aidoo',
        'Baba Rahman',
        'Thomas Partey',
        'Salis Abdul Samed',
        'Mohammed Kudus',
        'Elisha Owusu',
        'Kofi Kyereh',
        'Andre Ayew',
        'Jordan Ayew',
        'Inaki Williams',
        'Antoine Semenyo',
        'Ernest Nuamah',
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
