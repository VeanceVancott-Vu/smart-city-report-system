import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';

class OverseerReportDashboardScreen extends StatefulWidget {
  const OverseerReportDashboardScreen({
    super.key,
    required this.reportApiService,
  });

  final ReportApiService reportApiService;

  @override
  State<OverseerReportDashboardScreen> createState() =>
      OverseerReportDashboardScreenState();
}

class OverseerReportDashboardScreenState
    extends State<OverseerReportDashboardScreen> {
  final Set<String> _selectedReportIds = <String>{};
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  void refresh() {
    _reportsFuture = widget.reportApiService.fetchReports();
  }

  Future<void> reload() async {
    setState(refresh);
    await _reportsFuture;
  }

  Future<void> _openReport(String reportId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerReportDetail, arguments: reportId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  Future<void> _createTaskFromSelection() async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.overseerCreateTask,
      arguments: OverseerTaskFormArgs(reportIds: _selectedReportIds.toList()),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      _selectedReportIds.clear();
      setState(refresh);
    }
  }

  void _toggleSelection(String reportId, bool selected) {
    setState(() {
      if (selected) {
        _selectedReportIds.add(reportId);
      } else {
        _selectedReportIds.remove(reportId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_selectedReportIds.length} selected',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: _selectedReportIds.isEmpty
                    ? null
                    : _createTaskFromSelection,
                icon: const Icon(Icons.add_task_outlined),
                label: const Text('Create task'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Report>>(
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _ReportTile(
                      report: report,
                      selected: _selectedReportIds.contains(report.id),
                      onSelected: (selected) =>
                          _toggleSelection(report.id, selected),
                      onOpen: () => _openReport(report.id),
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

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.report,
    required this.selected,
    required this.onSelected,
    required this.onOpen,
  });

  final Report report;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onSelected(value ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(label: report.status.label),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
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
                          icon: Icons.trending_up,
                          label: 'Priority ${report.priorityScore}',
                        ),
                        _MetaChip(
                          icon: Icons.thumb_up_alt_outlined,
                          label: '${report.upvoteCount}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFE2F3EE),
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

class OverseerTaskFormArgs {
  const OverseerTaskFormArgs({this.taskId, this.reportIds = const <String>[]});

  final String? taskId;
  final List<String> reportIds;
}
