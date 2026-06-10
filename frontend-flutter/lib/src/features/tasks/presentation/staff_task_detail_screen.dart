import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../data/task_api_service.dart';
import '../domain/task.dart';

class StaffTaskDetailScreen extends StatefulWidget {
  const StaffTaskDetailScreen({super.key, required this.taskApiService});

  final TaskApiService taskApiService;

  @override
  State<StaffTaskDetailScreen> createState() => _StaffTaskDetailScreenState();
}

class _StaffTaskDetailScreenState extends State<StaffTaskDetailScreen> {
  late Future<Task> _taskFuture;
  String? _taskId;
  bool _didReadArgs = false;
  bool _isUpdating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) {
      return;
    }
    _didReadArgs = true;
    _taskId = ModalRoute.of(context)?.settings.arguments as String?;
    _loadTask();
  }

  void _loadTask() {
    final taskId = _taskId;
    _taskFuture = taskId == null
        ? Future<Task>.error(const TaskApiException('Task ID is missing.'))
        : widget.taskApiService.fetchTask(taskId);
  }

  Future<void> _refresh() async {
    setState(_loadTask);
    await _taskFuture;
  }

  Future<void> _startTask() async {
    final taskId = _taskId;
    if (taskId == null || _isUpdating) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final task = await widget.taskApiService.startTask(taskId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${task.title} started')));
      setState(() => _taskFuture = Future<Task>.value(task));
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to start task.');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _openCompleteTask() async {
    final taskId = _taskId;
    if (taskId == null) {
      return;
    }

    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.staffCompleteTask, arguments: taskId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(_loadTask);
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
              IconButton(
                tooltip: 'Refresh',
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(child: _buildBody(snapshot)),
          bottomNavigationBar: task == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _TaskActions(
                      task: task,
                      isUpdating: _isUpdating,
                      onStart: _startTask,
                      onComplete: _openCompleteTask,
                    ),
                  ),
                ),
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
            title: 'Linked reports',
            child: Text(
              task.reportIds.isEmpty ? 'None' : task.reportIds.join('\n'),
            ),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _TaskActions extends StatelessWidget {
  const _TaskActions({
    required this.task,
    required this.isUpdating,
    required this.onStart,
    required this.onComplete,
  });

  final Task task;
  final bool isUpdating;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    if (task.status.canStart) {
      return FilledButton.icon(
        onPressed: isUpdating ? null : onStart,
        icon: isUpdating
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: const Text('Start task'),
      );
    }

    if (task.status.canComplete) {
      return FilledButton.icon(
        onPressed: onComplete,
        icon: const Icon(Icons.task_alt),
        label: const Text('Complete task'),
      );
    }

    return OutlinedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.lock_outline),
      label: Text('Status: ${task.status.label}'),
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
