import 'package:flutter/material.dart';

import '../data/report_api_service.dart';
import '../domain/report.dart';
import 'citizen_report_form.dart';

class CitizenCreateReportScreen extends StatelessWidget {
  const CitizenCreateReportScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Report')),
      body: SafeArea(
        child: CitizenReportForm(
          submitLabel: 'Submit report',
          onSubmit: (draft) => _createReport(context, draft),
          onUploadBeforePhoto: reportApiService.uploadBeforePhoto,
          reportApiService: reportApiService,
        ),
      ),
    );
  }

  Future<void> _createReport(BuildContext context, ReportDraft draft) async {
    try {
      final report = await reportApiService.createReport(draft);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${report.title} created')));
      Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      _showError(context, error.message);
    } catch (_) {
      _showError(context, 'Unable to create report.');
    }
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }
}
