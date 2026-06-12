import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/domain/current_user.dart';
import '../domain/app_user.dart';

abstract class UserApiService {
  Future<List<AppUser>> fetchStaffUsers();

  Future<AppUser> createUser(UserDraft draft);
}

class BackendUserApiService extends ApiService implements UserApiService {
  BackendUserApiService({
    TokenStorage tokenStorage = const SecureTokenStorage(),
    http.Client? client,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  @override
  Future<List<AppUser>> fetchStaffUsers() async {
    final response = await _client.get(
      _uri('/api/users?role=STAFF'),
      headers: await _headers(),
    );
    _ensureSuccess(response);

    final body = _decodeMap(response.body);
    final users = body['users'] as List<dynamic>? ?? const <dynamic>[];
    return users
        .map((item) => AppUser.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<AppUser> createUser(UserDraft draft) async {
    final response = await _client.post(
      _uri('/api/users'),
      headers: await _headers(),
      body: jsonEncode(draft.toJson()),
    );
    _ensureSuccess(response);
    return AppUser.fromJson(_decodeMap(response.body));
  }

  Uri _uri(String path) {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$cleanBaseUrl$path');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const UserApiException('Please log in again.');
    }

    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw UserApiException(_errorMessage(response));
  }

  Map<String, dynamic> _decodeMap(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const UserApiException('Expected a JSON object response.');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = _decodeMap(response.body);
      final errors = body['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        return errors.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
      }
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } on Object {
      // Fall through to the status-based message.
    }

    return 'Request failed with status ${response.statusCode}.';
  }
}

class MockUserApiService extends ApiService implements UserApiService {
  final List<AppUser> _users = <AppUser>[
    const AppUser(
      id: '44444444-4444-4444-4444-444444444444',
      fullName: 'Test Staff',
      email: 'staff@test.com',
      role: UserRole.staff,
    ),
  ];

  @override
  Future<List<AppUser>> fetchStaffUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(
      _users.where((user) => user.role == UserRole.staff),
    );
  }

  @override
  Future<AppUser> createUser(UserDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final user = AppUser(
      id: '44444444-4444-4444-4444-${(_users.length + 1).toString().padLeft(12, '0')}',
      fullName: draft.fullName,
      email: draft.email,
      role: draft.role,
    );
    _users.add(user);
    return user;
  }
}

class UserApiException implements Exception {
  const UserApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
