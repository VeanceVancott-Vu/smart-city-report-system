import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../tasks/data/task_api_service.dart';
import '../../tasks/domain/task.dart';
import 'overseer_report_dashboard_screen.dart';

class OverseerTaskListScreen extends StatefulWidget {
  const OverseerTaskListScreen({super.key, required this.taskApiService});

  final TaskApiService taskApiService;

  @override
  State<OverseerTaskListScreen> createState() => OverseerTaskListScreenState();
}

class OverseerTaskListScreenState extends State<OverseerTaskListScreen> {
  late Future<List<Task>> _tasksFuture;
  TaskStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    _tasksFuture = widget.taskApiService.fetchTasks();
  }

  Future<void> reload() async {
    setState(refresh);
    await _tasksFuture;
  }

  Future<void> _createTask() async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.overseerCreateTask,
      arguments: const OverseerTaskFormArgs(),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  Future<void> _openTask(String taskId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerTaskDetail, arguments: taskId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4F7F6),
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFDCE6E3))),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.taskQueueTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _createTask,
                    icon: const Icon(Icons.add_task_outlined),
                    label: Text(context.l10n.taskCreateTitle),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(context.l10n.taskAllStatuses),
                        selected: _selectedStatus == null,
                        onSelected: (_) =>
                            setState(() => _selectedStatus = null),
                        selectedColor: const Color(0xFFE7F3F1),
                        checkmarkColor: const Color(0xFF0F766E),
                      ),
                    ),
                    for (final status in TaskStatus.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(status.localizedLabel(context)),
                          selected: _selectedStatus == status,
                          onSelected: (_) => setState(
                            () => _selectedStatus = _selectedStatus == status
                                ? null
                                : status,
                          ),
                          selectedColor: _statusColor(
                            status,
                          ).withValues(alpha: 0.14),
                          checkmarkColor: _statusColor(status),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Task>>(
            future: _tasksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: context.l10n.tasksLoadFailed,
                  onRetry: reload,
                );
              }

              final tasks = snapshot.data ?? const <Task>[];
              final filteredTasks = _selectedStatus == null
                  ? tasks
                  : tasks
                        .where((task) => task.status == _selectedStatus)
                        .toList(growable: false);

              if (tasks.isEmpty) {
                return RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 96),
                      Center(child: Text(context.l10n.tasksEmpty)),
                    ],
                  ),
                );
              }

              if (filteredTasks.isEmpty) {
                return RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 96),
                      Center(child: Text(context.l10n.tasksNoStatusMatches)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: reload,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 1080;
                    if (!isDesktop) {
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                        itemCount: filteredTasks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) => _TaskTile(
                          task: filteredTasks[index],
                          onTap: () => _openTask(filteredTasks[index].id),
                        ),
                      );
                    }

                    return GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 2.35,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) => _TaskTile(
                        task: filteredTasks[index],
                        onTap: () => _openTask(filteredTasks[index].id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(task.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFDCE6E3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: statusColor.withValues(alpha: .10), borderRadius: BorderRadius.circular(15)), child: Icon(task.status.needsReviewComparison ? Icons.rate_review_outlined : Icons.assignment_outlined, color: statusColor)),
            const SizedBox(width: 16),
            Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))), const SizedBox(width: 10), _StatusBadge(label: task.status.localizedLabel(context), color: statusColor)]),
              const SizedBox(height: 12),
              Wrap(spacing: 14, runSpacing: 8, children: [
                _MetaChip(icon: Icons.category_outlined, label: task.category.localizedLabel(context)),
                _MetaChip(icon: Icons.place_outlined, label: task.locationLabel),
                _MetaChip(icon: Icons.person_outline, label: task.assignedStaff?.fullName ?? context.l10n.commonUnassigned),
                _MetaChip(icon: Icons.trending_up, label: context.l10n.priorityValue(task.priorityScore)),
              ]),
            ])),
            const SizedBox(width: 8), const Icon(Icons.chevron_right_rounded, color: Color(0xFF8CA09C)),
          ]),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label; final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(99), border: Border.all(color: color.withValues(alpha: .18))), child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)));
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      ],
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

Color _statusColor(TaskStatus status) {
  return switch (status) {
    TaskStatus.newTask => const Color(0xFF607D8B),
    TaskStatus.assigned => const Color(0xFF2563EB),
    TaskStatus.inProgress => const Color(0xFF7C3AED),
    TaskStatus.done => const Color(0xFFE67E22),
    TaskStatus.pendingReview => const Color(0xFFD97706),
    TaskStatus.denied => const Color(0xFFB91C1C),
    TaskStatus.approved => const Color(0xFF0F766E),
    TaskStatus.closed => const Color(0xFF475569),
    TaskStatus.cancelled => const Color(0xFF78909C),
  };
}
