import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/ui/app_feedback.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';
import 'citizen_report_form.dart';

class CitizenCreateReportScreen extends StatelessWidget {
  const CitizenCreateReportScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reportCreateTitle)),
      body: SafeArea(
        child: CitizenReportForm(
          submitLabel: context.l10n.reportSubmit,
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
      AppFeedback.showSuccess(
        context,
        title: context.l10n.reportSubmittedTitle,
        message: report.title,
      );
      Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      await _showError(context, error.message);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      await _showError(context, context.l10n.reportCreateFailed);
    }
  }

  Future<void> _showError(BuildContext context, String message) async {
    await AppFeedback.showErrorDialog(
      context,
      title: context.l10n.reportSubmitFailedTitle,
      message: message,
    );
  }
}
