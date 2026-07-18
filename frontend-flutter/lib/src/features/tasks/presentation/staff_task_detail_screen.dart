import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.staffTaskStarted(task.title))),
      );
      setState(_loadTask);
      await Navigator.of(
        context,
      ).pushNamed(AppRoutes.staffTaskRoute, arguments: task.id);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError(context.l10n.taskUpdateFailed);
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _openCompleteTask() async {
    final taskId = _taskId;
    if (taskId == null || _isUpdating) {
      return;
    }

    setState(() => _isUpdating = true);
    try {
      if (!mounted) {
        return;
      }

      final detail = await _fetchDetail(taskId);
      if (!mounted) {
        return;
      }
      final missingPhoto = detail.reports.any(
        (report) => (report.afterPhotoUrl ?? '').trim().isEmpty,
      );
      if (missingPhoto) {
        _showError(context.l10n.staffAfterPhotoRequired);
        return;
      }

      if (!mounted) {
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
    } on TaskApiException catch (error) {
      _showError(error.message);
    } on ReportApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (mounted) {
        _showError(context.l10n.taskLoadFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
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
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            title: Text(context.l10n.taskDetailsTitle),
            actions: [
              IconButton(
                tooltip: context.l10n.commonRefresh,
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
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
      return _ErrorState(
        message: context.l10n.taskLoadFailed,
        onRetry: _refresh,
      );
    }

    final detail = snapshot.requireData;
    final task = detail.task;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            children: [
              _TaskHero(task: task),
              const SizedBox(height: 28),
              _Section(
                icon: task.status == TaskStatus.denied
                    ? Icons.replay_circle_filled_rounded
                    : Icons.notes_rounded,
                title: task.status == TaskStatus.denied
                    ? context.l10n.taskReworkInstructions
                    : context.l10n.commonDescription,
                child: Text(task.description, style: const TextStyle(height: 1.65)),
              ),
              _Section(
                icon: Icons.location_on_rounded,
                title: context.l10n.commonLocation,
                child: Text(task.locationLabel, style: const TextStyle(height: 1.55)),
              ),
              if ((task.staffNote ?? '').trim().isNotEmpty)
                _Section(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: context.l10n.taskStaffNote,
                  child: Text(task.staffNote!, style: const TextStyle(height: 1.55)),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.taskLinkedReports,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Text(
                    '${detail.reports.length}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F766E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _LinkedReportsList(
                reports: detail.reports,
                reportIds: task.reportIds,
                onOpenReport: _openReport,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskHero extends StatelessWidget {
  const _TaskHero({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF123C3A),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -36,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      task.status.localizedLabel(context),
                      style: const TextStyle(color: Color(0xFFD6F3EC), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.assignment_turned_in_outlined, color: Colors.white.withValues(alpha: .75)),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _HeroMeta(icon: Icons.category_outlined, text: task.category.localizedLabel(context)),
                  _HeroMeta(icon: Icons.trending_up_rounded, text: context.l10n.priorityValue(task.priorityScore)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF82D5C5)),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: Color(0xFFD6E7E3), fontWeight: FontWeight.w600)),
      ],
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
      return Text(context.l10n.commonNone);
    }

    if (reports.isEmpty) {
      return Text(context.l10n.staffNoLinkedReportDetails);
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border(left: BorderSide(color: Color(0xFF0F766E), width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 7))],
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
              _SmallMeta(
                icon: Icons.flag_outlined,
                label: report.status.localizedLabel(context),
              ),
              _SmallMeta(
                icon: Icons.category_outlined,
                label: report.category.localizedLabel(context),
              ),
              _SmallMeta(
                icon: Icons.trending_up,
                label: context.l10n.priorityValue(report.priorityScore),
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
        label: Text(
          task.status == TaskStatus.denied
              ? context.l10n.staffRedoTask
              : context.l10n.staffStartTask,
        ),
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
            label: Text(context.l10n.staffRouteMap),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: isUpdating ? null : onComplete,
            icon: isUpdating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.task_alt),
            label: Text(context.l10n.staffCompleteTask),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.lock_outline),
      label: Text(
        context.l10n.statusValue(task.status.localizedLabel(context)),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F1ED),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 21),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                DefaultTextStyle.merge(
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  child: child,
                ),
              ],
            ),
          ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
