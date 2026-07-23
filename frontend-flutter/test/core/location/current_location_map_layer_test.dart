import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/core/location/current_location_map_layer.dart';

void main() {
  testWidgets('shows current location with compass direction', (tester) async {
    final position = Position(
      longitude: 106.7009,
      latitude: 10.7769,
      timestamp: DateTime(2026),
      accuracy: 4,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(10.7769, 106.7009),
            initialZoom: 15,
          ),
          children: [
            CurrentLocationMapLayer(
              requestPermission: () async => true,
              positionStream: () => Stream<Position>.value(position),
              headingStream: Stream<double?>.value(90),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('currentLocationMarker')), findsOneWidget);
    expect(find.byKey(const Key('currentLocationDirection')), findsOneWidget);
  });

  testWidgets('does not show a marker when location permission is denied', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(10.7769, 106.7009),
            initialZoom: 15,
          ),
          children: [
            CurrentLocationMapLayer(
              requestPermission: () async => false,
              positionStream: () => const Stream<Position>.empty(),
              headingStream: const Stream<double?>.empty(),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('currentLocationMarker')), findsNothing);
  });
}
