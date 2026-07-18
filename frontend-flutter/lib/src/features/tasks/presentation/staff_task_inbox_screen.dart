import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/localization/language_menu_button.dart';
import '../../../core/routing/app_routes.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import '../data/task_api_service.dart';
import '../domain/staff_task.dart';
import '../domain/staff_task_query.dart';

class StaffTaskInboxScreen extends StatefulWidget {
  const StaffTaskInboxScreen({
    super.key,
    required this.taskApiService,
    required this.reportApiService,
    this.onLogout,
  });

  final TaskApiService taskApiService;
  final ReportApiService reportApiService;
  final VoidCallback? onLogout;

  @override
  State<StaffTaskInboxScreen> createState() => _StaffTaskInboxScreenState();
}

class _StaffTaskInboxScreenState extends State<StaffTaskInboxScreen> {
  late final MapController _mapController;
  late Future<_StaffTaskInboxData> _tasksFuture;

  List<StaffTask> _tasks = const <StaffTask>[];
  Map<String, List<Report>> _reportsByTaskId = const <String, List<Report>>{};
  StaffTask? _selectedTask;
  StaffTaskStatus? _selectedStatus;
  late final TextEditingController _taskSearchController;
  String _taskSearchQuery = '';
  StaffTaskSort _taskSort = StaffTaskSort.newest;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _taskSearchController = TextEditingController();
    _loadTasks();
  }

  @override
  void dispose() {
    _taskSearchController.dispose();
    super.dispose();
  }

  void _loadTasks() {
    _tasksFuture = _loadTaskData().then((data) {
      _tasks = data.tasks;
      _reportsByTaskId = data.reportsByTaskId;
      final selectedId = _selectedTask?.id;
      if (selectedId != null) {
        _selectedTask = _taskById(data.tasks, selectedId);
      }
      return data;
    });
  }

  Future<_StaffTaskInboxData> _loadTaskData() async {
    final tasks = await widget.taskApiService.fetchStaffTasks();
    final reportsById = await _fetchLinkedReports(tasks);
    final reportsByTaskId = <String, List<Report>>{
      for (final task in tasks)
        task.id: <Report>[
          for (final reportId in task.reportIds)
            if (reportsById[reportId] != null) reportsById[reportId]!,
        ],
    };

    return _StaffTaskInboxData(tasks: tasks, reportsByTaskId: reportsByTaskId);
  }

  Future<Map<String, Report>> _fetchLinkedReports(List<StaffTask> tasks) async {
    final reportIds = <String>{};
    for (final task in tasks) {
      reportIds.addAll(task.reportIds);
    }

    if (reportIds.isEmpty) {
      return const <String, Report>{};
    }

    final reports = await Future.wait<Report?>(
      reportIds.map((reportId) async {
        try {
          return await widget.reportApiService.fetchReport(reportId);
        } on Object {
          return null;
        }
      }),
    );

    return <String, Report>{
      for (final report in reports)
        if (report != null) report.id: report,
    };
  }

  Future<void> _refresh() async {
    setState(_loadTasks);
    await _tasksFuture;
  }

  Future<void> _openTask(String taskId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.staffTaskDetail, arguments: taskId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(_loadTasks);
    }
  }

  Future<void> _openReport(String reportId) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.staffReportDetail, arguments: reportId);
  }

  void _setTaskSearchQuery(String query) {
    setState(() => _taskSearchQuery = query);
  }

  void _setTaskSort(StaffTaskSort sort) {
    setState(() => _taskSort = sort);
  }

  void _selectTask(StaffTask task) {
    setState(() => _selectedTask = task);
  }

  void _focusTaskOnMap(StaffTask task) {
    setState(() => _selectedTask = task);
    _moveMap(LatLng(task.latitude, task.longitude), 15.5);
  }

  void _clearSelectedTask() {
    setState(() => _selectedTask = null);
  }

  void _selectStatus(StaffTaskStatus? status) {
    setState(() {
      _selectedStatus = status;
      if (_selectedTask != null &&
          !_filteredTasks(_tasks).any((task) => task.id == _selectedTask!.id)) {
        _selectedTask = null;
      }
    });

    final visibleTasks = _filteredTasks(_tasks);
    if (visibleTasks.isNotEmpty) {
      _moveMap(
        _taskMapCenter(visibleTasks),
        visibleTasks.length == 1 ? 15 : 13,
      );
    }
  }

  void _moveMap(LatLng center, double zoom) {
    try {
      _mapController.move(center, zoom);
    } on Object {
      // The controller can be unattached during the first build.
    }
  }

  List<StaffTask> _filteredTasks(List<StaffTask> tasks) {
    final selectedStatus = _selectedStatus;
    if (selectedStatus == null) {
      return tasks;
    }
    return tasks
        .where((task) => task.status == selectedStatus)
        .toList(growable: false);
  }

  StaffTask? _taskById(List<StaffTask> tasks, String id) {
    for (final task in tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  StaffTask? _visibleSelectedTask(List<StaffTask> visibleTasks) {
    final selectedTask = _selectedTask;
    if (selectedTask == null) {
      return null;
    }
    return visibleTasks.any((task) => task.id == selectedTask.id)
        ? selectedTask
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.l10n.staffMyTasksTitle),
        actions: [
          const LanguageMenuButton(),
          IconButton(
            tooltip: context.l10n.commonRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: context.l10n.commonLogout,
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<_StaffTaskInboxData>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                _tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && _tasks.isEmpty) {
              return _ErrorState(
                message: context.l10n.tasksLoadFailed,
                onRetry: _refresh,
              );
            }

            final data =
                snapshot.data ??
                _StaffTaskInboxData(
                  tasks: _tasks,
                  reportsByTaskId: _reportsByTaskId,
                );
            final tasks = data.tasks;
            final visibleTasks = _filteredTasks(tasks);
            final sidebarTasks = filterAndSortStaffTasks(
              visibleTasks,
              query: _taskSearchQuery,
              sort: _taskSort,
            );
            final selectedTask = _visibleSelectedTask(visibleTasks);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                if (isWide) {
                  return _buildWideDashboard(
                    tasks: tasks,
                    visibleTasks: visibleTasks,
                    sidebarTasks: sidebarTasks,
                    selectedTask: selectedTask,
                    reportsByTaskId: data.reportsByTaskId,
                  );
                }

                return _buildCompactDashboard(
                  tasks: tasks,
                  visibleTasks: visibleTasks,
                  sidebarTasks: sidebarTasks,
                  selectedTask: selectedTask,
                  reportsByTaskId: data.reportsByTaskId,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWideDashboard({
    required List<StaffTask> tasks,
    required List<StaffTask> visibleTasks,
    required List<StaffTask> sidebarTasks,
    required StaffTask? selectedTask,
    required Map<String, List<Report>> reportsByTaskId,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TaskSummary(tasks: tasks),
          const SizedBox(height: 12),
          _StatusFilters(
            tasks: tasks,
            selectedStatus: _selectedStatus,
            onSelected: _selectStatus,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _TaskMapPanel(
                    mapController: _mapController,
                    tasks: visibleTasks,
                    selectedTask: selectedTask,
                    onTaskSelected: _selectTask,
                    onClearSelected: _clearSelectedTask,
                    onOpenTask: _openTask,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 430,
                  child: _TaskListPanel(
                    tasks: sidebarTasks,
                    selectedTask: selectedTask,
                    reportsByTaskId: reportsByTaskId,
                    embedded: false,
                    searchController: _taskSearchController,
                    searchQuery: _taskSearchQuery,
                    sortOrder: _taskSort,
                    onSearchChanged: _setTaskSearchQuery,
                    onSortChanged: _setTaskSort,
                    onOpenTask: _openTask,
                    onOpenReport: _openReport,
                    onFocusTask: _focusTaskOnMap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDashboard({
    required List<StaffTask> tasks,
    required List<StaffTask> visibleTasks,
    required List<StaffTask> sidebarTasks,
    required StaffTask? selectedTask,
    required Map<String, List<Report>> reportsByTaskId,
  }) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const Key('staffTaskDashboardScroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        children: [
          _TaskSummary(tasks: tasks),
          const SizedBox(height: 12),
          _StatusFilters(
            tasks: tasks,
            selectedStatus: _selectedStatus,
            onSelected: _selectStatus,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 380,
            child: _TaskMapPanel(
              mapController: _mapController,
              tasks: visibleTasks,
              selectedTask: selectedTask,
              onTaskSelected: _selectTask,
              onClearSelected: _clearSelectedTask,
              onOpenTask: _openTask,
            ),
          ),
          const SizedBox(height: 12),
          _TaskListPanel(
            tasks: sidebarTasks,
            selectedTask: selectedTask,
            reportsByTaskId: reportsByTaskId,
            embedded: true,
            searchController: _taskSearchController,
            searchQuery: _taskSearchQuery,
            sortOrder: _taskSort,
            onSearchChanged: _setTaskSearchQuery,
            onSortChanged: _setTaskSort,
            onOpenTask: _openTask,
            onOpenReport: _openReport,
            onFocusTask: _focusTaskOnMap,
          ),
        ],
      ),
    );
  }
}

class _StaffTaskInboxData {
  const _StaffTaskInboxData({
    required this.tasks,
    required this.reportsByTaskId,
  });

  final List<StaffTask> tasks;
  final Map<String, List<Report>> reportsByTaskId;
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({required this.tasks});

  final List<StaffTask> tasks;

  @override
  Widget build(BuildContext context) {
    final assigned = _countByStatus(tasks, StaffTaskStatus.assigned);
    final inProgress = _countByStatus(tasks, StaffTaskStatus.inProgress);
    final awaitingReview = _countByStatus(
      tasks,
      StaffTaskStatus.awaitingReview,
    );
    final approved = _countByStatus(tasks, StaffTaskStatus.approved);
    final topPriority = tasks.fold<int>(
      0,
      (highest, task) =>
          task.priorityScore > highest ? task.priorityScore : highest,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryMetric(
          icon: Icons.assignment_ind_outlined,
          label: context.l10n.staffAssignedToYou,
          value: tasks.length.toString(),
          color: const Color(0xFF0F766E),
        ),
        _SummaryMetric(
          icon: Icons.play_circle_outline,
          label: context.l10n.staffInProgress,
          value: inProgress.toString(),
          color: _statusColor(StaffTaskStatus.inProgress),
        ),
        _SummaryMetric(
          icon: Icons.rate_review_outlined,
          label: context.l10n.staffReview,
          value: awaitingReview.toString(),
          color: _statusColor(StaffTaskStatus.awaitingReview),
        ),
        _SummaryMetric(
          icon: Icons.verified_outlined,
          label: context.l10n.staffApproved,
          value: approved.toString(),
          color: _statusColor(StaffTaskStatus.approved),
        ),
        _SummaryMetric(
          icon: Icons.trending_up,
          label: context.l10n.staffTopPriority,
          value: topPriority.toString(),
          color: const Color(0xFFB45309),
        ),
        if (assigned > 0)
          _SummaryMetric(
            icon: Icons.radio_button_checked,
            label: context.l10n.staffReady,
            value: assigned.toString(),
            color: _statusColor(StaffTaskStatus.assigned),
          ),
      ],
    );
  }

  int _countByStatus(List<StaffTask> tasks, StaffTaskStatus status) {
    return tasks.where((task) => task.status == status).length;
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
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
      constraints: const BoxConstraints(minWidth: 144, maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    required this.tasks,
    required this.selectedStatus,
    required this.onSelected,
  });

  final List<StaffTask> tasks;
  final StaffTaskStatus? selectedStatus;
  final ValueChanged<StaffTaskStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final counts = <StaffTaskStatus, int>{
      for (final status in StaffTaskStatus.values) status: 0,
    };
    for (final task in tasks) {
      counts[task.status] = (counts[task.status] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${context.l10n.taskAllStatuses} (${tasks.length})'),
              selected: selectedStatus == null,
              onSelected: (_) => onSelected(null),
              selectedColor: const Color(0xFFE2F3EE),
              checkmarkColor: const Color(0xFF0F766E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFDDE5E2)),
              ),
            ),
          ),
          ...StaffTaskStatus.values.map((status) {
            final count = counts[status] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(
                  _statusIcon(status),
                  size: 16,
                  color: selectedStatus == status
                      ? _statusColor(status)
                      : Colors.grey.shade600,
                ),
                label: Text('${status.localizedLabel(context)} ($count)'),
                selected: selectedStatus == status,
                onSelected: (_) => onSelected(status),
                selectedColor: _statusColor(status).withValues(alpha: 0.12),
                checkmarkColor: _statusColor(status),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFDDE5E2)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TaskMapPanel extends StatelessWidget {
  const _TaskMapPanel({
    required this.mapController,
    required this.tasks,
    required this.selectedTask,
    required this.onTaskSelected,
    required this.onClearSelected,
    required this.onOpenTask,
  });

  final MapController mapController;
  final List<StaffTask> tasks;
  final StaffTask? selectedTask;
  final ValueChanged<StaffTask> onTaskSelected;
  final VoidCallback onClearSelected;
  final ValueChanged<String> onOpenTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _taskMapCenter(tasks),
                initialZoom: tasks.length <= 1 ? 14 : 13,
                minZoom: 4,
                maxZoom: 18,
                onTap: (_, __) => onClearSelected(),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartcity.report',
                ),
                MarkerLayer(
                  markers: List<Marker>.generate(tasks.length, (index) {
                    final task = tasks[index];
                    return Marker(
                      point: LatLng(task.latitude, task.longitude),
                      width: 72,
                      height: 78,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTaskSelected(task),
                        child: _NumberedTaskMarker(
                          number: index + 1,
                          task: task,
                          isSelected: selectedTask?.id == task.id,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _MapCountBadge(count: tasks.length),
          ),
          if (tasks.isEmpty) const Positioned.fill(child: _EmptyMapOverlay()),
          if (selectedTask != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _SelectedTaskCard(
                task: selectedTask!,
                onClose: onClearSelected,
                onOpen: () => onOpenTask(selectedTask!.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapCountBadge extends StatelessWidget {
  const _MapCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 17, color: Color(0xFF0F766E)),
            const SizedBox(width: 6),
            Text(
              context.l10n.taskCount(count),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMapOverlay extends StatelessWidget {
  const _EmptyMapOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDDE5E2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                context.l10n.staffNoTaskLocations,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberedTaskMarker extends StatelessWidget {
  const _NumberedTaskMarker({
    required this.number,
    required this.task,
    required this.isSelected,
  });

  final int number;
  final StaffTask task;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(task.status);
    final size = isSelected ? 42.0 : 36.0;

    return Semantics(
      label: context.l10n.staffTaskMarkerLabel(number, task.reportTitle),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isSelected ? 0.42 : 0.28),
                  blurRadius: isSelected ? 14 : 9,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          CustomPaint(
            painter: _PinTrianglePainter(color: color),
            size: const Size(12, 7),
          ),
        ],
      ),
    );
  }
}

class _SelectedTaskCard extends StatelessWidget {
  const _SelectedTaskCard({
    required this.task,
    required this.onClose,
    required this.onOpen,
  });

  final StaffTask task;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(task.status);

    return Material(
      elevation: 5,
      shadowColor: color.withValues(alpha: 0.2),
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TaskStatusPill(status: task.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.reportTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.commonClose,
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    task.area,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new, size: 17),
                label: Text(context.l10n.commonOpen),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListPanel extends StatelessWidget {
  const _TaskListPanel({
    required this.tasks,
    required this.selectedTask,
    required this.reportsByTaskId,
    required this.embedded,
    required this.searchController,
    required this.searchQuery,
    required this.sortOrder,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onOpenTask,
    required this.onOpenReport,
    required this.onFocusTask,
  });

  final List<StaffTask> tasks;
  final StaffTask? selectedTask;
  final Map<String, List<Report>> reportsByTaskId;
  final bool embedded;
  final TextEditingController searchController;
  final String searchQuery;
  final StaffTaskSort sortOrder;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<StaffTaskSort> onSortChanged;
  final ValueChanged<String> onOpenTask;
  final ValueChanged<String> onOpenReport;
  final ValueChanged<StaffTask> onFocusTask;

  @override
  Widget build(BuildContext context) {
    final list = tasks.isEmpty
        ? _EmptyTaskList(
            message: searchQuery.trim().isEmpty
                ? context.l10n.staffNoAssignedTasks
                : context.l10n.staffNoTaskMatches,
          )
        : ListView.separated(
            shrinkWrap: embedded,
            physics: embedded ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTile(
                key: ValueKey('taskTile-${task.id}'),
                number: index + 1,
                task: task,
                reports: reportsByTaskId[task.id] ?? const <Report>[],
                selected: selectedTask?.id == task.id,
                onTap: () => onOpenTask(task.id),
                onOpenReport: onOpenReport,
                onFocusOnMap: () => onFocusTask(task),
              );
            },
          );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.staffTaskQueue,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SmallCount(value: tasks.length),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              key: const Key('staffTaskSearchField'),
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: context.l10n.staffTaskSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.l10n.commonClose,
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: DropdownButtonFormField<StaffTaskSort>(
              key: const Key('staffTaskSortDropdown'),
              value: sortOrder,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.staffTaskSort,
                prefixIcon: const Icon(Icons.sort),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: StaffTaskSort.newest,
                  child: Text(context.l10n.staffTaskSortNewest),
                ),
                DropdownMenuItem(
                  value: StaffTaskSort.oldest,
                  child: Text(context.l10n.staffTaskSortOldest),
                ),
                DropdownMenuItem(
                  value: StaffTaskSort.priority,
                  child: Text(context.l10n.staffTaskSortPriority),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSortChanged(value);
                }
              },
            ),
          ),
          if (embedded) list else Expanded(child: list),
        ],
      ),
    );
  }
}

class _SmallCount extends StatelessWidget {
  const _SmallCount({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F3EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value.toString(),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyTaskList extends StatelessWidget {
  const _EmptyTaskList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatefulWidget {
  const _TaskTile({
    super.key,
    required this.number,
    required this.task,
    required this.reports,
    required this.selected,
    required this.onTap,
    required this.onOpenReport,
    required this.onFocusOnMap,
  });

  final int number;
  final StaffTask task;
  final List<Report> reports;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<String> onOpenReport;
  final VoidCallback onFocusOnMap;

  @override
  State<_TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<_TaskTile> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant _TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.id != widget.task.id) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(widget.task.status);
    final reportCount = widget.reports.isNotEmpty
        ? widget.reports.length
        : widget.task.reportIds.length;
    final hasMultipleReports = widget.reports.length > 1;
    final reportCountLabel = context.l10n.reportCount(reportCount);

    return Card(
      elevation: 0,
      color: widget.selected ? color.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: widget.selected ? color : const Color(0xFFDDE5E2),
          width: widget.selected ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            onTap: widget.onTap,
            leading: _TaskIndexBadge(number: widget.number, color: color),
            title: Text(
              widget.task.reportTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TaskStatusPill(status: widget.task.status),
                      _TaskChip(
                        icon: Icons.category_outlined,
                        label: _localizedStaffTaskCategory(
                          context,
                          widget.task.category,
                        ),
                      ),
                      _TaskChip(
                        icon: Icons.place_outlined,
                        label: widget.task.area,
                      ),
                      _TaskChip(
                        icon: Icons.trending_up,
                        label: context.l10n.priorityValue(
                          widget.task.priorityScore,
                        ),
                      ),
                      _TaskChip(
                        icon: Icons.event_outlined,
                        label: _formatDate(widget.task.dueDate),
                      ),
                      if (reportCount > 0)
                        _TaskChip(
                          icon: Icons.article_outlined,
                          label: reportCountLabel,
                        ),
                    ],
                  ),
                  if (hasMultipleReports)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        key: ValueKey('taskReportsToggle-${widget.task.id}'),
                        onPressed: () => setState(() {
                          _expanded = !_expanded;
                        }),
                        icon: Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                        ),
                        label: Text(
                          _expanded
                              ? context.l10n.staffHideReports
                              : reportCountLabel,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            trailing: IconButton(
              tooltip: context.l10n.staffShowOnMap,
              onPressed: widget.onFocusOnMap,
              icon: const Icon(Icons.my_location_outlined),
            ),
          ),
          if (_expanded && hasMultipleReports)
            Padding(
              padding: const EdgeInsets.fromLTRB(58, 0, 12, 12),
              child: _TaskLinkedReports(
                reports: widget.reports,
                onOpenReport: widget.onOpenReport,
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskLinkedReports extends StatelessWidget {
  const _TaskLinkedReports({required this.reports, required this.onOpenReport});

  final List<Report> reports;
  final ValueChanged<String> onOpenReport;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var index = 0; index < reports.length; index++) ...[
            _TaskLinkedReportRow(
              number: index + 1,
              report: reports[index],
              onTap: () => onOpenReport(reports[index].id),
            ),
            if (index != reports.length - 1)
              const Divider(height: 1, color: Color(0xFFDDE5E2)),
          ],
        ],
      ),
    );
  }
}

class _TaskLinkedReportRow extends StatelessWidget {
  const _TaskLinkedReportRow({
    required this.number,
    required this.report,
    required this.onTap,
  });

  final int number;
  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final location = _reportLocationLabel(report);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFE2F3EE),
                shape: BoxShape.circle,
              ),
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ReportStatusPill(status: report.status),
                      _TaskChip(
                        icon: Icons.trending_up,
                        label: context.l10n.priorityValue(report.priorityScore),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

class _ReportStatusPill extends StatelessWidget {
  const _ReportStatusPill({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _reportStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        status.localizedLabel(context),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TaskIndexBadge extends StatelessWidget {
  const _TaskIndexBadge({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _TaskStatusPill extends StatelessWidget {
  const _TaskStatusPill({required this.status});

  final StaffTaskStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status.localizedLabel(context),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
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
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
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

String _reportLocationLabel(Report report) {
  final address = report.addressText?.trim();
  if (address != null && address.isNotEmpty) {
    return address;
  }
  return '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}';
}

String _localizedStaffTaskCategory(BuildContext context, String label) {
  for (final category in ReportCategory.values) {
    if (category.label == label) {
      return category.localizedLabel(context);
    }
  }
  return label;
}

Color _reportStatusColor(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => const Color(0xFF2563EB),
    ReportStatus.inProgress => const Color(0xFFB45309),
    ReportStatus.fixed => const Color(0xFF0F766E),
    ReportStatus.cancelled => const Color(0xFF64748B),
  };
}

LatLng _taskMapCenter(List<StaffTask> tasks) {
  if (tasks.isEmpty) {
    return LatLng(10.7769, 106.7009);
  }

  final latitude = tasks.fold<double>(
    0,
    (total, task) => total + task.latitude,
  );
  final longitude = tasks.fold<double>(
    0,
    (total, task) => total + task.longitude,
  );
  return LatLng(latitude / tasks.length, longitude / tasks.length);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

IconData _statusIcon(StaffTaskStatus status) {
  return switch (status) {
    StaffTaskStatus.queued => Icons.hourglass_empty,
    StaffTaskStatus.assigned => Icons.radio_button_checked,
    StaffTaskStatus.inProgress => Icons.play_circle_outline,
    StaffTaskStatus.awaitingReview => Icons.rate_review_outlined,
    StaffTaskStatus.denied => Icons.assignment_return_outlined,
    StaffTaskStatus.approved => Icons.verified_outlined,
  };
}

Color _statusColor(StaffTaskStatus status) {
  return switch (status) {
    StaffTaskStatus.queued => const Color(0xFF64748B),
    StaffTaskStatus.assigned => const Color(0xFF2563EB),
    StaffTaskStatus.inProgress => const Color(0xFF0F766E),
    StaffTaskStatus.awaitingReview => const Color(0xFFB45309),
    StaffTaskStatus.denied => const Color(0xFFB91C1C),
    StaffTaskStatus.approved => const Color(0xFF15803D),
  };
}
