import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;

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
  });

  final ReportApiService reportApiService;
  final LatLng? initialLocation;
  final String? initialAddress;

  @override
  State<CitizenReportMapPicker> createState() => _CitizenReportMapPickerState();
}

class _CitizenReportMapPickerState extends State<CitizenReportMapPicker> {
  late final MapController _mapController;
  LatLng? _pinnedLocation;
  String _addressText = '';
  bool _isGeocoding = false;

  List<ReportMapPin> _pins = const <ReportMapPin>[];
  double _minLat = 10.60;
  double _minLng = 106.50;
  double _maxLat = 10.95;
  double _maxLng = 106.90;

  Timer? _debounceTimer;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinnedLocation = widget.initialLocation ?? const LatLng(10.7769, 106.7009);
    _addressText = widget.initialAddress ?? '';

    // Trigger initial load of pins around default/initial location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pinnedLocation != null) {
        _mapController.move(_pinnedLocation!, 15.0);
        _updateBoundsAndLoadPins(_pinnedLocation!, 15.0);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _updateBoundsAndLoadPins(LatLng center, double zoom) {
    // Basic approx degree bounds based on zoom
    final double latDelta = 0.1 / (zoom / 10.0);
    final double lngDelta = 0.1 / (zoom / 10.0);
    _minLat = center.latitude - latDelta;
    _maxLat = center.latitude + latDelta;
    _minLng = center.longitude - lngDelta;
    _maxLng = center.longitude + lngDelta;
    _loadPins();
  }

  Future<void> _loadPins() async {
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
        });
      }
    } catch (_) {
      // Ignore background loading errors
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final bounds = camera.visibleBounds;
      setState(() {
        _minLat = bounds.southWest.latitude;
        _minLng = bounds.southWest.longitude;
        _maxLat = bounds.northEast.latitude;
        _maxLng = bounds.northEast.longitude;
      });
      _loadPins();
    });
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() {
      _isGeocoding = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&accept-language=en',
      );
      final response = await http.get(
        url,
        headers: const {
          'User-Agent': 'SmartCityReportSystem/1.0 (contact: admin@smartcity.com)',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final displayName = data['display_name'];
        if (displayName is String && displayName.isNotEmpty) {
          if (mounted) {
            setState(() {
              _addressText = displayName;
            });
          }
        }
      }
    } catch (_) {
      // Fail silently
    } finally {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
        });
      }
    }
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      _pinnedLocation = point;
    });
    _reverseGeocode(point.latitude, point.longitude);
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
    });

    _searchDebounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _addressSuggestions = [];
        _isSearchingAddress = false;
      });
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchAddressSuggestions(query);
    });
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    setState(() {
      _isSearchingAddress = true;
    });

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&accept-language=en',
      );
      final response = await http.get(
        url,
        headers: const {
          'User-Agent': 'SmartCityReportSystem/1.0 (contact: admin@smartcity.com)',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _addressSuggestions = data.cast<Map<String, dynamic>>();
            _isSearchingAddress = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isSearchingAddress = false);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  void _confirmSelection() {
    if (_pinnedLocation == null) return;
    Navigator.of(context).pop(
      MapPickerResult(location: _pinnedLocation!, address: _addressText),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Location'),
        actions: [
          IconButton(
            tooltip: 'Confirm location',
            icon: const Icon(Icons.check, size: 28, color: Colors.teal),
            onPressed: _pinnedLocation == null || _isGeocoding ? null : _confirmSelection,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen map picker
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _pinnedLocation ?? const LatLng(10.7769, 106.7009),
                initialZoom: 15.0,
                minZoom: 4.0,
                maxZoom: 18.0,
                onTap: (_, point) {
                  _searchFocusNode.unfocus();
                  _onMapTapped(point);
                },
                onPositionChanged: (camera, hasGesture) {
                  _onMapPositionChanged(camera, hasGesture);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartcity.report',
                ),
                MarkerLayer(
                  markers: [
                    // Render existing report pins
                    ..._pins.map((pin) {
                      final isSelectedPin = _pinnedLocation != null &&
                          (pin.latitude - _pinnedLocation!.latitude).abs() < 1e-6 &&
                          (pin.longitude - _pinnedLocation!.longitude).abs() < 1e-6;

                      return Marker(
                        point: LatLng(pin.latitude, pin.longitude),
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _searchFocusNode.unfocus();
                            setState(() {
                              _pinnedLocation = LatLng(pin.latitude, pin.longitude);
                              _addressText = pin.title; // Default to report title as address hint
                            });
                            // Trigger reverse geocoding to update address
                            _reverseGeocode(pin.latitude, pin.longitude);
                          },
                          child: _MapMarker(
                            pin: pin,
                            isSelected: isSelectedPin,
                          ),
                        ),
                      );
                    }),
                    // Custom pinned marker
                    if (_pinnedLocation != null)
                      Marker(
                        point: _pinnedLocation!,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.redAccent,
                          size: 46,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Floating Search Bar & Autocomplete suggestions
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDDE5E2)),
                    boxShadow: const [
                      BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchQueryChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search address or open reports...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _addressSuggestions = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty && _searchFocusNode.hasFocus)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDDE5E2)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          // Search inside active report pins
                          if (_pins.any((pin) =>
                              pin.title.toLowerCase().contains(_searchQuery.toLowerCase()))) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Text(
                                'ACTIVE REPORTS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                            ..._pins
                                .where((pin) =>
                                    pin.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                                .map((pin) {
                              final color = _getCategoryColor(pin.category);
                              return ListTile(
                                dense: true,
                                leading: Icon(_getCategoryIcon(pin.category), color: color, size: 16),
                                title: Text(pin.title, style: const TextStyle(fontSize: 13)),
                                onTap: () {
                                  setState(() {
                                    _pinnedLocation = LatLng(pin.latitude, pin.longitude);
                                    _addressText = pin.title;
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _addressSuggestions = [];
                                    _searchFocusNode.unfocus();
                                  });
                                  _mapController.move(LatLng(pin.latitude, pin.longitude), 16.0);
                                  _reverseGeocode(pin.latitude, pin.longitude);
                                },
                              );
                            }),
                          ],
                          // Nominatim Search Suggestions
                          if (_addressSuggestions.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                              child: Text(
                                'ADDRESSES & PLACES',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                            ..._addressSuggestions.map((addr) {
                              final name = addr['display_name'] ?? 'Address';
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.place, color: Colors.redAccent, size: 16),
                                title: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () {
                                  final lat = double.tryParse(addr['lat'] ?? '') ?? 0.0;
                                  final lon = double.tryParse(addr['lon'] ?? '') ?? 0.0;
                                  final point = LatLng(lat, lon);

                                  setState(() {
                                    _pinnedLocation = point;
                                    _addressText = name;
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _addressSuggestions = [];
                                    _searchFocusNode.unfocus();
                                  });
                                  _mapController.move(point, 16.0);
                                },
                              );
                            }),
                          ],
                          if (_isSearchingAddress)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Pinned position details and confirmation card at the bottom
          if (_pinnedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Location',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (_isGeocoding)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _addressText.isNotEmpty ? _addressText : 'Loading address...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _addressText.isNotEmpty ? Colors.black87 : Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Coordinates: ${_pinnedLocation!.latitude.toStringAsFixed(6)}, ${_pinnedLocation!.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isGeocoding ? null : _confirmSelection,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirm Pinned Location'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Marker Widget representing report pins
class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.pin, required this.isSelected});

  final ReportMapPin pin;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(pin.category);
    final icon = _getCategoryIcon(pin.category);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
          ),
          CustomPaint(
            painter: _PinTrianglePainter(color: color),
            size: const Size(8, 5),
          ),
        ],
      ),
    );
  }
}

class _PinTrianglePainter extends CustomPainter {
  _PinTrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

IconData _getCategoryIcon(ReportCategory category) {
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

Color _getCategoryColor(ReportCategory category) {
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
