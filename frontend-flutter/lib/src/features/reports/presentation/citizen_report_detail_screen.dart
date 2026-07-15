import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_feedback.dart';
import '../../auth/data/auth_api_service.dart';
import '../../auth/domain/current_user.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';

class CitizenReportDetailScreen extends StatefulWidget {
  const CitizenReportDetailScreen({
    super.key,
    required this.reportApiService,
    required this.authApiService,
  });

  final ReportApiService reportApiService;
  final AuthApiService authApiService;

  @override
  State<CitizenReportDetailScreen> createState() =>
      _CitizenReportDetailScreenState();
}

class _CitizenReportDetailScreenState extends State<CitizenReportDetailScreen> {
  late Future<Report> _reportFuture;
  CurrentUser? _currentUser;

  String get _reportId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReport();
  }

  void _loadReport() {
    _reportFuture = widget.reportApiService.fetchReport(_reportId);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await widget.authApiService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(_loadReport);
    await _reportFuture;
  }

  Future<void> _editReport() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenEditReport, arguments: _reportId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(_loadReport);
    }
  }

  Future<void> _deleteReport() async {
    final l10n = context.l10n;
    try {
      final report = await widget.reportApiService.cancelReport(_reportId);
      if (!mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        title: context.l10n.reportCancelledTitle,
        message: report.title,
      );
      Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      await _showError(error.message);
    } catch (_) {
      await _showError(l10n.reportCancelFailed);
    }
  }

  Future<void> _showError(String message) async {
    if (!mounted) {
      return;
    }
    await AppFeedback.showErrorDialog(
      context,
      title: context.l10n.reportCancelFailedTitle,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Report>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final report = snapshot.data;
        final isOwner =
            report != null &&
            _currentUser != null &&
            report.createdBy?.id == _currentUser!.id;

        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.reportDetailsTitle),
            actions: [
              if (report != null && isOwner && report.status.canCitizenEdit)
                IconButton(
                  tooltip: context.l10n.commonEdit,
                  onPressed: _editReport,
                  icon: const Icon(Icons.edit_outlined),
                ),
              if (report != null && isOwner && report.status.canCitizenCancel)
                IconButton(
                  tooltip: context.l10n.commonDelete,
                  onPressed: _deleteReport,
                  icon: const Icon(Icons.delete_outline),
                ),
            ],
          ),
          body: SafeArea(child: _buildBody(context, snapshot)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<Report> snapshot) {
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
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(status: report.status),
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
          const SizedBox(height: 18),
          _Section(
            title: context.l10n.commonDescription,
            child: Text(report.description),
          ),
          _Section(
            title: context.l10n.commonLocation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.coordinatesValue(
                    report.latitude.toStringAsFixed(6),
                    report.longitude.toStringAsFixed(6),
                  ),
                ),
                if ((report.addressText ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(report.addressText!),
                ],
              ],
            ),
          ),
          _Section(
            title: context.l10n.commonBeforePhoto,
            child: UploadedPhotoView(fileUrl: report.beforePhotoUrl),
          ),
          _Section(
            title: context.l10n.reportSubmittedAt,
            child: Text(_formatDateTime(report.createdAt)),
          ),
          _Section(
            title: context.l10n.reportLastUpdated,
            child: Text(_formatDateTime(report.updatedAt)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(status.localizedLabel(context)),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFE2F3EE),
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
