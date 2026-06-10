import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../domain/auth_session.dart';
import '../domain/current_user.dart';
import 'token_storage.dart';

abstract class AuthApiService {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<CurrentUser?> getCurrentUser();

  Future<void> logout();
}

class BackendAuthApiService extends ApiService implements AuthApiService {
  BackendAuthApiService({
    TokenStorage tokenStorage = const SecureTokenStorage(),
    http.Client? client,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return _authenticate('/api/auth/login', <String, Object?>{
      'email': email,
      'password': password,
    });
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _authenticate('/api/auth/register', <String, Object?>{
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  @override
  Future<CurrentUser?> getCurrentUser() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await _client.get(
      _uri('/api/auth/me'),
      headers: _headers(token: token),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await _tokenStorage.clearToken();
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_errorMessage(response));
    }

    final body = _decodeMap(response.body);
    return CurrentUser.fromJson(body);
  }

  @override
  Future<void> logout() {
    return _tokenStorage.clearToken();
  }

  Future<AuthSession> _authenticate(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_errorMessage(response));
    }

    final session = AuthSession.fromJson(_decodeMap(response.body));
    await _tokenStorage.saveToken(session.token);
    return session;
  }

  Uri _uri(String path) {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$cleanBaseUrl$path');
  }

  Map<String, String> _headers({String? token}) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeMap(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('Expected a JSON object response.');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = _decodeMap(response.body);
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } on FormatException {
      // Fall through to the status-based message.
    }

    return 'Request failed with status ${response.statusCode}.';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
