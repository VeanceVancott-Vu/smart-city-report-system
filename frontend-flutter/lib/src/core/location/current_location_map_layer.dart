import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../localization/app_localizations_extension.dart';

typedef LocationPermissionRequest = Future<bool> Function();
typedef PositionStreamFactory = Stream<Position> Function();

class CurrentLocationMapLayer extends StatefulWidget {
  const CurrentLocationMapLayer({
    super.key,
    this.mapController,
    this.initialZoom = 15.5,
    this.onLocationChanged,
    this.requestPermission,
    this.positionStream,
    this.headingStream,
  });

  final MapController? mapController;
  final double initialZoom;
  final ValueChanged<LatLng>? onLocationChanged;
  final LocationPermissionRequest? requestPermission;
  final PositionStreamFactory? positionStream;
  final Stream<double?>? headingStream;

  @override
  State<CurrentLocationMapLayer> createState() =>
      _CurrentLocationMapLayerState();
}

class _CurrentLocationMapLayerState extends State<CurrentLocationMapLayer> {
  static final Set<MapController> _centeredControllers = <MapController>{};

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<double?>? _headingSubscription;

  Position? _position;
  double? _compassHeading;
  double? _movementHeading;
  bool _didCenterMap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_startTracking());
      }
    });
  }

  Future<void> _startTracking() async {
    try {
      final canTrack =
          await (widget.requestPermission?.call() ??
              _requestLocationPermission());
      if (!mounted || !canTrack) {
        return;
      }

      final headingStream = widget.headingStream ?? _deviceHeadingStream();
      _headingSubscription = headingStream?.listen(
        _onHeadingChanged,
        onError: (_) {},
      );

      final positionStream =
          widget.positionStream?.call() ?? _devicePositionStream();
      _positionSubscription = positionStream.listen(
        _onPositionChanged,
        onError: (_) {},
      );
    } on Object {
      // The map remains usable when location services are unavailable.
    }
  }

  Future<bool> _requestLocationPermission() async {
    if (kIsWeb) {
      // On web, reading the position triggers the browser permission prompt.
      return true;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Stream<Position> _devicePositionStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Stream<double?>? _deviceHeadingStream() {
    return FlutterCompass.events?.map((event) => event.heading);
  }

  void _onPositionChanged(Position position) {
    if (!mounted) {
      return;
    }

    final location = LatLng(position.latitude, position.longitude);
    final movementHeading = position.speed > 0.5
        ? _normalizedHeading(position.heading)
        : null;
    setState(() {
      _position = position;
      _movementHeading = movementHeading;
    });
    widget.onLocationChanged?.call(location);
    _centerMapOnFirstFix(location);
  }

  void _centerMapOnFirstFix(LatLng location) {
    final mapController = widget.mapController;
    if (_didCenterMap || mapController == null || _centeredControllers.contains(mapController)) {
      return;
    }

    try {
      mapController.move(location, widget.initialZoom);
      _didCenterMap = true;
      _centeredControllers.add(mapController);
    } on Object {
      // A later position update retries if the map is not attached yet.
    }
  }

  void _onHeadingChanged(double? heading) {
    if (!mounted) {
      return;
    }

    final normalized = _normalizedHeading(heading);
    if (normalized == _compassHeading) {
      return;
    }

    setState(() => _compassHeading = normalized);
  }

  double? _normalizedHeading(double? heading) {
    if (heading == null || !heading.isFinite || heading < 0) {
      return null;
    }
    return heading % 360;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _headingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    if (position == null) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 64,
          height: 64,
          child: IgnorePointer(
            child: CurrentLocationMarker(
              key: const Key('currentLocationMarker'),
              heading: _compassHeading ?? _movementHeading,
              semanticLabel: context.l10n.mapUseCurrentLocationTooltip,
            ),
          ),
        ),
      ],
    );
  }
}

class CurrentLocationMarker extends StatelessWidget {
  const CurrentLocationMarker({
    super.key,
    required this.heading,
    required this.semanticLabel,
  });

  final double? heading;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (heading != null)
            Transform.rotate(
              key: const Key('currentLocationDirection'),
              angle: heading! * math.pi / 180,
              child: const CustomPaint(
                size: Size.square(58),
                painter: _DirectionConePainter(),
              ),
            ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionConePainter extends CustomPainter {
  const _DirectionConePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final cone = Path()
      ..moveTo(center.dx, 2)
      ..lineTo(center.dx + 17, center.dy + 3)
      ..quadraticBezierTo(
        center.dx,
        center.dy - 3,
        center.dx - 17,
        center.dy + 3,
      )
      ..close();

    canvas.drawPath(
      cone,
      Paint()
        ..color = const Color(0x551A73E8)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      cone,
      Paint()
        ..color = const Color(0xFF1A73E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _DirectionConePainter oldDelegate) => false;
}
