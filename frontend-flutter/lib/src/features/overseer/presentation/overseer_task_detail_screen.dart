import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_feedback.dart';
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

  Future<void> _approveTask() async {
    await _changeTask(
      () => widget.taskApiService.approveTask(_taskId),
      successTitle: 'Task approved',
    );
  }

  Future<void> _closeTask() async {
    await _changeTask(
      () => widget.taskApiService.closeTask(_taskId),
      successTitle: 'Task closed',
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Delete task?'),
        content: Text(
          'This will permanently delete "${task.title}" and unlink its reports.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep task'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await widget.taskApiService.deleteTask(_taskId);
      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        title: 'Task deleted',
        message: task.title,
      );
      Navigator.of(context).pop(true);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to delete task.');
    }
  }

  Future<void> _changeTask(
    Future<Task> Function() action, {
    required String successTitle,
  }) async {
    try {
      final task = await action();
      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        title: successTitle,
        message: task.title,
      );
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
    AppFeedback.showError(
      context,
      title: 'Unable to update task',
      message: message,
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
              if (task != null && task.status.canApprove)
                IconButton(
                  tooltip: 'Approve',
                  onPressed: _approveTask,
                  icon: const Icon(Icons.verified_outlined),
                ),
              if (task != null && task.status.canClose)
                IconButton(
                  tooltip: 'Close',
                  onPressed: _closeTask,
                  icon: const Icon(Icons.check_circle_outline),
                ),
              if (task != null && task.status.canDelete)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteTask(task),
                  icon: const Icon(Icons.delete_outline),
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
          if (task.status.needsReviewComparison) ...[
            const SizedBox(height: 18),
            _ReviewComparison(task: task),
          ],
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
          if (!task.status.needsReviewComparison) ...[
            _Section(
              title: 'Before photo',
              child: UploadedPhotoView(fileUrl: task.beforePhotoUrl),
            ),
            if ((task.afterPhotoUrl ?? '').trim().isNotEmpty)
              _Section(
                title: 'After photo',
                child: UploadedPhotoView(fileUrl: task.afterPhotoUrl),
              ),
          ],
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
              if (task.status.canApprove)
                FilledButton.icon(
                  onPressed: _approveTask,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Approve'),
                ),
              if (task.status.canClose)
                FilledButton.icon(
                  onPressed: _closeTask,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Close'),
                ),
              OutlinedButton.icon(
                onPressed: task.status.canDelete
                    ? () => _deleteTask(task)
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewComparison extends StatelessWidget {
  const _ReviewComparison({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review evidence',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final before = _ReviewPhotoCard(
              title: 'Before',
              icon: Icons.report_problem_outlined,
              fileUrl: task.beforePhotoUrl,
              emptyLabel: 'No before photo uploaded',
            );
            final after = _ReviewPhotoCard(
              title: 'After',
              icon: Icons.task_alt_outlined,
              fileUrl: task.afterPhotoUrl,
              emptyLabel: 'No after photo uploaded',
            );

            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: before),
                      const SizedBox(width: 12),
                      Expanded(child: after),
                    ],
                  )
                : Column(children: [before, const SizedBox(height: 12), after]);
          },
        ),
      ],
    );
  }
}

class _ReviewPhotoCard extends StatelessWidget {
  const _ReviewPhotoCard({
    required this.title,
    required this.icon,
    required this.fileUrl,
    required this.emptyLabel,
  });

  final String title;
  final IconData icon;
  final String? fileUrl;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF0F766E)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            UploadedPhotoView(fileUrl: fileUrl, emptyLabel: emptyLabel),
          ],
        ),
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
