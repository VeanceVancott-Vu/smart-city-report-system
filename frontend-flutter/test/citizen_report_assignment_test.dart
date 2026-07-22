import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/reports/presentation/citizen_report_detail_screen.dart';

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
    expect(tester.takeException(), isNull);
  });
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
