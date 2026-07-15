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
    return Scaffold(
      body: Stack(
        children: [
          // LỚP 1: BẢN ĐỒ TOÀN MÀN HÌNH CHỌN VỊ TRÍ
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
                onTap: (_, __) {
                  _searchFocusNode.unfocus();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartcity.report',
                ),
                // Hiển thị các sự cố hiện có xung quanh để chống trùng lặp trực quan
                MarkerLayer(
                  markers: _pins.map((pin) {
                    return Marker(
                      point: LatLng(pin.latitude, pin.longitude),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.error,
                        color: _getCategoryColorLocal(
                          pin.category,
                        ).withOpacity(0.7),
                        size: 24,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // LỚP 2: RADAR QUÉT ĐƯỜNG KÍNH KHU VỰC TRÙNG LẶP (Tâm màn hình)
          if (_radarActive)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 200 * _pulseController.value,
                        height: 200 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF0F766E,
                          ).withOpacity((1 - _pulseController.value) * 0.3),
                          border: Border.all(
                            color: const Color(
                              0xFF0F766E,
                            ).withOpacity((1 - _pulseController.value) * 0.8),
                            width: 1.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // LỚP 3: MARKER ĐỊNH VỊ CỐ ĐỊNH Ở CHÍNH GIỮA MÀN HÌNH CO PHÃN ANMATION
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF005C55),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111C2D).withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LỚP 4: THANH TÌM KIẾM ĐỊA CHỈ FLOATING CONSOLE (TOP AXIS)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF3E4947),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchQueryChanged,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF111C2D),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Search address or intersection...',
                                hintStyle: TextStyle(color: Color(0xFF64748B)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          if (_isSearchingAddress)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            )
                          else if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _addressSuggestions = [];
                                  _isSearchingAddress = false;
                                });
                              },
                            ),
                        ],
                      ),
                    ),

                    // Dropdown Kết quả tìm kiếm gợi ý địa chỉ
                    if (_addressSuggestions.isNotEmpty &&
                        _searchFocusNode.hasFocus)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _addressSuggestions.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFE2E8F0),
                            ),
                            itemBuilder: (context, index) {
                              final suggestion = _addressSuggestions[index];
                              final displayName = suggestion.displayName;
                              return ListTile(
                                leading: const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF0F766E),
                                ),
                                title: Text(
                                  displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF111C2D),
                                  ),
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
                      ),
                    const SizedBox(height: 12),
                    // Badge Chỉ báo phân tích trạng thái vùng Boundary khu vực
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F3FF).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0xFFBDC9C6).withOpacity(0.5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isGeocoding
                                  ? const Color(0xFF0F766E)
                                  : Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isGeocoding
                                ? 'Analyzing boundary...'
                                : 'Boundary Analyzed',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111C2D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LỚP 5: FLOATING MAP CONTROLS (BOTTOM RIGHT ACTION BUTTONS)
          Positioned(
            right: 16,
            bottom:
                260, // Đẩy lên trên vùng của thông tin Bottom Sheet bên dưới
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nút Radar tìm kiếm chuyên sâu (Area Insight)
                FloatingActionButton(
                  heroTag: 'radar_btn',
                  mini: true,
                  backgroundColor: _radarActive
                      ? const Color(0xFFBDECE2)
                      : Colors.white,
                  foregroundColor: const Color(0xFF0F766E),
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
                const SizedBox(height: 12),
                // Nút định vị về vị trí hiện tại
                FloatingActionButton(
                  heroTag: 'my_location_btn',
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F766E),
                  onPressed: () {
                    // Trả bản đồ về tọa độ mặc định ban đầu giả lập vị trí GPS người dùng
                    const currentLoc = LatLng(10.7769, 106.7009);
                    setState(() {
                      _pinnedLocation = currentLoc;
                    });
                    _mapController.move(currentLoc, 16.0);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // LỚP 6: DIALOG VÀ BOTTOM SHEET XÁC NHẬN CHỐNG TRÙNG LẶP SỰ CỐ
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: SafeArea(
                top: false,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 2 of 3',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111C2D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.pin_drop,
                            size: 18,
                            color: Color(0xFF3E4947),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _isGeocoding
                                  ? 'Fetching address details...'
                                  : _addressText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF3E4947),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // BANNER CẢNH BÁO BÁO CÁO TRÙNG LẶP NẾU PHÁT HIỆN SỰ CỐ < 100M
                      if (_nearbyDuplicatesCount > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFBA1A1A).withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Color(0xFFBA1A1A),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Possible duplicate reports found',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF93000A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'There are $_nearbyDuplicatesCount similar issues reported within 100m zone boundary.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF93000A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.analytics,
                                color: Color(0xFF425268),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Local Insight: Area is clear. No duplicate incidents matching inside this grid bounds.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF38485D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // KHU VỰC ĐIỀU HƯỚNG XÁC NHẬN CHÂN TRANG
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                foregroundColor: const Color(0xFF0F766E),
                                side: const BorderSide(
                                  color: Color(0xFFBDC9C6),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isGeocoding || _pinnedLocation == null
                                  ? null
                                  : () {
                                      Navigator.of(context).pop(
                                        MapPickerResult(
                                          location: _pinnedLocation!,
                                          address: _addressText,
                                        ),
                                      );
                                    },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Confirm Position',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward, size: 16),
                                ],
                              ),
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
