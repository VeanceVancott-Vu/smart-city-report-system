import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_report_frontend/src/features/analytics/data/analytics_api_service.dart';
import 'package:smart_city_report_frontend/src/features/analytics/domain/overseer_analytics.dart';
import 'package:smart_city_report_frontend/src/features/auth/data/token_storage.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';

void main() {
  test(
    'fetchOverseerAnalytics sends filters and parses all sections',
    () async {
      final from = DateTime.utc(2026, 7, 1);
      final to = DateTime.utc(2026, 7, 22);
      final client = MockClient((request) async {
        expect(request.url.path, '/api/analytics/overseer');
        expect(request.url.queryParameters['from'], from.toIso8601String());
        expect(request.url.queryParameters['to'], to.toIso8601String());
        expect(request.url.queryParameters['category'], 'ROAD_DAMAGE');
        expect(request.url.queryParameters['staffId'], 'staff-1');
        expect(request.url.queryParameters['area'], 'District 1');
        expect(request.headers['Authorization'], 'Bearer analytics-token');
        return http.Response(
          jsonEncode({
            'generatedAt': '2026-07-22T08:00:00Z',
            'filters': {
              'from': '2026-07-01T00:00:00Z',
              'to': '2026-07-22T00:00:00Z',
              'category': 'ROAD_DAMAGE',
              'staffId': 'staff-1',
              'area': 'district 1',
            },
            'reports': {
              'totalReports': 4,
              'byStatus': {'SUBMITTED': 1, 'IN_PROGRESS': 2, 'FIXED': 1},
              'totalUpvotes': 8,
              'averagePriority': 2.0,
              'fixedRate': 25.0,
              'cancellationRate': 0.0,
            },
            'tasks': {
              'totalTasks': 3,
              'byStatus': {'IN_PROGRESS': 2, 'CLOSED': 1},
              'unassignedTasks': 0,
              'activeTasks': 2,
              'pendingReviewTasks': 0,
              'completedTasks': 1,
              'completionRate': 33.33,
              'averageWorkHours': 12.5,
              'averageReviewHours': 2.0,
              'averageResolutionHours': 30.0,
            },
            'trends': [
              {
                'periodStart': '2026-07-21',
                'reportsCreated': 2,
                'reportsFixed': 1,
                'tasksCreated': 1,
                'tasksClosed': 1,
              },
            ],
            'categories': [
              {
                'category': 'ROAD_DAMAGE',
                'reports': 4,
                'fixedReports': 1,
                'tasks': 3,
                'closedTasks': 1,
              },
            ],
            'staffWorkloads': [
              {
                'staffId': 'staff-1',
                'fullName': 'Analytics Staff',
                'email': 'staff@test.com',
                'activeAccount': true,
                'totalTasks': 3,
                'activeTasks': 2,
                'pendingReviewTasks': 0,
                'completedTasks': 1,
                'deniedTasks': 0,
                'completionRate': 33.33,
                'averageCompletionHours': 12.5,
              },
            ],
            'attentionItems': [
              {
                'entityType': 'TASK',
                'id': 'task-1',
                'title': 'Review repair',
                'status': 'DONE',
                'reason': 'PENDING_REVIEW',
                'priorityScore': 3,
                'staffId': 'staff-1',
                'staffName': 'Analytics Staff',
                'addressText': 'District 1',
                'updatedAt': '2026-07-22T07:00:00Z',
              },
            ],
            'mapPoints': [
              {
                'reportId': 'report-1',
                'title': 'Road damage',
                'category': 'ROAD_DAMAGE',
                'status': 'IN_PROGRESS',
                'latitude': 10.77,
                'longitude': 106.70,
                'addressText': 'District 1',
                'priorityScore': 3,
                'upvoteCount': 3,
              },
            ],
          }),
          200,
        );
      });
      final service = BackendAnalyticsApiService(
        tokenStorage: _AnalyticsTokenStorage(),
        client: client,
      );

      final analytics = await service.fetchOverseerAnalytics(
        AnalyticsQuery(
          from: from,
          to: to,
          category: ReportCategory.roadDamage,
          staffId: 'staff-1',
          area: 'District 1',
        ),
      );

      expect(analytics.reports.totalReports, 4);
      expect(analytics.reports.byStatus[ReportStatus.cancelled], 0);
      expect(analytics.tasks.byStatus[TaskStatus.inProgress], 2);
      expect(analytics.tasks.byStatus[TaskStatus.pendingReview], 0);
      expect(analytics.trends.single.tasksClosed, 1);
      expect(analytics.categories.single.category, ReportCategory.roadDamage);
      expect(analytics.staffWorkloads.single.staffId, 'staff-1');
      expect(analytics.attentionItems.single.reason, 'PENDING_REVIEW');
      expect(analytics.mapPoints.single.reportId, 'report-1');
    },
  );
}

class _AnalyticsTokenStorage implements TokenStorage {
  @override
  Future<String?> readToken() async => 'analytics-token';

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> clearToken() async {}
}
