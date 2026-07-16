import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/ui/app_feedback.dart';
import '../../auth/data/auth_api_service.dart';
import '../../auth/domain/current_user.dart';
import '../../tasks/data/task_api_service.dart';
import '../../tasks/domain/task.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';
import 'report_category_visuals.dart';

class CitizenReportDetailScreen extends StatefulWidget {
  const CitizenReportDetailScreen({
    super.key,
    required this.reportApiService,
    required this.authApiService,
    required this.taskApiService,
  });

  final ReportApiService reportApiService;
  final AuthApiService authApiService;
  final TaskApiService taskApiService;

  @override
  State<CitizenReportDetailScreen> createState() =>
      _CitizenReportDetailScreenState();
}

class _CitizenReportDetailScreenState extends State<CitizenReportDetailScreen> {
  late Future<Report> _reportFuture;
  CurrentUser? _currentUser;
  late Future<Task?> _assignedTaskFuture;

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
    _assignedTaskFuture = _loadAssignedTask();
  }

  Future<Task?> _loadAssignedTask() async {
    try {
      final tasks = await widget.taskApiService.fetchTasks();
      for (final task in tasks) {
        if (task.reportIds.contains(_reportId)) {
          return task;
        }
      }
    } catch (_) {
      // The report remains usable even if task data is temporarily unavailable.
    }
    return null;
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await widget.authApiService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (_) {}
  }

  Future<void> _openFullPhoto(String url) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => UploadedPhotoView(fileUrl: url)),
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
          'Report details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          tooltip: 'Back',
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
              message: 'We could not load this report right now.',
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
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
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
                  color: colorScheme.surface.withOpacity(0.92),
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
                          'View photo',
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
              label: 'Priority ${report.priorityScore}',
            ),
            _InfoChip(
              icon: Icons.thumb_up_alt_outlined,
              label: '${report.upvoteCount} confirmations',
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
      title: 'Current status',
      subtitle: 'Track how this report is being handled.',
      child: FutureBuilder<Task?>(
        future: _assignedTaskFuture,
        builder: (context, snapshot) {
          final task = snapshot.data;
          final staff = task?.assignedStaff;

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
                                'Staff assignment',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'A staff member has not been assigned yet.',
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
                                'Assigned staff',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                staff.fullName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                staff.role,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                  if (task != null)
                    Chip(
                      avatar: const Icon(Icons.assignment_outlined, size: 16),
                      label: Text(task.status.label),
                      visualDensity: VisualDensity.compact,
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
      title: 'Description',
      subtitle: 'Details provided with the original report.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            report.description.isEmpty
                ? 'No additional description was provided.'
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
                      ? 'Submitted anonymously'
                      : 'Submitted from a public profile',
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
      title: 'Location',
      subtitle: 'The position attached to this report.',
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
                          'Selected location: '
                          '${point.latitude.toStringAsFixed(6)}, '
                          '${point.longitude.toStringAsFixed(6)}',
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
                              color: colorScheme.shadow.withOpacity(0.2),
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
                      report.addressText ?? 'Address not available',
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
      title: 'Report overview',
      subtitle: 'Quick reference information.',
      child: Column(
        children: [
          _MetaRow(
            icon: reportCategoryIcon(report.category),
            label: 'Category',
            value: report.category.localizedLabel(context),
          ),
          const SizedBox(height: 14),
          _MetaRow(
            icon: Icons.trending_up,
            label: 'Priority score',
            value: '${report.priorityScore}',
          ),
          const SizedBox(height: 14),
          _MetaRow(
            icon: Icons.thumb_up_alt_outlined,
            label: 'Confirmations',
            value: '${report.upvoteCount}',
          ),
        ],
      ),
    );
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
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.75)),
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
    final steps = const [
      ('Submitted', Icons.inbox_outlined),
      ('In progress', Icons.build_outlined),
      ('Resolved', Icons.check_circle_outline),
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final active =
            status != ReportStatus.cancelled && index <= _currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
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
                  const SizedBox(height: 6),
                  Text(
                    steps[index].$1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: active
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.fromLTRB(8, 0, 8, 22),
                    color: index < _currentStep
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
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
        status.label,
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
                  'Loading report',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please wait while the latest information is prepared.',
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
                    color: colorScheme.onErrorContainer,
                    size: 30,
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
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onSecondary,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
