import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/location/geocoding_service.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';

class MapPickerResult {
  final LatLng location;
  final String address;

  const MapPickerResult({required this.location, required this.address});
}

class CitizenReportMapPicker extends StatefulWidget {
  const CitizenReportMapPicker({
    super.key,
    required this.reportApiService,
    this.initialLocation,
    this.initialAddress,
    this.geocodingService,
  });

  final ReportApiService reportApiService;
  final LatLng? initialLocation;
  final String? initialAddress;
  final GeocodingService? geocodingService;

  @override
  State<CitizenReportMapPicker> createState() => _CitizenReportMapPickerState();
}

class _CitizenReportMapPickerState extends State<CitizenReportMapPicker>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final GeocodingService _geocodingService;
  LatLng? _pinnedLocation;
  String _addressText = '';
  bool _isGeocoding = false;

  List<ReportMapPin> _pins = const <ReportMapPin>[];
  double _minLat = 10.60;
  double _minLng = 106.50;
  double _maxLat = 10.95;
  double _maxLng = 106.90;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<PlaceSearchResult> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  Timer? _searchDebounceTimer;

  // Tính năng bổ sung: radar quét sự cố gần đó (Local Insight Lookup)
  bool _radarActive = false;
  late AnimationController _pulseController;
  int _nearbyDuplicatesCount = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _geocodingService = widget.geocodingService ?? NominatimGeocodingService();
    _pinnedLocation = widget.initialLocation ?? const LatLng(10.7769, 106.7009);
    _addressText = widget.initialAddress ?? '';
    _searchController.text = _addressText;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Kích hoạt nạp danh sách pins ban đầu
    _loadNearbyPins();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyPins() async {
    try {
      final pins = await widget.reportApiService.fetchMapPins(
        minLat: _minLat,
        minLng: _minLng,
        maxLat: _maxLat,
        maxLng: _maxLng,
      );
      if (mounted) {
        setState(() {
          _pins = pins;
          _checkNearbyDuplicates();
        });
      }
    } catch (_) {}
  }

  void _checkNearbyDuplicates() {
    if (_pinnedLocation == null) return;
    const Distance distance = Distance();
    int count = 0;
    for (final pin in _pins) {
      final double meters = distance.as(
        LengthUnit.Meter,
        _pinnedLocation!,
        LatLng(pin.latitude, pin.longitude),
      );
      if (meters <= 100) {
        count++;
      }
    }
    setState(() {
      _nearbyDuplicatesCount = count;
    });
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _addressSuggestions = [];
        _isSearchingAddress = false;
      });
      return;
    }

    setState(() {
      _addressSuggestions = [];
    });

    _searchDebounceTimer = Timer(
      const Duration(milliseconds: 350),
      () => _searchAddresses(query),
    );
  }

  Future<void> _searchAddresses(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    setState(() {
      _isSearchingAddress = true;
    });

    try {
      final suggestions = await _geocodingService.searchPlaces(
        query: trimmedQuery,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted || _searchController.text.trim() != trimmedQuery) return;
      setState(() => _addressSuggestions = suggestions);
    } catch (_) {
      // Keep the map picker usable when place search is unavailable.
    } finally {
      if (mounted && _searchController.text.trim() == trimmedQuery) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  Future<void> _fetchAddressFromCoordinates(LatLng coordinates) async {
    setState(() {
      _isGeocoding = true;
    });

    try {
      final place = await _geocodingService.reverseGeocode(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        languageCode: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      final displayName =
          place?.displayName ?? context.l10n.mapSelectedLocation;
      setState(() {
        _addressText = displayName;
        _searchController.text = displayName;
      });
    } catch (_) {
      // Preserve the previous address if reverse geocoding fails.
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  void _handleMapPositionChanged(MapCamera camera, bool hasGesture) {
    final bounds = camera.visibleBounds;
    _minLat = bounds.southWest.latitude;
    _minLng = bounds.southWest.longitude;
    _maxLat = bounds.northEast.latitude;
    _maxLng = bounds.northEast.longitude;

    // Khi người dùng di chuyển, cập nhật tọa độ tâm bản đồ làm vị trí ghim
    setState(() {
      _pinnedLocation = camera.center;
    });
  }

  void _handleMapCameraIdle() {
    if (_pinnedLocation != null) {
      _fetchAddressFromCoordinates(_pinnedLocation!);
      _checkNearbyDuplicates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final panelWidth = isDesktop ? 420.0 : constraints.maxWidth;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _pinnedLocation ?? const LatLng(10.7769, 106.7009),
                    initialZoom: 16.0,
                    minZoom: 4.0,
                    maxZoom: 18.0,
                    onPositionChanged: _handleMapPositionChanged,
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _handleMapCameraIdle();
                      }
                    },
                    onTap: (_, __) => _searchFocusNode.unfocus(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.smartcity.report',
                    ),
                    MarkerLayer(
                      markers: _pins.map((pin) {
                        final color = _getCategoryColorLocal(pin.category);
                        return Marker(
                          point: LatLng(pin.latitude, pin.longitude),
                          width: 38,
                          height: 38,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withOpacity(0.65),
                              ),
                            ),
                            child: Icon(
                              _getCategoryIconLocal(pin.category),
                              color: color,
                              size: 19,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              if (_radarActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final value = _pulseController.value;
                          return Container(
                            width: 120 * value,
                            height: 120 * value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary.withOpacity(
                                (1 - value) * 0.12,
                              ),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(
                                  (1 - value) * 0.35,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.24),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: colorScheme.onPrimary,
                              size: 30,
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: BoxDecoration(
                              color: colorScheme.shadow.withOpacity(0.35),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).padding.top + 14,
                left: 14,
                right: isDesktop ? panelWidth + 28 : 14,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          elevation: 5,
                          shadowColor: colorScheme.shadow.withOpacity(0.16),
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: _onSearchQueryChanged,
                                  decoration: const InputDecoration(
                                    hintText: 'Search address or place',
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_isSearchingAddress)
                                const Padding(
                                  padding: EdgeInsets.only(right: 14),
                                  child: SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              else if (_searchController.text.isNotEmpty)
                                IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _addressSuggestions = [];
                                      _isSearchingAddress = false;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                            ],
                          ),
                        ),
                        if (_addressSuggestions.isNotEmpty &&
                            _searchFocusNode.hasFocus)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 260),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _addressSuggestions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: colorScheme.outlineVariant,
                              ),
                              itemBuilder: (context, index) {
                                final suggestion = _addressSuggestions[index];
                                final displayName = suggestion.displayName;
                                return ListTile(
                                  leading: Icon(
                                    Icons.place_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    final targetLoc = LatLng(
                                      suggestion.latitude,
                                      suggestion.longitude,
                                    );
                                    setState(() {
                                      _pinnedLocation = targetLoc;
                                      _addressText = displayName;
                                      _searchController.text = displayName;
                                      _addressSuggestions = [];
                                      _searchFocusNode.unfocus();
                                    });
                                    _mapController.move(targetLoc, 16.0);
                                    _checkNearbyDuplicates();
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                right: isDesktop ? panelWidth + 20 : 14,
                bottom: isDesktop ? 20 : 290,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'radar_btn',
                      tooltip: 'Check nearby reports',
                      backgroundColor: _radarActive
                          ? colorScheme.primaryContainer
                          : colorScheme.surface,
                      foregroundColor: colorScheme.primary,
                      onPressed: () {
                        setState(() {
                          _radarActive = !_radarActive;
                          if (_radarActive) {
                            _pulseController.repeat();
                            _checkNearbyDuplicates();
                          } else {
                            _pulseController.stop();
                          }
                        });
                      },
                      child: const Icon(Icons.radar),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton.small(
                      heroTag: 'my_location_btn',
                      tooltip: 'Use current location',
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.primary,
                      onPressed: () {
                        const currentLoc = LatLng(10.7769, 106.7009);
                        setState(() => _pinnedLocation = currentLoc);
                        _mapController.move(currentLoc, 16.0);
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              Positioned(
                right: 0,
                bottom: 0,
                top: isDesktop ? 0 : null,
                left: isDesktop ? null : 0,
                width: panelWidth,
                child: Align(
                  alignment: isDesktop
                      ? Alignment.centerRight
                      : Alignment.bottomCenter,
                  child: Container(
                    margin: isDesktop
                        ? const EdgeInsets.all(16)
                        : EdgeInsets.zero,
                    padding: EdgeInsets.fromLTRB(
                      22,
                      20,
                      22,
                      isDesktop ? 22 : 28,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: isDesktop
                          ? BorderRadius.circular(24)
                          : const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.14),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm location',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Move the map until the pin is directly over the issue.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _isGeocoding
                                        ? 'Finding the address…'
                                        : (_addressText.isEmpty
                                            ? 'Address not available'
                                            : _addressText),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _nearbyDuplicatesCount > 0
                                  ? colorScheme.errorContainer
                                  : colorScheme.primaryContainer.withOpacity(
                                      0.55,
                                    ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  _nearbyDuplicatesCount > 0
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline,
                                  color: _nearbyDuplicatesCount > 0
                                      ? colorScheme.onErrorContainer
                                      : colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _nearbyDuplicatesCount > 0
                                        ? '$_nearbyDuplicatesCount existing report(s) were found within 100 metres.'
                                        : 'No nearby reports were found within 100 metres.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: _nearbyDuplicatesCount > 0
                                          ? colorScheme.onErrorContainer
                                          : colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      _isGeocoding || _pinnedLocation == null
                                          ? null
                                          : () {
                                              Navigator.of(context).pop(
                                                MapPickerResult(
                                                  location: _pinnedLocation!,
                                                  address: _addressText,
                                                ),
                                              );
                                            },
                                  icon: const Icon(Icons.check),
                                  label: const Text('Use this location'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIconLocal(ReportCategory category) {
    switch (category) {
      case ReportCategory.roadDamage:
        return Icons.construction;
      case ReportCategory.streetLight:
        return Icons.lightbulb;
      case ReportCategory.garbage:
        return Icons.delete_outline;
      case ReportCategory.waterLeak:
        return Icons.opacity;
      case ReportCategory.drainage:
        return Icons.waves;
      case ReportCategory.trafficSign:
        return Icons.traffic;
      case ReportCategory.treeBlockage:
        return Icons.park;
      case ReportCategory.other:
        return Icons.help_outline;
    }
  }

  Color _getCategoryColorLocal(ReportCategory category) {
    switch (category) {
      case ReportCategory.roadDamage:
        return Colors.deepOrange;
      case ReportCategory.streetLight:
        return Colors.amber.shade700;
      case ReportCategory.garbage:
        return Colors.brown;
      case ReportCategory.waterLeak:
        return Colors.blue;
      case ReportCategory.drainage:
        return Colors.teal;
      case ReportCategory.trafficSign:
        return Colors.red.shade600;
      case ReportCategory.treeBlockage:
        return Colors.green.shade700;
      case ReportCategory.other:
        return Colors.blueGrey;
    }
  }
}
