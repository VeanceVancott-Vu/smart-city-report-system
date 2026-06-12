class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  static String requireBaseUrl() {
    final value = baseUrl.trim();
    if (value.isEmpty) {
      throw StateError(
        'API_BASE_URL is not configured. Use --dart-define=API_BASE_URL=... '
        'or --dart-define-from-file=config/local_web.json for web / '
        'config/android_emulator.json for Android emulator.',
      );
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
