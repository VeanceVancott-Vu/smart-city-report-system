import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/routing/app_routes.dart';
import '../data/task_api_service.dart';
import '../domain/staff_task.dart';

class StaffTaskInboxScreen extends StatefulWidget {
  const StaffTaskInboxScreen({
    super.key,
    required this.taskApiService,
    this.onLogout,
  });

  final TaskApiService taskApiService;
  final VoidCallback? onLogout;

  @override
  State<StaffTaskInboxScreen> createState() => _StaffTaskInboxScreenState();
}

class _StaffTaskInboxScreenState extends State<StaffTaskInboxScreen> {
  late final MapController _mapController;
  late Future<List<StaffTask>> _tasksFuture;

  List<StaffTask> _tasks = const <StaffTask>[];
  StaffTask? _selectedTask;
  StaffTaskStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadTasks();
  }

  void _loadTasks() {
    _tasksFuture = widget.taskApiService.fetchStaffTasks().then((tasks) {
      _tasks = tasks;
      final selectedId = _selectedTask?.id;
      if (selectedId != null) {
        _selectedTask = _taskById(tasks, selectedId);
      }
      return tasks;
    });
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
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'Logout',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<StaffTask>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                _tasks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError && _tasks.isEmpty) {
              return _ErrorState(
                message: 'Unable to load assigned tasks.',
                onRetry: _refresh,
              );
            }

            final tasks = snapshot.data ?? _tasks;
            final visibleTasks = _filteredTasks(tasks);
            final selectedTask = _visibleSelectedTask(visibleTasks);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 980;
                if (isWide) {
                  return _buildWideDashboard(
                    tasks: tasks,
                    visibleTasks: visibleTasks,
                    selectedTask: selectedTask,
                  );
                }

                return _buildCompactDashboard(
                  tasks: tasks,
                  visibleTasks: visibleTasks,
                  selectedTask: selectedTask,
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
    required StaffTask? selectedTask,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                    tasks: visibleTasks,
                    selectedTask: selectedTask,
                    embedded: false,
                    onOpenTask: _openTask,
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
    required StaffTask? selectedTask,
  }) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const Key('staffTaskDashboardScroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
            tasks: visibleTasks,
            selectedTask: selectedTask,
            embedded: true,
            onOpenTask: _openTask,
            onFocusTask: _focusTaskOnMap,
          ),
        ],
      ),
    );
  }
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
          label: 'Assigned to you',
          value: tasks.length.toString(),
          color: const Color(0xFF0F766E),
        ),
        _SummaryMetric(
          icon: Icons.play_circle_outline,
          label: 'In progress',
          value: inProgress.toString(),
          color: _statusColor(StaffTaskStatus.inProgress),
        ),
        _SummaryMetric(
          icon: Icons.rate_review_outlined,
          label: 'Review',
          value: awaitingReview.toString(),
          color: _statusColor(StaffTaskStatus.awaitingReview),
        ),
        _SummaryMetric(
          icon: Icons.trending_up,
          label: 'Top priority',
          value: topPriority.toString(),
          color: const Color(0xFFB45309),
        ),
        if (assigned > 0)
          _SummaryMetric(
            icon: Icons.radio_button_checked,
            label: 'Ready',
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
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 176),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5E2)),
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
              label: Text('All (${tasks.length})'),
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
                label: Text('${status.label} ($count)'),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5E2)),
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
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5E2)),
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
              count == 1 ? '1 task' : '$count tasks',
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
                'No task locations',
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
      label: 'Task $number ${task.reportTitle}',
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
                  tooltip: 'Close',
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
                label: const Text('Open'),
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
    required this.embedded,
    required this.onOpenTask,
    required this.onFocusTask,
  });

  final List<StaffTask> tasks;
  final StaffTask? selectedTask;
  final bool embedded;
  final ValueChanged<String> onOpenTask;
  final ValueChanged<StaffTask> onFocusTask;

  @override
  Widget build(BuildContext context) {
    final list = tasks.isEmpty
        ? const _EmptyTaskList()
        : ListView.separated(
            shrinkWrap: embedded,
            physics: embedded ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskTile(
                number: index + 1,
                task: task,
                selected: selectedTask?.id == task.id,
                onTap: () => onOpenTask(task.id),
                onFocusOnMap: () => onFocusTask(task),
              );
            },
          );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE5E2)),
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
                    'Task queue',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SmallCount(value: tasks.length),
              ],
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
  const _EmptyTaskList();

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
            'No assigned tasks yet.',
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.number,
    required this.task,
    required this.selected,
    required this.onTap,
    required this.onFocusOnMap,
  });

  final int number;
  final StaffTask task;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onFocusOnMap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(task.status);

    return Card(
      elevation: 0,
      color: selected ? color.withValues(alpha: 0.06) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? color : const Color(0xFFDDE5E2),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        onTap: onTap,
        leading: _TaskIndexBadge(number: number, color: color),
        title: Text(
          task.reportTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TaskStatusPill(status: task.status),
              _TaskChip(icon: Icons.category_outlined, label: task.category),
              _TaskChip(icon: Icons.place_outlined, label: task.area),
              _TaskChip(
                icon: Icons.trending_up,
                label: 'Priority ${task.priorityScore}',
              ),
              _TaskChip(
                icon: Icons.event_outlined,
                label: _formatDate(task.dueDate),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Show on map',
          onPressed: onFocusOnMap,
          icon: const Icon(Icons.my_location_outlined),
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
            status.label,
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
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
  };
}

Color _statusColor(StaffTaskStatus status) {
  return switch (status) {
    StaffTaskStatus.queued => const Color(0xFF64748B),
    StaffTaskStatus.assigned => const Color(0xFF2563EB),
    StaffTaskStatus.inProgress => const Color(0xFF0F766E),
    StaffTaskStatus.awaitingReview => const Color(0xFFB45309),
  };
}
