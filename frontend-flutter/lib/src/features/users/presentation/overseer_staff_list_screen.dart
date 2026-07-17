import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../tasks/domain/task.dart';
import '../data/user_api_service.dart';
import '../domain/app_user.dart';

class OverseerStaffListScreen extends StatefulWidget {
  const OverseerStaffListScreen({super.key, required this.userApiService});

  final UserApiService userApiService;

  @override
  State<OverseerStaffListScreen> createState() =>
      _OverseerStaffListScreenState();
}

class _OverseerStaffListScreenState extends State<OverseerStaffListScreen> {
  late Future<List<StaffSummary>> _staffSummaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    setState(() {
      _staffSummaryFuture = widget.userApiService.fetchStaffSummary();
    });
  }

  Future<void> _refresh() async {
    _loadSummary();
    await _staffSummaryFuture;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Screen Header Stats
        FutureBuilder<List<StaffSummary>>(
          future: _staffSummaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                snapshot.hasError) {
              return const SizedBox.shrink();
            }
            final staff = snapshot.requireData;
            final activeAccounts = staff.where((s) => s.active).length;
            final inactiveAccounts = staff.where((s) => !s.active).length;
            final totalActiveTasks = staff.fold<int>(
              0,
              (sum, s) => sum + s.activeTasksCount,
            );
            final totalCompletedTasks = staff.fold<int>(
              0,
              (sum, s) => sum + s.completedTasksCount,
            );

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDDE5E2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryMetric(
                    label: context.l10n.staffActiveMetric,
                    value: activeAccounts.toString(),
                    color: const Color(0xFF0F766E),
                  ),
                  _SummaryMetric(
                    label: context.l10n.staffInactiveMetric,
                    value: inactiveAccounts.toString(),
                    color: Colors.redAccent,
                  ),
                  _SummaryMetric(
                    label: context.l10n.staffOngoingTasksMetric,
                    value: totalActiveTasks.toString(),
                    color: Colors.orange.shade800,
                  ),
                  _SummaryMetric(
                    label: context.l10n.staffCompletedTasksMetric,
                    value: totalCompletedTasks.toString(),
                    color: Colors.teal.shade700,
                  ),
                ],
              ),
            );
          },
        ),

        // Main List View
        Expanded(
          child: FutureBuilder<List<StaffSummary>>(
            future: _staffSummaryFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _ErrorState(
                  message: context.l10n.staffSummariesLoadFailed,
                  onRetry: _refresh,
                );
              }

              final staff = snapshot.requireData;
              if (staff.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 96),
                      Center(child: Text(context.l10n.staffEmpty)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: staff.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final member = staff[index];
                    return _StaffSummaryCard(
                      member: member,
                      initials: _getInitials(member.fullName),
                      onTaskTapped: (taskId) {
                        Navigator.of(context)
                            .pushNamed(
                              AppRoutes.overseerTaskDetail,
                              arguments: taskId,
                            )
                            .then((_) => _loadSummary());
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _StaffSummaryCard extends StatelessWidget {
  const _StaffSummaryCard({
    required this.member,
    required this.initials,
    required this.onTaskTapped,
  });

  final StaffSummary member;
  final String initials;
  final ValueChanged<String> onTaskTapped;

  @override
  Widget build(BuildContext context) {
    final avatarColor = member.active
        ? const Color(0xFFE2F3EE)
        : Colors.red.shade50;
    final avatarTextColor = member.active
        ? const Color(0xFF0F766E)
        : Colors.red.shade700;

    // Filter tasks
    final activeTasks = member.tasks
        .where(
          (t) =>
              t.status == TaskStatus.assigned ||
              t.status == TaskStatus.inProgress ||
              t.status == TaskStatus.denied,
        )
        .toList();
    final completedTasks = member.tasks
        .where(
          (t) =>
              t.status == TaskStatus.done ||
              t.status == TaskStatus.closed ||
              t.status == TaskStatus.approved ||
              t.status == TaskStatus.pendingReview,
        )
        .toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ExpansionTile(
          shape: Border.all(color: Colors.transparent),
          collapsedShape: Border.all(color: Colors.transparent),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          leading: CircleAvatar(
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: TextStyle(
                color: avatarTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  member.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AccountStatusChip(active: member.active),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.email,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStatChip(
                      label: context.l10n.staffActiveTaskCount(
                        member.activeTasksCount,
                      ),
                      color: Colors.orange.shade800,
                      backgroundColor: Colors.orange.shade50,
                    ),
                    const SizedBox(width: 8),
                    _MiniStatChip(
                      label: context.l10n.staffCompletedTaskCount(
                        member.completedTasksCount,
                      ),
                      color: Colors.teal.shade700,
                      backgroundColor: Colors.teal.shade50,
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: [
            const Divider(height: 1, color: Color(0xFFDDE5E2)),
            Container(
              color: const Color(0xFFF8FAF9),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Tasks Section
                  if (activeTasks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Text(
                        context.l10n.staffActiveTasksHeader,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...activeTasks.map(
                      (t) => _TaskSubTile(
                        task: t,
                        onTap: () => onTaskTapped(t.id),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Completed Tasks Section
                  if (completedTasks.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Text(
                        context.l10n.staffCompletedTasksHeader,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...completedTasks.map(
                      (t) => _TaskSubTile(
                        task: t,
                        onTap: () => onTaskTapped(t.id),
                      ),
                    ),
                  ],

                  if (activeTasks.isEmpty && completedTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          context.l10n.staffNoAssignedTasksForMember,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountStatusChip extends StatelessWidget {
  const _AccountStatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final text = active
        ? context.l10n.commonActive
        : context.l10n.commonInactive;
    final color = active ? const Color(0xFF0F766E) : Colors.red.shade700;
    final backgroundColor = active
        ? const Color(0xFFE2F3EE)
        : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TaskSubTile extends StatelessWidget {
  const _TaskSubTile({required this.task, required this.onTap});

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(task.status);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: ListTile(
        dense: true,
        onTap: onTap,
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  task.status.localizedLabel(context),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.priorityValue(task.priorityScore),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.newTask:
        return Colors.blue;
      case TaskStatus.assigned:
        return Colors.indigo;
      case TaskStatus.inProgress:
        return Colors.orange.shade700;
      case TaskStatus.done:
        return Colors.teal;
      case TaskStatus.pendingReview:
        return Colors.amber.shade800;
      case TaskStatus.denied:
        return Colors.red.shade700;
      case TaskStatus.approved:
        return Colors.green.shade700;
      case TaskStatus.closed:
        return Colors.grey.shade700;
      case TaskStatus.cancelled:
        return Colors.red.shade600;
    }
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
