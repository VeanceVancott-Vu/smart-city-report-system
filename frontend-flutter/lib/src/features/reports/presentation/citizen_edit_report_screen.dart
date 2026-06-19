import 'package:flutter/material.dart';

import '../data/report_api_service.dart';
import '../domain/report.dart';
import 'citizen_report_form.dart';

class CitizenEditReportScreen extends StatefulWidget {
  const CitizenEditReportScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CitizenEditReportScreen> createState() =>
      _CitizenEditReportScreenState();
}

class _CitizenEditReportScreenState extends State<CitizenEditReportScreen> {
  late Future<Report> _reportFuture;

  String get _reportId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reportFuture = widget.reportApiService.fetchReport(_reportId);
  }

  Future<void> _updateReport(ReportDraft draft) async {
    try {
      final report = await widget.reportApiService.updateReport(
        _reportId,
        draft,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${report.title} updated')));
      Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to update report.');
    }
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Report')),
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
                onRetry: () => setState(
                  () => _reportFuture = widget.reportApiService.fetchReport(
                    _reportId,
                  ),
                ),
              );
            }

            final report = snapshot.requireData;
            if (!report.status.canCitizenEdit) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Only submitted reports can be edited.'),
                ),
              );
            }

            return CitizenReportForm(
              initialReport: report,
              submitLabel: 'Save changes',
              onSubmit: _updateReport,
              onUploadBeforePhoto: widget.reportApiService.uploadBeforePhoto,
              reportApiService: widget.reportApiService,
            );
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
