abstract class ApiService {
  const ApiService();

  String get baseUrl => const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
