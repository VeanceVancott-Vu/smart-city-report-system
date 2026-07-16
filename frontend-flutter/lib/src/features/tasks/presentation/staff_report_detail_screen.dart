import 'package:flutter/material.dart';

import '../../../core/files/upload_file_picker.dart';
import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
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
  bool _isUploadingAfterPhoto = false;
  String? _afterPhotoError;

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
    _afterPhotoError = null;
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

  Future<void> _pickAndUploadAfterPhoto(Report report) async {
    if (_isUploadingAfterPhoto) {
      return;
    }

    setState(() {
      _isUploadingAfterPhoto = true;
      _afterPhotoError = null;
    });

    try {
      final pickedFile = await pickImageUploadFile();
      if (pickedFile == null) {
        return;
      }

      final updated = await widget.reportApiService.uploadAfterPhoto(
        reportId: report.id,
        filename: pickedFile.filename,
        bytes: pickedFile.bytes,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _afterPhotoError = null;
        _reportFuture = Future<Report>.value(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.staffAfterPhotoUploaded)),
      );
    } on FilePickerException catch (error) {
      _setAfterPhotoError(error.message);
    } on ReportApiException catch (error) {
      _setAfterPhotoError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _setAfterPhotoError(context.l10n.staffAfterPhotoUploadFailed);
    } finally {
      if (mounted) {
        setState(() => _isUploadingAfterPhoto = false);
      }
    }
  }

  void _setAfterPhotoError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _afterPhotoError = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.reportDetailsTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.commonRefresh,
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
                message: context.l10n.reportLoadFailed,
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
                        label: report.status.localizedLabel(context),
                      ),
                      _InfoChip(
                        icon: Icons.category_outlined,
                        label: report.category.localizedLabel(context),
                      ),
                      _InfoChip(
                        icon: Icons.thumb_up_alt_outlined,
                        label: context.l10n.upvoteCount(report.upvoteCount),
                      ),
                      _InfoChip(
                        icon: Icons.trending_up,
                        label: context.l10n.priorityValue(report.priorityScore),
                      ),
                    ],
                  ),
                  _Section(
                    title: context.l10n.commonDescription,
                    child: Text(report.description),
                  ),
                  _Section(
                    title: context.l10n.commonLocation,
                    child: Text(_locationLabel(context, report)),
                  ),
                  _Section(
                    title: context.l10n.commonCoordinates,
                    child: Text(
                      context.l10n.coordinatesValue(
                        report.latitude.toStringAsFixed(6),
                        report.longitude.toStringAsFixed(6),
                      ),
                    ),
                  ),
                  _Section(
                    title: context.l10n.commonBeforePhoto,
                    child: UploadedPhotoView(fileUrl: report.beforePhotoUrl),
                  ),
                  _Section(
                    title: context.l10n.commonAfterPhoto,
                    child: _AfterPhotoSection(
                      report: report,
                      isUploading: _isUploadingAfterPhoto,
                      errorText: _afterPhotoError,
                      onUpload: () => _pickAndUploadAfterPhoto(report),
                    ),
                  ),
                  _Section(
                    title: context.l10n.reportReporter,
                    child: Text(
                      report.anonymous
                          ? context.l10n.commonAnonymous
                          : report.createdBy?.fullName ??
                                context.l10n.commonUnknownUser,
                    ),
                  ),
                  _Section(
                    title: context.l10n.reportId,
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

  String _locationLabel(BuildContext context, Report report) {
    final address = report.addressText?.trim();
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return context.l10n.coordinatesValue(
      report.latitude.toStringAsFixed(4),
      report.longitude.toStringAsFixed(4),
    );
  }
}

class _AfterPhotoSection extends StatelessWidget {
  const _AfterPhotoSection({
    required this.report,
    required this.isUploading,
    required this.errorText,
    required this.onUpload,
  });

  final Report report;
  final bool isUploading;
  final String? errorText;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = (report.afterPhotoUrl ?? '').trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UploadedPhotoView(fileUrl: report.afterPhotoUrl),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onUpload,
          icon: isUploading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(hasPhoto ? Icons.swap_horiz : Icons.upload_file),
          label: Text(
            hasPhoto ? context.l10n.photoReplace : context.l10n.photoUpload,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
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
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
