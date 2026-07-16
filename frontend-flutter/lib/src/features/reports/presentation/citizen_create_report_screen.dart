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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          context.l10n.reportCreateTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1024;
            final horizontalPadding = isDesktop ? 32.0 : 16.0;
            final verticalPadding = isDesktop ? 32.0 : 20.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(
                              flex: 4,
                              child: _CreateReportIntro(),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 6,
                              child: _buildFormSurface(context),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _CreateReportIntro(compact: true),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildFormSurface(context),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormSurface(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
      if (!context.mounted) return;
      AppFeedback.showSuccess(
        context,
        title: context.l10n.reportSubmittedTitle,
        message: report.title,
      );
      Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      if (!context.mounted) return;
      await _showError(context, error.message);
    } catch (_) {
      if (!context.mounted) return;
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

class _CreateReportIntro extends StatelessWidget {
  const _CreateReportIntro({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.campaign_outlined,
              color: colorScheme.onPrimary,
              size: 28,
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
          Text(
            'Report a city issue',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimaryContainer,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Share the issue, add a clear photo and confirm the location so the city team can respond faster.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.78),
              height: 1.5,
            ),
          ),
          SizedBox(height: compact ? 18 : 28),
          const _IntroStep(
            number: '1',
            title: 'Choose the issue type',
            description: 'Select the category that best matches the problem.',
          ),
          const SizedBox(height: 16),
          const _IntroStep(
            number: '2',
            title: 'Add a clear photo',
            description: 'Use a photo that clearly shows the issue.',
          ),
          const SizedBox(height: 16),
          const _IntroStep(
            number: '3',
            title: 'Confirm the location',
            description: 'Pin the exact position before submitting.',
          ),
        ],
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({
    required this.number,
    required this.title,
    required this.description,
  });

  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.22),
            ),
          ),
          child: Text(
            number,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.72),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
