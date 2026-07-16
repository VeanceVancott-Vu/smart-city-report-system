import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/location/geocoding_service.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_feedback.dart';
import '../../auth/data/auth_api_service.dart';
import '../../auth/domain/current_user.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';
import 'report_category_visuals.dart';

class CitizenMapScreen extends StatefulWidget {
  const CitizenMapScreen({
    super.key,
    required this.reportApiService,
    required this.authApiService,
    this.geocodingService,
  });

  final ReportApiService reportApiService;
  final AuthApiService authApiService;
  final GeocodingService? geocodingService;

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
      _showError(context.l10n.mapUpvoteUpdateFailed);
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
      title: context.l10n.reportUpdateFailedTitle,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        return Scaffold(
          backgroundColor: colorScheme.surfaceContainerLowest,
          body: SafeArea(
            child: Column(
              children: [
                _MapTopBar(
                  isMapView: _isMapView,
                  isDesktop: isDesktop,
                  onRefresh: refresh,
                  onViewChanged: (value) {
                    setState(() {
                      _isMapView = value;
                      if (!_isMapView) {
                        _selectedPin = null;
                      }
                    });
                  },
                ),
                _FilterBar(
                  selectedCategory: _selectedCategory,
                  hideOwnReports: _hideOwnReports,
                  showHideOwnReports: _currentUser != null,
                  onCategoryChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                  onHideOwnReportsChanged: (value) {
                    setState(() => _hideOwnReports = value);
                  },
                ),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18,
                          color: colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: FutureBuilder<List<ReportMapPin>>(
                    future: _pinsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done &&
                          _pins.isEmpty) {
                        return const _MapLoadingState();
                      }

                      if (snapshot.hasError && _pins.isEmpty) {
                        return _ErrorState(
                          message: 'Unable to load open report pins.',
                          onRetry: refresh,
                        );
                      }

                      final pins = _pins.isNotEmpty
                          ? _pins
                          : (snapshot.data ?? const <ReportMapPin>[]);
                      final filteredPins = pins.where((pin) {
                        if (_selectedCategory != null &&
                            pin.category != _selectedCategory) {
                          return false;
                        }
                        if (_hideOwnReports &&
                            _currentUser != null &&
                            pin.creatorId == _currentUser!.id) {
                          return false;
                        }
                        return true;
                      }).toList();

                      if (_isMapView) {
                        return _buildMapView(
                          context,
                          filteredPins,
                          isDesktop,
                        );
                      }

                      if (filteredPins.isEmpty) {
                        return _EmptyMapListState(onRefresh: refresh);
                      }

                      return RefreshIndicator(
                        onRefresh: refresh,
                        child: isDesktop
                            ? GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  12,
                                  24,
                                  32,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 520,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  mainAxisExtent: 184,
                                ),
                                itemCount: filteredPins.length,
                                itemBuilder: (context, index) => _PinTile(
                                  pin: filteredPins[index],
                                  hasUpvoted: _upvotedReportIds.contains(
                                    filteredPins[index].id,
                                  ),
                                  onUpvote: () =>
                                      _toggleUpvote(filteredPins[index]),
                                  onViewDetails: () =>
                                      _openDetails(filteredPins[index]),
                                  showUpvote:
                                      _currentUser == null ||
                                      filteredPins[index].creatorId !=
                                          _currentUser!.id,
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  10,
                                  16,
                                  32,
                                ),
                                itemCount: filteredPins.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) => _PinTile(
                                  pin: filteredPins[index],
                                  hasUpvoted: _upvotedReportIds.contains(
                                    filteredPins[index].id,
                                  ),
                                  onUpvote: () =>
                                      _toggleUpvote(filteredPins[index]),
                                  onViewDetails: () =>
                                      _openDetails(filteredPins[index]),
                                  showUpvote:
                                      _currentUser == null ||
                                      filteredPins[index].creatorId !=
                                          _currentUser!.id,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView(
    BuildContext context,
    List<ReportMapPin> filteredPins,
    bool isDesktop,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 20 : 0,
        0,
        isDesktop ? 20 : 0,
        isDesktop ? 20 : 0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
        child: Stack(
          children: [
            Positioned.fill(
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartcity.report',
                  ),
                  MarkerLayer(
                    markers: [
                      ...filteredPins.map((pin) {
                        return Marker(
                          point: LatLng(pin.latitude, pin.longitude),
                          width: 72,
                          height: 72,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _searchFocusNode.unfocus();
                              setState(() => _selectedPin = pin);
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
                            name:
                                _searchedPlaceName ?? 'Searched location',
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
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SearchBar(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchQueryChanged,
                        onSubmitted: _searchAddresses,
                        onSearch: _searchAddresses,
                        isSearching: _isSearchingAddress,
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
                              _searchFocusNode.unfocus();
                            });
                            _mapController.move(
                              LatLng(pin.latitude, pin.longitude),
                              15.0,
                            );
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
            Positioned(
              right: 16,
              bottom: _selectedPin == null ? 18 : (isDesktop ? 190 : 230),
              child: FloatingActionButton.small(
                heroTag: 'citizen_map_refresh_visible',
                tooltip: 'Refresh visible area',
                onPressed: refresh,
                backgroundColor: colorScheme.surface,
                foregroundColor: colorScheme.primary,
                child: const Icon(Icons.refresh),
              ),
            ),
            if (_selectedPin != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Align(
                  alignment: isDesktop
                      ? Alignment.bottomRight
                      : Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: _SelectedPinCard(
                      pin: _selectedPin!,
                      hasUpvoted:
                          _upvotedReportIds.contains(_selectedPin!.id),
                      onUpvote: () => _toggleUpvote(_selectedPin!),
                      onViewDetails: () => _openDetails(_selectedPin!),
                      onClose: () {
                        setState(() => _selectedPin = null);
                      },
                      showUpvote:
                          _currentUser == null ||
                          _selectedPin!.creatorId != _currentUser!.id,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.isMapView,
    required this.isDesktop,
    required this.onRefresh,
    required this.onViewChanged,
  });

  final bool isMapView;
  final bool isDesktop;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 16,
        14,
        isDesktop ? 24 : 16,
        10,
      ),
      color: colorScheme.surface,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.location_city_outlined,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMapView ? 'Explore city issues' : 'Nearby reports',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isMapView
                      ? 'Browse and confirm issues reported around the city.'
                      : 'Review reports currently visible in this area.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment<bool>(
                value: true,
                icon: const Icon(Icons.map_outlined),
                label: isDesktop ? const Text('Map') : null,
              ),
              ButtonSegment<bool>(
                value: false,
                icon: const Icon(Icons.view_list_outlined),
                label: isDesktop ? const Text('List') : null,
              ),
            ],
            selected: {isMapView},
            onSelectionChanged: (value) => onViewChanged(value.first),
            showSelectedIcon: false,
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh visible area',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedCategory,
    required this.hideOwnReports,
    required this.showHideOwnReports,
    required this.onCategoryChanged,
    required this.onHideOwnReportsChanged,
  });

  final ReportCategory? selectedCategory;
  final bool hideOwnReports;
  final bool showHideOwnReports;
  final ValueChanged<ReportCategory?> onCategoryChanged;
  final ValueChanged<bool> onHideOwnReportsChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategoryChanged(null),
                  ),
                  const SizedBox(width: 8),
                  ...ReportCategory.values.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          _getCategoryIcon(category),
                          size: 16,
                        ),
                        label: Text(category.localizedLabel(context)),
                        selected: selectedCategory == category,
                        onSelected: (_) => onCategoryChanged(category),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (showHideOwnReports) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: hideOwnReports
                  ? 'Show my reports'
                  : 'Hide my reports',
              child: IconButton.filledTonal(
                onPressed: () =>
                    onHideOwnReportsChanged(!hideOwnReports),
                icon: Icon(
                  hideOwnReports
                      ? Icons.person_off
                      : Icons.person_outline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading nearby reports',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMapListState extends StatelessWidget {
  const _EmptyMapListState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 72),
          Icon(
            Icons.location_searching_outlined,
            size: 58,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'No reports in this area',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Move the map or change the filters to explore other reports.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      elevation: 5,
      shadowColor: colorScheme.shadow.withOpacity(0.18),
      borderRadius: BorderRadius.circular(18),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: 'Search reports, categories or places',
          prefixIcon: IconButton(
            tooltip: 'Search',
            onPressed: isSearching ? null : onSearch,
            icon: isSearching
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear search',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                )
              : null,
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.7),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 1.5,
            ),
          ),
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
      final categoryMatch = pin.category.label.toLowerCase().contains(
        query.toLowerCase(),
      );
      return titleMatch || categoryMatch;
    }).toList();

    if (filteredPins.isEmpty && addresses.isEmpty && !isSearchingAddress) {
      if (!hasSearchedAddress) {
        return const SizedBox.shrink();
      }
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
                    pin.category.localizedLabel(context),
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
                return ListTile(
                  mouseCursor: SystemMouseCursors.click,
                  dense: true,
                  leading: const Icon(
                    Icons.place,
                    color: Color(0xFFEF4444),
                    size: 18,
                  ),
                  title: Text(
                    addr.displayName,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0F766E),
                    ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _getCategoryColor(pin.category);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onViewDetails,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.75),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      _getCategoryIcon(pin.category),
                      color: categoryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pin.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pin.category.localizedLabel(context),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pin.latitude.toStringAsFixed(4)}, '
                      '${pin.longitude.toStringAsFixed(4)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.thumb_up_alt_outlined,
                    label: '${pin.upvoteCount} upvotes',
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.trending_up,
                    label: 'Priority ${pin.priorityScore}',
                  ),
                  const Spacer(),
                  if (showUpvote)
                    TextButton.icon(
                      onPressed: onUpvote,
                      icon: Icon(
                        hasUpvoted
                            ? Icons.thumb_down_alt_outlined
                            : Icons.thumb_up_alt_outlined,
                        size: 17,
                      ),
                      label: Text(
                        hasUpvoted ? 'Remove' : 'I see this too',
                      ),
                    ),
                ],
              ),
            ],
          ),
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
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: colorScheme.onErrorContainer,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Map unavailable',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _getCategoryIcon(ReportCategory category) {
  return reportCategoryIcon(category);
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

class _MapMarkerState extends State<_MapMarker>
    with SingleTickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _getCategoryColor(pin.category);

    return Material(
      elevation: 8,
      shadowColor: colorScheme.shadow.withOpacity(0.18),
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.75),
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getCategoryIcon(pin.category),
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pin.category.localizedLabel(context),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniTag(
                  icon: Icons.place_outlined,
                  label:
                      '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)}',
                  color: color,
                ),
                _MiniTag(
                  icon: Icons.thumb_up_alt_outlined,
                  label: context.l10n.upvoteCount(pin.upvoteCount),
                  color: color,
                ),
                _MiniTag(
                  icon: Icons.trending_up,
                  label: context.l10n.priorityValue(pin.priorityScore),
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    child: const Text('View details'),
                  ),
                ),
                if (showUpvote) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onUpvote,
                      icon: Icon(
                        hasUpvoted
                            ? Icons.thumb_down_alt_outlined
                            : Icons.thumb_up_alt_outlined,
                        size: 18,
                      ),
                      label: Text(
                        hasUpvoted ? 'Remove upvote' : 'I see this too',
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
