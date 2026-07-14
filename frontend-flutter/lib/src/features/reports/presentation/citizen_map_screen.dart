import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_feedback.dart';
import '../../auth/data/auth_api_service.dart';
import '../../auth/domain/current_user.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';

class CitizenMapScreen extends StatefulWidget {
  const CitizenMapScreen({
    super.key,
    required this.reportApiService,
    required this.authApiService,
  });

  final ReportApiService reportApiService;
  final AuthApiService authApiService;

  @override
  State<CitizenMapScreen> createState() => _CitizenMapScreenState();
}

class _CitizenMapScreenState extends State<CitizenMapScreen> {
  final Set<String> _upvotedReportIds = <String>{};

  CurrentUser? _currentUser;
  ReportCategory? _selectedCategory;
  bool _hideOwnReports = false;

  double _minLat = 10.60;
  double _minLng = 106.50;
  double _maxLat = 10.95;
  double _maxLng = 106.90;

  bool _isMapView = true;
  ReportMapPin? _selectedPin;

  late final MapController _mapController;
  late Future<List<ReportMapPin>> _pinsFuture;

  List<ReportMapPin> _pins = const <ReportMapPin>[];
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  Timer? _searchDebounceTimer;
  LatLng? _searchedPlaceLocation;
  String? _searchedPlaceName;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pinsFuture = _loadPins();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await widget.authApiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      final response = await http
          .get(
            url,
            headers: const {
              'User-Agent':
                  'SmartCityReportSystem/1.0 (contact: admin@smartcity.com)',
            },
          )
          .timeout(const Duration(seconds: 4));

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

  Future<List<ReportMapPin>> _loadPins() async {
    final pins = await widget.reportApiService.fetchMapPins(
      minLat: _minLat,
      minLng: _minLng,
      maxLat: _maxLat,
      maxLng: _maxLng,
    );
    _pins = pins;
    return pins;
  }

  Future<void> refresh() async {
    setState(() {
      _errorMessage = null;
      _selectedPin = null;
      _pinsFuture = _loadPins();
    });
    await _pinsFuture;
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
        _errorMessage = null;
        _pinsFuture = _loadPins();
      });
    });
  }

  Future<void> _toggleUpvote(ReportMapPin pin) async {
    try {
      final summary = _upvotedReportIds.contains(pin.id)
          ? await widget.reportApiService.removeUpvote(pin.id)
          : await widget.reportApiService.upvoteReport(pin.id);

      if (!mounted) {
        return;
      }

      setState(() {
        if (summary.hasUpvoted) {
          _upvotedReportIds.add(pin.id);
        } else {
          _upvotedReportIds.remove(pin.id);
        }

        _pins = _pins
            .map(
              (item) => item.id == pin.id
                  ? item.copyWith(
                      upvoteCount: summary.upvoteCount,
                      priorityScore: summary.priorityScore,
                    )
                  : item,
            )
            .toList(growable: false);

        if (_selectedPin?.id == pin.id) {
          _selectedPin = _selectedPin!.copyWith(
            upvoteCount: summary.upvoteCount,
            priorityScore: summary.priorityScore,
          );
        }

        _pinsFuture = Future<List<ReportMapPin>>.value(_pins);
      });
    } on ReportApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to update upvote.');
    }
  }

  Future<void> _openDetails(ReportMapPin pin) async {
    _searchFocusNode.unfocus();
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenReportDetail, arguments: pin.id);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      await refresh();
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _errorMessage = message);
    AppFeedback.showError(
      context,
      title: 'Unable to update report',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1024; // Breakpoint cho cấu trúc Web PC

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9F8), // Background màu xám xanh dịu nhẹ theo theme
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nếu là giao diện Web Desktop: Tự động thêm Navigation Rail bên trái để tối ưu không gian rộng
              if (isDesktop)
                Container(
                  width: 280,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Icon(Icons.location_city, color: const Color(0xFF0F766E), size: 32),
                            const SizedBox(width: 12),
                            Text(
                              'Citizen Portal',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          children: [
                            ListTile(
                              selected: _isMapView,
                              selectedTileColor: const Color(0xFFCCFBF1),
                              selectedColor: const Color(0xFF115E59),
                              iconColor: const Color(0xFF64748B),
                              textColor: const Color(0xFF64748B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              leading: const Icon(Icons.map_outlined),
                              title: const Text('Map View', style: TextStyle(fontWeight: FontWeight.w600)),
                              onTap: () => setState(() => _isMapView = true),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              selected: !_isMapView,
                              selectedTileColor: const Color(0xFFCCFBF1),
                              selectedColor: const Color(0xFF115E59),
                              iconColor: const Color(0xFF64748B),
                              textColor: const Color(0xFF64748B),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                              leading: const Icon(Icons.list_alt_outlined),
                              title: const Text('List View', style: TextStyle(fontWeight: FontWeight.w600)),
                              onTap: () => setState(() {
                                _isMapView = false;
                                _selectedPin = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Vùng nội dung chính bên phải
              Expanded(
                child: Column(
                  children: [
                    // Top App Header bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isMapView ? 'Map View' : 'Report List View',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                mouseCursor: SystemMouseCursors.click,
                                tooltip: 'Refresh visible area',
                                icon: const Icon(Icons.refresh, color: Color(0xFF0F766E)),
                                onPressed: refresh,
                              ),
                              const SizedBox(width: 8),
                              // Chỉ hiện SegmentedButton chuyển view trên Mobile/Tablet (khi không có Sidebar)
                              if (!isDesktop)
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment<bool>(
                                      value: true,
                                      icon: Icon(Icons.map_outlined),
                                      label: Text('Map'),
                                    ),
                                    ButtonSegment<bool>(
                                      value: false,
                                      icon: Icon(Icons.list_alt_outlined),
                                      label: Text('List'),
                                    ),
                                  ],
                                  selected: {_isMapView},
                                  onSelectionChanged: (value) {
                                    setState(() {
                                      _isMapView = value.first;
                                      if (!_isMapView) {
                                        _selectedPin = null;
                                      }
                                    });
                                  },
                                  showSelectedIcon: false,
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: const Color(0xFF0F766E),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Bộ lọc Chips / Category Ribbon
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                mouseCursor: SystemMouseCursors.click,
                                label: const Text('All Types'),
                                selected: _selectedCategory == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                },
                                selectedColor: const Color(0xFFCCFBF1),
                                checkmarkColor: const Color(0xFF115E59),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ...ReportCategory.values.map((category) {
                                final isSelected = _selectedCategory == category;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    mouseCursor: SystemMouseCursors.click,
                                    label: Text(category.label),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        _selectedCategory = selected ? category : null;
                                      });
                                    },
                                    selectedColor: const Color(0xFFCCFBF1),
                                    checkmarkColor: const Color(0xFF115E59),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                );
                              }),
                              if (_currentUser != null)
                                FilterChip(
                                  mouseCursor: SystemMouseCursors.click,
                                  avatar: Icon(
                                    _hideOwnReports ? Icons.person_off : Icons.person_off_outlined,
                                    size: 16,
                                    color: _hideOwnReports ? const Color(0xFF115E59) : const Color(0xFF64748B),
                                  ),
                                  label: const Text('Hide My Reports'),
                                  selected: _hideOwnReports,
                                  onSelected: (selected) {
                                    setState(() {
                                      _hideOwnReports = selected;
                                    });
                                  },
                                  selectedColor: const Color(0xFFCCFBF1),
                                  checkmarkColor: const Color(0xFF115E59),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Hiển thị thông báo lỗi nếu có
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),

                    // Phần thân quản lý Bản đồ hoặc Danh sách (Dùng chung FutureBuilder)
                    Expanded(
                      child: FutureBuilder<List<ReportMapPin>>(
                        future: _pinsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done && _pins.isEmpty) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)));
                          }

                          if (snapshot.hasError && _pins.isEmpty) {
                            return _ErrorState(
                              message: 'Unable to load open report pins.',
                              onRetry: refresh,
                            );
                          }

                          final pins = _pins.isNotEmpty ? _pins : (snapshot.data ?? const <ReportMapPin>[]);
                          final filteredPins = pins.where((pin) {
                            if (_selectedCategory != null && pin.category != _selectedCategory) {
                              return false;
                            }
                            if (_hideOwnReports && _currentUser != null && pin.creatorId == _currentUser!.id) {
                              return false;
                            }
                            return true;
                          }).toList();

                          // CHẾ ĐỘ 1: BẢN ĐỒ TOÀN MÀN HÌNH
                          if (_isMapView) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: Container(
                                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x0D000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: const LatLng(10.7769, 106.7009),
                                          initialZoom: 13.0,
                                          minZoom: 4.0,
                                          maxZoom: 18.0,
                                          onTap: (_, __) {
                                            _searchFocusNode.unfocus();
                                            setState(() {
                                              _selectedPin = null;
                                              _searchedPlaceLocation = null;
                                              _searchedPlaceName = null;
                                            });
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
                                              ...filteredPins.map((pin) {
                                                return Marker(
                                                  point: LatLng(pin.latitude, pin.longitude),
                                                  width: 80,
                                                  height: 80,
                                                  child: GestureDetector(
                                                    behavior: HitTestBehavior.opaque,
                                                    onTap: () {
                                                      _searchFocusNode.unfocus();
                                                      setState(() {
                                                        _selectedPin = pin;
                                                      });
                                                    },
                                                    child: MouseRegion(
                                                      cursor: SystemMouseCursors.click,
                                                      child: _MapMarker(
                                                        pin: pin,
                                                        isSelected: _selectedPin?.id == pin.id,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                              if (_searchedPlaceLocation != null)
                                                Marker(
                                                  point: _searchedPlaceLocation!,
                                                  width: 160,
                                                  height: 90,
                                                  child: _SearchedPlaceMarker(
                                                    name: _searchedPlaceName ?? 'Searched location',
                                                    onClear: () {
                                                      setState(() {
                                                        _searchedPlaceLocation = null;
                                                        _searchedPlaceName = null;
                                                      });
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Thanh Tìm Kiếm Địa Điểm & Suggestions thả xuống
                                Positioned(
                                  top: 12,
                                  left: 28,
                                  right: 28,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 600), // Giới hạn max-width 600px trên PC
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _SearchBar(
                                            controller: _searchController,
                                            focusNode: _searchFocusNode,
                                            onChanged: _onSearchQueryChanged,
                                            onClear: () {
                                              setState(() {
                                                _searchController.clear();
                                                _searchQuery = '';
                                                _addressSuggestions = [];
                                                _searchedPlaceLocation = null;
                                                _searchedPlaceName = null;
                                              });
                                            },
                                          ),
                                          if (_searchQuery.isNotEmpty && _searchFocusNode.hasFocus)
                                            _SearchSuggestions(
                                              pins: filteredPins,
                                              addresses: _addressSuggestions,
                                              query: _searchQuery,
                                              isSearchingAddress: _isSearchingAddress,
                                              onSelectPin: (pin) {
                                                setState(() {
                                                  _selectedPin = pin;
                                                  _searchController.text = pin.title;
                                                  _searchQuery = '';
                                                  _addressSuggestions = [];
                                                  _searchFocusNode.unfocus();
                                                });
                                                _mapController.move(
                                                  LatLng(pin.latitude, pin.longitude),
                                                  15.0,
                                                );
                                              },
                                              onSelectAddress: (addr) {
                                                final displayName = addr['display_name'] ?? 'Searched place';
                                                final lat = double.tryParse(addr['lat'] ?? '') ?? 0.0;
                                                final lon = double.tryParse(addr['lon'] ?? '') ?? 0.0;
                                                final point = LatLng(lat, lon);

                                                setState(() {
                                                  _searchedPlaceLocation = point;
                                                  _searchedPlaceName = displayName;
                                                  _searchController.text = displayName;
                                                  _searchQuery = '';
                                                  _addressSuggestions = [];
                                                  _searchFocusNode.unfocus();
                                                });
                                                _mapController.move(point, 15.0);
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Bottom Sheet/Card Xem Nhanh Sự Cố Khi Nhấp Vào Marker
                                if (_selectedPin != null)
                                  Positioned(
                                    left: 28,
                                    right: 28,
                                    bottom: 28,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 500), // Giới hạn độ rộng của Bottom Card
                                        child: _SelectedPinCard(
                                          pin: _selectedPin!,
                                          hasUpvoted: _upvotedReportIds.contains(_selectedPin!.id),
                                          onUpvote: () => _toggleUpvote(_selectedPin!),
                                          onViewDetails: () => _openDetails(_selectedPin!),
                                          onClose: () {
                                            setState(() {
                                              _selectedPin = null;
                                            });
                                          },
                                          showUpvote: _currentUser == null || _selectedPin!.creatorId != _currentUser!.id,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }

                          // CHẾ ĐỘ 2: DANH SÁCH BÁO CÁO DẠNG LƯỚI GRID (WEB) HOẶC DỌC (MOBILE)
                          if (filteredPins.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: refresh,
                              color: const Color(0xFF0F766E),
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(24),
                                children: const [
                                  SizedBox(height: 96),
                                  Center(child: Text('No open report pins in bounds', style: TextStyle(color: Color(0xFF64748B)))),
                                ],
                              ),
                            );
                          }

                          // Web hiển thị Grid 2 hoặc 3 cột, Mobile hiển thị dạng danh sách cuộn dọc đơn thuần
                          return RefreshIndicator(
                            onRefresh: refresh,
                            color: const Color(0xFF0F766E),
                            child: isDesktop
                                ? GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      mainAxisExtent: 190,
                                    ),
                                    itemCount: filteredPins.length,
                                    itemBuilder: (context, index) => _PinTile(
                                      pin: filteredPins[index],
                                      hasUpvoted: _upvotedReportIds.contains(filteredPins[index].id),
                                      onUpvote: () => _toggleUpvote(filteredPins[index]),
                                      onViewDetails: () => _openDetails(filteredPins[index]),
                                      showUpvote: _currentUser == null || filteredPins[index].creatorId != _currentUser!.id,
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                                    itemCount: filteredPins.length,
                                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) => _PinTile(
                                      pin: filteredPins[index],
                                      hasUpvoted: _upvotedReportIds.contains(filteredPins[index].id),
                                      onUpvote: () => _toggleUpvote(filteredPins[index]),
                                      onViewDetails: () => _openDetails(filteredPins[index]),
                                      showUpvote: _currentUser == null || filteredPins[index].creatorId != _currentUser!.id,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(9999), // Bo góc full hình viên thuốc mềm mại
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Search reports or categories...',
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  mouseCursor: SystemMouseCursors.click,
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B), size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({
    required this.pins,
    required this.addresses,
    required this.query,
    required this.isSearchingAddress,
    required this.onSelectPin,
    required this.onSelectAddress,
  });

  final List<ReportMapPin> pins;
  final List<Map<String, dynamic>> addresses;
  final String query;
  final bool isSearchingAddress;
  final ValueChanged<ReportMapPin> onSelectPin;
  final ValueChanged<Map<String, dynamic>> onSelectAddress;

  @override
  Widget build(BuildContext context) {
    final filteredPins = pins.where((pin) {
      final titleMatch = pin.title.toLowerCase().contains(query.toLowerCase());
      final categoryMatch = pin.category.label.toLowerCase().contains(query.toLowerCase());
      return titleMatch || categoryMatch;
    }).toList();

    if (filteredPins.isEmpty && addresses.isEmpty && !isSearchingAddress) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: const Text(
          'No matching reports or addresses found',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: [
            if (filteredPins.isNotEmpty) ...[
              Container(
                color: const Color(0xFFF7F9F8),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: const Text(
                  'REPORTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...filteredPins.map((pin) {
                final color = _getCategoryColor(pin.category);
                final icon = _getCategoryIcon(pin.category);
                return ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  dense: true,
                  leading: Icon(icon, color: color, size: 18),
                  title: Text(
                    pin.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    pin.category.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => onSelectPin(pin),
                );
              }),
            ],
            if (addresses.isNotEmpty) ...[
              Container(
                color: const Color(0xFFF7F9F8),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: const Text(
                  'ADDRESSES & PLACES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...addresses.map((addr) {
                final displayName = addr['display_name'] ?? '';
                return ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  dense: true,
                  leading: const Icon(
                    Icons.place,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  title: Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  onTap: () => onSelectAddress(addr),
                );
              }),
            ],
            if (isSearchingAddress)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F766E)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinTile extends StatelessWidget {
  const _PinTile({
    required this.pin,
    required this.hasUpvoted,
    required this.onUpvote,
    required this.onViewDetails,
    required this.showUpvote,
  });

  final ReportMapPin pin;
  final bool hasUpvoted;
  final VoidCallback onUpvote;
  final VoidCallback onViewDetails;
  final bool showUpvote;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        pin.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        pin.category.label,
                        style: const TextStyle(color: Color(0xFF115E59), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      side: BorderSide.none,
                      backgroundColor: const Color(0xFFCCFBF1),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.place_outlined,
                      label: '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)}',
                    ),
                    _MetaChip(
                      icon: Icons.thumb_up_alt_outlined,
                      label: '${pin.upvoteCount} upvotes',
                    ),
                    _MetaChip(
                      icon: Icons.trending_up,
                      label: 'Priority ${pin.priorityScore}',
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('View details', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (showUpvote) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onUpvote,
                      icon: Icon(
                        hasUpvoted ? Icons.thumb_down_alt_outlined : Icons.thumb_up_alt_outlined,
                        size: 16,
                      ),
                      label: Text(
                        hasUpvoted ? 'Remove upvote' : 'I see this too',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasUpvoted ? const Color(0xFFEF4444) : const Color(0xFF0F766E),
                        side: BorderSide(color: hasUpvoted ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F766E)),
            ),
          ],
        ),
      ),
    );
  }
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

class _MapMarker extends StatefulWidget {
  const _MapMarker({required this.pin, required this.isSelected});

  final ReportMapPin pin;
  final bool isSelected;

  @override
  State<_MapMarker> createState() => _MapMarkerState();
}

class _MapMarkerState extends State<_MapMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isSelected) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isSelected && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.pin.category;
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isSelected)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 50 * _controller.value + 20,
                height: 50 * _controller.value + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity((1 - _controller.value) * 0.4),
                ),
              );
            },
          ),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 250),
          tween: Tween<double>(begin: 1.0, end: widget.isSelected ? 1.25 : 1.0),
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.isSelected ? color : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  icon,
                  size: 20,
                  color: widget.isSelected ? Colors.white : color,
                ),
              ),
              CustomPaint(
                painter: _PinTrianglePainter(color: color),
                size: const Size(10, 6),
              ),
            ],
          ),
        ),
      ],
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

class _SelectedPinCard extends StatelessWidget {
  const _SelectedPinCard({
    required this.pin,
    required this.hasUpvoted,
    required this.onUpvote,
    required this.onViewDetails,
    required this.onClose,
    required this.showUpvote,
  });

  final ReportMapPin pin;
  final bool hasUpvoted;
  final VoidCallback onUpvote;
  final VoidCallback onViewDetails;
  final VoidCallback onClose;
  final bool showUpvote;

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(pin.category);

    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
      ),
      color: Colors.white.withOpacity(0.98),
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withOpacity(0.04)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${pin.category.label}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  mouseCursor: SystemMouseCursors.click,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
            const Divider(height: 16, color: Color(0xFFE2E8F0)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniTag(
                  icon: Icons.place_outlined,
                  label: '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)}',
                  color: color,
                ),
                _MiniTag(
                  icon: Icons.thumb_up_alt_outlined,
                  label: '${pin.upvoteCount} upvotes',
                  color: color,
                ),
                _MiniTag(
                  icon: Icons.trending_up,
                  label: 'Priority ${pin.priorityScore}',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withOpacity(0.55)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (showUpvote) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: onUpvote,
                    style: FilledButton.styleFrom(
                      backgroundColor: hasUpvoted ? const Color(0xFFEF4444) : color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      hasUpvoted ? Icons.thumb_down_alt_outlined : Icons.thumb_up_alt_outlined,
                      size: 16,
                    ),
                    label: Text(
                      hasUpvoted ? 'Remove upvote' : 'I see this too',
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.darken(0.15),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

class _SearchedPlaceMarker extends StatelessWidget {
  const _SearchedPlaceMarker({required this.name, required this.onClear});

  final String name;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(Icons.close, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 32),
      ],
    );
  }
}