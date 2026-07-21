import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/core/location/geocoding_service.dart';
import 'package:smart_city_report_frontend/src/features/auth/data/auth_api_service.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/auth_session.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/map/presentation/overseer_map_screen.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';

void main() {
  testWidgets('mobile overseer selected pin actions wrap without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OverseerMapScreen(
            reportApiService: MockReportApiService(),
            authApiService: _SignedOutAuthApiService(),
            geocodingService: _FakeGeocodingService(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    final submittedPin = find.byKey(
      const ValueKey<String>(
        'overseerMapPin-11111111-1111-1111-1111-000000000004',
      ),
    );
    expect(submittedPin, findsOneWidget);
    tester.widget<GestureDetector>(submittedPin).onTap!();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(find.text('View full details'), findsOneWidget);
    expect(find.text('Mark fixed'), findsOneWidget);
    expect(find.text('Create task'), findsOneWidget);
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

class _FakeGeocodingService implements GeocodingService {
  @override
  Future<PlaceSearchResult?> reverseGeocode({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async => null;

  @override
  Future<List<PlaceSearchResult>> searchPlaces({
    required String query,
    required String languageCode,
  }) async => const <PlaceSearchResult>[];
}
