import 'dart:convert';

import '../../core/storage/preferences_service.dart';
import '../models/exercise.dart';

/// Избранное хранится целиком (а не только id), чтобы карточки
/// открывались без повторного запроса к сети.
class FavoritesRepository {
  FavoritesRepository(this._preferences);

  final PreferencesService _preferences;

  List<Exercise> load() {
    final raw = _preferences.readRaw(PreferencesService.favoritesKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Exercise.fromJson)
          .toList(growable: false);
    } catch (_) {
      // Повреждённые локальные данные не должны ронять приложение.
      return const [];
    }
  }

  Future<void> save(List<Exercise> exercises) {
    final payload = jsonEncode(
      exercises.map((exercise) => exercise.toJson()).toList(),
    );
    return _preferences.writeRaw(PreferencesService.favoritesKey, payload);
  }

  Future<void> clear() {
    return _preferences.removeRaw(PreferencesService.favoritesKey);
  }
}
