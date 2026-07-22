import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';

import '../data/report_api_service.dart';
import '../domain/report.dart';
import 'report_category_visuals.dart';

class CitizenReportDetailScreen extends StatefulWidget {
  const CitizenReportDetailScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CitizenReportDetailScreen> createState() =>
      _CitizenReportDetailScreenState();
}

class _CitizenReportDetailScreenState extends State<CitizenReportDetailScreen> {
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

  Future<void> _openFullPhoto(String url) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => UploadedPhotoFullscreenView(fileUrl: url),
      ),
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
          context.l10n.reportDetailsTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Report>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _LoadingState();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: context.l10n.reportLoadFailed,
              onSecondary: _loadReport,
            );
          }

          final report = snapshot.requireData;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 980;
              final horizontalPadding = isDesktop ? 32.0 : 16.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isDesktop ? 28 : 16,
                  horizontalPadding,
                  40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSection(report, isDesktop),
                        SizedBox(height: isDesktop ? 28 : 20),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  children: [
                                    _buildDescriptionSection(report),
                                    const SizedBox(height: 20),
                                    _buildLocationSection(report),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _buildCurrentStatusSection(report),
                                    const SizedBox(height: 20),
                                    _buildReportMetaSection(report),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildCurrentStatusSection(report),
                              const SizedBox(height: 16),
                              _buildDescriptionSection(report),
                              const SizedBox(height: 16),
                              _buildLocationSection(report),
                              const SizedBox(height: 16),
                              _buildReportMetaSection(report),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeroSection(Report report, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isDesktop
          ? SizedBox(
              height: 360,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 6, child: _buildHeroPhoto(report, 360)),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: SingleChildScrollView(
                        child: _buildHeroContent(report),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroPhoto(report, 250),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildHeroContent(report),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroPhoto(Report report, double height) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: report.beforePhotoUrl != null
          ? () => _openFullPhoto(report.beforePhotoUrl!)
          : null,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (report.beforePhotoUrl != null)
              UploadedPhotoImage(
                fileUrl: report.beforePhotoUrl!,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 56,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (report.beforePhotoUrl != null)
              Positioned(
                right: 14,
                bottom: 14,
                child: Material(
                  color: colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_full,
                          size: 16,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.reportViewPhoto,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroContent(Report report) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [_StatusBadge(status: report.status)]),
        const SizedBox(height: 20),
        Text(
          report.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              icon: reportCategoryIcon(report.category),
              label: report.category.localizedLabel(context),
            ),
            _InfoChip(
              icon: Icons.trending_up,
              label: context.l10n.priorityValue(report.priorityScore),
            ),
            _InfoChip(
              icon: Icons.thumb_up_alt_outlined,
              label: context.l10n.confirmationCount(report.upvoteCount),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentStatusSection(Report report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SectionSurface(
      title: context.l10n.reportCurrentStatusTitle,
      subtitle: context.l10n.reportCurrentStatusDescription,
      child: Builder(
        builder: (context) {
          final staff = report.assignedStaff;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusProgress(status: report.status),
              const SizedBox(height: 20),
              Divider(color: colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      staff == null
                          ? Icons.person_search_outlined
                          : Icons.person_outline,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: staff == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.reportStaffAssignment,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.reportStaffUnassigned,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.taskAssignedStaff,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 3),
                              TextButton.icon(
                                key: const Key('assignedStaffProfileButton'),
                                onPressed: () =>
                                    Navigator.of(context).pushNamed(
                                      AppRoutes.staffPublicProfile,
                                      arguments: staff.id,
                                    ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                iconAlignment: IconAlignment.end,
                                icon: const Icon(Icons.chevron_right, size: 18),
                                label: Text(
                                  staff.fullName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                _localizedRole(staff.role),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDescriptionSection(Report report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _SectionSurface(
      title: context.l10n.commonDescription,
      subtitle: context.l10n.reportDescriptionSectionHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.description.isEmpty
                ? context.l10n.reportNoDescription
                : report.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                report.anonymous
                    ? Icons.visibility_off_outlined
                    : Icons.account_circle_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.anonymous
                      ? context.l10n.reportSubmittedAnonymously
                      : context.l10n.reportSubmittedPublicly,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(Report report) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final reportLatLng = LatLng(report.latitude, report.longitude);

    return _SectionSurface(
      title: context.l10n.commonLocation,
      subtitle: context.l10n.reportLocationSectionHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: reportLatLng,
                initialZoom: 16.0,
                onTap: (_, point) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.mapSelectedLocationCoordinates(
                            point.latitude.toStringAsFixed(6),
                            point.longitude.toStringAsFixed(6),
                          ),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.smartcity.report',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: reportLatLng,
                      width: 48,
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.place_outlined,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.addressText ??
                          context.l10n.commonAddressUnavailable,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.latitude.toStringAsFixed(4)}, '
                      '${report.longitude.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportMetaSection(Report report) {
    return _SectionSurface(
      title: context.l10n.reportOverviewTitle,
      subtitle: context.l10n.reportOverviewDescription,
      child: Column(
        children: [
          _MetaRow(
            icon: reportCategoryIcon(report.category),
            label: context.l10n.commonCategory,
            value: report.category.localizedLabel(context),
          ),
          const SizedBox(height: 14),
          _MetaRow(
            icon: Icons.trending_up,
            label: context.l10n.commonPriorityScore,
            value: '${report.priorityScore}',
          ),
          const SizedBox(height: 14),
          _MetaRow(
            icon: Icons.thumb_up_alt_outlined,
            label: context.l10n.commonConfirmations,
            value: '${report.upvoteCount}',
          ),
        ],
      ),
    );
  }

  String _localizedRole(String role) {
    switch (role.trim().toUpperCase()) {
      case 'CITIZEN':
        return context.l10n.roleCitizen;
      case 'STAFF':
        return context.l10n.roleStaff;
      case 'OVERSEER':
        return context.l10n.roleOverseer;
      default:
        return role;
    }
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.status});

  final ReportStatus status;

  int get _currentStep {
    switch (status) {
      case ReportStatus.submitted:
        return 0;
      case ReportStatus.inProgress:
        return 1;
      case ReportStatus.fixed:
        return 2;
      case ReportStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final steps = [
      (context.l10n.reportStatusSubmitted, Icons.inbox_outlined),
      (context.l10n.reportStatusInProgress, Icons.build_outlined),
      (context.l10n.reportStatusFixed, Icons.check_circle_outline),
    ];

    Color connectorColor(bool active) =>
        active ? colorScheme.primary : colorScheme.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final active =
            status != ReportStatus.cancelled && index <= _currentStep;
        final hasLeftConnector = index > 0;
        final hasRightConnector = index < steps.length - 1;
        final leftConnectorActive =
            status != ReportStatus.cancelled && index <= _currentStep;
        final rightConnectorActive =
            status != ReportStatus.cancelled && index < _currentStep;

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(right: 8),
                      color: hasLeftConnector
                          ? connectorColor(leftConnectorActive)
                          : Colors.transparent,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: active
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      steps[index].$2,
                      size: 19,
                      color: active
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(left: 8),
                      color: hasRightConnector
                          ? connectorColor(rightConnectorActive)
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                steps[index].$1,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;

    switch (status) {
      case ReportStatus.submitted:
        backgroundColor = const Color(0xFFDEE8FF);
        foregroundColor = const Color(0xFF005C55);
        break;
      case ReportStatus.inProgress:
        backgroundColor = const Color(0xFFFFE4C7);
        foregroundColor = const Color(0xFF8A4B00);
        break;
      case ReportStatus.fixed:
        backgroundColor = const Color(0xFFCCFBF1);
        foregroundColor = const Color(0xFF115E59);
        break;
      case ReportStatus.cancelled:
        backgroundColor = const Color(0xFFFFDAD6);
        foregroundColor = const Color(0xFFBA1A1A);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      child: Text(
        status.localizedLabel(context),
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
                const SizedBox(height: 18),
                Text(
                  context.l10n.reportLoadingTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.reportLoadingMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
  const _ErrorState({required this.message, required this.onSecondary});

  final String message;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.18),
              ),
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
                    color: colorScheme.onErrorContainer,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.reportLoadFailed,
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
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onSecondary,
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
