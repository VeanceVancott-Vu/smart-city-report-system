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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text(
          'Report Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111C2D),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111C2D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<Report>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Unable to load report detailed insight specifications.',
              onSecondary: _loadReport,
            );
          }

          final report = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1100 : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // CỘT TRÁI WEB (60%): Ảnh, Bản đồ, Vị trí địa lý
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildPhotosSection(report),
                                    const SizedBox(height: 20),
                                    _buildLocationSection(report),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // CỘT PHẢI WEB (40%): Thông tin tổng quan, Trạng thái, Mô tả
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _buildOverviewCard(report),
                                    const SizedBox(height: 20),
                                    _buildCurrentStatusCard(report),
                                    const SizedBox(height: 20),
                                    _buildDescriptionCard(report),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            // BỐ CỤC MOBILE DI ĐỘNG: Các thẻ xếp dọc liền mạch
                            children: [
                              _buildOverviewCard(report),
                              const SizedBox(height: 16),
                              _buildCurrentStatusCard(report),
                              const SizedBox(height: 16),
                              _buildPhotosSection(report),
                              const SizedBox(height: 16),
                              _buildLocationSection(report),
                              const SizedBox(height: 16),
                              _buildDescriptionCard(report),
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

  Widget _buildCurrentStatusCard(Report report) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Task?>(
          future: _assignedTaskFuture,
          builder: (context, snapshot) {
            final task = snapshot.data;
            final staff = task?.assignedStaff;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111C2D),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatusBadge(status: report.status),
                    if (task != null) ...[
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Icon(Icons.assignment_outlined, size: 16),
                        label: Text(task.status.label),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      staff == null
                          ? Icons.person_off_outlined
                          : Icons.person_outline,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: staff == null
                          ? const Text(
                              'Not assigned to a staff member yet',
                              style: TextStyle(color: Color(0xFF64748B)),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Assigned staff',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  staff.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  staff.role,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
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
      ),
    );
  }

  // COMPONENT 1: THẺ TỔNG QUAN (MÃ SỰ CỐ, DANH MỤC, TRẠNG THÁI)
  Widget _buildOverviewCard(Report report) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    '#RPT-${report.id.substring(0, report.id.length > 8 ? 8 : report.id.length).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF425268),
                    ),
                  ),
                ),
                _StatusBadge(status: report.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111C2D),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.category_outlined,
                  label: report.category.label,
                ),
                _InfoChip(
                  icon: Icons.flash_on_outlined,
                  label: 'Priority: ${report.priorityScore}',
                ),
                _InfoChip(
                  icon: Icons.thumb_up_outlined,
                  label: '${report.upvoteCount} Confirmations',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // COMPONENT 2: KHU VỰC HÌNH ẢNH TRƯỚC VÀ SAU XỬ LÝ (BEFORE / AFTER CANVAS)
  Widget _buildPhotosSection(Report report) {
    // Report currently exposes only the before photo. The after-photo field
    // will be added when the backend workflow supports it.
    const String? afterPhotoUrl = null;
    final hasAfterPhoto = afterPhotoUrl != null;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visual Proof Evidence',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111C2D),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Khung ảnh trước xử lý (Before Photo)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BEFORE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: report.beforePhotoUrl != null
                            ? () => _openFullPhoto(report.beforePhotoUrl!)
                            : null,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9F8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: report.beforePhotoUrl != null
                              ? UploadedPhotoImage(
                                  fileUrl: report.beforePhotoUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Khung ảnh sau xử lý nếu có (After Photo)
                if (hasAfterPhoto) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AFTER RESOLVED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _openFullPhoto(afterPhotoUrl!),
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCCFBF1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF0F766E).withOpacity(0.3),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: UploadedPhotoImage(
                              fileUrl: afterPhotoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // COMPONENT 3: VỊ TRÍ CHI TIẾT KÈM MINI MAP WORKSPACE TỰ THÍCH ỨNG
  Widget _buildLocationSection(Report report) {
    final reportLatLng = LatLng(report.latitude, report.longitude);

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111C2D),
              ),
            ),
            const SizedBox(height: 14),
            // Bản đồ Mini tích hợp (Mini Map Canvas Box)
            Container(
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smartcity.report',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: reportLatLng,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFEF4444),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.addressText ??
                            'GPS Geocoded Workplace Address Position',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coordinates: ${report.latitude.toStringAsFixed(4)}° N, ${report.longitude.toStringAsFixed(4)}° E',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // COMPONENT 4: THỂ HIỆN NỘI DUNG MÔ TẢ PHẢN ÁNH CHI TIẾT
  Widget _buildDescriptionCard(Report report) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incident Description Context',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111C2D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              report.description.isEmpty
                  ? 'No supplementary detailed description texts provided.'
                  : report.description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF3E4947),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  report.anonymous
                      ? 'Submitted Anonymously (Ẩn danh)'
                      : 'Public Profile Transmission',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        backgroundColor = const Color(0xFFFFDAD6);
        foregroundColor = Colors.orange.shade900;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        status.label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSecondary,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Lookup'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFFBDC9C6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
