import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';

class CitizenReportListScreen extends StatefulWidget {
  const CitizenReportListScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CitizenReportListScreen> createState() =>
      CitizenReportListScreenState();
}

class CitizenReportListScreenState extends State<CitizenReportListScreen> {
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    _reportsFuture = widget.reportApiService.fetchCitizenReports();
  }

  Future<void> reload() async {
    setState(refresh);
    await _reportsFuture;
  }

  Future<void> openCreateReport() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenCreateReport);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  Future<void> _openDetails(String reportId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenReportDetail, arguments: reportId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Report>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: 'Unable to load reports.',
            onRetry: reload,
          );
        }

        final reports = snapshot.data ?? const <Report>[];
        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: const [
                SizedBox(height: 96),
                Center(child: Text('No reports yet')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _ReportListTile(
              report: reports[index],
              onTap: () => _openDetails(reports[index].id),
            ),
          ),
        );
      },
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(report.description, style: textTheme.bodyMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    icon: Icons.category_outlined,
                    label: report.category.label,
                  ),
                  _MetaChip(
                    icon: Icons.place_outlined,
                    label:
                        '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                  ),
                  _MetaChip(
                    icon: Icons.thumb_up_alt_outlined,
                    label: '${report.upvoteCount}',
                  ),
                  _MetaChip(
                    icon: Icons.photo_outlined,
                    label: report.photoLabel,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (status) {
      ReportStatus.submitted => const Color(0xFFE2F3EE),
      ReportStatus.inProgress => const Color(0xFFFFF2D6),
      ReportStatus.fixed => const Color(0xFFE8EEF8),
      ReportStatus.cancelled => const Color(0xFFF5E4E4),
    };
    final foregroundColor = switch (status) {
      ReportStatus.submitted => colorScheme.primary,
      ReportStatus.inProgress => const Color(0xFFB45309),
      ReportStatus.fixed => const Color(0xFF35548A),
      ReportStatus.cancelled => colorScheme.error,
    };

    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.label),
      side: BorderSide.none,
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(
        color: foregroundColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

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
