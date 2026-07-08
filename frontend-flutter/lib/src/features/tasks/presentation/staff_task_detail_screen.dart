import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/routing/app_routes.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import '../data/task_api_service.dart';
import '../domain/task.dart';

class StaffTaskDetailScreen extends StatefulWidget {
  const StaffTaskDetailScreen({
    super.key,
    required this.taskApiService,
    required this.reportApiService,
  });

  final TaskApiService taskApiService;
  final ReportApiService reportApiService;

  @override
  State<StaffTaskDetailScreen> createState() => _StaffTaskDetailScreenState();
}

class _StaffTaskDetailScreenState extends State<StaffTaskDetailScreen> {
  late Future<_TaskDetailData> _detailFuture;
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
    _detailFuture = taskId == null
        ? Future<_TaskDetailData>.error(
            const TaskApiException('Task ID is missing.'),
          )
        : _fetchDetail(taskId);
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
    await _detailFuture;
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
      setState(_loadTask);
      await Navigator.of(
        context,
      ).pushNamed(AppRoutes.staffTaskRoute, arguments: task.id);
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

  void _openRouteMap() {
    final taskId = _taskId;
    if (taskId == null) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.staffTaskRoute, arguments: taskId);
  }

  void _openReport(String reportId) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.staffReportDetail, arguments: reportId);
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
    return FutureBuilder<_TaskDetailData>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final task = snapshot.data?.task;

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
                      onRoute: _openRouteMap,
                      onComplete: _openCompleteTask,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<_TaskDetailData> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _ErrorState(message: 'Unable to load task.', onRetry: _refresh);
    }

    final detail = snapshot.requireData;
    final task = detail.task;
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
            title: 'Before photo',
            child: UploadedPhotoView(fileUrl: task.beforePhotoUrl),
          ),
          if ((task.afterPhotoUrl ?? '').trim().isNotEmpty)
            _Section(
              title: 'After photo',
              child: UploadedPhotoView(fileUrl: task.afterPhotoUrl),
            ),
          if ((task.staffNote ?? '').trim().isNotEmpty)
            _Section(title: 'Staff note', child: Text(task.staffNote!)),
          _Section(
            title: 'Linked reports',
            child: _LinkedReportsList(
              reports: detail.reports,
              reportIds: task.reportIds,
              onOpenReport: _openReport,
            ),
          ),
          const SizedBox(height: 96),
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

class _LinkedReportsList extends StatelessWidget {
  const _LinkedReportsList({
    required this.reports,
    required this.reportIds,
    required this.onOpenReport,
  });

  final List<Report> reports;
  final List<String> reportIds;
  final ValueChanged<String> onOpenReport;

  @override
  Widget build(BuildContext context) {
    if (reportIds.isEmpty) {
      return const Text('None');
    }

    if (reports.isEmpty) {
      return const Text('No linked report details found.');
    }

    return Column(
      children: [
        for (var index = 0; index < reports.length; index++) ...[
          _LinkedReportTile(
            number: index + 1,
            report: reports[index],
            onTap: () => onOpenReport(reports[index].id),
          ),
          if (index < reports.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LinkedReportTile extends StatelessWidget {
  const _LinkedReportTile({
    required this.number,
    required this.report,
    required this.onTap,
  });

  final int number;
  final Report report;
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
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE2F3EE),
          foregroundColor: const Color(0xFF0F766E),
          child: Text(
            number.toString(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          report.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallMeta(icon: Icons.flag_outlined, label: report.status.label),
              _SmallMeta(
                icon: Icons.category_outlined,
                label: report.category.label,
              ),
              _SmallMeta(
                icon: Icons.trending_up,
                label: 'Priority ${report.priorityScore}',
              ),
              if ((report.addressText ?? '').trim().isNotEmpty)
                _SmallMeta(
                  icon: Icons.place_outlined,
                  label: report.addressText!,
                ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _SmallMeta extends StatelessWidget {
  const _SmallMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
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

class _TaskActions extends StatelessWidget {
  const _TaskActions({
    required this.task,
    required this.isUpdating,
    required this.onStart,
    required this.onRoute,
    required this.onComplete,
  });

  final Task task;
  final bool isUpdating;
  final VoidCallback onStart;
  final VoidCallback onRoute;
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onRoute,
            icon: const Icon(Icons.route),
            label: const Text('Route map'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.task_alt),
            label: const Text('Complete task'),
          ),
        ],
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
