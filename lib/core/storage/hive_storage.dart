import 'package:hive_flutter/hive_flutter.dart';

import '../data/world_cup_2026_seed.dart';

/// Claves del box de preferencias (onboarding + perfil local).
abstract final class PreferencesKeys {
  PreferencesKeys._();

  static const String hasCompletedOnboarding = 'hasCompletedOnboarding';
  static const String userName = 'userName';
  static const String favoriteTeam = 'favoriteTeam';
  static const String profileColorHex = 'profileColorHex';

  /// 'light' | 'dark' | 'system'
  static const String themeMode = 'themeMode';
}

/// Nombre del box de preferencias de la app.
const String kPreferencesBoxName = 'app_preferences';

/// Nombre del box de progreso de colección (laminas).
const String kCollectionBoxName = 'collection_box';

/// Clave del mapa de colección: stickerId -> count (1 = collected, >1 = duplicates).
const String kCollectedStickersKey = 'collectedStickers';

/// Inicializa Hive (Flutter) y abre los boxes.
/// Debe llamarse una sola vez al arranque, antes de [runApp].
Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox(kPreferencesBoxName);
  await Hive.openBox(kCollectionBoxName);
}

/// Box de preferencias. Solo usar después de [initHive].
Box get preferencesBox => Hive.box(kPreferencesBoxName);

/// Indica si el usuario completó el onboarding (personalización).
bool get hasCompletedOnboarding {
  final v = preferencesBox.get(PreferencesKeys.hasCompletedOnboarding);
  return v == true;
}

/// Guarda que el onboarding fue completado.
Future<void> setOnboardingCompleted() async {
  await preferencesBox.put(PreferencesKeys.hasCompletedOnboarding, true);
}

/// Obtiene el nombre del usuario (guardado en personalización).
String? get storedUserName =>
    preferencesBox.get(PreferencesKeys.userName) as String?;

/// Obtiene el equipo favorito (opcional).
String? get storedFavoriteTeam =>
    preferencesBox.get(PreferencesKeys.favoriteTeam) as String?;

/// Obtiene el color de perfil en hex (opcional), ej. "FF3B82F6".
String? get storedProfileColorHex =>
    preferencesBox.get(PreferencesKeys.profileColorHex) as String?;

/// Obtiene el modo de tema: 'light', 'dark' o 'system'. Por defecto 'system'.
String get storedThemeMode {
  final v = preferencesBox.get(PreferencesKeys.themeMode) as String?;
  switch (v) {
    case 'light':
      return 'light';
    case 'dark':
      return 'dark';
    case 'system':
      return 'system';
    default:
      return 'system';
  }
}

/// Guarda el modo de tema ('light', 'dark', 'system').
Future<void> saveThemeMode(String mode) async {
  await preferencesBox.put(PreferencesKeys.themeMode, mode);
}

/// Guarda el perfil de usuario (nombre, equipo favorito, color).
Future<void> saveUserProfile({
  required String name,
  String? favoriteTeam,
  String? profileColorHex,
}) async {
  final box = preferencesBox;
  await box.put(PreferencesKeys.userName, name);
  if (favoriteTeam != null && favoriteTeam.isNotEmpty) {
    await box.put(PreferencesKeys.favoriteTeam, favoriteTeam);
  } else {
    await box.delete(PreferencesKeys.favoriteTeam);
  }
  if (profileColorHex != null && profileColorHex.isNotEmpty) {
    await box.put(PreferencesKeys.profileColorHex, profileColorHex);
  } else {
    await box.delete(PreferencesKeys.profileColorHex);
  }
}

// --- Collection progress (album stickers) ---

Box get collectionBox => Hive.box(kCollectionBoxName);

/// Mapa stickerId -> count. No modificar directamente; usar [setStickerCount] / [addStickersByGlobalNumbers].
Map<String, int> get collectedStickersMap {
  final raw = collectionBox.get(kCollectedStickersKey);
  if (raw is Map) {
    return Map<String, int>.from(
      raw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)),
    );
  }
  return {};
}

/// Guarda el mapa completo (para batch updates).
Future<void> saveCollectedStickersMap(Map<String, int> map) async {
  await collectionBox.put(kCollectedStickersKey, map);
}

/// Establece la cantidad de una lamina (0 = no tiene, 1+ = tiene y duplicados).
Future<void> setStickerCount(String stickerId, int count) async {
  final map = Map<String, int>.from(collectedStickersMap);
  if (count <= 0) {
    map.remove(stickerId);
  } else {
    map[stickerId] = count;
  }
  await saveCollectedStickersMap(map);
}

/// Añade laminas por número global (bulk add). Para cada número, pone count en 1 o incrementa.
Future<void> addStickersByGlobalNumbers(Iterable<int> globalNumbers) async {
  final map = Map<String, int>.from(collectedStickersMap);
  for (final n in globalNumbers) {
    final sticker = WorldCup2026Seed.getStickerByGlobalNumber(n);
    if (sticker != null) {
      map[sticker.id] = (map[sticker.id] ?? 0) + 1;
    }
  }
  await saveCollectedStickersMap(map);
}

/// Añade láminas por identificador flexible de sticker (id/código interno).
Future<void> addStickersByStickerIds(Iterable<String> stickerIds) async {
  final map = Map<String, int>.from(collectedStickersMap);
  for (final id in stickerIds) {
    final normalized = id.trim();
    if (normalized.isEmpty) continue;
    map[normalized] = (map[normalized] ?? 0) + 1;
  }
  await saveCollectedStickersMap(map);
}

/// Aplica varios conteos en una sola escritura (importación CSV).
Future<void> applyStickerCounts(Map<String, int> counts) async {
  final map = Map<String, int>.from(collectedStickersMap);
  for (final e in counts.entries) {
    if (e.value <= 0) {
      map.remove(e.key);
    } else {
      map[e.key] = e.value;
    }
  }
  await saveCollectedStickersMap(map);
}

/// Import CSV modo sumar: cantidad final = actual + CSV (filas con cantidad ≤ 0 se ignoran).
Future<void> mergeStickerCounts(Map<String, int> counts) async {
  final map = Map<String, int>.from(collectedStickersMap);
  for (final e in counts.entries) {
    if (e.value <= 0) continue;
    map[e.key] = (map[e.key] ?? 0) + e.value;
  }
  await saveCollectedStickersMap(map);
}

/// Import CSV modo reemplazar: la colección queda solo con los datos del CSV (solo cantidades > 0).
Future<void> replaceStickerCounts(Map<String, int> counts) async {
  final map = <String, int>{};
  for (final e in counts.entries) {
    if (e.value > 0) {
      map[e.key] = e.value;
    }
  }
  await saveCollectedStickersMap(map);
}
