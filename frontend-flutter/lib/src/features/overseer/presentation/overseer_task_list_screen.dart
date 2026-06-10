import 'package:flutter/material.dart';

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _createTask,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Create task'),
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
                  message: 'Unable to load tasks.',
                  onRetry: reload,
                );
              }

              final tasks = snapshot.data ?? const <Task>[];
              if (tasks.isEmpty) {
                return RefreshIndicator(
                  onRefresh: reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: const [
                      SizedBox(height: 96),
                      Center(child: Text('No tasks yet')),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _TaskTile(
                    task: tasks[index],
                    onTap: () => _openTask(tasks[index].id),
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE2F3EE),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.assignment_outlined),
        ),
        title: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.category_outlined,
                label: task.category.label,
              ),
              _MetaChip(icon: Icons.place_outlined, label: task.locationLabel),
              _MetaChip(
                icon: Icons.person_outline,
                label: task.assignedStaff?.fullName ?? 'Unassigned',
              ),
              _MetaChip(
                icon: Icons.trending_up,
                label: 'Priority ${task.priorityScore}',
              ),
            ],
          ),
        ),
        trailing: Chip(
          visualDensity: VisualDensity.compact,
          label: Text(task.status.label),
          side: BorderSide.none,
          backgroundColor: const Color(0xFFF6E7C8),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
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
