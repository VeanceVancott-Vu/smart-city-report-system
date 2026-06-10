import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import 'overseer_report_dashboard_screen.dart';

class OverseerReportDetailScreen extends StatefulWidget {
  const OverseerReportDetailScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<OverseerReportDetailScreen> createState() =>
      _OverseerReportDetailScreenState();
}

class _OverseerReportDetailScreenState
    extends State<OverseerReportDetailScreen> {
  late Future<Report> _reportFuture;

  String get _reportId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReport();
  }

  void _loadReport() {
    _reportFuture = widget.reportApiService.fetchReport(_reportId);
  }

  Future<void> _refresh() async {
    setState(_loadReport);
    await _reportFuture;
  }

  Future<void> _createTask() async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.overseerCreateTask,
      arguments: OverseerTaskFormArgs(reportIds: <String>[_reportId]),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            tooltip: 'Create task',
            onPressed: _createTask,
            icon: const Icon(Icons.add_task_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Report>(
          future: _reportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Unable to load report.',
                onRetry: _refresh,
              );
            }

            final report = snapshot.requireData;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    report.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                        icon: Icons.flag_outlined,
                        label: report.status.label,
                      ),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: report.category.label,
                      ),
                      _InfoChip(
                        icon: Icons.trending_up,
                        label: 'Priority ${report.priorityScore}',
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Description',
                    child: Text(report.description),
                  ),
                  _Section(
                    title: 'Location',
                    child: Text(
                      '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                    ),
                  ),
                  if ((report.addressText ?? '').trim().isNotEmpty)
                    _Section(
                      title: 'Address',
                      child: Text(report.addressText!),
                    ),
                  _Section(
                    title: 'Before photo URL',
                    child: Text(report.photoLabel),
                  ),
                  _Section(
                    title: 'Created by',
                    child: Text(report.createdBy?.fullName ?? 'Unknown user'),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _createTask,
                    icon: const Icon(Icons.add_task_outlined),
                    label: const Text('Create task from report'),
                  ),
                ],
              ),
            );
          },
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
