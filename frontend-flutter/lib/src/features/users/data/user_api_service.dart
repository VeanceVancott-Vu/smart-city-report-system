import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/domain/current_user.dart';
import '../domain/app_user.dart';
import '../../tasks/domain/task.dart';
import '../../reports/domain/report.dart';

abstract class UserApiService {
  Future<List<AppUser>> fetchStaffUsers();

  Future<AppUser> createUser(UserDraft draft);

  Future<List<StaffSummary>> fetchStaffSummary();
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

  @override
  Future<List<StaffSummary>> fetchStaffSummary() async {
    final response = await _client.get(
      _uri('/api/users/staff-summary'),
      headers: await _headers(),
    );
    _ensureSuccess(response);

    final body = _decodeMap(response.body);
    final list = body['staff'] as List<dynamic>? ?? const <dynamic>[];
    return list
        .map((item) => StaffSummary.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
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

  @override
  Future<List<StaffSummary>> fetchStaffSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    return [
      StaffSummary(
        id: '44444444-4444-4444-4444-444444444444',
        fullName: 'Test Staff',
        email: 'staff@test.com',
        active: true,
        activeTasksCount: 1,
        completedTasksCount: 1,
        tasks: [
          Task(
            id: 'mock-task-1',
            title: 'Fix broken streetlight near Nguyen Hue',
            description: 'Streetlight is completely off.',
            category: ReportCategory.streetLight,
            status: TaskStatus.inProgress,
            latitude: 10.7769,
            longitude: 106.7009,
            addressText: 'Nguyen Hue, District 1',
            priorityScore: 3,
            assignedStaff: const ReportUserSummary(
              id: '44444444-4444-4444-4444-444444444444',
              fullName: 'Test Staff',
              role: 'STAFF',
            ),
            createdByOverseer: const ReportUserSummary(
              id: 'overseer-id',
              fullName: 'Test Overseer',
              role: 'OVERSEER',
            ),
            beforePhotoUrl: null,
            afterPhotoUrl: null,
            staffNote: null,
            aiConfidenceScore: null,
            aiDecision: null,
            startedAt: now.subtract(const Duration(hours: 2)),
            submittedAt: null,
            reviewedAt: null,
            closedAt: null,
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now,
            reportIds: const [],
          ),
          Task(
            id: 'mock-task-2',
            title: 'Pothole repairs at Le Loi',
            description: 'Fill the large pothole in the left lane.',
            category: ReportCategory.roadDamage,
            status: TaskStatus.done,
            latitude: 10.7827,
            longitude: 106.6994,
            addressText: 'Le Loi, District 1',
            priorityScore: 5,
            assignedStaff: const ReportUserSummary(
              id: '44444444-4444-4444-4444-444444444444',
              fullName: 'Test Staff',
              role: 'STAFF',
            ),
            createdByOverseer: const ReportUserSummary(
              id: 'overseer-id',
              fullName: 'Test Overseer',
              role: 'OVERSEER',
            ),
            beforePhotoUrl: null,
            afterPhotoUrl: '/uploads/report-after/pothole-after.jpg',
            staffNote: 'Completed successfully',
            aiConfidenceScore: null,
            aiDecision: null,
            startedAt: now.subtract(const Duration(days: 2)),
            submittedAt: now.subtract(const Duration(days: 1)),
            reviewedAt: null,
            closedAt: null,
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now.subtract(const Duration(days: 1)),
            reportIds: const [],
          ),
        ],
      ),
      StaffSummary(
        id: '44444444-4444-4444-4444-444444444445',
        fullName: 'Inactive Staff Member',
        email: 'inactive.staff@test.com',
        active: false,
        activeTasksCount: 0,
        completedTasksCount: 1,
        tasks: [
          Task(
            id: 'mock-task-3',
            title: 'Clean road garbage at Ham Nghi',
            description: 'Garbage pile needs sweeping.',
            category: ReportCategory.garbage,
            status: TaskStatus.closed,
            latitude: 10.7712,
            longitude: 106.7043,
            addressText: 'Ham Nghi, District 1',
            priorityScore: 1,
            assignedStaff: const ReportUserSummary(
              id: '44444444-4444-4444-4444-444444444445',
              fullName: 'Inactive Staff Member',
              role: 'STAFF',
            ),
            createdByOverseer: const ReportUserSummary(
              id: 'overseer-id',
              fullName: 'Test Overseer',
              role: 'OVERSEER',
            ),
            beforePhotoUrl: null,
            afterPhotoUrl: null,
            staffNote: 'Cleaned up completely.',
            aiConfidenceScore: null,
            aiDecision: null,
            startedAt: now.subtract(const Duration(days: 5)),
            submittedAt: now.subtract(const Duration(days: 4)),
            reviewedAt: now.subtract(const Duration(days: 4)),
            closedAt: now.subtract(const Duration(days: 4)),
            createdAt: now.subtract(const Duration(days: 6)),
            updatedAt: now.subtract(const Duration(days: 4)),
            reportIds: const [],
          ),
        ],
      ),
    ];
  }
}

class UserApiException implements Exception {
  const UserApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
