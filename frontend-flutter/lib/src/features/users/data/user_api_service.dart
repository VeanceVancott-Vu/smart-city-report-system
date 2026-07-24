import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../../auth/data/token_storage.dart';
import '../../auth/domain/current_user.dart';
import '../domain/app_user.dart';
import '../../tasks/domain/task.dart';
import '../../reports/domain/report.dart';

abstract class UserApiService {
  Future<UserProfile> fetchMyProfile();

  Future<StaffPublicProfile> fetchStaffPublicProfile(String staffId);

  Future<StaffDetailProfile> fetchStaffDetailProfile(String staffId);

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
  Future<UserProfile> fetchMyProfile() async {
    final response = await _client.get(
      _uri('/api/users/me/profile'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return UserProfile.fromJson(_decodeMap(response.body));
  }

  @override
  Future<StaffPublicProfile> fetchStaffPublicProfile(String staffId) async {
    final response = await _client.get(
      _uri('/api/users/staff/$staffId/profile'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return StaffPublicProfile.fromJson(_decodeMap(response.body));
  }

  @override
  Future<StaffDetailProfile> fetchStaffDetailProfile(String staffId) async {
    final response = await _client.get(
      _uri('/api/users/staff/$staffId/details'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return StaffDetailProfile.fromJson(_decodeMap(response.body));
  }

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
  Future<UserProfile> fetchMyProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return UserProfile(
      id: '22222222-2222-2222-2222-222222222222',
      fullName: 'Test Citizen',
      email: 'citizen@test.com',
      role: UserRole.citizen,
      active: true,
      createdAt: DateTime(2026, 6, 1),
      citizenReportAnalytics: const CitizenReportAnalytics(
        totalReports: 4,
        byStatus: {
          ReportStatus.submitted: 1,
          ReportStatus.inProgress: 1,
          ReportStatus.fixed: 1,
          ReportStatus.cancelled: 1,
        },
      ),
      staffTaskAnalytics: null,
    );
  }

  @override
  Future<StaffPublicProfile> fetchStaffPublicProfile(String staffId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final staff = _users.firstWhere(
      (user) => user.id == staffId && user.role == UserRole.staff,
      orElse: () => throw const UserApiException('Staff user not found.'),
    );
    return StaffPublicProfile(
      id: staff.id,
      fullName: staff.fullName,
      email: staff.email,
      role: staff.role,
      active: true,
      createdAt: DateTime(2026, 6, 1),
    );
  }

  @override
  Future<StaffDetailProfile> fetchStaffDetailProfile(String staffId) async {
    final summary = (await fetchStaffSummary()).firstWhere(
      (member) => member.id == staffId,
      orElse: () => throw const UserApiException('Staff user not found.'),
    );
    final counts = <TaskStatus, int>{
      for (final status in TaskStatus.values) status: 0,
    };
    for (final task in summary.tasks) {
      counts[task.status] = (counts[task.status] ?? 0) + 1;
    }
    return StaffDetailProfile(
      id: summary.id,
      fullName: summary.fullName,
      email: summary.email,
      role: UserRole.staff,
      active: summary.active,
      createdAt: DateTime(2026, 6, 1),
      taskAnalytics: StaffTaskAnalytics(
        totalTasks: summary.tasks.length,
        byStatus: counts,
      ),
      tasks: summary.tasks,
    );
  }

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
            latitude: 16.0602,
            longitude: 108.2148,
            addressText: 'Nguyen Hue, Hai Chau District',
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
            latitude: 16.0679,
            longitude: 108.2208,
            addressText: 'Le Loi, Hai Chau District',
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
            latitude: 16.0701,
            longitude: 108.2168,
            addressText: 'Ham Nghi, Hai Chau District',
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
