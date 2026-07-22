import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_report_frontend/src/features/auth/data/token_storage.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';
import 'package:smart_city_report_frontend/src/features/users/data/user_api_service.dart';

void main() {
  test('fetchMyProfile parses citizen status analytics', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/users/me/profile');
      expect(request.headers['Authorization'], 'Bearer test-token');
      return http.Response(
        jsonEncode({
          'id': 'citizen-1',
          'fullName': 'Demo Citizen',
          'email': 'citizen@test.com',
          'role': 'CITIZEN',
          'active': true,
          'createdAt': '2026-06-01T08:00:00Z',
          'citizenReportAnalytics': {
            'totalReports': 4,
            'byStatus': {'SUBMITTED': 2, 'FIXED': 1, 'CANCELLED': 1},
          },
          'staffTaskAnalytics': null,
        }),
        200,
      );
    });
    final service = BackendUserApiService(
      tokenStorage: _MemoryTokenStorage(),
      client: client,
    );

    final profile = await service.fetchMyProfile();

    expect(profile.citizenReportAnalytics?.totalReports, 4);
    expect(profile.citizenReportAnalytics?.byStatus[ReportStatus.submitted], 2);
    expect(
      profile.citizenReportAnalytics?.byStatus[ReportStatus.inProgress],
      0,
    );
    expect(profile.staffTaskAnalytics, isNull);
  });

  test('fetchMyProfile parses every staff task status', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'id': 'staff-1',
          'fullName': 'Demo Staff',
          'email': 'staff@test.com',
          'role': 'STAFF',
          'active': true,
          'createdAt': null,
          'citizenReportAnalytics': null,
          'staffTaskAnalytics': {
            'totalTasks': 3,
            'byStatus': {'ASSIGNED': 1, 'IN_PROGRESS': 1, 'DENIED': 1},
          },
        }),
        200,
      );
    });
    final service = BackendUserApiService(
      tokenStorage: _MemoryTokenStorage(),
      client: client,
    );

    final profile = await service.fetchMyProfile();

    expect(profile.staffTaskAnalytics?.totalTasks, 3);
    expect(profile.staffTaskAnalytics?.byStatus[TaskStatus.denied], 1);
    expect(profile.staffTaskAnalytics?.byStatus[TaskStatus.closed], 0);
  });

  test('fetchStaffPublicProfile calls the staff profile endpoint', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/users/staff/staff-1/profile');
      return http.Response(
        jsonEncode({
          'id': 'staff-1',
          'fullName': 'Demo Staff',
          'email': 'staff@test.com',
          'role': 'STAFF',
          'active': true,
          'createdAt': '2026-06-01T08:00:00Z',
        }),
        200,
      );
    });
    final service = BackendUserApiService(
      tokenStorage: _MemoryTokenStorage(),
      client: client,
    );

    final profile = await service.fetchStaffPublicProfile('staff-1');

    expect(profile.fullName, 'Demo Staff');
    expect(profile.email, 'staff@test.com');
  });

  test('fetchStaffDetailProfile parses analytics and tasks', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/users/staff/staff-1/details');
      return http.Response(
        jsonEncode({
          'id': 'staff-1',
          'fullName': 'Demo Staff',
          'email': 'staff@test.com',
          'role': 'STAFF',
          'active': true,
          'createdAt': '2026-06-01T08:00:00Z',
          'taskAnalytics': {
            'totalTasks': 2,
            'byStatus': {'ASSIGNED': 1, 'IN_PROGRESS': 1},
          },
          'tasks': <Object?>[],
        }),
        200,
      );
    });
    final service = BackendUserApiService(
      tokenStorage: _MemoryTokenStorage(),
      client: client,
    );

    final profile = await service.fetchStaffDetailProfile('staff-1');

    expect(profile.fullName, 'Demo Staff');
    expect(profile.taskAnalytics.totalTasks, 2);
    expect(profile.taskAnalytics.byStatus[TaskStatus.assigned], 1);
    expect(profile.taskAnalytics.byStatus[TaskStatus.closed], 0);
    expect(profile.tasks, isEmpty);
  });
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => 'test-token';

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}
