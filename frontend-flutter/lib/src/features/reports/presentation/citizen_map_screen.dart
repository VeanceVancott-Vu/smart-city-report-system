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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isMapView
                    ? context.l10n.mapViewTitle
                    : context.l10n.reportListViewTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: context.l10n.mapRefreshVisibleArea,
                    icon: const Icon(Icons.refresh),
                    onPressed: refresh,
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: true,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(context.l10n.commonMap),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        icon: const Icon(Icons.list_alt_outlined),
                        label: Text(context.l10n.commonList),
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
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(context.l10n.mapAllCategories),
                  selected: _selectedCategory == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                  selectedColor: const Color(0xFFE2F3EE),
                  checkmarkColor: const Color(0xFF00796B),
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
                      checkmarkColor: const Color(0xFF00796B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFDDE5E2)),
                      ),
                    ),
                  );
                }),
                if (_currentUser != null)
                  FilterChip(
                    avatar: Icon(
                      _hideOwnReports
                          ? Icons.person_off
                          : Icons.person_off_outlined,
                      size: 16,
                      color: _hideOwnReports
                          ? const Color(0xFF00796B)
                          : Colors.grey,
                    ),
                    label: Text(context.l10n.mapHideMyReports),
                    selected: _hideOwnReports,
                    onSelected: (selected) {
                      setState(() {
                        _hideOwnReports = selected;
                      });
                    },
                    selectedColor: const Color(0xFFE2F3EE),
                    checkmarkColor: const Color(0xFF00796B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFDDE5E2)),
                    ),
                  ),
              ],
            ),
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
        Expanded(
          child: FutureBuilder<List<ReportMapPin>>(
            future: _pinsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  _pins.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError && _pins.isEmpty) {
                return _ErrorState(
                  message: context.l10n.mapOpenPinsLoadFailed,
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
                              initialCenter: LatLng(10.7769, 106.7009),
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
                                      point: LatLng(
                                        pin.latitude,
                                        pin.longitude,
                                      ),
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
                                        child: _MapMarker(
                                          pin: pin,
                                          isSelected:
                                              _selectedPin?.id == pin.id,
                                        ),
                                      ),
                                    );
                                  }).toList(),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 28,
                      right: 28,
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
                    if (_selectedPin != null)
                      Positioned(
                        left: 28,
                        right: 28,
                        bottom: 28,
                        child: _SelectedPinCard(
                          pin: _selectedPin!,
                          hasUpvoted: _upvotedReportIds.contains(
                            _selectedPin!.id,
                          ),
                          onUpvote: () => _toggleUpvote(_selectedPin!),
                          onViewDetails: () => _openDetails(_selectedPin!),
                          onClose: () {
                            setState(() {
                              _selectedPin = null;
                            });
                          },
                          showUpvote:
                              _currentUser == null ||
                              _selectedPin!.creatorId != _currentUser!.id,
                        ),
                      ),
                  ],
                );
              }

              if (filteredPins.isEmpty) {
                return RefreshIndicator(
                  onRefresh: refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 96),
                      Center(child: Text(context.l10n.mapNoOpenPins)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: filteredPins.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _PinTile(
                    pin: filteredPins[index],
                    hasUpvoted: _upvotedReportIds.contains(
                      filteredPins[index].id,
                    ),
                    onUpvote: () => _toggleUpvote(filteredPins[index]),
                    onViewDetails: () => _openDetails(filteredPins[index]),
                    showUpvote:
                        _currentUser == null ||
                        filteredPins[index].creatorId != _currentUser!.id,
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
          hintText: context.l10n.mapCitizenSearchHint,
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
      constraints: const BoxConstraints(maxHeight: 300),
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
                final color = _getCategoryColor(pin.category);
                final icon = _getCategoryIcon(pin.category);
                return ListTile(
                  dense: true,
                  leading: Icon(icon, color: color, size: 18),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    pin.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(pin.category.localizedLabel(context)),
                  side: BorderSide.none,
                  backgroundColor: const Color(0xFFE2F3EE),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.place_outlined,
                  label:
                      '${pin.latitude.toStringAsFixed(4)}, ${pin.longitude.toStringAsFixed(4)}',
                ),
                _MetaChip(
                  icon: Icons.thumb_up_alt_outlined,
                  label: context.l10n.upvoteCount(pin.upvoteCount),
                ),
                _MetaChip(
                  icon: Icons.trending_up,
                  label: context.l10n.priorityValue(pin.priorityScore),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline),
                    label: Text(context.l10n.mapViewDetails),
                  ),
                  if (showUpvote)
                    OutlinedButton.icon(
                      onPressed: onUpvote,
                      icon: Icon(
                        hasUpvoted
                            ? Icons.thumb_down_alt_outlined
                            : Icons.thumb_up_alt_outlined,
                      ),
                      label: Text(
                        hasUpvoted
                            ? context.l10n.mapRemoveUpvote
                            : context.l10n.mapSeeThisToo,
                      ),
                    ),
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
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: const BorderSide(color: Color(0xFFDDE5E2)),
      backgroundColor: Colors.white,
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
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
    final color = _getCategoryColor(pin.category);

    return Card(
      elevation: 6,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2), width: 1.5),
      ),
      color: Colors.white.withOpacity(0.95),
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.95), color.withOpacity(0.05)],
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
                      Text(
                        context.l10n.mapCategoryValue(
                          pin.category.localizedLabel(context),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
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
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: Text(context.l10n.mapViewDetails),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.55)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (showUpvote)
                    FilledButton.icon(
                      onPressed: onUpvote,
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        hasUpvoted
                            ? Icons.thumb_down_alt_outlined
                            : Icons.thumb_up_alt_outlined,
                        size: 16,
                      ),
                      label: Text(
                        hasUpvoted
                            ? context.l10n.mapRemoveUpvote
                            : context.l10n.mapSeeThisToo,
                      ),
                    ),
                ],
              ),
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
