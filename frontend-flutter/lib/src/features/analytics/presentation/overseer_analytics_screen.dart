import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../reports/domain/report.dart';
import '../../tasks/domain/task.dart';
import '../../users/data/user_api_service.dart';
import '../../users/domain/app_user.dart';
import '../data/analytics_api_service.dart';
import '../domain/overseer_analytics.dart';

class OverseerAnalyticsScreen extends StatefulWidget {
  const OverseerAnalyticsScreen({
    super.key,
    required this.analyticsApiService,
    required this.userApiService,
    this.standalone = false,
  });

  final AnalyticsApiService analyticsApiService;
  final UserApiService userApiService;
  final bool standalone;

  @override
  State<OverseerAnalyticsScreen> createState() =>
      _OverseerAnalyticsScreenState();
}

class _OverseerAnalyticsScreenState extends State<OverseerAnalyticsScreen> {
  final _areaController = TextEditingController();
  late Future<OverseerAnalytics> _analyticsFuture;
  late Future<List<AppUser>> _staffFuture;
  _AnalyticsRange _range = _AnalyticsRange.last30Days;
  ReportCategory? _category;
  String? _staffId;
  String? _area;

  @override
  void initState() {
    super.initState();
    _staffFuture = widget.userApiService.fetchStaffUsers();
    _analyticsFuture = _fetchAnalytics();
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  AnalyticsQuery _query() {
    final now = DateTime.now().toUtc();
    final from = switch (_range) {
      _AnalyticsRange.last7Days => now.subtract(const Duration(days: 7)),
      _AnalyticsRange.last30Days => now.subtract(const Duration(days: 30)),
      _AnalyticsRange.last90Days => now.subtract(const Duration(days: 90)),
      _AnalyticsRange.allTime => null,
    };
    return AnalyticsQuery(
      from: from,
      to: now,
      category: _category,
      staffId: _staffId,
      area: _area,
    );
  }

  Future<OverseerAnalytics> _fetchAnalytics() {
    return widget.analyticsApiService.fetchOverseerAnalytics(_query());
  }

  Future<void> _reload() async {
    final next = _fetchAnalytics();
    setState(() {
      _analyticsFuture = next;
    });
    await next;
  }

  void _changeFilters(VoidCallback change) {
    setState(() {
      change();
      _analyticsFuture = _fetchAnalytics();
    });
  }

  void _applyArea() {
    _changeFilters(() {
      final value = _areaController.text.trim();
      _area = value.isEmpty ? null : value;
    });
  }

  void _clearFilters() {
    _areaController.clear();
    _changeFilters(() {
      _range = _AnalyticsRange.last30Days;
      _category = null;
      _staffId = null;
      _area = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: const Color(0xFFF4F7F6),
      child: FutureBuilder<OverseerAnalytics>(
        future: _analyticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _AnalyticsError(onRetry: _reload);
          }
          return _buildDashboard(snapshot.requireData);
        },
      ),
    );
    if (!widget.standalone) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.analyticsTitle)),
      body: content,
    );
  }

  Widget _buildDashboard(OverseerAnalytics analytics) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        key: const Key('overseerAnalyticsDashboard'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 112),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeading(analytics: analytics),
                  const SizedBox(height: 16),
                  _buildFilters(),
                  const SizedBox(height: 16),
                  _OverviewGrid(analytics: analytics),
                  const SizedBox(height: 16),
                  _AnalyticsSection(
                    title: context.l10n.analyticsOperationalTrend,
                    icon: Icons.stacked_line_chart,
                    child: _TrendChart(points: analytics.trends),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final reportStatus = _AnalyticsSection(
                        title: context.l10n.analyticsReportStatus,
                        icon: Icons.pie_chart_outline,
                        child: _StatusDistribution<ReportStatus>(
                          entries: analytics.reports.byStatus.entries.toList(),
                          label: (status) => status.localizedLabel(context),
                          color: _reportStatusColor,
                        ),
                      );
                      final taskWorkflow = _AnalyticsSection(
                        title: context.l10n.analyticsTaskWorkflow,
                        icon: Icons.account_tree_outlined,
                        child: _StatusDistribution<TaskStatus>(
                          entries: analytics.tasks.byStatus.entries.toList(),
                          label: (status) => status.localizedLabel(context),
                          color: _taskStatusColor,
                        ),
                      );
                      if (constraints.maxWidth >= 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: reportStatus),
                            const SizedBox(width: 16),
                            Expanded(child: taskWorkflow),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          reportStatus,
                          const SizedBox(height: 16),
                          taskWorkflow,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _AnalyticsSection(
                    title: context.l10n.analyticsCategoryBreakdown,
                    icon: Icons.category_outlined,
                    child: _CategoryBreakdown(categories: analytics.categories),
                  ),
                  const SizedBox(height: 16),
                  _AnalyticsSection(
                    title: context.l10n.analyticsCycleTimes,
                    icon: Icons.timer_outlined,
                    child: _CycleTimes(analytics: analytics),
                  ),
                  const SizedBox(height: 16),
                  _AnalyticsSection(
                    title: context.l10n.analyticsStaffWorkload,
                    icon: Icons.groups_outlined,
                    child: _StaffWorkloadTable(
                      workloads: analytics.staffWorkloads,
                      onStaffTapped: _openStaff,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnalyticsSection(
                    title: context.l10n.analyticsAttentionRequired,
                    icon: Icons.notification_important_outlined,
                    child: _AttentionList(
                      items: analytics.attentionItems,
                      onItemTapped: _openAttentionItem,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnalyticsSection(
                    title: context.l10n.analyticsGeographicDistribution,
                    icon: Icons.public,
                    child: _AnalyticsMap(
                      points: analytics.mapPoints,
                      onPointTapped: _openReport,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 10),
                Text(
                  context.l10n.analyticsFilters,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FilterBox(
                  child: DropdownButton<_AnalyticsRange>(
                    value: _range,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final range in _AnalyticsRange.values)
                        DropdownMenuItem(
                          value: range,
                          child: Text(range.label(context)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _changeFilters(() => _range = value);
                      }
                    },
                  ),
                ),
                _FilterBox(
                  child: DropdownButton<ReportCategory?>(
                    value: _category,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem<ReportCategory?>(
                        value: null,
                        child: Text(context.l10n.analyticsAllCategories),
                      ),
                      for (final category in ReportCategory.values)
                        DropdownMenuItem<ReportCategory?>(
                          value: category,
                          child: Text(category.localizedLabel(context)),
                        ),
                    ],
                    onChanged: (value) =>
                        _changeFilters(() => _category = value),
                  ),
                ),
                _FilterBox(child: _buildStaffFilter()),
                SizedBox(
                  width: 230,
                  child: TextField(
                    key: const Key('analyticsAreaFilter'),
                    controller: _areaController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _applyArea(),
                    decoration: InputDecoration(
                      labelText: context.l10n.analyticsArea,
                      hintText: context.l10n.analyticsAreaHint,
                      isDense: true,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('analyticsApplyFilters'),
                  onPressed: _applyArea,
                  icon: const Icon(Icons.search),
                  label: Text(context.l10n.analyticsApplyFilters),
                ),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  label: Text(context.l10n.analyticsClearFilters),
                ),
                IconButton(
                  tooltip: context.l10n.commonRetry,
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffFilter() {
    return FutureBuilder<List<AppUser>>(
      future: _staffFuture,
      builder: (context, snapshot) {
        final staff = snapshot.data ?? const <AppUser>[];
        return DropdownButton<String?>(
          value: _staffId,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(context.l10n.analyticsAllStaff),
            ),
            for (final member in staff)
              DropdownMenuItem<String?>(
                value: member.id,
                child: Text(member.fullName, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => _changeFilters(() => _staffId = value),
        );
      },
    );
  }

  Future<void> _openStaff(String staffId) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerStaffProfile, arguments: staffId);
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openAttentionItem(AnalyticsAttentionItem item) async {
    await Navigator.of(context).pushNamed(
      item.isReport
          ? AppRoutes.overseerReportDetail
          : AppRoutes.overseerTaskDetail,
      arguments: item.id,
    );
    if (mounted) {
      await _reload();
    }
  }

  Future<void> _openReport(String reportId) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerReportDetail, arguments: reportId);
    if (mounted) {
      await _reload();
    }
  }
}

class _DashboardHeading extends StatelessWidget {
  const _DashboardHeading({required this.analytics});

  final OverseerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.analytics_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.analyticsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(context.l10n.analyticsSubtitle),
              const SizedBox(height: 5),
              Text(
                '${context.l10n.analyticsLastUpdated}: ${_dateTimeLabel(analytics.generatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterBox extends StatelessWidget {
  const _FilterBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 205,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.analytics});

  final OverseerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _OverviewMetric(
        context.l10n.analyticsTotalReports,
        analytics.reports.totalReports,
        Icons.description_outlined,
        const Color(0xFF2563EB),
      ),
      _OverviewMetric(
        context.l10n.analyticsSubmittedReports,
        analytics.reports.byStatus[ReportStatus.submitted] ?? 0,
        Icons.upload_file_outlined,
        const Color(0xFF7C3AED),
      ),
      _OverviewMetric(
        context.l10n.analyticsReportsInProgress,
        analytics.reports.byStatus[ReportStatus.inProgress] ?? 0,
        Icons.engineering_outlined,
        const Color(0xFFEA580C),
      ),
      _OverviewMetric(
        context.l10n.analyticsFixedReports,
        analytics.reports.byStatus[ReportStatus.fixed] ?? 0,
        Icons.check_circle_outline,
        const Color(0xFF059669),
      ),
      _OverviewMetric(
        context.l10n.analyticsUnassignedTasks,
        analytics.tasks.unassignedTasks,
        Icons.person_off_outlined,
        const Color(0xFFDC2626),
      ),
      _OverviewMetric(
        context.l10n.analyticsActiveTasks,
        analytics.tasks.activeTasks,
        Icons.assignment_outlined,
        const Color(0xFFD97706),
      ),
      _OverviewMetric(
        context.l10n.analyticsPendingReview,
        analytics.tasks.pendingReviewTasks,
        Icons.rate_review_outlined,
        const Color(0xFF9333EA),
      ),
      _OverviewMetric(
        context.l10n.analyticsCompletedTasks,
        analytics.tasks.completedTasks,
        Icons.task_alt,
        const Color(0xFF0F766E),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 620
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: _OverviewCard(metric: metric),
              ),
          ],
        );
      },
    );
  }
}

class _OverviewMetric {
  const _OverviewMetric(this.label, this.value, this.icon, this.color);

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.metric});

  final _OverviewMetric metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(metric.icon, color: metric.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${metric.value}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: metric.color,
                    ),
                  ),
                  Text(metric.label, maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<AnalyticsTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final maximum = points.fold<int>(1, (current, point) {
      return [
        current,
        point.reportsCreated,
        point.reportsFixed,
        point.tasksCreated,
        point.tasksClosed,
      ].reduce((a, b) => a > b ? a : b);
    });
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF059669),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _Legend(colors[0], context.l10n.analyticsReportsCreated),
            _Legend(colors[1], context.l10n.analyticsReportsFixed),
            _Legend(colors[2], context.l10n.analyticsTasksCreated),
            _Legend(colors[3], context.l10n.analyticsTasksClosed),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 205,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  SizedBox(
                    width: 86,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 155,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _TrendBar(
                                point.reportsCreated,
                                maximum,
                                colors[0],
                              ),
                              _TrendBar(point.reportsFixed, maximum, colors[1]),
                              _TrendBar(point.tasksCreated, maximum, colors[2]),
                              _TrendBar(point.tasksClosed, maximum, colors[3]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _shortDate(point.periodStart),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar(this.value, this.maximum, this.color);

  final int value;
  final int maximum;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final height = value == 0 ? 3.0 : 130 * value / maximum;
    return Tooltip(
      message: '$value',
      child: Container(
        width: 13,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _StatusDistribution<T> extends StatelessWidget {
  const _StatusDistribution({
    required this.entries,
    required this.label,
    required this.color,
  });

  final List<MapEntry<T, int>> entries;
  final String Function(T) label;
  final Color Function(T) color;

  @override
  Widget build(BuildContext context) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value);
    return Column(
      children: [
        for (final entry in entries) ...[
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label(entry.key))),
              Text(
                '${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: total == 0 ? 0 : entry.value / total,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
            color: color(entry.key),
            backgroundColor: color(entry.key).withValues(alpha: 0.1),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.categories});

  final List<CategoryAnalytics> categories;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(context.l10n.commonCategory)),
          DataColumn(
            label: Text(context.l10n.analyticsReportsColumn),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsFixedColumn),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsTasksColumn),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsClosedColumn),
            numeric: true,
          ),
        ],
        rows: [
          for (final item in categories)
            DataRow(
              cells: [
                DataCell(Text(item.category.localizedLabel(context))),
                DataCell(Text('${item.reports}')),
                DataCell(Text('${item.fixedReports}')),
                DataCell(Text('${item.tasks}')),
                DataCell(Text('${item.closedTasks}')),
              ],
            ),
        ],
      ),
    );
  }
}

class _CycleTimes extends StatelessWidget {
  const _CycleTimes({required this.analytics});

  final OverseerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        context.l10n.analyticsAverageWorkTime,
        analytics.tasks.averageWorkHours,
        Icons.handyman_outlined,
        true,
        false,
      ),
      (
        context.l10n.analyticsAverageReviewTime,
        analytics.tasks.averageReviewHours,
        Icons.fact_check_outlined,
        true,
        false,
      ),
      (
        context.l10n.analyticsAverageResolutionTime,
        analytics.tasks.averageResolutionHours,
        Icons.schedule_outlined,
        true,
        false,
      ),
      (
        context.l10n.analyticsCompletionRate,
        analytics.tasks.completionRate,
        Icons.task_alt,
        false,
        true,
      ),
      (
        context.l10n.analyticsFixedRate,
        analytics.reports.fixedRate,
        Icons.build_circle_outlined,
        false,
        true,
      ),
      (
        context.l10n.analyticsAveragePriority,
        analytics.reports.averagePriority,
        Icons.trending_up,
        false,
        false,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(metric.$3),
                      const SizedBox(width: 10),
                      Expanded(child: Text(metric.$1)),
                      Text(
                        metric.$4
                            ? '${_number(metric.$2)} ${context.l10n.analyticsHours}'
                            : metric.$5
                            ? '${_number(metric.$2)}%'
                            : _number(metric.$2),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StaffWorkloadTable extends StatelessWidget {
  const _StaffWorkloadTable({
    required this.workloads,
    required this.onStaffTapped,
  });

  final List<StaffWorkloadAnalytics> workloads;
  final ValueChanged<String> onStaffTapped;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        showCheckboxColumn: false,
        columns: [
          DataColumn(label: Text(context.l10n.commonStaff)),
          DataColumn(label: Text(context.l10n.analyticsAccount)),
          DataColumn(
            label: Text(context.l10n.profileTotalTasks),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsActiveColumn),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsReviewColumn),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsCompletedColumn),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsDeniedColumn),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsCompletionRate),
            numeric: true,
          ),
          DataColumn(
            label: Text(context.l10n.analyticsAverageCompletionColumn),
            numeric: true,
          ),
        ],
        rows: [
          for (final workload in workloads)
            DataRow(
              key: ValueKey('analyticsStaff-${workload.staffId}'),
              onSelectChanged: (_) => onStaffTapped(workload.staffId),
              cells: [
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workload.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        workload.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      workload.activeAccount
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                    ),
                    label: Text(
                      workload.activeAccount
                          ? context.l10n.commonActive
                          : context.l10n.commonInactive,
                    ),
                  ),
                ),
                DataCell(Text('${workload.totalTasks}')),
                DataCell(Text('${workload.activeTasks}')),
                DataCell(Text('${workload.pendingReviewTasks}')),
                DataCell(Text('${workload.completedTasks}')),
                DataCell(Text('${workload.deniedTasks}')),
                DataCell(Text('${_number(workload.completionRate)}%')),
                DataCell(Text('${_number(workload.averageCompletionHours)} h')),
              ],
            ),
        ],
      ),
    );
  }
}

class _AttentionList extends StatelessWidget {
  const _AttentionList({required this.items, required this.onItemTapped});

  final List<AnalyticsAttentionItem> items;
  final ValueChanged<AnalyticsAttentionItem> onItemTapped;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(child: Text(context.l10n.analyticsNoAttention)),
      );
    }
    return Column(
      children: [
        for (final item in items)
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: ListTile(
              key: ValueKey('analyticsAttention-${item.id}'),
              onTap: () => onItemTapped(item),
              leading: CircleAvatar(
                backgroundColor: _attentionColor(
                  item.reason,
                ).withValues(alpha: 0.12),
                child: Icon(
                  item.isReport
                      ? Icons.description_outlined
                      : Icons.assignment_outlined,
                  color: _attentionColor(item.reason),
                ),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_attentionReason(context, item.reason)),
                    if ((item.addressText ?? '').isNotEmpty)
                      Text(
                        item.addressText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_attentionStatus(context, item)),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AnalyticsMap extends StatelessWidget {
  const _AnalyticsMap({required this.points, required this.onPointTapped});

  final List<AnalyticsMapPoint> points;
  final ValueChanged<String> onPointTapped;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(child: Text(context.l10n.analyticsNoMapPoints)),
      );
    }
    final latitude =
        points.fold<double>(0, (sum, point) => sum + point.latitude) /
        points.length;
    final longitude =
        points.fold<double>(0, (sum, point) => sum + point.longitude) /
        points.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 380,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(latitude, longitude),
            initialZoom: points.length == 1 ? 14 : 11,
            minZoom: 4,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.smartcity.report',
            ),
            MarkerLayer(
              markers: [
                for (final point in points)
                  Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 46,
                    height: 46,
                    child: Tooltip(
                      message: point.title,
                      child: GestureDetector(
                        key: ValueKey('analyticsMap-${point.reportId}'),
                        onTap: () => onPointTapped(point.reportId),
                        child: Icon(
                          Icons.location_on,
                          size: 42,
                          color: _reportStatusColor(point.status),
                          shadows: const [
                            Shadow(color: Colors.white, blurRadius: 5),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.analytics_outlined, size: 48),
            const SizedBox(height: 12),
            Text(context.l10n.analyticsLoadFailed),
            const SizedBox(height: 16),
            FilledButton.icon(
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

enum _AnalyticsRange { last7Days, last30Days, last90Days, allTime }

extension on _AnalyticsRange {
  String label(BuildContext context) {
    return switch (this) {
      _AnalyticsRange.last7Days => context.l10n.analyticsRange7Days,
      _AnalyticsRange.last30Days => context.l10n.analyticsRange30Days,
      _AnalyticsRange.last90Days => context.l10n.analyticsRange90Days,
      _AnalyticsRange.allTime => context.l10n.analyticsRangeAllTime,
    };
  }
}

Color _reportStatusColor(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => const Color(0xFF2563EB),
    ReportStatus.inProgress => const Color(0xFFD97706),
    ReportStatus.fixed => const Color(0xFF059669),
    ReportStatus.cancelled => const Color(0xFF64748B),
  };
}

Color _taskStatusColor(TaskStatus status) {
  return switch (status) {
    TaskStatus.newTask => const Color(0xFF2563EB),
    TaskStatus.assigned => const Color(0xFF4F46E5),
    TaskStatus.inProgress => const Color(0xFFD97706),
    TaskStatus.done => const Color(0xFF0891B2),
    TaskStatus.pendingReview => const Color(0xFF7C3AED),
    TaskStatus.denied => const Color(0xFFDC2626),
    TaskStatus.approved => const Color(0xFF16A34A),
    TaskStatus.closed => const Color(0xFF0F766E),
    TaskStatus.cancelled => const Color(0xFF64748B),
  };
}

Color _attentionColor(String reason) {
  return switch (reason) {
    'HIGH_PRIORITY_UNASSIGNED_REPORT' => const Color(0xFFDC2626),
    'UNASSIGNED_REPORT' || 'UNASSIGNED_TASK' => const Color(0xFFD97706),
    'PENDING_REVIEW' => const Color(0xFF7C3AED),
    'DENIED_REWORK' => const Color(0xFFDC2626),
    'STALE_ACTIVE_TASK' => const Color(0xFFEA580C),
    'INACTIVE_STAFF_ASSIGNMENT' => const Color(0xFF64748B),
    _ => const Color(0xFF2563EB),
  };
}

String _attentionReason(BuildContext context, String reason) {
  return switch (reason) {
    'HIGH_PRIORITY_UNASSIGNED_REPORT' =>
      context.l10n.analyticsReasonHighPriorityReport,
    'UNASSIGNED_REPORT' => context.l10n.analyticsReasonUnassignedReport,
    'UNASSIGNED_TASK' => context.l10n.analyticsReasonUnassignedTask,
    'PENDING_REVIEW' => context.l10n.analyticsReasonPendingReview,
    'DENIED_REWORK' => context.l10n.analyticsReasonDeniedRework,
    'STALE_ACTIVE_TASK' => context.l10n.analyticsReasonStaleTask,
    'INACTIVE_STAFF_ASSIGNMENT' => context.l10n.analyticsReasonInactiveStaff,
    _ => reason,
  };
}

String _attentionStatus(BuildContext context, AnalyticsAttentionItem item) {
  return item.isReport
      ? ReportStatus.fromJson(item.status).localizedLabel(context)
      : TaskStatus.fromJson(item.status).localizedLabel(context);
}

String _number(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

String _shortDate(DateTime value) {
  final local = value.toLocal();
  return '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}';
}

String _dateTimeLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
