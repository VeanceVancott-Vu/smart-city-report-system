import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/core/location/geocoding_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/presentation/citizen_report_map_picker.dart';

void main() {
  testWidgets('citizen map picker opens at mobile width', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CitizenReportMapPicker(
          reportApiService: MockReportApiService(),
          geocodingService: _FakeGeocodingService(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(find.text('Confirm location'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
