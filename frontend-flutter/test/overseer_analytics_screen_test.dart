import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/core/routing/app_routes.dart';
import 'package:smart_city_report_frontend/src/features/analytics/data/analytics_api_service.dart';
import 'package:smart_city_report_frontend/src/features/analytics/domain/overseer_analytics.dart';
import 'package:smart_city_report_frontend/src/features/analytics/presentation/overseer_analytics_screen.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';
import 'package:smart_city_report_frontend/src/features/users/data/user_api_service.dart';
import 'package:smart_city_report_frontend/src/features/users/domain/app_user.dart';

void main() {
  testWidgets('renders full analytics and applies area filter', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final analyticsApi = _RecordingAnalyticsApi();

    await tester.pumpWidget(_analyticsApp(analyticsApi));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('overseerAnalyticsDashboard')), findsOneWidget);
    expect(find.text('City analytics'), findsOneWidget);
    expect(find.text('Total reports'), findsOneWidget);
    expect(find.text('Operational trend'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('analyticsAreaFilter')),
      'District 1',
    );
    await tester.tap(find.byKey(const Key('analyticsApplyFilters')));
    await tester.pumpAndSettle();

    expect(analyticsApi.lastQuery?.area, 'District 1');
    expect(analyticsApi.requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attention and staff rows navigate to detail routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_analyticsApp(_RecordingAnalyticsApi()));
    await tester.pumpAndSettle();

    final attention = find.byKey(const Key('analyticsAttention-task-1')).first;
    await tester.ensureVisible(attention);
    await tester.pumpAndSettle();
    await tester.tap(attention);
    await tester.pumpAndSettle();
    expect(find.text('Opened task task-1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final staff = find.text('Analytics Staff').last;
    await tester.ensureVisible(staff);
    await tester.pumpAndSettle();
    await tester.tap(staff);
    await tester.pumpAndSettle();
    expect(find.text('Opened staff staff-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _analyticsApp(AnalyticsApiService analyticsApi) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: OverseerAnalyticsScreen(
      analyticsApiService: analyticsApi,
      userApiService: _AnalyticsUserApi(),
    ),
    onGenerateRoute: (settings) {
      if (settings.name == AppRoutes.overseerTaskDetail) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              Scaffold(body: Text('Opened task ${settings.arguments}')),
        );
      }
      if (settings.name == AppRoutes.overseerReportDetail) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              Scaffold(body: Text('Opened report ${settings.arguments}')),
        );
      }
      if (settings.name == AppRoutes.overseerStaffProfile) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              Scaffold(body: Text('Opened staff ${settings.arguments}')),
        );
      }
      return null;
    },
  );
}

class _RecordingAnalyticsApi implements AnalyticsApiService {
  int requests = 0;
  AnalyticsQuery? lastQuery;

  @override
  Future<OverseerAnalytics> fetchOverseerAnalytics(AnalyticsQuery query) async {
    requests++;
    lastQuery = query;
    return _analyticsFixture;
  }
}

class _AnalyticsUserApi extends MockUserApiService {
  @override
  Future<List<AppUser>> fetchStaffUsers() async {
    return const [
      AppUser(
        id: 'staff-1',
        fullName: 'Analytics Staff',
        email: 'staff@test.com',
        role: UserRole.staff,
      ),
    ];
  }
}

final _analyticsFixture = OverseerAnalytics(
  generatedAt: DateTime.utc(2026, 7, 22, 8),
  filters: AppliedAnalyticsFilters(
    from: DateTime.utc(2026, 7, 1),
    to: DateTime.utc(2026, 7, 22),
    category: null,
    staffId: null,
    area: null,
  ),
  reports: const ReportAnalyticsOverview(
    totalReports: 4,
    byStatus: {
      ReportStatus.submitted: 1,
      ReportStatus.inProgress: 2,
      ReportStatus.fixed: 1,
      ReportStatus.cancelled: 0,
    },
    totalUpvotes: 8,
    averagePriority: 2,
    fixedRate: 25,
    cancellationRate: 0,
  ),
  tasks: const TaskAnalyticsOverview(
    totalTasks: 3,
    byStatus: {
      TaskStatus.newTask: 0,
      TaskStatus.assigned: 0,
      TaskStatus.inProgress: 2,
      TaskStatus.done: 1,
      TaskStatus.pendingReview: 0,
      TaskStatus.denied: 0,
      TaskStatus.approved: 0,
      TaskStatus.closed: 0,
      TaskStatus.cancelled: 0,
    },
    unassignedTasks: 0,
    activeTasks: 2,
    pendingReviewTasks: 1,
    completedTasks: 1,
    completionRate: 33.33,
    averageWorkHours: 12,
    averageReviewHours: 2,
    averageResolutionHours: 30,
  ),
  trends: [
    AnalyticsTrendPoint(
      periodStart: DateTime.utc(2026, 7, 21),
      reportsCreated: 2,
      reportsFixed: 1,
      tasksCreated: 1,
      tasksClosed: 0,
    ),
  ],
  categories: const [
    CategoryAnalytics(
      category: ReportCategory.roadDamage,
      reports: 4,
      fixedReports: 1,
      tasks: 3,
      closedTasks: 0,
    ),
  ],
  staffWorkloads: const [
    StaffWorkloadAnalytics(
      staffId: 'staff-1',
      fullName: 'Analytics Staff',
      email: 'staff@test.com',
      activeAccount: true,
      totalTasks: 3,
      activeTasks: 2,
      pendingReviewTasks: 1,
      completedTasks: 1,
      deniedTasks: 0,
      completionRate: 33.33,
      averageCompletionHours: 12,
    ),
  ],
  attentionItems: [
    AnalyticsAttentionItem(
      entityType: 'TASK',
      id: 'task-1',
      title: 'Review repair',
      status: 'DONE',
      reason: 'PENDING_REVIEW',
      priorityScore: 3,
      staffId: 'staff-1',
      staffName: 'Analytics Staff',
      addressText: 'District 1',
      updatedAt: DateTime.utc(2026, 7, 22),
    ),
  ],
  mapPoints: const [],
);
