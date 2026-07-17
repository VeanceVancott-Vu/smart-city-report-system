import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';
import 'overseer_report_dashboard_screen.dart';

class OverseerReportDetailScreen extends StatefulWidget {
  const OverseerReportDetailScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<OverseerReportDetailScreen> createState() =>
      _OverseerReportDetailScreenState();
}

class _OverseerReportDetailScreenState
    extends State<OverseerReportDetailScreen> {
  late Future<Report> _reportFuture;
  bool _showMap = false;

  String get _reportId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadReport();
  }

  void _loadReport() {
    _reportFuture = widget.reportApiService.fetchReport(_reportId);
  }

  Future<void> _refresh() async {
    setState(_loadReport);
    await _reportFuture;
  }

  Future<void> _createTask(Report report) async {
    if (report.status != ReportStatus.submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.reportSubmittedOnlyTaskable)),
      );
      return;
    }

    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.overseerCreateTask,
      arguments: OverseerTaskFormArgs(reportIds: <String>[report.id]),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(context.l10n.reportDetailsTitle),
        actions: [
          FutureBuilder<Report>(
            future: _reportFuture,
            builder: (context, snapshot) {
              final report = snapshot.data;
              final canCreateTask = report?.status == ReportStatus.submitted;
              return IconButton(
                tooltip: context.l10n.taskCreate,
                onPressed: canCreateTask ? () => _createTask(report!) : null,
                icon: const Icon(Icons.add_task_outlined),
              );
            },
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
            final canCreateTask = report.status == ReportStatus.submitted;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 920;
                  final summary = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: const Color(0xFF123B38), borderRadius: BorderRadius.circular(24)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.report_gmailerrorred_outlined, color: Colors.white)), const Spacer(), _InfoChip(icon: Icons.flag_outlined, label: report.status.localizedLabel(context))]),
                        const SizedBox(height: 18),
                        Text(report.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.25)),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: [_InfoChip(icon: Icons.category_outlined, label: report.category.localizedLabel(context)), _InfoChip(icon: Icons.trending_up, label: context.l10n.priorityValue(report.priorityScore))]),
                      ]),
                    ),
                    _Section(title: context.l10n.commonDescription, icon: Icons.notes_outlined, child: Text(report.description)),
                    _Section(
                      title: context.l10n.commonLocation,
                      icon: Icons.map_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showMap = true;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.l10n.coordinatesValue(
                                      report.latitude.toStringAsFixed(6),
                                      report.longitude.toStringAsFixed(6),
                                    ),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if ((report.addressText ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(report.addressText!),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _Section(title: context.l10n.commonBeforePhoto, icon: Icons.photo_outlined, child: UploadedPhotoView(fileUrl: report.beforePhotoUrl)),
                  ]);
                  final side = Column(children: [
                    _Section(title: context.l10n.reportCreatedBy, icon: Icons.person_outline, child: Text(report.createdBy?.fullName ?? context.l10n.commonUnknownUser)),
                    const SizedBox(height: 14),
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: canCreateTask ? () => _createTask(report) : null, icon: const Icon(Icons.add_task_outlined), label: Text(context.l10n.taskCreateFromReport), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
                    if (_showMap) ...[
                      const SizedBox(height: 16),
                      _MapSection(
                        latitude: report.latitude,
                        longitude: report.longitude,
                        onClose: () {
                          setState(() {
                            _showMap = false;
                          });
                        },
                      ),
                    ],
                  ]);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
                    children: [Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1180), child: wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: _showMap ? 6 : 7, child: summary), const SizedBox(width: 18), Expanded(flex: _showMap ? 4 : 3, child: side)]) : Column(children: [summary, const SizedBox(height: 16), side])) )],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, required this.icon});

  final String title;
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFDCE6E3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFE8F3F1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: const Color(0xFF0F766E))), const SizedBox(width: 10), Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))]), const SizedBox(height: 14), child]),
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
      side: const BorderSide(color: Color(0xFFDCE5E3)),
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

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.latitude,
    required this.longitude,
    required this.onClose,
  });

  final double latitude;
  final double longitude;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reportLatLng = LatLng(latitude, longitude);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCE6E3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    size: 18,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.commonLocation,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close map',
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          Container(
            height: 420,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(19),
                bottomRight: Radius.circular(19),
              ),
            ),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: reportLatLng,
                initialZoom: 15.0,
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
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.shadow.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
