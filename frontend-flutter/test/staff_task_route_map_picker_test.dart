import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/tasks/data/task_api_service.dart';
import 'package:smart_city_report_frontend/src/features/tasks/presentation/staff_task_route_map_screen.dart';

void main() {
  const viewports = <String, Size>{
    'mobile': Size(390, 800),
    'web': Size(1200, 800),
  };

  for (final entry in viewports.entries) {
    testWidgets('staff picks the route start on ${entry.key}', (tester) async {
      tester.view.physicalSize = entry.value;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final roadRouteService = _RecordingRoadRouteService();
      await tester.pumpWidget(_routeHarness(roadRouteService));

      await tester.tap(find.byKey(const Key('openStaffRoute')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('staffRoutePickOnMapButton')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('staffRoutePickOnMapButton')));
      await tester.pump();

      expect(find.byKey(const Key('staffRouteMapPickHint')), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.options.onTap, isNotNull);

      final selectedPoint = LatLng(10.775, 106.705);
      map.options.onTap!(
        const TapPosition(Offset.zero, Offset.zero),
        selectedPoint,
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const Key('staffRouteStartAddressField')),
      );
      expect(field.controller?.text, '10.775000, 106.705000');
      expect(find.byKey(const Key('staffRouteMapPickHint')), findsNothing);
      expect(find.text('Pick on map'), findsOneWidget);
      expect(roadRouteService.waypointCalls.last.first.latitude, 10.775);
      expect(roadRouteService.waypointCalls.last.first.longitude, 106.705);
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _routeHarness(RoadRouteService roadRouteService) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            key: const Key('openStaffRoute'),
            onPressed: () => Navigator.of(context).pushNamed(
              '/staff-route',
              arguments: '33333333-3333-3333-3333-000000000001',
            ),
            child: const Text('Open route'),
          ),
        ),
      ),
    ),
    onGenerateRoute: (settings) {
      if (settings.name != '/staff-route') {
        return null;
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => StaffTaskRouteMapScreen(
          taskApiService: MockTaskApiService(),
          reportApiService: MockReportApiService(),
          roadRouteService: roadRouteService,
        ),
      );
    },
  );
}

class _RecordingRoadRouteService implements RoadRouteService {
  final List<List<LatLng>> waypointCalls = <List<LatLng>>[];

  @override
  Future<RoadRouteResult> fetchRoute(List<LatLng> waypoints) async {
    waypointCalls.add(List<LatLng>.from(waypoints));
    return RoadRouteResult(
      points: List<LatLng>.from(waypoints),
      distanceMeters: 1200,
      durationSeconds: 300,
      steps: const <RoadRouteStep>[],
    );
  }
}
