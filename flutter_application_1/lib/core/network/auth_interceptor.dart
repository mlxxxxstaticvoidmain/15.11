import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/preferences_service.dart';

/// Автоматически подставляет ключ API в каждый запрос.
///
/// Ключ читается из локального хранилища на момент запроса, поэтому
/// после смены ключа в настройках пересоздавать Dio не нужно.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._preferences);

  final PreferencesService _preferences;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final apiKey = _preferences.apiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      options.headers[AppConfig.apiKeyHeader] = apiKey;
    }
    handler.next(options);
  }
}
