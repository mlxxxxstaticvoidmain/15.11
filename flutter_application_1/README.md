# Атлас упражнений

Мобильное Flutter-приложение для поиска упражнений по базе
[API Ninjas](https://api-ninjas.com/api/exercises). Демонстрирует полноценную
работу с сетью: `Dio`, собственный интерсептор с токеном, `pretty_dio_logger`
и внедрение зависимостей через `get_it`.

Ключ API вводится в приложении при первом запуске и хранится локально — в
исходном коде его нет.

## Что умеет приложение

- **Поиск упражнений** по названию с debounce (запрос уходит не на каждую букву).
- **Фильтры**: 16 групп мышц, тип тренировки, уровень сложности. Фильтры
  комбинируются, их можно сбросить одним касанием.
- **Карточка упражнения**: пошаговая техника, блок безопасности, инвентарь.
- **Избранное**: упражнения сохраняются целиком и открываются без интернета.
- **План тренировки**: добавление упражнений, отметки о выполнении, прогресс,
  удаление и очистка. Всё сохраняется между запусками.
- **Настройки**: сохранение и проверка ключа реальным запросом, светлая/тёмная/
  системная тема, очистка локальных данных.
- **Состояния экрана**: загрузочные скелетоны, ошибки с расшифровкой (401, 429,
  таймаут, нет сети), пустые состояния, pull-to-refresh.
- **Онбординг** с объяснением, где взять ключ API Ninjas.

## Стек

| Пакет | Роль |
| --- | --- |
| `dio 5.11` | HTTP-клиент, базовый URL, таймауты |
| `pretty_dio_logger 1.4` | журнал запросов и ответов в debug-режиме |
| `get_it 9.3` | контейнер зависимостей |
| `shared_preferences 2.5` | ключ API, избранное, план, тема |
| `url_launcher 6.3` | переход на сайт API Ninjas |

## Запуск

Нужен Flutter 3.41+ (проект собран и проверен на Flutter 3.47.8 / Dart 3.13.7).

```bash
flutter pub get
flutter run
```

На этой машине Flutter установлен в `D:\flutter`, но не добавлен в `PATH`:

```powershell
$env:Path = "D:\flutter\bin;$env:Path"
flutter run
```

1. Зарегистрируйтесь на <https://api-ninjas.com/register> и скопируйте ключ.
2. Вставьте ключ в приложении (стартовый экран или «Настройки»).
3. Приложение проверит ключ запросом `GET /v1/exercises?muscle=biceps` и покажет
   результат проверки.

Ключ можно заменить или удалить в настройках; после сохранения поиск сразу
перезагружается с новым ключом.

### Web

```bash
flutter run -d chrome
```

Для web нужен CORS на стороне API. Если браузер блокирует запросы, запускайте
приложение на Android, Windows или iOS. Мобильные и десктопные сборки не
подвержены CORS-ограничениям.

## API

```
GET https://api.api-ninjas.com/v1/exercises
X-Api-Key: <ключ>
```

Параметры: `name`, `muscle`, `type`, `difficulty`. Бесплатный тариф отдаёт до
**5 упражнений за запрос** (поэтому в интерфейсе есть подпись «до 5 на запрос»).
Пагинация `offset` доступна только на платных тарифах, поэтому приложение
предлагает уточнять фильтры, а не листать бесконечную ленту.

## Архитектура

```
lib/
├─ core/
│  ├─ config/app_config.dart        базовый URL, заголовок, таймауты
│  ├─ di/injection.dart             регистрация всех зависимостей в get_it
│  ├─ network/
│  │  ├─ auth_interceptor.dart      добавляет X-Api-Key в каждый запрос
│  │  ├─ dio_factory.dart           BaseOptions + AuthInterceptor + PrettyDioLogger
│  │  └─ api_exception.dart         единые понятные ошибки
│  ├─ storage/preferences_service.dart
│  ├─ theme/                        палитра, типографика, светлая/тёмная тема
│  └─ utils/                        debounce, склонения
├─ data/
│  ├─ models/                       Exercise, WorkoutEntry, ExerciseQuery, подписи
│  ├─ sources/exercise_api.dart     только HTTP и JSON
│  └─ repositories/                 поиск, избранное, план
├─ features/
│  ├─ search/                       контроллер поиска + экран
│  ├─ details/                      карточка упражнения
│  ├─ favorites/                    избранное
│  ├─ plan/                         тренировка
│  ├─ settings/                     ключ, тема, данные, тема-контроллер
│  └─ shell/                        нижняя навигация и онбординг
└─ ui/widgets/                      переиспользуемые элементы
```

Поток данных: `Widget → Controller (ChangeNotifier) → Repository → ExerciseApi → Dio`.
Экраны не работают с `Dio` напрямую и не парсят JSON.

## Как закрыты требования

### Оценка 3 — приложение на Dio

`lib/core/network/dio_factory.dart`:

```dart
final dio = Dio(
  BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    headers: const {'Accept': 'application/json'},
  ),
);

dio.interceptors.add(authInterceptor);
```

Запросы выполняются в `lib/data/sources/exercise_api.dart`, ошибки
`DioException` преобразуются в `ApiException` с понятным текстом.

### Оценка 4 — токен и PrettyDioLogger

`lib/core/network/auth_interceptor.dart` — класс-интерсептор, который читает
ключ из локального хранилища и подставляет его в заголовок:

```dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._preferences);

  final PreferencesService _preferences;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final apiKey = _preferences.apiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      options.headers[AppConfig.apiKeyHeader] = apiKey; // X-Api-Key
    }
    handler.next(options);
  }
}
```

`DioFactory` подключает его перед логгером:

```dart
dio.interceptors.add(authInterceptor);

if (kDebugMode) {
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: false, // ключ не попадает в консоль
      requestBody: true,
      responseBody: true,
      error: true,
      compact: true,
      maxWidth: 110,
    ),
  );
}
```

Ключ намеренно не печатается в лог: заголовки отключены, чтобы не утекал
`X-Api-Key`. Сам токен можно увидеть в настройках в замаскированном виде.

### Оценка 5 — get_it

`lib/core/di/injection.dart` регистрирует `PreferencesService`, `Dio`,
`AuthInterceptor`, API, репозитории и контроллеры:

```dart
getIt
  ..registerSingleton<PreferencesService>(preferences)
  ..registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(getIt<PreferencesService>()),
  )
  ..registerLazySingleton<Dio>(() => createDio(getIt<AuthInterceptor>()))
  ..registerLazySingleton<ExerciseApi>(() => ExerciseApi(getIt<Dio>()))
  ..registerLazySingleton<ExerciseRepository>(
    () => ExerciseRepository(getIt<ExerciseApi>()),
  )
  ..registerLazySingleton<ExerciseSearchController>(
    () => ExerciseSearchController(getIt<ExerciseRepository>()),
  );
```

Экраны получают зависимости через `getIt<...>()`, вручную ничего не создают.
`AuthInterceptor` читает ключ на момент запроса, поэтому после смены ключа
`Dio` не нужно пересоздавать.

## Проверка

```bash
flutter analyze   # без замечаний
flutter test      # 13 тестов
```

Тесты покрывают разбор ответа API (включая `equipments` строкой и массивом),
шаги инструкции, параметры запроса, склонения, маппинг ошибок 401/429/таймаут
и сохранение избранного, плана и ключа в `SharedPreferences`.

## Замечание про ключ

Бесплатный ключ API Ninjas выдаётся после регистрации. Приложение не содержит
ключ в репозитории: он вводится пользователем и хранится в
`SharedPreferences` на устройстве. Для проверки работы можно использовать
любой действующий ключ API Ninjas.
