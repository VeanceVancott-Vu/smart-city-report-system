import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/core/routing/app_routes.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/overseer/presentation/overseer_report_detail_screen.dart';
import 'package:smart_city_report_frontend/src/features/overseer/presentation/overseer_task_detail_screen.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/tasks/data/task_api_service.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';
import 'package:smart_city_report_frontend/src/features/users/data/user_api_service.dart';
import 'package:smart_city_report_frontend/src/features/users/domain/app_user.dart';
import 'package:smart_city_report_frontend/src/features/users/presentation/overseer_staff_list_screen.dart';
import 'package:smart_city_report_frontend/src/features/users/presentation/overseer_staff_profile_screen.dart';

void main() {
  testWidgets('staff list opens the detailed staff profile page', (
    tester,
  ) async {
    _useLargeTestWindow(tester);
    final userApi = _OverseerUserApi();

    await tester.pumpWidget(
      _localizedApp(
        home: OverseerStaffListScreen(userApiService: userApi),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.overseerStaffProfile) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) =>
                  OverseerStaffProfileScreen(userApiService: userApi),
            );
          }
          return null;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExpansionTile), findsNothing);
    await tester.tap(find.text('Detailed Staff'));
    await tester.pumpAndSettle();

    expect(userApi.requestedDetailStaffId, 'staff-1');
    expect(find.text('Staff profile'), findsOneWidget);
    expect(find.text('staff@test.com'), findsOneWidget);
    expect(find.text('Task summary'), findsOneWidget);
    expect(find.text('Assigned task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('task assigned staff opens the staff profile route', (
    tester,
  ) async {
    _useLargeTestWindow(tester);
    await tester.pumpWidget(
      _detailHarness(
        openLabel: 'Open task',
        detailBuilder: (_) => OverseerTaskDetailScreen(
          taskApiService: _AssignedTaskApi(),
          reportApiService: _AssignedReportApi(),
        ),
      ),
    );

    await tester.tap(find.text('Open task'));
    await tester.pumpAndSettle();
    final staffButton = find.byKey(
      const Key('overseerTaskAssignedStaffProfileButton'),
    );
    await tester.scrollUntilVisible(staffButton, 200);
    await tester.tap(staffButton);
    await tester.pumpAndSettle();

    expect(find.text('Opened staff profile: staff-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report assigned staff opens the staff profile route', (
    tester,
  ) async {
    _useLargeTestWindow(tester);
    await tester.pumpWidget(
      _detailHarness(
        openLabel: 'Open report',
        detailBuilder: (_) =>
            OverseerReportDetailScreen(reportApiService: _AssignedReportApi()),
      ),
    );

    await tester.tap(find.text('Open report'));
    await tester.pumpAndSettle();
    final staffButton = find.byKey(
      const Key('overseerReportAssignedStaffProfileButton'),
    );
    await tester.scrollUntilVisible(staffButton, 200);
    await tester.tap(staffButton);
    await tester.pumpAndSettle();

    expect(find.text('Opened staff profile: staff-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _useLargeTestWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1100, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _localizedApp({
  required Widget home,
  Route<dynamic>? Function(RouteSettings)? onGenerateRoute,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
    onGenerateRoute: onGenerateRoute,
  );
}

Widget _detailHarness({
  required String openLabel,
  required WidgetBuilder detailBuilder,
}) {
  return _localizedApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(arguments: 'detail-1'),
                builder: detailBuilder,
              ),
            ),
            child: Text(openLabel),
          ),
        ),
      ),
    ),
    onGenerateRoute: (settings) {
      if (settings.name == AppRoutes.overseerStaffProfile) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Opened staff profile: ${settings.arguments}'),
            ),
          ),
        );
      }
      return null;
    },
  );
}

class _OverseerUserApi extends MockUserApiService {
  String? requestedDetailStaffId;

  @override
  Future<List<StaffSummary>> fetchStaffSummary() async {
    return [
      StaffSummary(
        id: 'staff-1',
        fullName: 'Detailed Staff',
        email: 'staff@test.com',
        active: true,
        activeTasksCount: 1,
        completedTasksCount: 0,
        tasks: [_assignedTask],
      ),
    ];
  }

  @override
  Future<StaffDetailProfile> fetchStaffDetailProfile(String staffId) async {
    requestedDetailStaffId = staffId;
    return StaffDetailProfile(
      id: staffId,
      fullName: 'Detailed Staff',
      email: 'staff@test.com',
      role: UserRole.staff,
      active: true,
      createdAt: DateTime.utc(2026, 6, 1),
      taskAnalytics: const StaffTaskAnalytics(
        totalTasks: 1,
        byStatus: {TaskStatus.assigned: 1},
      ),
      tasks: [_assignedTask],
    );
  }
}

class _AssignedTaskApi extends MockTaskApiService {
  @override
  Future<Task> fetchTask(String id) async => _assignedTask;
}

class _AssignedReportApi extends MockReportApiService {
  @override
  Future<Report> fetchReport(String id) async => _assignedReport;
}

final _assignedTask = Task(
  id: 'task-1',
  title: 'Assigned task',
  description: 'Repair the reported issue.',
  category: ReportCategory.roadDamage,
  status: TaskStatus.assigned,
  latitude: 10.7769,
  longitude: 106.7009,
  addressText: 'District 1',
  priorityScore: 2,
  assignedStaff: _staffSummary,
  createdByOverseer: const ReportUserSummary(
    id: 'overseer-1',
    fullName: 'Demo Overseer',
    role: 'OVERSEER',
  ),
  staffNote: null,
  aiConfidenceScore: null,
  aiDecision: null,
  startedAt: null,
  submittedAt: null,
  reviewedAt: null,
  closedAt: null,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 1),
  reportIds: const [],
);

final _assignedReport = Report(
  id: 'report-1',
  title: 'Assigned report',
  description: 'A report assigned to staff.',
  category: ReportCategory.roadDamage,
  status: ReportStatus.submitted,
  latitude: 10.7769,
  longitude: 106.7009,
  addressText: 'District 1',
  beforePhotoUrl: null,
  anonymous: false,
  upvoteCount: 0,
  priorityScore: 0,
  createdAt: DateTime.utc(2026, 7, 1),
  updatedAt: DateTime.utc(2026, 7, 1),
  createdBy: const ReportUserSummary(
    id: 'citizen-1',
    fullName: 'Demo Citizen',
    role: 'CITIZEN',
  ),
  assignedStaff: _staffSummary,
);

const _staffSummary = ReportUserSummary(
  id: 'staff-1',
  fullName: 'Detailed Staff',
  role: 'STAFF',
);
