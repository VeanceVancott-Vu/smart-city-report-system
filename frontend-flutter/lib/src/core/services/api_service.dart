import '../config/api_config.dart';

abstract class ApiService {
  const ApiService();

  String get baseUrl => ApiConfig.requireBaseUrl();
}
