import 'package:flutter/material.dart';

import '../../../core/files/uploaded_photo_view.dart';
import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/domain/report.dart';

class OverseerReportDashboardScreen extends StatefulWidget {
  const OverseerReportDashboardScreen({
    super.key,
    required this.reportApiService,
  });

  final ReportApiService reportApiService;

  @override
  State<OverseerReportDashboardScreen> createState() =>
      OverseerReportDashboardScreenState();
}

class OverseerReportDashboardScreenState
    extends State<OverseerReportDashboardScreen> {
  final Set<String> _selectedReportIds = <String>{};
  late Future<List<Report>> _reportsFuture;
  late final ScrollController _scrollController;
  bool _showHeader = true;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    refresh();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final currentOffset = _scrollController.offset;
    if (currentOffset <= 0) {
      if (!_showHeader) {
        setState(() => _showHeader = true);
      }
    } else if (currentOffset > _lastOffset && currentOffset > 10) {
      if (_showHeader) {
        setState(() => _showHeader = false);
      }
    }
    _lastOffset = currentOffset;
  }

  void refresh() {
    _reportsFuture = widget.reportApiService.fetchReports();
  }

  Future<void> reload() async {
    setState(refresh);
    await _reportsFuture;
  }

  Future<void> _openReport(String reportId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.overseerReportDetail, arguments: reportId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  Future<void> _createTaskFromSelection() async {
    final changed = await Navigator.of(context).pushNamed(
      AppRoutes.overseerCreateTask,
      arguments: OverseerTaskFormArgs(reportIds: _selectedReportIds.toList()),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      _selectedReportIds.clear();
      setState(refresh);
    }
  }

  void _toggleSelection(String reportId, bool selected) {
    setState(() {
      if (selected) {
        _selectedReportIds.add(reportId);
      } else {
        _selectedReportIds.remove(reportId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF4F7F6),
      child: FutureBuilder<List<Report>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          final reports = snapshot.data ?? const <Report>[];
          return Column(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                heightFactor: _showHeader ? 1.0 : 0.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showHeader ? 1.0 : 0.0,
                  child: ClipRect(
                    child: _DashboardHeader(
                      totalReports: reports.length,
                      selectedCount: _selectedReportIds.length,
                      onCreateTask: _selectedReportIds.isEmpty
                          ? null
                          : _createTaskFromSelection,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const _DashboardLoading();
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: context.l10n.reportsLoadFailed,
                        onRetry: reload,
                      );
                    }
                    if (reports.isEmpty) {
                      return _EmptyState(
                        icon: Icons.inbox_outlined,
                        title: context.l10n.reportsEmpty,
                        onRefresh: reload,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: reload,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1180
                              ? 3
                              : constraints.maxWidth >= 760
                                  ? 2
                                  : 1;
                          return GridView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 112),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: columns == 1 ? 1.35 : (columns == 2 ? 1.0 : 0.85),
                            ),
                            itemCount: reports.length,
                            itemBuilder: (context, index) {
                              final report = reports[index];
                              return _ReportTile(
                                report: report,
                                selected: _selectedReportIds.contains(report.id),
                                onSelected: (selected) =>
                                    _toggleSelection(report.id, selected),
                                onOpen: () => _openReport(report.id),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.totalReports,
    required this.selectedCount,
    required this.onCreateTask,
  });

  final int totalReports;
  final int selectedCount;
  final VoidCallback? onCreateTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF123B38),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A123B38), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeaderMetric(icon: Icons.assignment_outlined, value: '$totalReports', label: context.l10n.reportCount(totalReports)),
              _HeaderMetric(icon: Icons.checklist_rounded, value: '$selectedCount', label: context.l10n.selectedReportCount(selectedCount)),
            ],
          );
          final action = FilledButton.icon(
            onPressed: onCreateTask,
            icon: const Icon(Icons.add_task_outlined),
            label: Text(context.l10n.taskCreate),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF123B38),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          );
          if (constraints.maxWidth < 720) {
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Report Operations', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16), metrics, const SizedBox(height: 18), SizedBox(width: double.infinity, child: action),
            ]);
          }
          return Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Report Operations', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16), metrics,
            ])),
            const SizedBox(width: 20), action,
          ]);
        },
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.icon, required this.value, required this.label});
  final IconData icon; final String value; final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: .12))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: const Color(0xFF9DE2D8), size: 20), const SizedBox(width: 10), Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(width: 8), Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFD8E8E6))))]),
  );
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.selected, required this.onSelected, required this.onOpen});
  final Report report; final bool selected; final ValueChanged<bool> onSelected; final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final hasPhoto = report.beforePhotoUrl != null && report.beforePhotoUrl!.isNotEmpty;

    return Material(
      color: selected ? const Color(0xFFE7F4F1) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFDCE6E3), width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE8F3F1), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.location_city_outlined, color: Color(0xFF0F766E))),
                const Spacer(), Checkbox(value: selected, onChanged: (v) => onSelected(v ?? false)),
              ]),
              const SizedBox(height: 14),
              Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.25)),
              const SizedBox(height: 6),
              Text(report.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF60706D), height: 1.45)),
              if (hasPhoto) ...[
                const SizedBox(height: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: UploadedPhotoImage(
                        fileUrl: report.beforePhotoUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: _MetaChip(icon: Icons.category_outlined, label: report.category.localizedLabel(context))), const SizedBox(width: 8), _StatusChip(label: report.status.localizedLabel(context))]),
              const SizedBox(height: 10),
              Row(children: [Expanded(child: _MetaChip(icon: Icons.trending_up, label: context.l10n.priorityValue(report.priorityScore))), const SizedBox(width: 8), Expanded(child: _MetaChip(icon: Icons.thumb_up_alt_outlined, label: context.l10n.upvoteCount(report.upvoteCount)))]),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();
  @override
  Widget build(BuildContext context) => ListView.builder(padding: const EdgeInsets.all(20), itemCount: 5, itemBuilder: (_, __) => Container(height: 150, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22))));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.onRefresh});
  final IconData icon; final String title; final Future<void> Function() onRefresh;
  @override
  Widget build(BuildContext context) => RefreshIndicator(onRefresh: onRefresh, child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [const SizedBox(height: 120), Icon(icon, size: 56, color: const Color(0xFF8BA19D)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))]));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFE7F3F1),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

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

class OverseerTaskFormArgs {
  const OverseerTaskFormArgs({this.taskId, this.reportIds = const <String>[]});

  final String? taskId;
  final List<String> reportIds;
}
