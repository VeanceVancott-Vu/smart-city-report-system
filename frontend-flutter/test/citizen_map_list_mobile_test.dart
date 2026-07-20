import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/features/auth/data/auth_api_service.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/auth_session.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/presentation/citizen_map_screen.dart';

void main() {
  testWidgets('mobile map list lays out report cards', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CitizenMapScreen(
          reportApiService: MockReportApiService(),
          authApiService: _SignedOutAuthApiService(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.view_list_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(find.text('Broken streetlight near Nguyen Hue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _SignedOutAuthApiService implements AuthApiService {
  @override
  Future<CurrentUser?> getCurrentUser() async => null;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}
