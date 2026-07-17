import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
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
      successTitle: context.l10n.taskApprovedTitle,
    );
  }

  Future<void> _closeTask() async {
    await _changeTask(
      () => widget.taskApiService.closeTask(_taskId),
      successTitle: context.l10n.taskClosedTitle,
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.l10n.taskDeleteQuestion),
        content: Text(context.l10n.taskDeleteWarning(task.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.taskKeep),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: Text(context.l10n.commonDelete),
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
        title: context.l10n.taskDeletedTitle,
        message: task.title,
      );
      Navigator.of(context).pop(true);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError(context.l10n.taskDeleteFailed);
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
      if (!mounted) {
        return;
      }
      _showError(context.l10n.taskUpdateFailed);
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    AppFeedback.showError(
      context,
      title: context.l10n.taskUpdateFailedTitle,
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
          backgroundColor: const Color(0xFFF6F8F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Text(context.l10n.taskDetailsTitle),
            actions: [
              if (task != null)
                IconButton(
                  tooltip: context.l10n.commonEdit,
                  onPressed: _editTask,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (task != null && task.status.canAssign)
                IconButton(
                  tooltip:
                      '${context.l10n.commonAssign} ${context.l10n.commonStaff}',
                  onPressed: _assignTask,
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              if (task != null && task.status.canApprove)
                IconButton(
                  tooltip: context.l10n.commonApprove,
                  onPressed: _approveTask,
                  icon: const Icon(Icons.verified_outlined),
                ),
              if (task != null && task.status.canClose)
                IconButton(
                  tooltip: context.l10n.commonClose,
                  onPressed: _closeTask,
                  icon: const Icon(Icons.check_circle_outline),
                ),
              if (task != null && task.status.canDelete)
                IconButton(
                  tooltip: context.l10n.commonDelete,
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
      return _ErrorState(
        message: context.l10n.taskLoadFailed,
        onRetry: _refresh,
      );
    }

    final task = snapshot.requireData;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
        children: [
          Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF123B38), borderRadius: BorderRadius.circular(24)),
            child: Text(
            task.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
          )),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.flag_outlined,
                label: task.status.localizedLabel(context),
              ),
              _InfoChip(
                icon: Icons.category_outlined,
                label: task.category.localizedLabel(context),
              ),
              _InfoChip(
                icon: Icons.trending_up,
                label: context.l10n.priorityValue(task.priorityScore),
              ),
              _InfoChip(
                icon: Icons.link_outlined,
                label: context.l10n.reportCount(task.reportIds.length),
              ),
            ],
          ),
          if (task.status.needsReviewComparison) ...[
            const SizedBox(height: 18),
            _ReviewComparison(task: task),
          ],
          _Section(
            title: context.l10n.commonDescription,
            child: Text(task.description),
          ),
          _Section(
            title: context.l10n.commonLocation,
            child: Text(task.locationLabel),
          ),
          _Section(
            title: context.l10n.commonCoordinates,
            child: Text(
              '${task.latitude.toStringAsFixed(6)}, ${task.longitude.toStringAsFixed(6)}',
            ),
          ),
          _Section(
            title: context.l10n.taskAssignedStaff,
            child: Text(
              task.assignedStaff?.fullName ?? context.l10n.commonUnassigned,
            ),
          ),
          if (!task.status.needsReviewComparison) ...[
            _Section(
              title: context.l10n.commonBeforePhoto,
              child: UploadedPhotoView(fileUrl: task.beforePhotoUrl),
            ),
            if ((task.afterPhotoUrl ?? '').trim().isNotEmpty)
              _Section(
                title: context.l10n.commonAfterPhoto,
                child: UploadedPhotoView(fileUrl: task.afterPhotoUrl),
              ),
          ],
          if ((task.staffNote ?? '').trim().isNotEmpty)
            _Section(
              title: context.l10n.taskStaffNote,
              child: Text(task.staffNote!),
            ),
          _Section(
            title: context.l10n.taskReportIds,
            child: Text(
              task.reportIds.isEmpty
                  ? context.l10n.commonNone
                  : task.reportIds.join('\n'),
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
                label: Text(context.l10n.commonAssign),
              ),
              OutlinedButton.icon(
                onPressed: _editTask,
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.l10n.commonEdit),
              ),
              if (task.status.canApprove)
                FilledButton.icon(
                  onPressed: _approveTask,
                  icon: const Icon(Icons.verified_outlined),
                  label: Text(context.l10n.commonApprove),
                ),
              if (task.status.canClose)
                FilledButton.icon(
                  onPressed: _closeTask,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(context.l10n.commonClose),
                ),
              OutlinedButton.icon(
                onPressed: task.status.canDelete
                    ? () => _deleteTask(task)
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: Text(context.l10n.commonDelete),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          ]))),
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
          context.l10n.taskReviewEvidence,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final before = _ReviewPhotoCard(
              title: context.l10n.commonBeforePhoto,
              icon: Icons.report_problem_outlined,
              fileUrl: task.beforePhotoUrl,
              emptyLabel: context.l10n.taskNoBeforePhoto,
            );
            final after = _ReviewPhotoCard(
              title: context.l10n.commonAfterPhoto,
              icon: Icons.task_alt_outlined,
              fileUrl: task.afterPhotoUrl,
              emptyLabel: context.l10n.taskNoAfterPhoto,
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
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDCE5E3)),
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
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFDCE6E3))),
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
      side: const BorderSide(color: Color(0xFFDCE5E3)),
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
