import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/ui/app_feedback.dart';
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
      AppFeedback.showSuccess(
        context,
        title: context.l10n.reportUpdatedTitle,
        message: report.title,
      );
      Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      await _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await _showError(context.l10n.reportUpdateFailed);
    }
  }

  Future<void> _showError(String message) async {
    if (!mounted) {
      return;
    }
    await AppFeedback.showErrorDialog(
      context,
      title: context.l10n.reportUpdateFailedTitle,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          context.l10n.reportEditTitle,
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
        child: FutureBuilder<Report>(
          future: _reportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _LoadingState();
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: context.l10n.reportLoadFailed,
                onRetry: () => setState(
                  () => _reportFuture = widget.reportApiService.fetchReport(
                    _reportId,
                  ),
                ),
              );
            }

            final report = snapshot.requireData;
            if (!report.status.canCitizenEdit) {
              return _InfoState(
                message: context.l10n.reportSubmittedOnlyEditable,
              );
            }

            return LayoutBuilder(
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
                                Expanded(
                                  flex: 4,
                                  child: _EditReportIntro(report: report),
                                ),
                                const SizedBox(width: 32),
                                Expanded(
                                  flex: 6,
                                  child: _buildFormSurface(report),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _EditReportIntro(report: report, compact: true),
                                const SizedBox(height: 16),
                                Expanded(child: _buildFormSurface(report)),
                              ],
                            ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormSurface(Report report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.75)),
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
          initialReport: report,
          submitLabel: context.l10n.reportSaveChanges,
          onSubmit: _updateReport,
          onUploadBeforePhoto: widget.reportApiService.uploadBeforePhoto,
          reportApiService: widget.reportApiService,
        ),
      ),
    );
  }
}

class _EditReportIntro extends StatelessWidget {
  const _EditReportIntro({required this.report, this.compact = false});

  final Report report;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 28),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withOpacity(0.58),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: colorScheme.onSecondary,
                  size: 30,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 24),
          Text(
            'Update your report',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSecondaryContainer,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            report.title,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review the existing information and update only what has changed before saving.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSecondaryContainer.withOpacity(0.76),
              height: 1.5,
            ),
          ),
          SizedBox(height: compact ? 18 : 28),
          const _EditHint(
            icon: Icons.photo_camera_outlined,
            title: 'Keep the photo clear',
            description:
                'Replace the image only when a better view is available.',
          ),
          const SizedBox(height: 16),
          const _EditHint(
            icon: Icons.location_on_outlined,
            title: 'Check the location',
            description:
                'Confirm that the pin still matches the reported issue.',
          ),
          const SizedBox(height: 16),
          const _EditHint(
            icon: Icons.fact_check_outlined,
            title: 'Save accurate details',
            description:
                'Clear information helps the city team respond correctly.',
          ),
        ],
      ),
    );
  }
}

class _EditHint extends StatelessWidget {
  const _EditHint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
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
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.secondary.withOpacity(0.16)),
          ),
          child: Icon(icon, size: 18, color: colorScheme.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer.withOpacity(0.7),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Loading report',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please wait while the latest information is prepared.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.error.withOpacity(0.18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.cloud_off_outlined,
                    size: 30,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Unable to load report',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colorScheme.primary.withOpacity(0.16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 30,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Editing is unavailable',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
