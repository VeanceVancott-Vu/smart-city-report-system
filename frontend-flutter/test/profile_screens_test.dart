import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';
import 'package:smart_city_report_frontend/src/features/users/data/user_api_service.dart';
import 'package:smart_city_report_frontend/src/features/users/domain/app_user.dart';
import 'package:smart_city_report_frontend/src/features/users/presentation/my_profile_screen.dart';
import 'package:smart_city_report_frontend/src/features/users/presentation/staff_public_profile_screen.dart';

void main() {
  testWidgets('citizen profile displays report counts by status', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = _ProfileApiService(
      profile: UserProfile(
        id: 'citizen-1',
        fullName: 'Demo Citizen',
        email: 'citizen@test.com',
        role: UserRole.citizen,
        active: true,
        createdAt: DateTime.utc(2026, 6, 1),
        citizenReportAnalytics: const CitizenReportAnalytics(
          totalReports: 4,
          byStatus: {
            ReportStatus.submitted: 2,
            ReportStatus.inProgress: 1,
            ReportStatus.fixed: 1,
            ReportStatus.cancelled: 0,
          },
        ),
        staffTaskAnalytics: null,
      ),
    );

    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('Demo Citizen'), findsOneWidget);
    expect(find.text('Report summary'), findsOneWidget);
    expect(find.text('Total reports'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Fixed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('staff profile displays counts for task statuses', (
    tester,
  ) async {
    final service = _ProfileApiService(
      profile: UserProfile(
        id: 'staff-1',
        fullName: 'Demo Staff',
        email: 'staff@test.com',
        role: UserRole.staff,
        active: true,
        createdAt: DateTime.utc(2026, 6, 1),
        citizenReportAnalytics: null,
        staffTaskAnalytics: const StaffTaskAnalytics(
          totalTasks: 3,
          byStatus: {
            TaskStatus.assigned: 1,
            TaskStatus.inProgress: 1,
            TaskStatus.denied: 1,
          },
        ),
      ),
    );

    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    expect(find.text('Task summary'), findsOneWidget);
    expect(find.text('Total assigned tasks'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('Denied'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overseer profile keeps analytics on a separate page', (
    tester,
  ) async {
    final service = _ProfileApiService(
      profile: const UserProfile(
        id: 'overseer-1',
        fullName: 'Demo Overseer',
        email: 'overseer@test.com',
        role: UserRole.overseer,
        active: true,
        createdAt: null,
        citizenReportAnalytics: null,
        staffTaskAnalytics: null,
      ),
    );

    await tester.pumpWidget(_profileApp(service));
    await tester.pumpAndSettle();

    expect(find.text('Demo Overseer'), findsOneWidget);
    expect(
      find.text(
        'A complete overseer analytics dashboard will be available on its own page.',
      ),
      findsOneWidget,
    );
    expect(find.text('Report summary'), findsNothing);
    expect(find.text('Task summary'), findsNothing);
  });

  testWidgets('public staff profile displays basic information', (
    tester,
  ) async {
    final service = _ProfileApiService(
      profile: const UserProfile(
        id: 'citizen-1',
        fullName: 'Demo Citizen',
        email: 'citizen@test.com',
        role: UserRole.citizen,
        active: true,
        createdAt: null,
        citizenReportAnalytics: null,
        staffTaskAnalytics: null,
      ),
    );

    await tester.pumpWidget(_publicStaffApp(service));
    await tester.tap(find.text('Open staff'));
    await tester.pumpAndSettle();

    expect(find.text('Staff profile'), findsOneWidget);
    expect(find.text('Demo Staff'), findsOneWidget);
    expect(find.text('staff@test.com'), findsOneWidget);
    expect(find.text('Account status'), findsOneWidget);
  });
}

Widget _profileApp(UserApiService service) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MyProfileScreen(userApiService: service),
  );
}

Widget _publicStaffApp(UserApiService service) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                settings: const RouteSettings(arguments: 'staff-1'),
                builder: (_) =>
                    StaffPublicProfileScreen(userApiService: service),
              ),
            ),
            child: const Text('Open staff'),
          ),
        ),
      ),
    ),
  );
}

class _ProfileApiService extends MockUserApiService {
  _ProfileApiService({required this.profile});

  final UserProfile profile;

  @override
  Future<UserProfile> fetchMyProfile() async => profile;

  @override
  Future<StaffPublicProfile> fetchStaffPublicProfile(String staffId) async {
    return StaffPublicProfile(
      id: staffId,
      fullName: 'Demo Staff',
      email: 'staff@test.com',
      role: UserRole.staff,
      active: true,
      createdAt: DateTime.utc(2026, 6, 1),
    );
  }
}
