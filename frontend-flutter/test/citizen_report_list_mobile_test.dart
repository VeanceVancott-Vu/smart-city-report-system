import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/presentation/citizen_report_list_screen.dart';

void main() {
  testWidgets('mobile citizen list can clear a selected status chip', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CitizenReportListScreen(reportApiService: MockReportApiService()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Broken streetlight near Nguyen Hue'), findsOneWidget);

    final inProgressChip = find.text('In progress');

    await tester.ensureVisible(inProgressChip);
    await tester.pumpAndSettle();
    await tester.tap(inProgressChip);
    await tester.pumpAndSettle();

    expect(find.text('No matching reports'), findsOneWidget);

    await tester.ensureVisible(inProgressChip);
    await tester.pumpAndSettle();
    await tester.tap(inProgressChip);
    await tester.pumpAndSettle();

    expect(find.text('No matching reports'), findsNothing);
    expect(find.text('Broken streetlight near Nguyen Hue'), findsOneWidget);
  });
}
