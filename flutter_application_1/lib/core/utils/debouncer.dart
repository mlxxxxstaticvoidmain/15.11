import 'dart:async';
import 'dart:ui';

/// Откладывает выполнение колбэка: поиск не уходит на сервер
/// на каждую нажатую букву.
class Debouncer {
  Debouncer(this._duration);

  final Duration _duration;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(_duration, action);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
