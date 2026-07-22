import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../tasks/domain/task.dart';
import '../data/user_api_service.dart';
import '../domain/app_user.dart';

class OverseerStaffProfileScreen extends StatefulWidget {
  const OverseerStaffProfileScreen({super.key, required this.userApiService});

  final UserApiService userApiService;

  @override
  State<OverseerStaffProfileScreen> createState() =>
      _OverseerStaffProfileScreenState();
}

class _OverseerStaffProfileScreenState
    extends State<OverseerStaffProfileScreen> {
  Future<StaffDetailProfile>? _profileFuture;

  String get _staffId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileFuture ??= widget.userApiService.fetchStaffDetailProfile(_staffId);
  }

  Future<void> _refresh() async {
    final next = widget.userApiService.fetchStaffDetailProfile(_staffId);
    setState(() => _profileFuture = next);
    await next;
  }

  Future<void> _openTask(String taskId) async {
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerTaskDetail, arguments: taskId);
    if (mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.staffProfileTitle)),
      body: FutureBuilder<StaffDetailProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(context.l10n.staffProfileLoadFailed),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(context.l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StaffIdentity(profile: profile),
                        const SizedBox(height: 18),
                        _TaskAnalytics(analytics: profile.taskAnalytics),
                        const SizedBox(height: 18),
                        _TaskList(
                          tasks: profile.tasks,
                          onTaskTapped: _openTask,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StaffIdentity extends StatelessWidget {
  const _StaffIdentity({required this.profile});

  final StaffDetailProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    _initials(profile.fullName),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.roleStaff,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(
                profile.active ? Icons.check_circle : Icons.cancel,
                size: 18,
              ),
              label: Text(
                profile.active
                    ? context.l10n.profileActive
                    : context.l10n.profileInactive,
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 18),
            _DetailRow(
              icon: Icons.email_outlined,
              label: context.l10n.profileEmail,
              value: profile.email,
            ),
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: context.l10n.profileMemberSince,
              value: _dateLabel(profile.createdAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskAnalytics extends StatelessWidget {
  const _TaskAnalytics({required this.analytics});

  final StaffTaskAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.profileTaskAnalytics,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720
                    ? 3
                    : constraints.maxWidth >= 440
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - ((columns - 1) * 12)) / columns;
                final metrics = <(String, int)>[
                  (context.l10n.profileTotalTasks, analytics.totalTasks),
                  for (final status in TaskStatus.values)
                    (
                      status.localizedLabel(context),
                      analytics.byStatus[status] ?? 0,
                    ),
                ];
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: width,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.assignment_outlined, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  metric.$1,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${metric.$2}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks, required this.onTaskTapped});

  final List<Task> tasks;
  final ValueChanged<String> onTaskTapped;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.commonTasks,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(context.l10n.staffNoAssignedTasksForMember),
                ),
              )
            else
              ...tasks.map(
                (task) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: ListTile(
                    key: Key('overseerStaffProfileTask-${task.id}'),
                    onTap: () => onTaskTapped(task.id),
                    leading: const Icon(Icons.assignment_outlined),
                    title: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(task.status.localizedLabel(context)),
                          ),
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              context.l10n.priorityValue(task.priorityScore),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _initials(String fullName) {
  return fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

String _dateLabel(DateTime? date) {
  if (date == null) return '—';
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
