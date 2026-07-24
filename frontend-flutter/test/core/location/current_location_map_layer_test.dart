import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/core/location/current_location_map_layer.dart';

void main() {
  testWidgets('shows direction and centers the map on the first location', (
    tester,
  ) async {
    final mapController = MapController();
    final position = Position(
      longitude: 108.2022,
      latitude: 16.0544,
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
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(10.7769, 106.7009),
            initialZoom: 15,
          ),
          children: [
            CurrentLocationMapLayer(
              mapController: mapController,
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
    expect(mapController.camera.center.latitude, closeTo(16.0544, 0.000001));
    expect(mapController.camera.center.longitude, closeTo(108.2022, 0.000001));
    expect(mapController.camera.zoom, 15.5);
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

  testWidgets('does not re-center map on widget rebuild if already centered', (
    tester,
  ) async {
    final mapController = MapController();
    final position = Position(
      longitude: 108.2022,
      latitude: 16.0544,
      timestamp: DateTime(2026),
      accuracy: 4,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    // Initial render - map centers on user location
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(10.7769, 106.7009),
            initialZoom: 15,
          ),
          children: [
            CurrentLocationMapLayer(
              mapController: mapController,
              requestPermission: () async => true,
              positionStream: () => Stream<Position>.value(position),
              headingStream: Stream<double?>.value(90),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // User drags map to a new location (e.g. 16.10, 108.25)
    const newCenter = LatLng(16.10, 108.25);
    mapController.move(newCenter, 14.0);
    await tester.pump();

    expect(mapController.camera.center.latitude, closeTo(16.10, 0.000001));

    // Rebuild layer tree (simulating parent setState / reload)
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FlutterMap(
          mapController: mapController,
          options: const MapOptions(
            initialCenter: LatLng(10.7769, 106.7009),
            initialZoom: 15,
          ),
          children: [
            CurrentLocationMapLayer(
              key: UniqueKey(), // new key forces state recreation
              mapController: mapController,
              requestPermission: () async => true,
              positionStream: () => Stream<Position>.value(position),
              headingStream: Stream<double?>.value(90),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    // Verify map center remains at user's dragged position (16.10, 108.25)
    expect(mapController.camera.center.latitude, closeTo(16.10, 0.000001));
    expect(mapController.camera.center.longitude, closeTo(108.25, 0.000001));
  });
}
