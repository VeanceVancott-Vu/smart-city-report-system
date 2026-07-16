import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_report_frontend/src/features/auth/data/token_storage.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';

void main() {
  test(
    'refreshes the report after a successful upload acknowledgment',
    () async {
      const reportId = '11111111-1111-1111-1111-111111111111';
      final methods = <String>[];
      final client = MockClient((request) async {
        methods.add(request.method);
        if (request.method == 'POST') {
          return http.Response('', 204);
        }

        return http.Response(
          jsonEncode(<String, Object?>{
            'id': reportId,
            'title': 'Pothole',
            'description': 'Large pothole',
            'category': 'ROAD_DAMAGE',
            'status': 'IN_PROGRESS',
            'latitude': 10.762622,
            'longitude': 106.660172,
            'addressText': 'District 1',
            'beforePhotoUrl': '/uploads/report-before/before.jpg',
            'afterPhotoUrl': '/uploads/report-after/after.jpg',
            'anonymous': false,
            'upvoteCount': 0,
            'priorityScore': 0,
            'createdAt': '2026-07-16T08:00:00Z',
            'updatedAt': '2026-07-16T08:01:00Z',
            'createdBy': <String, Object?>{
              'id': '22222222-2222-2222-2222-222222222222',
              'displayName': 'Citizen',
              'role': 'CITIZEN',
            },
          }),
          200,
        );
      });

      final service = BackendReportApiService(
        tokenStorage: _MemoryTokenStorage(),
        client: client,
      );

      final report = await service.uploadAfterPhoto(
        reportId: reportId,
        filename: 'after.jpg',
        bytes: <int>[1, 2, 3],
      );

      expect(report.afterPhotoUrl, '/uploads/report-after/after.jpg');
      expect(methods, <String>['POST', 'GET']);
    },
  );
}

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => 'test-token';

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}
