import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/domain_localizations.dart';
import '../../../core/routing/app_routes.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';

class CitizenReportListScreen extends StatefulWidget {
  const CitizenReportListScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CitizenReportListScreen> createState() =>
      CitizenReportListScreenState();
}

class CitizenReportListScreenState extends State<CitizenReportListScreen> {
  late Future<List<Report>> _reportsFuture;
  final TextEditingController _searchController = TextEditingController();

  ReportStatus? _selectedStatus;
  String _searchQuery = '';
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void refresh() {
    _reportsFuture = widget.reportApiService.fetchCitizenReports();
  }

  Future<void> reload() async {
    setState(refresh);
    await _reportsFuture;
  }

  Future<void> openCreateReport() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenCreateReport);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  Future<void> _openDetails(String reportId) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AppRoutes.citizenReportDetail, arguments: reportId);
    if (!mounted) {
      return;
    }
    if (changed == true) {
      setState(refresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text(
          'My Reports',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111C2D)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0F766E)),
            onPressed: reload,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateReport,
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;

          return Column(
            children: [
              // PANEL ĐIỀU KHIỂN: TÌM KIẾM & BỘ SẮP XẾP SỰ CỐ
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search my reports...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      initialValue: _sortBy,
                      onSelected: (String item) {
                        setState(() {
                          _sortBy = item;
                        });
                      },
                      icon: const Icon(Icons.sort_rounded, color: Color(0xFF0F766E)),
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(value: 'Newest', child: Text('Sort by: Newest')),
                        const PopupMenuItem<String>(value: 'Oldest', child: Text('Sort by: Oldest')),
                        const PopupMenuItem<String>(value: 'Priority', child: Text('Sort by: Priority')),
                      ],
                    ),
                  ],
                ),
              ),

              // DẢI FILTER NGANG: LỌC DANH SÁCH THEO REPORT STATUS CHUẨN MATERIAL 3
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedStatus == null,
                        onSelected: (_) => setState(() => _selectedStatus = null),
                        selectedColor: const Color(0xFFCCFBF1),
                        checkmarkColor: const Color(0xFF115E59),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                      const SizedBox(width: 8),
                      ...ReportStatus.values.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.label),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedStatus = status),
                            selectedColor: const Color(0xFFCCFBF1),
                            checkmarkColor: const Color(0xFF115E59),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // THÂN TRANG GIAO DIỆN CHỨA FUTUREBUILDER VÀ LIST/GRID TỰ THÍCH ỨNG RESPONSIVE
              Expanded(
                child: FutureBuilder<List<Report>>(
                  future: _reportsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                      );
                    }

                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: 'Unable to load your citizen reports list.',
                        onRetry: reload,
                      );
                    }

                    final reports = snapshot.data ?? const <Report>[];

                    // Xử lý bộ lọc tại chỗ (Local Client Filtering)
                    final filteredReports = reports.where((r) {
                      final matchesStatus = _selectedStatus == null || r.status == _selectedStatus;
                      final matchesQuery = r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          r.category.label.toLowerCase().contains(_searchQuery.toLowerCase());
                      return matchesStatus && matchesQuery;
                    }).toList();

                    // Xử lý sắp xếp dữ liệu tại chỗ (Local Client Sorting)
                    if (_sortBy == 'Newest') {
                      filteredReports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    } else if (_sortBy == 'Oldest') {
                      filteredReports.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    } else if (_sortBy == 'Priority') {
                      filteredReports.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
                    }

                    if (filteredReports.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: reload,
                        color: const Color(0xFF0F766E),
                        child: ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No reports matching your constraints.',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Điều hướng giao diện thích ứng: Web dùng Grid, Mobile dùng ListView Dọc
                    return RefreshIndicator(
                      onRefresh: reload,
                      color: const Color(0xFF0F766E),
                      child: isDesktop
                          ? GridView.builder(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 180,
                              ),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) => _ReportTile(
                                report: filteredReports[index],
                                onTap: () => _openDetails(filteredReports[index].id),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                              itemCount: filteredReports.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) => _ReportTile(
                                report: filteredReports[index],
                                onTap: () => _openDetails(filteredReports[index].id),
                              ),
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

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.onTap});

  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Khung hiển thị ảnh thu nhỏ (Thumbnail Box)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: report.beforePhotoUrl != null
                    ? Image.network(
                        report.beforePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image_outlined,
                          size: 28,
                          color: Color(0xFF64748B),
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        size: 28,
                        color: Color(0xFF64748B),
                      ),
              ),
              const SizedBox(width: 14),

              // Cụm thông tin chi tiết phản ánh đô thị bên phải
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF111C2D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: #${report.id.substring(0, report.id.length > 8 ? 8 : report.id.length).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.addressText ?? 'GPS Coordinates Point Location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // Footer chứa điểm ưu tiên và số người xác nhận sự cố
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _MetaChip(icon: Icons.flash_on, label: 'Priority ${report.priorityScore}'),
                        _MetaChip(icon: Icons.thumb_up_outlined, label: '${report.upvoteCount} upvotes'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        status.label,
        style: TextStyle(color: foregroundColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBDC9C6).withOpacity(0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF3E4947)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF3E4947)),
          ),
        ],
      ),
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
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
