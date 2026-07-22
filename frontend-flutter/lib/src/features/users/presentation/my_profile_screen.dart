import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../auth/domain/current_user.dart';
import '../../reports/domain/report.dart';
import '../../tasks/domain/task.dart';
import '../data/user_api_service.dart';
import '../domain/app_user.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key, required this.userApiService});

  final UserApiService userApiService;

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.userApiService.fetchMyProfile();
  }

  Future<void> _refresh() async {
    final next = widget.userApiService.fetchMyProfile();
    setState(() => _profileFuture = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileTitle)),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ProfileError(
              message: context.l10n.profileLoadFailed,
              onRetry: _refresh,
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
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _IdentityCard(profile: profile),
                        const SizedBox(height: 20),
                        if (profile.citizenReportAnalytics case final data?)
                          _CitizenAnalytics(data: data)
                        else if (profile.staffTaskAnalytics case final data?)
                          _StaffAnalytics(data: data)
                        else
                          _OverseerProfileNote(),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
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
                        _roleLabel(context, profile.role),
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
            const SizedBox(height: 24),
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

class _CitizenAnalytics extends StatelessWidget {
  const _CitizenAnalytics({required this.data});

  final CitizenReportAnalytics data;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsSection(
      title: context.l10n.profileReportAnalytics,
      totalLabel: context.l10n.profileTotalReports,
      total: data.totalReports,
      metrics: [
        for (final status in ReportStatus.values)
          _Metric(
            label: status.localizedLabel(context),
            value: data.byStatus[status] ?? 0,
            icon: _reportStatusIcon(status),
          ),
      ],
    );
  }
}

class _StaffAnalytics extends StatelessWidget {
  const _StaffAnalytics({required this.data});

  final StaffTaskAnalytics data;

  @override
  Widget build(BuildContext context) {
    return _AnalyticsSection(
      title: context.l10n.profileTaskAnalytics,
      totalLabel: context.l10n.profileTotalTasks,
      total: data.totalTasks,
      metrics: [
        for (final status in TaskStatus.values)
          _Metric(
            label: status.localizedLabel(context),
            value: data.byStatus[status] ?? 0,
            icon: _taskStatusIcon(status),
          ),
      ],
    );
  }
}

class _OverseerProfileNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.analytics_outlined, size: 30),
            const SizedBox(width: 16),
            Expanded(child: Text(context.l10n.profileOverseerAnalyticsNote)),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({
    required this.title,
    required this.totalLabel,
    required this.total,
    required this.metrics,
  });

  final String title;
  final String totalLabel;
  final int total;
  final List<_Metric> metrics;

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
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _MetricCard(
              metric: _Metric(
                label: totalLabel,
                value: total,
                icon: Icons.assessment_outlined,
              ),
              emphasized: true,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 720
                    ? 3
                    : width >= 440
                    ? 2
                    : 1;
                final itemWidth = (width - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final metric in metrics)
                      SizedBox(
                        width: itemWidth,
                        child: _MetricCard(metric: metric),
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

class _Metric {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final int value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric, this.emphasized = false});

  final _Metric metric;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.primaryContainer
            : colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(metric.icon, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${metric.value}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
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

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

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
            const Icon(Icons.person_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
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

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();
}

String _dateLabel(DateTime? date) {
  if (date == null) {
    return '—';
  }
  final local = date.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _roleLabel(BuildContext context, UserRole role) {
  return switch (role) {
    UserRole.citizen => context.l10n.roleCitizen,
    UserRole.staff => context.l10n.roleStaff,
    UserRole.overseer => context.l10n.roleOverseer,
  };
}

IconData _reportStatusIcon(ReportStatus status) {
  return switch (status) {
    ReportStatus.submitted => Icons.send_outlined,
    ReportStatus.inProgress => Icons.build_outlined,
    ReportStatus.fixed => Icons.check_circle_outline,
    ReportStatus.cancelled => Icons.cancel_outlined,
  };
}

IconData _taskStatusIcon(TaskStatus status) {
  return switch (status) {
    TaskStatus.newTask => Icons.fiber_new_outlined,
    TaskStatus.assigned => Icons.assignment_ind_outlined,
    TaskStatus.inProgress => Icons.play_circle_outline,
    TaskStatus.done => Icons.task_alt,
    TaskStatus.pendingReview => Icons.rate_review_outlined,
    TaskStatus.denied => Icons.replay_outlined,
    TaskStatus.approved => Icons.verified_outlined,
    TaskStatus.closed => Icons.lock_outline,
    TaskStatus.cancelled => Icons.cancel_outlined,
  };
}
