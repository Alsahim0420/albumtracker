/// Ruta a los escudos por código de equipo (3 letras: MEX, ALG, etc.).
/// Código extraído del stickerId (ej. MEX-B-01 → MEX).
const Map<String, String> _teamCodeToShield = {
  'ALG': 'assets/shields/algeria-national-team.football-logos.cc.png',
  'ARG': 'assets/shields/argentina-national-team.football-logos.cc.png',
  'AUS': 'assets/shields/australia-national-team.football-logos.cc.png',
  'AUT': 'assets/shields/austria-national-team.football-logos.cc.png',
  'BEL': 'assets/shields/belgium-national-team.football-logos.cc.png',
  'BRA': 'assets/shields/brazil-national-team.football-logos.cc.png',
  'CAN': 'assets/shields/canada-national-team.football-logos.cc.png',
  'CPV': 'assets/shields/cabo-verde-national-team.football-logos.cc.png',
  'CIV': 'assets/shields/cote-d-ivoire-national-team.football-logos.cc.png',
  'COL': 'assets/shields/colombia-national-team.football-logos.cc.png',
  'CRO': 'assets/shields/croatia-national-team.football-logos.cc.png',
  'CUW': 'assets/shields/curacao-national-team.football-logos.cc.png',
  'ECU': 'assets/shields/ecuador-national-team.football-logos.cc.png',
  'EGY': 'assets/shields/egypt-national-team.football-logos.cc.png',
  'ENG': 'assets/shields/england-national-team.football-logos.cc.png',
  'ESP': 'assets/shields/spain-national-team.football-logos.cc.png',
  'FRA': 'assets/shields/france-national-team.football-logos.cc.png',
  'GER': 'assets/shields/germany-national-team.football-logos.cc.png',
  'GHA': 'assets/shields/ghana-national-team.football-logos.cc.png',
  'HAI': 'assets/shields/haiti-national-team.football-logos.cc.png',
  'IRN': 'assets/shields/iran-national-team.football-logos.cc.png',
  'JPN': 'assets/shields/japan-national-team.football-logos.cc.png',
  'JOR': 'assets/shields/jordan-national-team.football-logos.cc.png',
  'KOR': 'assets/shields/south-korea-national-team.football-logos.cc.png',
  'KSA': 'assets/shields/saudi-arabia-national-team.football-logos.cc.png',
  'MAR': 'assets/shields/morocco-national-team.football-logos.cc.png',
  'MEX': 'assets/shields/mexico-national-team.football-logos.cc.png',
  'NED': 'assets/shields/dutch-national-team.football-logos.cc.png',
  'NZL': 'assets/shields/new-zealand-national-team.football-logos.cc.png',
  'NOR': 'assets/shields/norway-national-team.football-logos.cc.png',
  'PAN': 'assets/shields/panama-national-team.football-logos.cc.png',
  'PAR': 'assets/shields/paraguay-national-team.football-logos.cc.png',
  'POR': 'assets/shields/portuguese-football-federation.football-logos.cc.png',
  'QAT': 'assets/shields/qatar-national-team.football-logos.cc.png',
  'RSA': 'assets/shields/south-africa-national-team.football-logos.cc.png',
  'SCO': 'assets/shields/scotland-national-team.football-logos.cc.png',
  'SEN': 'assets/shields/senegal-national-team.football-logos.cc.png',
  'SUI': 'assets/shields/switzerland-national-team.football-logos.cc.png',
  'TUN': 'assets/shields/tunisia-national-team.football-logos.cc.png',
  'USA': 'assets/shields/usa-national-team.football-logos.cc.png',
  'URU': 'assets/shields/uruguay-national-team.football-logos.cc.png',
  'UZB': 'assets/shields/uzbekistan-national-team.football-logos.cc.png',
};

/// Devuelve la ruta del asset del escudo para el código de equipo, o null si no hay.
String? getShieldAssetPath(String teamCode) {
  if (teamCode.isEmpty) return null;
  final key = teamCode.length >= 3 ? teamCode.substring(0, 3).toUpperCase() : teamCode.toUpperCase();
  return _teamCodeToShield[key];
}

/// Extrae el código de equipo del stickerId (ej. MEX-B-01 → MEX).
String teamCodeFromStickerId(String stickerId) {
  final idx = stickerId.indexOf('-');
  return idx > 0 ? stickerId.substring(0, idx).toUpperCase() : stickerId.toUpperCase();
}
