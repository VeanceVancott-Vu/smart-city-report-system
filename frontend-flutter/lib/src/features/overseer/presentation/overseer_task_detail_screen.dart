import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../reports/presentation/report_category_visuals.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_feedback.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import '../../tasks/data/task_api_service.dart';
import '../../tasks/domain/task.dart';
import 'overseer_report_dashboard_screen.dart';

class OverseerTaskDetailScreen extends StatefulWidget {
  const OverseerTaskDetailScreen({
    super.key,
    required this.taskApiService,
    required this.reportApiService,
  });

  final TaskApiService taskApiService;
  final ReportApiService reportApiService;

  @override
  State<OverseerTaskDetailScreen> createState() =>
      _OverseerTaskDetailScreenState();
}

class _OverseerTaskDetailScreenState extends State<OverseerTaskDetailScreen> {
  late Future<_TaskDetailData> _taskFuture;

  String get _taskId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTask();
  }

  void _loadTask() {
    _taskFuture = _fetchDetail(_taskId);
  }

  Future<_TaskDetailData> _fetchDetail(String taskId) async {
    final task = await widget.taskApiService.fetchTask(taskId);
    final reports = task.reportIds.isEmpty
        ? const <Report>[]
        : await Future.wait(
            task.reportIds.map(widget.reportApiService.fetchReport),
          );
    return _TaskDetailData(task: task, reports: reports);
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

  Future<void> _denyTask() async {
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          Icons.assignment_return_outlined,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(context.l10n.taskDenyTitle),
        content: Form(
          key: formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.taskDenyPrompt),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  autofocus: true,
                  maxLength: 2000,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.taskDenyNoteLabel,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? context.l10n.taskDenyNoteRequired
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton.icon(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(dialogContext).pop(noteController.text.trim());
              }
            },
            icon: const Icon(Icons.assignment_return_outlined),
            label: Text(context.l10n.commonDeny),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null || note.isEmpty || !mounted) {
      return;
    }

    await _changeTask(
      () => widget.taskApiService.denyTask(_taskId, note),
      successTitle: context.l10n.taskDeniedTitle,
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
    } on TaskApiException catch (_) {
      _showError(context.l10n.taskDeleteFailed);
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
    } on TaskApiException catch (_) {
      _showError(context.l10n.taskUpdateFailed);
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
    return FutureBuilder<_TaskDetailData>(
      future: _taskFuture,
      builder: (context, snapshot) {
        final task = snapshot.data?.task;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F8F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Text(context.l10n.taskDetailsTitle),
            actions: [
              if (task != null && task.status.canEdit)
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
              if (task != null && task.status.canDeny)
                IconButton(
                  tooltip: context.l10n.commonDeny,
                  onPressed: _denyTask,
                  icon: const Icon(Icons.assignment_return_outlined),
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

  Widget _buildBody(AsyncSnapshot<_TaskDetailData> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _ErrorState(
        message: context.l10n.taskLoadFailed,
        onRetry: _refresh,
      );
    }

    final detail = snapshot.requireData;
    final task = detail.task;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF123B38),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                    ),
                  ),
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
                    child: task.assignedStaff == null
                        ? Text(context.l10n.commonUnassigned)
                        : TextButton.icon(
                            key: const Key(
                              'overseerTaskAssignedStaffProfileButton',
                            ),
                            onPressed: () => Navigator.of(context).pushNamed(
                              AppRoutes.overseerStaffProfile,
                              arguments: task.assignedStaff!.id,
                            ),
                            iconAlignment: IconAlignment.end,
                            icon: const Icon(Icons.chevron_right),
                            label: Text(task.assignedStaff!.fullName),
                          ),
                  ),
                  if (task.submittedAt != null && task.assignedStaff != null)
                    _Section(
                      title: context.l10n.taskCompletedBy,
                      child: Text(task.assignedStaff!.fullName),
                    ),
                  _Section(
                    title: context.l10n.taskCreatedBy,
                    child: Text(
                      task.createdByOverseer?.fullName ??
                          context.l10n.commonNone,
                    ),
                  ),
                  _TaskLifecycle(task: task),
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
                  _Section(
                    title: context.l10n.taskReviewEvidence,
                    child: detail.reports.isEmpty
                        ? Text(context.l10n.commonNone)
                        : Column(
                            children: detail.reports
                                .map(
                                  (report) => _LinkedReportCard(report: report),
                                )
                                .toList(growable: false),
                          ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (task.status.canAssign)
                        OutlinedButton.icon(
                          onPressed: _assignTask,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: Text(context.l10n.commonAssign),
                        ),
                      if (task.status.canEdit)
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
                      if (task.status.canDeny)
                        FilledButton.icon(
                          onPressed: _denyTask,
                          icon: const Icon(Icons.assignment_return_outlined),
                          label: Text(context.l10n.commonDeny),
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                      if (task.status.canClose)
                        FilledButton.icon(
                          onPressed: _closeTask,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(context.l10n.commonClose),
                        ),
                      if (task.status.canDelete)
                        OutlinedButton.icon(
                          onPressed: () => _deleteTask(task),
                          icon: const Icon(Icons.delete_outline),
                          label: Text(context.l10n.commonDelete),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskDetailData {
  const _TaskDetailData({required this.task, required this.reports});

  final Task task;
  final List<Report> reports;
}

class _TaskLifecycle extends StatelessWidget {
  const _TaskLifecycle({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _DetailRow(
        label: context.l10n.taskCreatedAt,
        value: _formatTimestamp(task.createdAt),
      ),
      if (task.startedAt != null)
        _DetailRow(
          label: context.l10n.taskStartedAt,
          value: _formatTimestamp(task.startedAt!),
        ),
      if (task.submittedAt != null)
        _DetailRow(
          label: context.l10n.taskSubmittedAt,
          value: _formatTimestamp(task.submittedAt!),
        ),
      if (task.reviewedAt != null)
        _DetailRow(
          label: context.l10n.taskReviewedAt,
          value: _formatTimestamp(task.reviewedAt!),
        ),
      if (task.closedAt != null)
        _DetailRow(
          label: context.l10n.taskClosedAt,
          value: _formatTimestamp(task.closedAt!),
        ),
    ];

    return _Section(
      title: context.l10n.taskData,
      child: Column(children: rows),
    );
  }
}

class _LinkedReportCard extends StatelessWidget {
  const _LinkedReportCard({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDCE5E3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  reportCategoryIcon(report.category),
                  color: const Color(0xFF0F766E),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.flag_outlined,
                  label: report.status.localizedLabel(context),
                ),
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: report.category.localizedLabel(context),
                ),
                _InfoChip(
                  icon: Icons.trending_up,
                  label: context.l10n.priorityValue(report.priorityScore),
                ),
                _InfoChip(
                  icon: Icons.thumb_up_alt_outlined,
                  label: '${report.upvoteCount}',
                ),
              ],
            ),
            _DetailRow(
              label: context.l10n.commonDescription,
              value: report.description,
            ),
            _DetailRow(
              label: context.l10n.commonLocation,
              value: report.addressText?.trim().isNotEmpty == true
                  ? report.addressText!.trim()
                  : '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
            ),
            _DetailRow(
              label: context.l10n.commonCoordinates,
              value:
                  '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
            ),
            _DetailRow(label: context.l10n.taskReportIds, value: report.id),
            _DetailRow(
              label: context.l10n.taskCreatedBy,
              value: report.anonymous
                  ? context.l10n.commonAnonymous
                  : report.createdBy?.fullName ?? context.l10n.commonNone,
            ),
            _DetailRow(
              label: context.l10n.taskCreatedAt,
              value: _formatTimestamp(report.createdAt),
            ),
            _DetailRow(
              label: context.l10n.reportLastUpdated,
              value: _formatTimestamp(report.updatedAt),
            ),
            const SizedBox(height: 12),
            _PhotoSection(
              title: context.l10n.commonBeforePhoto,
              fileUrl: report.beforePhotoUrl,
              emptyLabel: context.l10n.taskNoBeforePhoto,
            ),
            const SizedBox(height: 12),
            _PhotoSection(
              title: context.l10n.commonAfterPhoto,
              fileUrl: report.afterPhotoUrl,
              emptyLabel: context.l10n.taskNoAfterPhoto,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.title,
    required this.fileUrl,
    required this.emptyLabel,
  });

  final String title;
  final String? fileUrl;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        UploadedPhotoView(fileUrl: fileUrl, emptyLabel: emptyLabel),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(value),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  final local = value.toLocal();
  return local.toString().split('.').first;
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6E3)),
      ),
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
