import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/core/routing/app_routes.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/reports/presentation/citizen_report_detail_screen.dart';
import 'package:smart_city_report_frontend/src/features/users/data/user_api_service.dart';
import 'package:smart_city_report_frontend/src/features/users/domain/app_user.dart';
import 'package:smart_city_report_frontend/src/features/users/presentation/staff_public_profile_screen.dart';

void main() {
  testWidgets('fixed citizen report shows its assigned staff on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('openAssignedReport'),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed('/report', arguments: 'report-1'),
                child: const Text('Open report'),
              ),
            ),
          ),
        ),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.staffPublicProfile) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => StaffPublicProfileScreen(
                userApiService: _AssignedStaffApiService(),
              ),
            );
          }
          if (settings.name != '/report') {
            return null;
          }
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => CitizenReportDetailScreen(
              reportApiService: _AssignedReportApiService(),
            ),
          );
        },
      ),
    );

    await tester.tap(find.byKey(const Key('openAssignedReport')));
    await tester.pumpAndSettle();

    expect(find.text('Fixed'), findsWidgets);
    expect(find.text('Assigned staff'), findsOneWidget);
    expect(find.text('Demo Staff'), findsOneWidget);
    expect(
      find.text('A staff member has not been assigned yet.'),
      findsNothing,
    );

    await tester.ensureVisible(
      find.byKey(const Key('assignedStaffProfileButton')),
    );
    await tester.tap(find.byKey(const Key('assignedStaffProfileButton')));
    await tester.pumpAndSettle();

    expect(find.text('Staff profile'), findsOneWidget);
    expect(find.text('Demo Staff'), findsOneWidget);
    expect(find.text('demo.staff@test.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _AssignedStaffApiService extends MockUserApiService {
  @override
  Future<StaffPublicProfile> fetchStaffPublicProfile(String staffId) async {
    return StaffPublicProfile(
      id: staffId,
      fullName: 'Demo Staff',
      email: 'demo.staff@test.com',
      role: UserRole.staff,
      active: true,
      createdAt: DateTime.utc(2026, 6, 1),
    );
  }
}

class _AssignedReportApiService extends MockReportApiService {
  @override
  Future<Report> fetchReport(String id) async {
    return Report(
      id: id,
      title: 'Fixed streetlight',
      description: 'The light is working again.',
      category: ReportCategory.streetLight,
      status: ReportStatus.fixed,
      latitude: 10.7769,
      longitude: 106.7009,
      addressText: 'Nguyen Hue',
      beforePhotoUrl: '/uploads/report-before/light.jpg',
      afterPhotoUrl: '/uploads/report-after/light.jpg',
      anonymous: false,
      upvoteCount: 3,
      priorityScore: 3,
      createdAt: DateTime.utc(2026, 7, 20, 8),
      updatedAt: DateTime.utc(2026, 7, 21, 8),
      createdBy: const ReportUserSummary(
        id: 'citizen-1',
        fullName: 'Demo Citizen',
        role: 'CITIZEN',
      ),
      assignedStaff: const ReportUserSummary(
        id: 'staff-1',
        fullName: 'Demo Staff',
        role: 'STAFF',
      ),
    );
  }
}
