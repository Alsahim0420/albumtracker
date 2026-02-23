import 'package:hive_flutter/hive_flutter.dart';

import '../data/world_cup_2026_seed.dart';

/// Claves del box de preferencias (onboarding + perfil local).
abstract final class PreferencesKeys {
  PreferencesKeys._();

  static const String hasCompletedOnboarding = 'hasCompletedOnboarding';
  static const String userName = 'userName';
  static const String favoriteTeam = 'favoriteTeam';
  static const String profileColorHex = 'profileColorHex';
}

/// Nombre del box de preferencias de la app.
const String kPreferencesBoxName = 'app_preferences';

/// Nombre del box de progreso de colección (pegatinas).
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
    return Map<String, int>.from(raw.map((k, v) => MapEntry(k.toString(), v is int ? v : 0)));
  }
  return {};
}

/// Guarda el mapa completo (para batch updates).
Future<void> saveCollectedStickersMap(Map<String, int> map) async {
  await collectionBox.put(kCollectedStickersKey, map);
}

/// Establece la cantidad de una pegatina (0 = no tiene, 1+ = tiene y duplicados).
Future<void> setStickerCount(String stickerId, int count) async {
  final map = Map<String, int>.from(collectedStickersMap);
  if (count <= 0) {
    map.remove(stickerId);
  } else {
    map[stickerId] = count;
  }
  await saveCollectedStickersMap(map);
}

/// Añade pegatinas por número global (bulk add). Para cada número, pone count en 1 o incrementa.
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
