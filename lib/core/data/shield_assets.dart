/// Ruta a banderas por código de equipo (3 letras: MEX, ALG, etc.).
/// Código extraído del stickerId (ej. MEX-01 o MEX-1 → MEX).
const Map<String, String> _teamCodeToShield = {
  'ALG': 'assets/flags/dz.svg',
  'ARG': 'assets/flags/ar.svg',
  'AUS': 'assets/flags/au.svg',
  'AUT': 'assets/flags/at.svg',
  'BEL': 'assets/flags/be.svg',
  'BIH': 'assets/flags/ba.svg',
  'BRA': 'assets/flags/br.svg',
  'CAN': 'assets/flags/ca.svg',
  'CPV': 'assets/flags/cv.svg',
  'CIV': 'assets/flags/ci.svg',
  'CZE': 'assets/flags/cz.svg',
  'COL': 'assets/flags/co.svg',
  'COD': 'assets/flags/cd.svg',
  'CRO': 'assets/flags/hr.svg',
  'CUW': 'assets/flags/cw.svg',
  'ECU': 'assets/flags/ec.svg',
  'EGY': 'assets/flags/eg.svg',
  'ENG': 'assets/flags/gb-eng.svg',
  'ESP': 'assets/flags/es.svg',
  'FRA': 'assets/flags/fr.svg',
  'GER': 'assets/flags/de.svg',
  'GHA': 'assets/flags/gh.svg',
  'HAI': 'assets/flags/ht.svg',
  'IRN': 'assets/flags/ir.svg',
  'IRQ': 'assets/flags/iq.svg',
  'JPN': 'assets/flags/jp.svg',
  'JOR': 'assets/flags/jo.svg',
  'KOR': 'assets/flags/kr.svg',
  'KSA': 'assets/flags/sa.svg',
  'MAR': 'assets/flags/ma.svg',
  'MEX': 'assets/flags/mx.svg',
  'NED': 'assets/flags/nl.svg',
  'NZL': 'assets/flags/nz.svg',
  'NOR': 'assets/flags/no.svg',
  'PAN': 'assets/flags/pa.svg',
  'PAR': 'assets/flags/py.svg',
  'POR': 'assets/flags/pt.svg',
  'QAT': 'assets/flags/qa.svg',
  'RSA': 'assets/flags/za.svg',
  'SCO': 'assets/flags/gb-sct.svg',
  'SEN': 'assets/flags/sn.svg',
  'SUI': 'assets/flags/ch.svg',
  'SWE': 'assets/flags/se.svg',
  'TUN': 'assets/flags/tn.svg',
  'TUR': 'assets/flags/tr.svg',
  'USA': 'assets/flags/us.svg',
  'URU': 'assets/flags/uy.svg',
  'UZB': 'assets/flags/uz.svg',
};

/// Pares (código de equipo, ruta asset) para comparación con capturas.
Iterable<MapEntry<String, String>> get allTeamShieldAssetEntries =>
    _teamCodeToShield.entries;

/// Devuelve la ruta del asset de bandera para el código de equipo, o null si no hay.
String? getShieldAssetPath(String teamCode) {
  if (teamCode.isEmpty) return null;
  final key = teamCode.length >= 3 ? teamCode.substring(0, 3).toUpperCase() : teamCode.toUpperCase();
  return _teamCodeToShield[key];
}

/// Extrae el código de equipo del stickerId (p. ej. MEX-01 → MEX).
String teamCodeFromStickerId(String stickerId) {
  final idx = stickerId.indexOf('-');
  return idx > 0 ? stickerId.substring(0, idx).toUpperCase() : stickerId.toUpperCase();
}
