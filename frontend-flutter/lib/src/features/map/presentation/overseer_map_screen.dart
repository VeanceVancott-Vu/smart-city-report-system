import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/location/current_location_map_layer.dart';
import '../../../core/location/geocoding_service.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_api_service.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import '../../overseer/presentation/overseer_report_dashboard_screen.dart';

class OverseerMapScreen extends StatefulWidget {
  const OverseerMapScreen({
    super.key,
    required this.reportApiService,
    required this.authApiService,
    this.geocodingService,
  });

  final ReportApiService reportApiService;
  final AuthApiService authApiService;
  final GeocodingService? geocodingService;

  @override
  State<OverseerMapScreen> createState() => _OverseerMapScreenState();
}

class _OverseerMapScreenState extends State<OverseerMapScreen> {
  final Set<String> _selectedReportIds = <String>{};
  bool _multiSelectMode = false;

  ReportCategory? _selectedCategory;
  ReportStatus? _selectedStatus;
  int _minPriority = 0;

  double _minLat = 15.95;
  double _minLng = 108.05;
  double _maxLat = 16.18;
  double _maxLng = 108.32;

  ReportMapPin? _selectedPin;
  Report? _selectedPinDetails;
  bool _isLoadingDetails = false;

  late final MapController _mapController;
  late final GeocodingService _geocodingService;
  late Future<List<ReportMapPin>> _pinsFuture;

  List<ReportMapPin> _pins = const <ReportMapPin>[];
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _debounceTimer;

  List<PlaceSearchResult> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  bool _hasSearchedAddress = false;
  LatLng? _searchedPlaceLocation;
  String? _searchedPlaceName;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _geocodingService = widget.geocodingService ?? NominatimGeocodingService();
    _pinsFuture = _loadPins();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      _searchQuery = query;
      _addressSuggestions = [];
      _isSearchingAddress = false;
      _hasSearchedAddress = false;
    });
  }

  Future<void> _searchAddresses([String? submittedQuery]) async {
    final query = (submittedQuery ?? _searchController.text).trim();
    if (query.isEmpty || _isSearchingAddress) {
      return;
    }

    setState(() {
      _isSearchingAddress = true;
      _hasSearchedAddress = true;
    });

    try {
      final suggestions = await _geocodingService.searchPlaces(
        query: query,
        languageCode: Localizations.localeOf(context).languageCode,
      );

      if (!mounted || _searchController.text.trim() != query) {
        return;
      }
      setState(() => _addressSuggestions = suggestions);
    } catch (_) {
      // Local report matching remains available if place search fails.
    } finally {
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
      includeAllStatuses: true,
    );
    _pins = pins;
    return pins;
  }

  Future<void> _refresh() async {
    setState(() {
      _errorMessage = null;
      _selectedPin = null;
      _selectedPinDetails = null;
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

  Future<void> _selectPin(ReportMapPin pin) async {
    _searchFocusNode.unfocus();
    setState(() {
      _selectedPin = pin;
      _selectedPinDetails = null;
      _isLoadingDetails = true;
    });

    try {
      final details = await widget.reportApiService.fetchReport(pin.id);
      if (mounted && _selectedPin?.id == pin.id) {
        setState(() {
          _selectedPinDetails = details;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted && _selectedPin?.id == pin.id) {
        setState(() {
          _isLoadingDetails = false;
          _errorMessage = context.l10n.reportLoadFailed;
        });
      }
    }
  }

  Future<void> _quickFix(String reportId) async {
    try {
      await widget.reportApiService.fixReport(reportId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.overseerReportFixed)));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.overseerReportUpdateFailed(e.toString())),
        ),
      );
    }
  }

  bool _canCreateTaskForPin(ReportMapPin pin) {
    return pin.status == ReportStatus.submitted;
  }

  ReportMapPin? _pinById(String reportId) {
    for (final pin in _pins) {
      if (pin.id == reportId) {
        return pin;
      }
    }
    return null;
  }

  void _showTaskUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.taskOnlySubmittedReports)),
    );
  }

  void _createTaskForSingleReport(String reportId) {
    final pin = _pinById(reportId);
    if (pin != null && !_canCreateTaskForPin(pin)) {
      _showTaskUnavailable();
      return;
    }

    Navigator.of(context)
        .pushNamed(
          AppRoutes.overseerCreateTask,
          arguments: OverseerTaskFormArgs(reportIds: [reportId]),
        )
        .then((changed) {
          if (changed == true) {
            _refresh();
          }
        });
  }

  void _createTaskFromSelection() {
    final reportIds = _pins
        .where(
          (pin) =>
              _selectedReportIds.contains(pin.id) && _canCreateTaskForPin(pin),
        )
        .map((pin) => pin.id)
        .toList(growable: false);
    if (reportIds.isEmpty) {
      _showTaskUnavailable();
      return;
    }

    Navigator.of(context)
        .pushNamed(
          AppRoutes.overseerCreateTask,
          arguments: OverseerTaskFormArgs(reportIds: reportIds),
        )
        .then((changed) {
          if (changed == true) {
            setState(() {
              _selectedReportIds.clear();
              _multiSelectMode = false;
            });
            _refresh();
          }
        });
  }

  void _toggleReportSelection(String reportId) {
    setState(() {
      if (_selectedReportIds.contains(reportId)) {
        _selectedReportIds.remove(reportId);
      } else {
        _selectedReportIds.add(reportId);
      }
    });
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _multiSelectMode = !_multiSelectMode;
      if (!_multiSelectMode) {
        _selectedReportIds.clear();
      } else {
        _selectedPin = null;
        _selectedPinDetails = null;
      }
    });
  }

  void _openQueuePin(ReportMapPin pin) {
    _searchFocusNode.unfocus();
    _mapController.move(LatLng(pin.latitude, pin.longitude), 15.0);

    if (_multiSelectMode) {
      if (_canCreateTaskForPin(pin)) {
        _toggleReportSelection(pin.id);
      }
      return;
    }

    _selectPin(pin);
  }

  String _topCategoryLabel(BuildContext context, List<ReportMapPin> pins) {
    if (pins.isEmpty) {
      return context.l10n.commonNone;
    }

    final counts = <ReportCategory, int>{};
    for (final pin in pins) {
      counts[pin.category] = (counts[pin.category] ?? 0) + 1;
    }

    ReportCategory? topCategory;
    var topCount = 0;
    for (final entry in counts.entries) {
      if (entry.value > topCount) {
        topCategory = entry.key;
        topCount = entry.value;
      }
    }

    return topCategory?.localizedLabel(context) ?? context.l10n.commonNone;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Filters Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(context.l10n.mapAllCategories),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                  selectedColor: const Color(0xFFE2F3EE),
                  checkmarkColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFDDE5E2)),
                  ),
                ),
                const SizedBox(width: 8),
                ...ReportCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.localizedLabel(context)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                      selectedColor: const Color(0xFFE2F3EE),
                      checkmarkColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFDDE5E2)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Status & Priority Filters Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Status Filters
                      FilterChip(
                        label: Text(context.l10n.mapAllStatuses),
                        selected: _selectedStatus == null,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = null),
                        selectedColor: const Color(0xFFE2F3EE),
                        checkmarkColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFDDE5E2)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...ReportStatus.values.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.localizedLabel(context)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? status : null;
                              });
                            },
                            selectedColor: const Color(0xFFE2F3EE),
                            checkmarkColor: const Color(0xFF0F766E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xFFDDE5E2)),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 16),
                      // Priority threshold selector
                      DropdownButton<int>(
                        value: _minPriority,
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _minPriority = val);
                          }
                        },
                        underline: Container(),
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Text(context.l10n.mapAllPriorities),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text(context.l10n.mapMinimumPriority(3)),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text(context.l10n.mapMinimumPriority(5)),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text(context.l10n.mapMinimumPriority(10)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),

        // Main Map Canvas
        Expanded(
          child: FutureBuilder<List<ReportMapPin>>(
            future: _pinsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  _pins.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final pins = _pins.isNotEmpty
                  ? _pins
                  : (snapshot.data ?? const <ReportMapPin>[]);
              final filteredPins = pins.where((pin) {
                if (_selectedCategory != null &&
                    pin.category != _selectedCategory) {
                  return false;
                }
                if (_selectedStatus != null && pin.status != _selectedStatus) {
                  return false;
                }
                if (pin.priorityScore < _minPriority) {
                  return false;
                }
                return true;
              }).toList();

              // Calculate invisible metrics
              final submittedCount = filteredPins
                  .where((p) => p.status == ReportStatus.submitted)
                  .length;
              final fixedCount = filteredPins
                  .where((p) => p.status == ReportStatus.fixed)
                  .length;
              final cancelledCount = filteredPins
                  .where((p) => p.status == ReportStatus.cancelled)
                  .length;
              final highPriorityCount = filteredPins
                  .where((p) => p.priorityScore >= 5)
                  .length;
              final priorityTotal = filteredPins.fold<int>(
                0,
                (total, pin) => total + pin.priorityScore,
              );
              final averagePriority = filteredPins.isEmpty
                  ? 0
                  : (priorityTotal / filteredPins.length).round();
              final topCategoryLabel = _topCategoryLabel(context, filteredPins);

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1040;
                  const queueWidth = 430.0;
                  const queueInset = 16.0;
                  const queueReserveWidth = queueWidth + queueInset + 16.0;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDDE5E2)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: const LatLng(16.0544, 108.2022),
                                initialZoom: 13.0,
                                minZoom: 4.0,
                                maxZoom: 18.0,
                                onTap: (_, __) {
                                  _searchFocusNode.unfocus();
                                  setState(() {
                                    _selectedPin = null;
                                    _selectedPinDetails = null;
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
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.smartcity.report',
                                ),
                                MarkerLayer(
                                  markers: [
                                    ...filteredPins.map((pin) {
                                      final isCurrentlySelected =
                                          _selectedPin?.id == pin.id;
                                      final isMultiSelected = _selectedReportIds
                                          .contains(pin.id);

                                      return Marker(
                                        point: LatLng(
                                          pin.latitude,
                                          pin.longitude,
                                        ),
                                        width: 80,
                                        height: 80,
                                        child: GestureDetector(
                                          key: ValueKey<String>(
                                            'overseerMapPin-${pin.id}',
                                          ),
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            if (_multiSelectMode) {
                                              if (_canCreateTaskForPin(pin)) {
                                                _toggleReportSelection(pin.id);
                                              }
                                            } else {
                                              _selectPin(pin);
                                            }
                                          },
                                          child: _OverseerMapMarker(
                                            pin: pin,
                                            isSelected: isCurrentlySelected,
                                            isMultiSelected: isMultiSelected,
                                            multiSelectMode: _multiSelectMode,
                                          ),
                                        ),
                                      );
                                    }),
                                    if (_searchedPlaceLocation != null)
                                      Marker(
                                        point: _searchedPlaceLocation!,
                                        width: 145,
                                        height: 90,
                                        child: _SearchedPlaceMarker(
                                          name:
                                              _searchedPlaceName ??
                                              context.l10n.mapSearchedLocation,
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
                                CurrentLocationMapLayer(
                                  mapController: _mapController,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Floating Search Box Overlay
                      Positioned(
                        top: 12,
                        left: 28,
                        right: isWide ? queueReserveWidth : 28,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SearchBar(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchQueryChanged,
                              onSubmitted: _searchAddresses,
                              onSearch: () => _searchAddresses(),
                              isSearching: _isSearchingAddress,
                              onClear: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _addressSuggestions = [];
                                  _isSearchingAddress = false;
                                  _hasSearchedAddress = false;
                                  _searchedPlaceLocation = null;
                                  _searchedPlaceName = null;
                                });
                              },
                            ),
                            if (_searchQuery.isNotEmpty &&
                                _searchFocusNode.hasFocus)
                              _SearchSuggestions(
                                pins: filteredPins,
                                addresses: _addressSuggestions,
                                query: _searchQuery,
                                isSearchingAddress: _isSearchingAddress,
                                hasSearchedAddress: _hasSearchedAddress,
                                onSelectPin: (pin) {
                                  setState(() {
                                    _selectedPin = pin;
                                    _searchController.text = pin.title;
                                    _searchQuery = '';
                                    _addressSuggestions = [];
                                    _hasSearchedAddress = false;
                                    _searchFocusNode.unfocus();
                                  });
                                  _mapController.move(
                                    LatLng(pin.latitude, pin.longitude),
                                    15.0,
                                  );
                                  _selectPin(pin);
                                },
                                onSelectAddress: (addr) {
                                  final point = LatLng(
                                    addr.latitude,
                                    addr.longitude,
                                  );

                                  setState(() {
                                    _searchedPlaceLocation = point;
                                    _searchedPlaceName = addr.displayName;
                                    _searchController.text = addr.displayName;
                                    _searchQuery = '';
                                    _addressSuggestions = [];
                                    _hasSearchedAddress = false;
                                    _searchFocusNode.unfocus();
                                  });
                                  _mapController.move(point, 15.0);
                                },
                              ),
                          ],
                        ),
                      ),

                      // Floating analytics panel for overseer triage
                      Positioned(
                        top: 72,
                        left: 28,
                        right: isWide ? queueReserveWidth : 28,
                        child: _OverseerAnalyticsPanel(
                          totalCount: filteredPins.length,
                          submittedCount: submittedCount,
                          fixedCount: fixedCount,
                          cancelledCount: cancelledCount,
                          highPriorityCount: highPriorityCount,
                          averagePriority: averagePriority,
                          topCategoryLabel: topCategoryLabel,
                        ),
                      ),

                      if (isWide)
                        Positioned(
                          top: 12,
                          right: queueInset,
                          bottom: queueInset,
                          width: queueWidth,
                          child: _ReportQueuePanel(
                            pins: filteredPins,
                            selectedReportIds: _selectedReportIds,
                            multiSelectMode: _multiSelectMode,
                            onToggleMultiSelectMode: _toggleMultiSelectMode,
                            onOpenPin: _openQueuePin,
                            onToggleSelection: _toggleReportSelection,
                            onCreateTask: _createTaskForSingleReport,
                          ),
                        ),

                      // Single selected pin sheet
                      if (_selectedPin != null && !_multiSelectMode)
                        Positioned(
                          left: 28,
                          right: isWide ? queueReserveWidth : 28,
                          bottom: 28,
                          child: _SelectedPinDetailsCard(
                            pin: _selectedPin!,
                            details: _selectedPinDetails,
                            isLoading: _isLoadingDetails,
                            onClose: () {
                              setState(() {
                                _selectedPin = null;
                                _selectedPinDetails = null;
                              });
                            },
                            onQuickFix: () => _quickFix(_selectedPin!.id),
                            onCreateTask: () =>
                                _createTaskForSingleReport(_selectedPin!.id),
                            onViewDetails: () {
                              Navigator.of(context)
                                  .pushNamed(
                                    AppRoutes.overseerReportDetail,
                                    arguments: _selectedPin!.id,
                                  )
                                  .then((_) => _refresh());
                            },
                          ),
                        ),

                      // Multi-select actions floating button
                      if (_multiSelectMode && _selectedReportIds.isNotEmpty)
                        Positioned(
                          left: 28,
                          right: isWide ? queueReserveWidth : 28,
                          bottom: 28,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: const Color(0xFF0F766E),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.l10n.selectedReportCount(
                                      _selectedReportIds.length,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _createTaskFromSelection,
                                    icon: const Icon(
                                      Icons.add_task_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      context.l10n.mapCreateRepairTask,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0F766E),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Marker Widget with status indicators and upvote badges
class _OverseerMapMarker extends StatefulWidget {
  const _OverseerMapMarker({
    required this.pin,
    required this.isSelected,
    required this.isMultiSelected,
    required this.multiSelectMode,
  });

  final ReportMapPin pin;
  final bool isSelected;
  final bool isMultiSelected;
  final bool multiSelectMode;

  @override
  State<_OverseerMapMarker> createState() => _OverseerMapMarkerState();
}

class _OverseerMapMarkerState extends State<_OverseerMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isSelected) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _OverseerMapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isSelected && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.pin.status);
    final categoryColor = _getCategoryColor(widget.pin.category);
    final icon = _getCategoryIcon(widget.pin.category);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing Selection Overlay
        if (widget.isSelected)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 50 * _pulseController.value + 20,
                height: 50 * _pulseController.value + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(
                    (1 - _pulseController.value) * 0.4,
                  ),
                ),
              );
            },
          ),

        // Glowing selection frame for multi-select
        if (widget.multiSelectMode && widget.isMultiSelected)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(color: const Color(0xFF0F766E), width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

        // The Pin Body
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
                  color: widget.isSelected ? statusColor : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: Icon(
                  icon,
                  size: 20,
                  color: widget.isSelected ? Colors.white : categoryColor,
                ),
              ),
              CustomPaint(
                painter: _PinTrianglePainter(color: statusColor),
                size: const Size(10, 6),
              ),
            ],
          ),
        ),

        // Upvote/Priority Score Badge
        if (widget.pin.priorityScore > 0)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2)],
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  widget.pin.priorityScore.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Multi-select Checkbox indicator overlay
        if (widget.multiSelectMode && widget.isMultiSelected)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0F766E),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.check, color: Colors.white, size: 10),
            ),
          ),
      ],
    );
  }
}

// Color/Icon helpers matching citizen's look
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

Color _getStatusColor(ReportStatus status) {
  switch (status) {
    case ReportStatus.submitted:
      return const Color(0xFFE11D48); // Red
    case ReportStatus.inProgress:
      return const Color(0xFFB45309);
    case ReportStatus.fixed:
      return const Color(0xFF0F766E); // Green
    case ReportStatus.cancelled:
      return Colors.blueGrey.shade400; // Grey
  }
}

// Triangle painter for pins
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

class _OverseerAnalyticsPanel extends StatelessWidget {
  const _OverseerAnalyticsPanel({
    required this.totalCount,
    required this.submittedCount,
    required this.fixedCount,
    required this.cancelledCount,
    required this.highPriorityCount,
    required this.averagePriority,
    required this.topCategoryLabel,
  });

  final int totalCount;
  final int submittedCount;
  final int fixedCount;
  final int cancelledCount;
  final int highPriorityCount;
  final int averagePriority;
  final String topCategoryLabel;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _AnalyticTile(
        icon: Icons.radar_outlined,
        label: context.l10n.mapMetricVisible,
        value: totalCount.toString(),
        color: const Color(0xFF1D4ED8),
      ),
      _AnalyticTile(
        icon: Icons.pending_actions_outlined,
        label: context.l10n.reportStatusSubmitted,
        value: submittedCount.toString(),
        color: const Color(0xFFE11D48),
      ),
      _AnalyticTile(
        icon: Icons.priority_high_outlined,
        label: context.l10n.mapMetricHighPriority,
        value: highPriorityCount.toString(),
        color: const Color(0xFFD97706),
      ),
      _AnalyticTile(
        icon: Icons.speed_outlined,
        label: context.l10n.mapMetricAveragePriority,
        value: averagePriority.toString(),
        color: const Color(0xFF7C3AED),
      ),
      _AnalyticTile(
        icon: Icons.category_outlined,
        label: context.l10n.mapMetricTopCategory,
        value: topCategoryLabel,
        color: const Color(0xFF0F766E),
      ),
      _AnalyticTile(
        icon: Icons.done_all_outlined,
        label: context.l10n.mapMetricClosedOut,
        value: (fixedCount + cancelledCount).toString(),
        color: Colors.blueGrey,
      ),
    ];

    return Material(
      elevation: 4,
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDE5E2)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tile in tiles) ...[
                      SizedBox(width: 132, child: tile),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              );
            }

            return Row(
              children: [
                for (final tile in tiles) ...[
                  Expanded(child: tile),
                  if (tile != tiles.last) const SizedBox(width: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnalyticTile extends StatelessWidget {
  const _AnalyticTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportQueuePanel extends StatelessWidget {
  const _ReportQueuePanel({
    required this.pins,
    required this.selectedReportIds,
    required this.multiSelectMode,
    required this.onToggleMultiSelectMode,
    required this.onOpenPin,
    required this.onToggleSelection,
    required this.onCreateTask,
  });

  final List<ReportMapPin> pins;
  final Set<String> selectedReportIds;
  final bool multiSelectMode;
  final VoidCallback onToggleMultiSelectMode;
  final ValueChanged<ReportMapPin> onOpenPin;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onCreateTask;

  List<ReportMapPin> get _rows {
    final sortedPins = pins.toList()
      ..sort((a, b) {
        final statusComparison = _statusRank(
          a.status,
        ).compareTo(_statusRank(b.status));
        if (statusComparison != 0) {
          return statusComparison;
        }

        final priorityComparison = b.priorityScore.compareTo(a.priorityScore);
        if (priorityComparison != 0) {
          return priorityComparison;
        }

        return b.upvoteCount.compareTo(a.upvoteCount);
      });

    return sortedPins.take(10).toList(growable: false);
  }

  int _statusRank(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return 0;
      case ReportStatus.inProgress:
        return 1;
      case ReportStatus.fixed:
        return 2;
      case ReportStatus.cancelled:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;

    return Material(
      elevation: 6,
      color: Colors.white.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDE5E2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.table_rows_outlined,
                    size: 18,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.mapOperationsQueue,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F3EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${pins.length}',
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: context.l10n.mapSelectMultipleTooltip,
                    onPressed: onToggleMultiSelectMode,
                    icon: Icon(
                      multiSelectMode
                          ? Icons.check_box
                          : Icons.check_box_outlined,
                      color: multiSelectMode
                          ? const Color(0xFF0F766E)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const _QueueHeaderRow(),
            const Divider(height: 1),
            if (rows.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    context.l10n.mapNoReportsInView,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final pin = rows[index];
                    final isActionable = pin.status == ReportStatus.submitted;
                    return _ReportQueueRow(
                      pin: pin,
                      selected: selectedReportIds.contains(pin.id),
                      multiSelectMode: multiSelectMode,
                      onOpen: isActionable ? () => onOpenPin(pin) : null,
                      onToggleSelection: isActionable
                          ? () => onToggleSelection(pin.id)
                          : null,
                      onCreateTask: isActionable
                          ? () => onCreateTask(pin.id)
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QueueHeaderRow extends StatelessWidget {
  const _QueueHeaderRow();

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: Colors.grey.shade600,
      fontSize: 10,
      fontWeight: FontWeight.w800,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Center(
              child: Text(context.l10n.mapTableCategory, style: textStyle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(context.l10n.mapTableReport, style: textStyle),
          ),
          SizedBox(
            width: 78,
            child: Text(context.l10n.mapTableStatus, style: textStyle),
          ),
          SizedBox(
            width: 44,
            child: Text(
              context.l10n.mapTablePriority,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              context.l10n.mapTableVotes,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _ReportQueueRow extends StatelessWidget {
  const _ReportQueueRow({
    required this.pin,
    required this.selected,
    required this.multiSelectMode,
    required this.onOpen,
    required this.onToggleSelection,
    required this.onCreateTask,
  });

  final ReportMapPin pin;
  final bool selected;
  final bool multiSelectMode;
  final VoidCallback? onOpen;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(pin.status);
    final isActionable = onOpen != null;
    final content = Opacity(
      opacity: isActionable ? 1 : 0.68,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 9, 8, 9),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: _QueueCategoryCell(
                pin: pin,
                selected: selected,
                multiSelectMode: multiSelectMode,
                onToggleSelection: onToggleSelection,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Text(
                pin.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActionable
                      ? Colors.grey.shade900
                      : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 78, child: _StatusPill(status: pin.status)),
            SizedBox(
              width: 44,
              child: Text(
                pin.priorityScore.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pin.priorityScore >= 5 && isActionable
                      ? const Color(0xFFE11D48)
                      : Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 46,
              child: Text(
                pin.upvoteCount.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: IconButton(
                tooltip: isActionable
                    ? context.l10n.taskCreate
                    : context.l10n.mapTaskUnavailable,
                onPressed: onCreateTask,
                icon: Icon(
                  Icons.add_task_outlined,
                  size: 18,
                  color: isActionable ? statusColor : Colors.grey.shade400,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );

    if (!isActionable) {
      return content;
    }

    return InkWell(
      onTap: onOpen,
      hoverColor: const Color(0xFFE2F3EE).withValues(alpha: 0.55),
      child: content,
    );
  }
}

class _QueueCategoryCell extends StatelessWidget {
  const _QueueCategoryCell({
    required this.pin,
    required this.selected,
    required this.multiSelectMode,
    required this.onToggleSelection,
  });

  final ReportMapPin pin;
  final bool selected;
  final bool multiSelectMode;
  final VoidCallback? onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(pin.category);
    final canSelect = multiSelectMode && onToggleSelection != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 24,
          child: Center(
            child: canSelect
                ? Checkbox(
                    value: selected,
                    onChanged: (_) => onToggleSelection?.call(),
                    visualDensity: VisualDensity.compact,
                  )
                : Icon(
                    _getCategoryIcon(pin.category),
                    size: 18,
                    color: categoryColor,
                  ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          pin.category.localizedLabel(context),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: categoryColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        status.localizedLabel(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Search bar overlays
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearch,
    required this.isSearching,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;
  final bool isSearching;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: context.l10n.mapOverseerSearchHint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: IconButton(
            tooltip: context.l10n.mapSearchPlacesTooltip,
            onPressed: isSearching ? null : onSearch,
            icon: const Icon(Icons.search, color: Colors.grey),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
    required this.hasSearchedAddress,
    required this.onSelectPin,
    required this.onSelectAddress,
  });

  final List<ReportMapPin> pins;
  final List<PlaceSearchResult> addresses;
  final String query;
  final bool isSearchingAddress;
  final bool hasSearchedAddress;
  final ValueChanged<ReportMapPin> onSelectPin;
  final ValueChanged<PlaceSearchResult> onSelectAddress;

  @override
  Widget build(BuildContext context) {
    final filteredPins = pins.where((pin) {
      final titleMatch = pin.title.toLowerCase().contains(query.toLowerCase());
      final normalizedQuery = query.toLowerCase();
      final categoryMatch =
          pin.category
              .localizedLabel(context)
              .toLowerCase()
              .contains(normalizedQuery) ||
          pin.category.label.toLowerCase().contains(normalizedQuery);
      return titleMatch || categoryMatch;
    }).toList();

    if (filteredPins.isEmpty && addresses.isEmpty && !isSearchingAddress) {
      if (!hasSearchedAddress) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.only(top: 4),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDE5E2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Text(
          context.l10n.mapNoSearchMatches,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE5E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 4),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  context.l10n.mapReportsHeader,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...filteredPins.map((pin) {
                final categoryColor = _getCategoryColor(pin.category);
                final icon = _getCategoryIcon(pin.category);
                return ListTile(
                  dense: true,
                  leading: Icon(icon, color: categoryColor, size: 18),
                  title: Text(
                    pin.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.mapCategoryAndStatus(
                      pin.category.localizedLabel(context),
                      pin.status.localizedLabel(context),
                    ),
                    style: TextStyle(
                      color: _getStatusColor(pin.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => onSelectPin(pin),
                );
              }),
            ],
            if (addresses.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  context.l10n.mapPlacesHeader,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...addresses.map((addr) {
                return ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.place,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  title: Text(
                    addr.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
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
                child: const Icon(Icons.close, color: Colors.white, size: 10),
              ),
            ],
          ),
        ),
        const Icon(Icons.location_on, color: Colors.redAccent, size: 32),
      ],
    );
  }
}

// Custom Premium Detail Sheet for Overseer
class _SelectedPinDetailsCard extends StatelessWidget {
  const _SelectedPinDetailsCard({
    required this.pin,
    required this.details,
    required this.isLoading,
    required this.onClose,
    required this.onQuickFix,
    required this.onCreateTask,
    required this.onViewDetails,
  });

  final ReportMapPin pin;
  final Report? details;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onQuickFix;
  final VoidCallback onCreateTask;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(pin.status);
    final categoryColor = _getCategoryColor(pin.category);

    return Card(
      elevation: 8,
      shadowColor: statusColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
      ),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, statusColor.withOpacity(0.04)],
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusLabelChip(status: pin.status),
                          const SizedBox(width: 8),
                          Text(
                            pin.category.localizedLabel(context),
                            style: TextStyle(
                              color: categoryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  color: Colors.grey,
                ),
              ],
            ),
            const Divider(height: 16),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else if (details != null) ...[
              // Description
              if (details!.description.isNotEmpty) ...[
                Text(
                  details!.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],

              // Address text
              if ((details!.addressText ?? '').trim().isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        details!.addressText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Mini Photo Preview & Meta tags
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (details!.beforePhotoUrl != null &&
                      details!.beforePhotoUrl!.isNotEmpty) ...[
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: UploadedPhotoView(
                          fileUrl: details!.beforePhotoUrl,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MiniMetadataTag(
                          icon: Icons.thumb_up_alt_outlined,
                          label: context.l10n.upvoteCount(pin.upvoteCount),
                        ),
                        _MiniMetadataTag(
                          icon: Icons.trending_up,
                          label: context.l10n.priorityValue(pin.priorityScore),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else
              // Fallback basic metrics if loading details failed
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniMetadataTag(
                    icon: Icons.place_outlined,
                    label:
                        '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)}',
                  ),
                  _MiniMetadataTag(
                    icon: Icons.thumb_up_alt_outlined,
                    label: context.l10n.upvoteCount(pin.upvoteCount),
                  ),
                  _MiniMetadataTag(
                    icon: Icons.trending_up,
                    label: context.l10n.priorityValue(pin.priorityScore),
                  ),
                ],
              ),

            const SizedBox(height: 12),
            // Actions
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(context.l10n.mapViewFullDetails),
                ),
                if (pin.status == ReportStatus.submitted) ...[
                  OutlinedButton.icon(
                    onPressed: onQuickFix,
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: Text(context.l10n.mapMarkFixed),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F766E),
                      side: const BorderSide(color: Color(0xFF0F766E)),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onCreateTask,
                    icon: const Icon(Icons.add_task_outlined, size: 14),
                    label: Text(context.l10n.taskCreate),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

class _StatusLabelChip extends StatelessWidget {
  const _StatusLabelChip({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Text(
        status.localizedLabel(context),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniMetadataTag extends StatelessWidget {
  const _MiniMetadataTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
