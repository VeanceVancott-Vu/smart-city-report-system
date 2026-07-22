import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';

class CitizenReportListScreen extends StatefulWidget {
  const CitizenReportListScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CitizenReportListScreen> createState() =>
      CitizenReportListScreenState();
}

class CitizenReportListScreenState extends State<CitizenReportListScreen> {
  late Future<List<Report>> _reportsFuture;
  final TextEditingController _searchController = TextEditingController();

  ReportStatus? _selectedStatus;
  String _searchQuery = '';
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void refresh() {
    _reportsFuture = widget.reportApiService.fetchCitizenReports();
  }

  Future<void> reload() async {
    setState(refresh);
    await _reportsFuture;
  }

  Future<void> openCreateReport() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenCreateReport);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  Future<void> _openDetails(String reportId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenReportDetail, arguments: reportId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'citizen_report_list_create_report',
        onPressed: openCreateReport,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.reportNew),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            return Column(
              children: [
                _PageHeader(
                  isDesktop: isDesktop,
                  onCreate: openCreateReport,
                  onRefresh: reload,
                ),
                Expanded(
                  child: FutureBuilder<List<Report>>(
                    future: _reportsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const _LoadingState();
                      }

                      if (snapshot.hasError) {
                        return _ErrorState(
                          message: context.l10n.reportsLoadFailed,
                          onRetry: reload,
                        );
                      }

                      final reports = snapshot.data ?? const <Report>[];
                      final filteredReports = reports.where((r) {
                        final matchesStatus =
                            _selectedStatus == null ||
                            r.status == _selectedStatus;
                        final matchesQuery =
                            r.title.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            r.category.label.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ) ||
                            r.category
                                .localizedLabel(context)
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                        return matchesStatus && matchesQuery;
                      }).toList();

                      if (_sortBy == 'Newest') {
                        filteredReports.sort(
                          (a, b) => b.createdAt.compareTo(a.createdAt),
                        );
                      } else if (_sortBy == 'Oldest') {
                        filteredReports.sort(
                          (a, b) => a.createdAt.compareTo(b.createdAt),
                        );
                      } else if (_sortBy == 'Priority') {
                        filteredReports.sort(
                          (a, b) => b.priorityScore.compareTo(a.priorityScore),
                        );
                      }

                      return Column(
                        children: [
                          _Toolbar(
                            searchController: _searchController,
                            searchQuery: _searchQuery,
                            selectedStatus: _selectedStatus,
                            sortBy: _sortBy,
                            onSearchChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            onClearSearch: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                            onStatusChanged: (status) {
                              setState(() => _selectedStatus = status);
                            },
                            onSortChanged: (value) {
                              setState(() => _sortBy = value);
                            },
                          ),
                          Expanded(
                            child: filteredReports.isEmpty
                                ? _EmptyState(
                                    hasFilters:
                                        _searchQuery.isNotEmpty ||
                                        _selectedStatus != null,
                                    onCreate: openCreateReport,
                                    onClearFilters: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _selectedStatus = null;
                                      });
                                    },
                                    onRefresh: reload,
                                  )
                                : RefreshIndicator(
                                    onRefresh: reload,
                                    child: isDesktop
                                        ? ListView.separated(
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              14,
                                              24,
                                              96,
                                            ),
                                            itemCount: filteredReports.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (context, index) =>
                                                _DesktopReportRow(
                                                  report:
                                                      filteredReports[index],
                                                  onTap: () => _openDetails(
                                                    filteredReports[index].id,
                                                  ),
                                                ),
                                          )
                                        : ListView.separated(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              14,
                                              16,
                                              96,
                                            ),
                                            itemCount: filteredReports.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (context, index) =>
                                                _ReportTile(
                                                  report:
                                                      filteredReports[index],
                                                  onTap: () => _openDetails(
                                                    filteredReports[index].id,
                                                  ),
                                                ),
                                          ),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.isDesktop,
    required this.onCreate,
    required this.onRefresh,
  });

  final bool isDesktop;
  final VoidCallback onCreate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 24 : 16,
        isDesktop ? 22 : 18,
        isDesktop ? 24 : 16,
        18,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.assignment_outlined,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeMyReports,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.reportsTrackProgressDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.l10n.commonRefresh,
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.reportNew),
            ),
          ],
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatus,
    required this.sortBy,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final ReportStatus? selectedStatus;
  final String sortBy;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<ReportStatus?> onStatusChanged;
  final ValueChanged<String> onSortChanged;

  String _localizedSortLabel(BuildContext context, String value) {
    switch (value) {
      case 'Oldest':
        return context.l10n.reportsSortOldest;
      case 'Priority':
        return context.l10n.reportsSortPriority;
      case 'Newest':
      default:
        return context.l10n.reportsSortNewest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: context.l10n.reportsSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: context.l10n.commonClearSearch,
                            onPressed: onClearSearch,
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                initialValue: sortBy,
                onSelected: onSortChanged,
                tooltip: context.l10n.reportsSortTooltip,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Newest',
                    child: Text(context.l10n.reportsSortNewest),
                  ),
                  PopupMenuItem(
                    value: 'Oldest',
                    child: Text(context.l10n.reportsSortOldest),
                  ),
                  PopupMenuItem(
                    value: 'Priority',
                    child: Text(context.l10n.reportsSortPriority),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sort),
                      const SizedBox(width: 8),
                      Text(_localizedSortLabel(context, sortBy)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: Text(context.l10n.commonAll),
                  selected: selectedStatus == null,
                  onSelected: (_) => onStatusChanged(null),
                ),
                const SizedBox(width: 8),
                ...ReportStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status.localizedLabel(context)),
                      selected: selectedStatus == status,
                      onSelected: (selected) =>
                          onStatusChanged(selected ? status : null),
                    ),
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

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final photoUrl = resolveUploadedPhotoUrl(report.beforePhotoUrl);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                clipBehavior: Clip.antiAlias,
                child: photoUrl != null
                    ? UploadedPhotoImage(fileUrl: photoUrl, fit: BoxFit.cover)
                    : Icon(
                        Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.addressText ??
                          context.l10n.commonAddressUnavailable,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaChip(
                          icon: Icons.category_outlined,
                          label: report.category.localizedLabel(context),
                        ),
                        _MetaChip(
                          icon: Icons.trending_up,
                          label: context.l10n.priorityValue(
                            report.priorityScore,
                          ),
                        ),
                        _MetaChip(
                          icon: Icons.thumb_up_alt_outlined,
                          label: '${report.upvoteCount}',
                        ),
                      ],
                    ),
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

class _DesktopReportRow extends StatelessWidget {
  const _DesktopReportRow({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final photoUrl = resolveUploadedPhotoUrl(report.beforePhotoUrl);

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: photoUrl != null
                    ? UploadedPhotoImage(fileUrl: photoUrl, fit: BoxFit.cover)
                    : Icon(
                        Icons.image_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      report.addressText ??
                          context.l10n.commonAddressUnavailable,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  report.category.localizedLabel(context),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(child: _StatusBadge(status: report.status)),
              Expanded(
                child: Text(
                  context.l10n.priorityValue(report.priorityScore),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.confirmationCount(report.upvoteCount),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;

    switch (status) {
      case ReportStatus.submitted:
        backgroundColor = const Color(0xFFDEE8FF);
        foregroundColor = const Color(0xFF005C55);
        break;
      case ReportStatus.inProgress:
        backgroundColor = const Color(0xFFFFE4C7);
        foregroundColor = const Color(0xFF8A4B00);
        break;
      case ReportStatus.fixed:
        backgroundColor = const Color(0xFFCCFBF1);
        foregroundColor = const Color(0xFF115E59);
        break;
      case ReportStatus.cancelled:
        backgroundColor = const Color(0xFFFFDAD6);
        foregroundColor = const Color(0xFFBA1A1A);
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          status.localizedLabel(context),
          style: TextStyle(
            color: foregroundColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(context.l10n.reportsLoading),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasFilters,
    required this.onCreate,
    required this.onClearFilters,
    required this.onRefresh,
  });

  final bool hasFilters;
  final VoidCallback onCreate;
  final VoidCallback onClearFilters;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 64),
          Icon(
            hasFilters ? Icons.search_off_outlined : Icons.assignment_outlined,
            size: 62,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            hasFilters
                ? context.l10n.reportsNoMatches
                : context.l10n.reportsEmpty,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? context.l10n.reportsNoMatchesHelp
                : context.l10n.reportsEmptyHelp,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: hasFilters
                ? OutlinedButton.icon(
                    onPressed: onClearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: Text(context.l10n.commonClearFilters),
                  )
                : FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add),
                    label: Text(context.l10n.reportCreateTitle),
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
              Icon(
                Icons.cloud_off_outlined,
                size: 54,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.reportsLoadFailed,
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
                label: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
