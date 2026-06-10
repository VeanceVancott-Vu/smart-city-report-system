import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    _reportsFuture = widget.reportApiService.fetchCitizenReports();
  }

  Future<void> _openCreateReport() async {
    await Navigator.of(context).pushNamed(AppRoutes.createReport);
    if (!mounted) {
      return;
    }
    setState(_loadReports);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citizen Reports'),
        actions: [
          IconButton(
            tooltip: 'Staff tasks',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.staffTasks),
            icon: const Icon(Icons.assignment_outlined),
          ),
          IconButton(
            tooltip: 'Overseer map',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.overseerMap),
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Report>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data ?? const <Report>[];
          if (reports.isEmpty) {
            return const Center(child: Text('No reports yet'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadReports);
              await _reportsFuture;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) =>
                  _ReportListTile(report: reports[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateReport,
        icon: const Icon(Icons.add),
        label: const Text('Report'),
      ),
    );
  }
}

class _ReportListTile extends StatelessWidget {
  const _ReportListTile({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
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
                _StatusChip(label: report.status.label),
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
                _MetaChip(icon: Icons.photo_outlined, label: report.photoLabel),
              ],
            ),
          ],
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
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
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
