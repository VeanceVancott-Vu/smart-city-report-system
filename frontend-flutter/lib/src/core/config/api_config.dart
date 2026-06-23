import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment('API_BASE_URL');

  static String requireBaseUrl() {
    var value = baseUrl.trim();
    if (value.isEmpty) {
      if (kIsWeb) {
        value = 'http://127.0.0.1:8080';
      } else {
        value = 'http://10.0.2.2:8080';
      }
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}

