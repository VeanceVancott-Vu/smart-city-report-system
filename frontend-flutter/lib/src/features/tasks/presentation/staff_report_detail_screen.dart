import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';

class StaffReportDetailScreen extends StatefulWidget {
  const StaffReportDetailScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<StaffReportDetailScreen> createState() =>
      _StaffReportDetailScreenState();
}

class _StaffReportDetailScreenState extends State<StaffReportDetailScreen> {
  late Future<Report> _reportFuture;
  String? _reportId;
  bool _didReadArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) {
      return;
    }
    _didReadArgs = true;
    _reportId = ModalRoute.of(context)?.settings.arguments as String?;
    _loadReport();
  }

  void _loadReport() {
    final reportId = _reportId;
    _reportFuture = reportId == null
        ? Future<Report>.error(
            const ReportApiException('Report ID is missing.'),
          )
        : widget.reportApiService.fetchReport(reportId);
  }

  Future<void> _refresh() async {
    setState(_loadReport);
    await _reportFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
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
                        icon: Icons.thumb_up_alt_outlined,
                        label: '${report.upvoteCount} upvotes',
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
                    child: Text(_locationLabel(report)),
                  ),
                  _Section(
                    title: 'Coordinates',
                    child: Text(
                      '${report.latitude.toStringAsFixed(6)}, ${report.longitude.toStringAsFixed(6)}',
                    ),
                  ),
                  _Section(
                    title: 'Before photo',
                    child: UploadedPhotoView(fileUrl: report.beforePhotoUrl),
                  ),
                  _Section(
                    title: 'Reporter',
                    child: Text(
                      report.anonymous
                          ? 'Anonymous'
                          : report.createdBy?.fullName ?? 'Unknown user',
                    ),
                  ),
                  _Section(
                    title: 'Report ID',
                    child: SelectableText(report.id),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _locationLabel(Report report) {
    final address = report.addressText?.trim();
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}';
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
