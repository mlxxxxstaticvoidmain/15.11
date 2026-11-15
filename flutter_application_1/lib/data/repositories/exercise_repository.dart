import '../models/exercise.dart';
import '../models/exercise_query.dart';
import '../sources/exercise_api.dart';

/// Репозиторий приложения: экраны не знают про Dio и JSON.
class ExerciseRepository {
  ExerciseRepository(this._api);

  final ExerciseApi _api;

  Future<List<Exercise>> search(ExerciseQuery query) {
    return _api.fetchExercises(query);
  }

  Future<void> checkApiKey() => _api.ping();
}
