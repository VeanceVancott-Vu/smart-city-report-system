import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../tasks/data/task_api_service.dart';
import '../../tasks/domain/task.dart';
import 'overseer_report_dashboard_screen.dart';

class OverseerTaskDetailScreen extends StatefulWidget {
  const OverseerTaskDetailScreen({super.key, required this.taskApiService});

  final TaskApiService taskApiService;

  @override
  State<OverseerTaskDetailScreen> createState() =>
      _OverseerTaskDetailScreenState();
}

class _OverseerTaskDetailScreenState extends State<OverseerTaskDetailScreen> {
  late Future<Task> _taskFuture;

  String get _taskId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTask();
  }

  void _loadTask() {
    _taskFuture = widget.taskApiService.fetchTask(_taskId);
  }

  Future<void> _refresh() async {
    setState(_loadTask);
    await _taskFuture;
  }

  Future<void> _editTask() async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.overseerCreateTask,
      arguments: OverseerTaskFormArgs(taskId: _taskId),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(_loadTask);
    }
  }

  Future<void> _assignTask() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerAssignStaff, arguments: _taskId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(_loadTask);
    }
  }

  Future<void> _closeTask() async {
    await _changeTask(() => widget.taskApiService.closeTask(_taskId), 'closed');
  }

  Future<void> _cancelTask() async {
    await _changeTask(
      () => widget.taskApiService.cancelTask(_taskId),
      'cancelled',
    );
  }

  Future<void> _changeTask(Future<Task> Function() action, String verb) async {
    try {
      final task = await action();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${task.title} $verb')));
      setState(_loadTask);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to update task.');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Task>(
      future: _taskFuture,
      builder: (context, snapshot) {
        final task = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              if (task != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: _editTask,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (task != null && task.status.canAssign)
                IconButton(
                  tooltip: 'Assign staff',
                  onPressed: _assignTask,
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              if (task != null && task.status.canClose)
                IconButton(
                  tooltip: 'Close',
                  onPressed: _closeTask,
                  icon: const Icon(Icons.check_circle_outline),
                ),
              if (task != null && task.status.canCancel)
                IconButton(
                  tooltip: 'Cancel',
                  onPressed: _cancelTask,
                  icon: const Icon(Icons.cancel_outlined),
                ),
            ],
          ),
          body: SafeArea(child: _buildBody(snapshot)),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<Task> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _ErrorState(message: 'Unable to load task.', onRetry: _refresh);
    }

    final task = snapshot.requireData;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            task.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(icon: Icons.flag_outlined, label: task.status.label),
              _InfoChip(
                icon: Icons.category_outlined,
                label: task.category.label,
              ),
              _InfoChip(
                icon: Icons.trending_up,
                label: 'Priority ${task.priorityScore}',
              ),
              _InfoChip(
                icon: Icons.link_outlined,
                label: '${task.reportIds.length} reports',
              ),
            ],
          ),
          _Section(title: 'Description', child: Text(task.description)),
          _Section(title: 'Location', child: Text(task.locationLabel)),
          _Section(
            title: 'Coordinates',
            child: Text(
              '${task.latitude.toStringAsFixed(6)}, ${task.longitude.toStringAsFixed(6)}',
            ),
          ),
          _Section(
            title: 'Assigned staff',
            child: Text(task.assignedStaff?.fullName ?? 'Unassigned'),
          ),
          _Section(
            title: 'Before photo URL',
            child: Text(task.beforePhotoUrl ?? 'No photo URL'),
          ),
          if ((task.afterPhotoUrl ?? '').trim().isNotEmpty)
            _Section(
              title: 'After photo URL',
              child: Text(task.afterPhotoUrl!),
            ),
          if ((task.staffNote ?? '').trim().isNotEmpty)
            _Section(title: 'Staff note', child: Text(task.staffNote!)),
          _Section(
            title: 'Report IDs',
            child: Text(
              task.reportIds.isEmpty ? 'None' : task.reportIds.join('\n'),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: task.status.canAssign ? _assignTask : null,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Assign'),
              ),
              OutlinedButton.icon(
                onPressed: _editTask,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              FilledButton.icon(
                onPressed: task.status.canClose ? _closeTask : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Close'),
              ),
              OutlinedButton.icon(
                onPressed: task.status.canCancel ? _cancelTask : null,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

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
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
