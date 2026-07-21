import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/routing/app_routes.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import '../data/task_api_service.dart';
import '../domain/task.dart';

class StaffTaskRouteMapScreen extends StatefulWidget {
  StaffTaskRouteMapScreen({
    super.key,
    required this.taskApiService,
    required this.reportApiService,
    RoadRouteService? roadRouteService,
  }) : roadRouteService = roadRouteService ?? OsrmRoadRouteService();

  final TaskApiService taskApiService;
  final ReportApiService reportApiService;
  final RoadRouteService roadRouteService;

  @override
  State<StaffTaskRouteMapScreen> createState() =>
      _StaffTaskRouteMapScreenState();
}

class _StaffTaskRouteMapScreenState extends State<StaffTaskRouteMapScreen> {
  late Future<_RouteSourceData> _routeFuture;
  final TextEditingController _startAddressController = TextEditingController();
  String? _taskId;
  _ResolvedStart? _customStart;
  String? _addressMessage;
  String? _roadRouteKey;
  Future<RoadRouteResult?>? _roadRouteFuture;
  bool _didReadArgs = false;
  bool _isPickingStart = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) {
      return;
    }
    _didReadArgs = true;
    _taskId = ModalRoute.of(context)?.settings.arguments as String?;
    _loadRoute();
  }

  @override
  void dispose() {
    _startAddressController.dispose();
    super.dispose();
  }

  void _loadRoute() {
    final taskId = _taskId;
    _routeFuture = taskId == null
        ? Future<_RouteSourceData>.error(
            const TaskApiException('Task ID is missing.'),
          )
        : _fetchRoute(taskId);
  }

  Future<_RouteSourceData> _fetchRoute(String taskId) async {
    final task = await widget.taskApiService.fetchTask(taskId);
    final reports = task.reportIds.isEmpty
        ? const <Report>[]
        : await Future.wait(
            task.reportIds.map(widget.reportApiService.fetchReport),
          );
    return _RouteSourceData(task: task, reports: reports);
  }

  Future<void> _refresh() async {
    setState(_loadRoute);
    await _routeFuture;
  }

  void _openReport(String reportId) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.staffReportDetail, arguments: reportId);
  }

  void _routeFromAddress(_RouteSourceData data) {
    final value = _startAddressController.text.trim();
    if (value.isEmpty) {
      setState(() {
        _customStart = null;
        _addressMessage = context.l10n.routeUsingTaskAddress;
        _isPickingStart = false;
        _roadRouteKey = null;
        _roadRouteFuture = null;
      });
      return;
    }

    final resolved = _resolveStartAddress(value, data);
    setState(() {
      _customStart = resolved;
      _roadRouteKey = null;
      _roadRouteFuture = null;
      _isPickingStart = false;
      _addressMessage = resolved == null
          ? context.l10n.routeAddressNotFound
          : context.l10n.routeStartsFrom(resolved.label);
    });
  }

  void _useTaskAddress(_RouteSourceData data) {
    _startAddressController.text = data.task.locationLabel;
    setState(() {
      _customStart = null;
      _addressMessage = context.l10n.routeUsingTaskAddress;
      _isPickingStart = false;
    });
  }

  void _toggleStartPicker() {
    setState(() {
      _isPickingStart = !_isPickingStart;
    });
  }

  void _pickStartOnMap(LatLng point) {
    final label =
        '${point.latitude.toStringAsFixed(6)}, '
        '${point.longitude.toStringAsFixed(6)}';
    _startAddressController.text = label;
    setState(() {
      _customStart = _ResolvedStart(label: label, point: point);
      _addressMessage = context.l10n.routeStartsFrom(label);
      _roadRouteKey = null;
      _roadRouteFuture = null;
      _isPickingStart = false;
    });
  }

  void _ensureRoadRoute(_RoutePlan plan) {
    final key = _roadRouteCacheKey(plan.routePoints);
    if (_roadRouteKey == key && _roadRouteFuture != null) {
      return;
    }

    _roadRouteKey = key;
    _roadRouteFuture = widget.roadRouteService
        .fetchRoute(plan.routePoints)
        .then<RoadRouteResult?>((route) => route)
        .catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.l10n.routeMapTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.commonRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_RouteSourceData>(
          future: _routeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _RouteErrorState(onRetry: _refresh);
            }

            final data = snapshot.requireData;
            final plan = _buildRoutePlan(
              data.task,
              data.reports,
              start: _customStart,
            );
            _ensureRoadRoute(plan);
            return FutureBuilder<RoadRouteResult?>(
              future: _roadRouteFuture,
              builder: (context, routeSnapshot) {
                return _RouteMapBody(
                  plan: plan.withRoadRoute(routeSnapshot.data),
                  addressController: _startAddressController,
                  addressMessage: _addressMessage,
                  onRouteFromAddress: () => _routeFromAddress(data),
                  onUseTaskAddress: () => _useTaskAddress(data),
                  isPickingStart: _isPickingStart,
                  onToggleStartPicker: _toggleStartPicker,
                  onPickStart: _pickStartOnMap,
                  onOpenReport: _openReport,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RouteMapBody extends StatelessWidget {
  const _RouteMapBody({
    required this.plan,
    required this.addressController,
    required this.addressMessage,
    required this.onRouteFromAddress,
    required this.onUseTaskAddress,
    required this.isPickingStart,
    required this.onToggleStartPicker,
    required this.onPickStart,
    required this.onOpenReport,
  });

  final _RoutePlan plan;
  final TextEditingController addressController;
  final String? addressMessage;
  final VoidCallback onRouteFromAddress;
  final VoidCallback onUseTaskAddress;
  final bool isPickingStart;
  final VoidCallback onToggleStartPicker;
  final ValueChanged<LatLng> onPickStart;
  final ValueChanged<String> onOpenReport;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _RouteMap(
            plan: plan,
            isPickingStart: isPickingStart,
            onPickStart: onPickStart,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: _RouteStartPanel(
            plan: plan,
            controller: addressController,
            message: addressMessage,
            onRouteFromAddress: onRouteFromAddress,
            onUseTaskAddress: onUseTaskAddress,
            isPickingStart: isPickingStart,
            onToggleStartPicker: onToggleStartPicker,
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _RouteStopPanel(plan: plan, onOpenReport: onOpenReport),
        ),
      ],
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({
    required this.plan,
    required this.isPickingStart,
    required this.onPickStart,
  });

  final _RoutePlan plan;
  final bool isPickingStart;
  final ValueChanged<LatLng> onPickStart;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      key: ValueKey(
        'routeMap-${plan.startPoint.latitude}-${plan.startPoint.longitude}',
      ),
      options: MapOptions(
        initialCenter: _routeCenter(plan.displayRoutePoints),
        initialZoom: _initialZoom(plan.displayRoutePoints),
        minZoom: 4,
        maxZoom: 18,
        onTap: isPickingStart ? (_, point) => onPickStart(point) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.smartcity.report',
        ),
        if (plan.displayRoutePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: plan.displayRoutePoints,
                color: const Color(0xFF0F766E),
                strokeWidth: 5,
              ),
            ],
          ),
        MarkerLayer(markers: _markersForPlan(context, plan)),
      ],
    );
  }
}

class _RouteStartPanel extends StatelessWidget {
  const _RouteStartPanel({
    required this.plan,
    required this.controller,
    required this.message,
    required this.onRouteFromAddress,
    required this.onUseTaskAddress,
    required this.isPickingStart,
    required this.onToggleStartPicker,
  });

  final _RoutePlan plan;
  final TextEditingController controller;
  final String? message;
  final VoidCallback onRouteFromAddress;
  final VoidCallback onUseTaskAddress;
  final bool isPickingStart;
  final VoidCallback onToggleStartPicker;

  @override
  Widget build(BuildContext context) {
    final nearest = plan.orderedReports.isEmpty
        ? null
        : plan.orderedReports.first;

    return Material(
      elevation: 3,
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F3EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.route, color: Color(0xFF0F766E)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nearest == null ? plan.task.title : nearest.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.routeSummary(
                          plan.orderedReports.length,
                          _formatDistance(plan.totalDistanceKm),
                          plan.startLabel,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('staffRouteStartAddressField'),
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onRouteFromAddress(),
              decoration: InputDecoration(
                labelText: context.l10n.routeCurrentAddress,
                hintText: context.l10n.routeAddressHint,
                prefixIcon: const Icon(Icons.my_location_outlined),
                suffixIcon: IconButton(
                  tooltip: context.l10n.routeFromAddress,
                  onPressed: onRouteFromAddress,
                  icon: const Icon(Icons.directions),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onUseTaskAddress,
                  icon: const Icon(Icons.assignment_return_outlined, size: 18),
                  label: Text(context.l10n.routeUseTaskAddress),
                ),
                OutlinedButton.icon(
                  key: const Key('staffRoutePickOnMapButton'),
                  onPressed: onToggleStartPicker,
                  icon: Icon(
                    isPickingStart
                        ? Icons.close
                        : Icons.add_location_alt_outlined,
                    size: 18,
                  ),
                  label: Text(
                    isPickingStart
                        ? context.l10n.commonCancel
                        : context.l10n.routePickOnMap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isPickingStart
                  ? context.l10n.routeTapMapToChooseStart
                  : message ?? context.l10n.routeKnownAddressesHelp,
              key: isPickingStart
                  ? const Key('staffRouteMapPickHint')
                  : null,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isPickingStart
                    ? const Color(0xFF0F766E)
                    : Colors.grey.shade700,
                fontWeight: isPickingStart ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStopPanel extends StatelessWidget {
  const _RouteStopPanel({required this.plan, required this.onOpenReport});

  final _RoutePlan plan;
  final ValueChanged<String> onOpenReport;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 330),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_list_numbered, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.routeVisitOrder,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    _formatDistance(plan.totalDistanceKm),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (plan.orderedReports.isEmpty)
                      Text(context.l10n.routeNoStops)
                    else
                      for (
                        var index = 0;
                        index < plan.orderedReports.length;
                        index++
                      ) ...[
                        _RouteStopTile(
                          number: index + 1,
                          report: plan.orderedReports[index],
                          onTap: () =>
                              onOpenReport(plan.orderedReports[index].id),
                        ),
                        if (index != plan.orderedReports.length - 1)
                          const Divider(height: 1),
                      ],
                    if (plan.directions.isNotEmpty) ...[
                      const Divider(height: 18),
                      Text(
                        context.l10n.routeDirections,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      for (
                        var index = 0;
                        index < math.min(plan.directions.length, 6);
                        index++
                      )
                        _DirectionStepTile(step: plan.directions[index]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteStopTile extends StatelessWidget {
  const _RouteStopTile({
    required this.number,
    required this.report,
    required this.onTap,
  });

  final int number;
  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            _RouteNumberBadge(number: number),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _reportLocationLabel(report),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _DirectionStepTile extends StatelessWidget {
  const _DirectionStepTile({required this.step});

  final RoadRouteStep step;

  @override
  Widget build(BuildContext context) {
    final instruction = localizeRoadRouteInstruction(context, step);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.turn_right, size: 17, color: Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$instruction - ${_formatDistance(step.distanceMeters / 1000)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 13, color: color),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Icon(Icons.location_on, color: color, size: 30),
      ],
    );
  }
}

class _RouteNumberBadge extends StatelessWidget {
  const _RouteNumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF0F766E),
        shape: BoxShape.circle,
      ),
      child: Text(
        number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RouteErrorState extends StatelessWidget {
  const _RouteErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.routeLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class RoadRouteService {
  Future<RoadRouteResult> fetchRoute(List<LatLng> waypoints);
}

class OsrmRoadRouteService implements RoadRouteService {
  OsrmRoadRouteService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<RoadRouteResult> fetchRoute(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      return RoadRouteResult(
        points: waypoints,
        distanceMeters: 0,
        durationSeconds: 0,
        steps: const <RoadRouteStep>[],
      );
    }

    final coordinates = waypoints
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final uri =
        Uri.parse(
          'https://router.project-osrm.org/route/v1/driving/$coordinates',
        ).replace(
          queryParameters: const <String, String>{
            'overview': 'full',
            'geometries': 'geojson',
            'steps': 'true',
          },
        );

    final response = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RouteServiceException('Road route request failed.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['code'] != 'Ok') {
      throw const RouteServiceException('Road route was not found.');
    }

    final routes = decoded['routes'];
    if (routes is! List ||
        routes.isEmpty ||
        routes.first is! Map<String, dynamic>) {
      throw const RouteServiceException('Road route response was empty.');
    }

    final route = routes.first as Map<String, dynamic>;
    return RoadRouteResult(
      points: _parseGeoJsonPoints(route),
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      steps: _parseRouteSteps(route),
    );
  }

  List<LatLng> _parseGeoJsonPoints(Map<String, dynamic> route) {
    final geometry = route['geometry'];
    if (geometry is! Map<String, dynamic>) {
      return const <LatLng>[];
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List) {
      return const <LatLng>[];
    }

    return coordinates
        .whereType<List>()
        .where((point) => point.length >= 2)
        .map(
          (point) => LatLng(
            (point[1] as num).toDouble(),
            (point[0] as num).toDouble(),
          ),
        )
        .toList(growable: false);
  }

  List<RoadRouteStep> _parseRouteSteps(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List) {
      return const <RoadRouteStep>[];
    }

    final steps = <RoadRouteStep>[];
    for (final leg in legs.whereType<Map<String, dynamic>>()) {
      final legSteps = leg['steps'];
      if (legSteps is! List) {
        continue;
      }
      for (final step in legSteps.whereType<Map<String, dynamic>>()) {
        final maneuver = step['maneuver'];
        final maneuverType = maneuver is Map<String, dynamic>
            ? maneuver['type'] as String?
            : null;
        final maneuverModifier = maneuver is Map<String, dynamic>
            ? maneuver['modifier'] as String?
            : null;
        final roadName = (step['name'] as String? ?? '').trim();
        final instruction = _formatOsrmInstruction(
          type: maneuverType,
          modifier: maneuverModifier,
          roadName: roadName,
        );
        if (instruction.isEmpty) {
          continue;
        }
        steps.add(
          RoadRouteStep(
            instruction: instruction,
            distanceMeters: (step['distance'] as num?)?.toDouble() ?? 0,
            maneuverType: maneuverType,
            maneuverModifier: maneuverModifier,
            roadName: roadName.isEmpty ? null : roadName,
          ),
        );
      }
    }
    return steps;
  }

  String _formatOsrmInstruction({
    required String? type,
    required String? modifier,
    required String roadName,
  }) {
    final action = switch (type) {
      'depart' => 'Head out',
      'arrive' => 'Arrive',
      'turn' => 'Turn ${modifier ?? ''}'.trim(),
      'continue' => 'Continue',
      'new name' => 'Continue',
      'merge' => 'Merge ${modifier ?? ''}'.trim(),
      'on ramp' => 'Take the ramp',
      'off ramp' => 'Take the exit',
      'fork' => 'Keep ${modifier ?? ''}'.trim(),
      'roundabout' || 'rotary' => 'Enter the roundabout',
      _ => 'Continue',
    };

    if (roadName.isEmpty || type == 'arrive') {
      return action;
    }
    return '$action onto $roadName';
  }
}

class RoadRouteResult {
  const RoadRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.steps,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final List<RoadRouteStep> steps;
}

class RoadRouteStep {
  const RoadRouteStep({
    required this.instruction,
    required this.distanceMeters,
    this.maneuverType,
    this.maneuverModifier,
    this.roadName,
  });

  final String instruction;
  final double distanceMeters;
  final String? maneuverType;
  final String? maneuverModifier;
  final String? roadName;
}

String localizeRoadRouteInstruction(BuildContext context, RoadRouteStep step) {
  final maneuverType = step.maneuverType?.trim().toLowerCase();
  if (maneuverType == null || maneuverType.isEmpty) {
    return step.instruction;
  }

  final direction = _localizedManeuverDirection(context, step.maneuverModifier);
  final l10n = context.l10n;
  final action = switch (maneuverType) {
    'depart' => l10n.routeManeuverHeadOut,
    'arrive' => l10n.routeManeuverArrive,
    'turn' =>
      direction == null
          ? l10n.routeManeuverTurnGeneric
          : l10n.routeManeuverTurn(direction),
    'continue' || 'new name' => l10n.routeManeuverContinue,
    'merge' =>
      direction == null
          ? l10n.routeManeuverMergeGeneric
          : l10n.routeManeuverMerge(direction),
    'on ramp' => l10n.routeManeuverTakeRamp,
    'off ramp' => l10n.routeManeuverTakeExit,
    'fork' =>
      direction == null
          ? l10n.routeManeuverKeepGeneric
          : l10n.routeManeuverKeep(direction),
    'roundabout' || 'rotary' => l10n.routeManeuverEnterRoundabout,
    _ => l10n.routeManeuverContinue,
  };

  final roadName = step.roadName?.trim() ?? '';
  if (roadName.isEmpty || maneuverType == 'arrive') {
    return action;
  }
  return l10n.routeManeuverOnto(action, roadName);
}

String? _localizedManeuverDirection(BuildContext context, String? modifier) {
  final normalized = modifier?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }

  return switch (normalized) {
    'uturn' || 'u-turn' => context.l10n.routeDirectionUTurn,
    'sharp right' => context.l10n.routeDirectionSharpRight,
    'right' => context.l10n.routeDirectionRight,
    'slight right' => context.l10n.routeDirectionSlightRight,
    'straight' => context.l10n.routeDirectionStraight,
    'slight left' => context.l10n.routeDirectionSlightLeft,
    'left' => context.l10n.routeDirectionLeft,
    'sharp left' => context.l10n.routeDirectionSharpLeft,
    _ => modifier!.trim(),
  };
}

class RouteServiceException implements Exception {
  const RouteServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _RouteSourceData {
  const _RouteSourceData({required this.task, required this.reports});

  final Task task;
  final List<Report> reports;
}

class _ResolvedStart {
  const _ResolvedStart({required this.label, required this.point});

  final String label;
  final LatLng point;
}

class _RoutePlan {
  const _RoutePlan({
    required this.task,
    required this.startLabel,
    required this.startPoint,
    required this.orderedReports,
    required this.routePoints,
    required this.fallbackDistanceKm,
    required this.roadRoute,
  });

  final Task task;
  final String startLabel;
  final LatLng startPoint;
  final List<Report> orderedReports;
  final List<LatLng> routePoints;
  final double fallbackDistanceKm;
  final RoadRouteResult? roadRoute;

  List<LatLng> get displayRoutePoints {
    final points = roadRoute?.points;
    if (points != null && points.length > 1) {
      return points;
    }
    return routePoints;
  }

  double get totalDistanceKm {
    final distanceMeters = roadRoute?.distanceMeters;
    if (distanceMeters != null && distanceMeters > 0) {
      return distanceMeters / 1000;
    }
    return fallbackDistanceKm;
  }

  List<RoadRouteStep> get directions =>
      roadRoute?.steps ?? const <RoadRouteStep>[];

  String get routeModeLabel =>
      roadRoute == null ? 'Direct estimate' : 'Road route';

  _RoutePlan withRoadRoute(RoadRouteResult? nextRoadRoute) {
    return _RoutePlan(
      task: task,
      startLabel: startLabel,
      startPoint: startPoint,
      orderedReports: orderedReports,
      routePoints: routePoints,
      fallbackDistanceKm: fallbackDistanceKm,
      roadRoute: nextRoadRoute,
    );
  }
}

_RoutePlan _buildRoutePlan(
  Task task,
  List<Report> reports, {
  _ResolvedStart? start,
}) {
  final distance = const Distance();
  final startPoint = start?.point ?? LatLng(task.latitude, task.longitude);
  final startLabel = start?.label ?? task.locationLabel;
  final remaining = List<Report>.from(reports);
  final orderedReports = <Report>[];
  var current = startPoint;
  var totalDistanceKm = 0.0;

  while (remaining.isNotEmpty) {
    var nearestIndex = 0;
    var nearestDistanceKm = double.infinity;

    for (var index = 0; index < remaining.length; index++) {
      final report = remaining[index];
      final point = LatLng(report.latitude, report.longitude);
      final distanceKm = distance.as(LengthUnit.Kilometer, current, point);
      if (distanceKm < nearestDistanceKm) {
        nearestDistanceKm = distanceKm;
        nearestIndex = index;
      }
    }

    final nextReport = remaining.removeAt(nearestIndex);
    orderedReports.add(nextReport);
    totalDistanceKm += nearestDistanceKm;
    current = LatLng(nextReport.latitude, nextReport.longitude);
  }

  return _RoutePlan(
    task: task,
    startLabel: startLabel,
    startPoint: startPoint,
    orderedReports: orderedReports,
    routePoints: <LatLng>[
      startPoint,
      for (final report in orderedReports)
        LatLng(report.latitude, report.longitude),
    ],
    fallbackDistanceKm: totalDistanceKm,
    roadRoute: null,
  );
}

_ResolvedStart? _resolveStartAddress(String value, _RouteSourceData data) {
  final coordinate = _parseCoordinate(value);
  if (coordinate != null) {
    return _ResolvedStart(label: value, point: coordinate);
  }

  final normalized = _normalizeAddress(value);
  final candidates = <_ResolvedStart>[
    _ResolvedStart(
      label: data.task.locationLabel,
      point: LatLng(data.task.latitude, data.task.longitude),
    ),
    for (final report in data.reports)
      _ResolvedStart(
        label: _reportLocationLabel(report),
        point: LatLng(report.latitude, report.longitude),
      ),
    for (final report in data.reports)
      _ResolvedStart(
        label: report.title,
        point: LatLng(report.latitude, report.longitude),
      ),
  ];

  for (final candidate in candidates) {
    final candidateText = _normalizeAddress(candidate.label);
    if (candidateText == normalized ||
        candidateText.contains(normalized) ||
        normalized.contains(candidateText)) {
      return candidate;
    }
  }

  return null;
}

LatLng? _parseCoordinate(String value) {
  final pieces = value.split(',');
  if (pieces.length != 2) {
    return null;
  }

  final latitude = double.tryParse(pieces[0].trim());
  final longitude = double.tryParse(pieces[1].trim());
  if (latitude == null || longitude == null) {
    return null;
  }
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    return null;
  }
  return LatLng(latitude, longitude);
}

String _normalizeAddress(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

String _roadRouteCacheKey(List<LatLng> points) {
  return points
      .map(
        (point) =>
            '${point.latitude.toStringAsFixed(6)},${point.longitude.toStringAsFixed(6)}',
      )
      .join('|');
}

List<Marker> _markersForPlan(BuildContext context, _RoutePlan plan) {
  return <Marker>[
    Marker(
      point: plan.startPoint,
      width: 96,
      height: 72,
      child: _RouteMarker(
        label: context.l10n.routeStartMarker,
        color: const Color(0xFF2563EB),
        icon: Icons.navigation,
      ),
    ),
    for (var index = 0; index < plan.orderedReports.length; index++)
      Marker(
        point: LatLng(
          plan.orderedReports[index].latitude,
          plan.orderedReports[index].longitude,
        ),
        width: 84,
        height: 72,
        child: _RouteMarker(
          label: '${index + 1}',
          color: const Color(0xFF0F766E),
          icon: Icons.report_outlined,
        ),
      ),
  ];
}

LatLng _routeCenter(List<LatLng> points) {
  if (points.isEmpty) {
    return LatLng(10.7769, 106.7009);
  }

  final lat = points.fold<double>(0, (total, point) => total + point.latitude);
  final lng = points.fold<double>(0, (total, point) => total + point.longitude);
  return LatLng(lat / points.length, lng / points.length);
}

double _initialZoom(List<LatLng> points) {
  if (points.length <= 1) {
    return 15.5;
  }

  final bounds = _RouteBounds.fromPoints(points);
  final maxDelta = math.max(
    bounds.maxLatitude - bounds.minLatitude,
    bounds.maxLongitude - bounds.minLongitude,
  );

  if (maxDelta < 0.006) {
    return 16;
  }
  if (maxDelta < 0.02) {
    return 14;
  }
  if (maxDelta < 0.08) {
    return 12;
  }
  return 10;
}

String _formatDistance(double kilometers) {
  if (kilometers < 1) {
    return '${(kilometers * 1000).round()} m';
  }
  return '${kilometers.toStringAsFixed(1)} km';
}

String _reportLocationLabel(Report report) {
  final address = report.addressText?.trim();
  if (address != null && address.isNotEmpty) {
    return address;
  }
  return '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}';
}

class _RouteBounds {
  const _RouteBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  factory _RouteBounds.fromPoints(List<LatLng> points) {
    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      minLatitude = math.min(minLatitude, point.latitude);
      maxLatitude = math.max(maxLatitude, point.latitude);
      minLongitude = math.min(minLongitude, point.longitude);
      maxLongitude = math.max(maxLongitude, point.longitude);
    }

    return _RouteBounds(
      minLatitude: minLatitude,
      maxLatitude: maxLatitude,
      minLongitude: minLongitude,
      maxLongitude: maxLongitude,
    );
  }
}
