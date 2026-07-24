import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/services/api_service.dart';
import '../../auth/data/token_storage.dart';
import '../../reports/domain/report.dart';
import '../../tasks/domain/task.dart';
import '../domain/overseer_analytics.dart';

abstract class AnalyticsApiService {
  Future<OverseerAnalytics> fetchOverseerAnalytics(AnalyticsQuery query);
}

class BackendAnalyticsApiService extends ApiService
    implements AnalyticsApiService {
  BackendAnalyticsApiService({
    TokenStorage tokenStorage = const SecureTokenStorage(),
    http.Client? client,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  @override
  Future<OverseerAnalytics> fetchOverseerAnalytics(AnalyticsQuery query) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const AnalyticsApiException('Please log in again.');
    }
    final uri = _uri(
      '/api/analytics/overseer',
    ).replace(queryParameters: query.toQueryParameters());
    final response = await _client.get(
      uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AnalyticsApiException(_errorMessage(response));
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AnalyticsApiException('Expected a JSON object response.');
    }
    return OverseerAnalytics.fromJson(decoded);
  }

  Uri _uri(String path) {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$cleanBaseUrl$path');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final message = body['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Fall through to the status-based message.
    }
    return 'Request failed with status ${response.statusCode}.';
  }
}

class MockAnalyticsApiService implements AnalyticsApiService {
  @override
  Future<OverseerAnalytics> fetchOverseerAnalytics(AnalyticsQuery query) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    return OverseerAnalytics(
      generatedAt: now,
      filters: AppliedAnalyticsFilters(
        from: query.from,
        to: query.to,
        category: query.category,
        staffId: query.staffId,
        area: query.area,
      ),
      reports: const ReportAnalyticsOverview(
        totalReports: 18,
        byStatus: {
          ReportStatus.submitted: 5,
          ReportStatus.inProgress: 6,
          ReportStatus.fixed: 6,
          ReportStatus.cancelled: 1,
        },
        totalUpvotes: 42,
        averagePriority: 2.33,
        fixedRate: 33.33,
        cancellationRate: 5.56,
      ),
      tasks: const TaskAnalyticsOverview(
        totalTasks: 13,
        byStatus: {
          TaskStatus.newTask: 2,
          TaskStatus.assigned: 2,
          TaskStatus.inProgress: 3,
          TaskStatus.done: 1,
          TaskStatus.pendingReview: 1,
          TaskStatus.denied: 1,
          TaskStatus.approved: 1,
          TaskStatus.closed: 2,
          TaskStatus.cancelled: 0,
        },
        unassignedTasks: 2,
        activeTasks: 6,
        pendingReviewTasks: 2,
        completedTasks: 5,
        completionRate: 38.46,
        averageWorkHours: 20.5,
        averageReviewHours: 5.25,
        averageResolutionHours: 50.75,
      ),
      trends: List<AnalyticsTrendPoint>.generate(
        7,
        (index) => AnalyticsTrendPoint(
          periodStart: now.subtract(Duration(days: 6 - index)),
          reportsCreated: 1 + index % 4,
          reportsFixed: index % 3,
          tasksCreated: 1 + index % 2,
          tasksClosed: index % 2,
        ),
      ),
      categories: [
        for (final category in ReportCategory.values)
          CategoryAnalytics(
            category: category,
            reports: category.index + 1,
            fixedReports: category.index ~/ 2,
            tasks: category.index,
            closedTasks: category.index ~/ 3,
          ),
      ],
      staffWorkloads: const [
        StaffWorkloadAnalytics(
          staffId: '44444444-4444-4444-4444-444444444444',
          fullName: 'Test Staff',
          email: 'staff@test.com',
          activeAccount: true,
          totalTasks: 7,
          activeTasks: 3,
          pendingReviewTasks: 1,
          completedTasks: 3,
          deniedTasks: 0,
          completionRate: 42.86,
          averageCompletionHours: 18.5,
        ),
      ],
      attentionItems: [
        AnalyticsAttentionItem(
          entityType: 'TASK',
          id: 'mock-task-1',
          title: 'Review completed streetlight repair',
          status: 'DONE',
          reason: 'PENDING_REVIEW',
          priorityScore: 3,
          staffId: '44444444-4444-4444-4444-444444444444',
          staffName: 'Test Staff',
          addressText: 'Nguyen Hue, Hai Chau District',
          updatedAt: now,
        ),
      ],
      mapPoints: const [
        AnalyticsMapPoint(
          reportId: '11111111-1111-1111-1111-000000000001',
          title: 'Broken streetlight',
          category: ReportCategory.streetLight,
          status: ReportStatus.inProgress,
          latitude: 16.0602,
          longitude: 108.2148,
          addressText: 'Nguyen Hue, Hai Chau District',
          priorityScore: 4,
          upvoteCount: 4,
        ),
      ],
    );
  }
}

class AnalyticsApiException implements Exception {
  const AnalyticsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
