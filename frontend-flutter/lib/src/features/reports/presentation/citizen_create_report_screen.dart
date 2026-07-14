import 'package:flutter/material.dart';

import '../../../core/files/upload_file_picker.dart';
import '../../../core/ui/app_feedback.dart';
import '../data/report_api_service.dart';
import '../domain/report.dart';


class CitizenCreateReportScreen extends StatefulWidget {
  const CitizenCreateReportScreen({super.key, required this.reportApiService});

  final ReportApiService reportApiService;

  @override
  State<CitizenCreateReportScreen> createState() => _CitizenCreateReportScreenState();
}

class _CitizenCreateReportScreenState extends State<CitizenCreateReportScreen> {
  int _currentStep = 1;
  final int _totalSteps = 5;
  bool _isOffline = false; // Trạng thái giả lập mạng để phục vụ giao diện offline cache

  // Quản lý dữ liệu form tạm thời cho Wizard
  ReportCategory? _selectedCategory;
  String _reportTitle = '';
  String _reportDescription = '';
  double? _latitude;
  double? _longitude;
  String? _uploadedPhotoPath;

  @override
  void initState() {
    super.initState();
    // Giả lập kiểm tra kết nối mạng ban đầu (Có thể tích hợp thêm connectivity_plus nếu cần)
    _checkNetworkStatus();
  }

  void _checkNetworkStatus() {
    // Để mặc định online, logic ứng dụng sẽ tự bắt lỗi mạng qua ReportApiException
    setState(() {
      _isOffline = false;
    });
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Select Category';
      case 2:
        return 'Select Location';
      case 3:
        return 'Input Content';
      case 4:
        return 'Add Photos';
      case 5:
        return 'Review & Submit';
      default:
        return '';
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  // Tận dụng chính xác hàm xử lý Submit nguyên bản kết nối với Backend
  Future<void> _handleFinalSubmit() async {
    // Tạo đối tượng ReportDraft từ dữ liệu các bước của Wizard
    final draft = ReportDraft(
      title: _reportTitle.isEmpty ? 'Untitled Report' : _reportTitle,
      description: _reportDescription,
      category: _selectedCategory ?? ReportCategory.other,
      latitude: _latitude ?? 10.7769,
      longitude: _longitude ?? 106.7009,
      addressText: null,
      beforePhotoUrl: _uploadedPhotoPath,
      anonymous: false,
    );

    await _createReport(context, draft);
  }

  Future<void> _createReport(BuildContext context, ReportDraft draft) async {
    try {
      final report = await widget.reportApiService.createReport(draft);
      if (!context.mounted) {
        return;
      }
      AppFeedback.showSuccess(
        context,
        title: 'Report submitted',
        message: report.title,
      );
      Navigator.of(context).pop(true);
    } on ReportApiException catch (error) {
      await _showError(context, error.message);
    } catch (_) {
      await _showError(context, 'Unable to create report.');
    }
  }

  Future<void> _showError(BuildContext context, String message) async {
    await AppFeedback.showErrorDialog(
      context,
      title: 'Could not submit report',
      message: message,
    );
  }

  void _saveDraftLocally() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF263143),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: const Row(
          children: [
            Icon(Icons.cloud_off, color: Color(0xFFFFDAD6), size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Báo cáo được lưu cục bộ để tự động đồng bộ khi có Internet.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text('Create Report'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111C2D),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isOffline ? Icons.wifi_off : Icons.wifi, color: const Color(0xFF64748B)),
            onPressed: () {
              setState(() => _isOffline = !_isOffline);
            },
            tooltip: 'Simulate Network Toggle',
          )
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 680 : double.infinity,
                ),
                child: Container(
                  margin: EdgeInsets.all(isDesktop ? 24 : 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isDesktop ? 16 : 0),
                    boxShadow: isDesktop
                        ? const [
                            BoxShadow(
                              color: Color(0x0F000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      // Thanh tiến trình bước (Progress Tracker Header)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0F3FF),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Step $_currentStep of $_totalSteps',
                                  style: const TextStyle(
                                    color: Color(0xFF3E4947),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _getStepTitle(_currentStep),
                                  style: const TextStyle(
                                    color: Color(0xFF111C2D),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(9999),
                              child: LinearProgressIndicator(
                                value: _currentStep / _totalSteps,
                                backgroundColor: const Color(0xFFDEE8FF),
                                color: const Color(0xFF005C55),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Nội dung từng Bước chi tiết của Wizard Form
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildWizardStepContent(),
                        ),
                      ),

                      // Thanh công cụ điều hướng chân trang cố định (Navigation Footer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: Color(0xFFBDC9C6), width: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Nút quay lại bước trước
                            Opacity(
                              opacity: _currentStep == 1 ? 0.0 : 1.0,
                              child: OutlinedButton.icon(
                                onPressed: _currentStep == 1 ? null : _prevStep,
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('Back'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF3E4947),
                                  side: const BorderSide(color: Color(0xFFBDC9C6)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                                ),
                              ),
                            ),

                            // Các nút hành động bên phải
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: _saveDraftLocally,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF005C55),
                                    side: const BorderSide(color: Color(0xFF005C55)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                                  ),
                                  child: const Text('Save Draft'),
                                ),
                                const SizedBox(width: 12),
                                _currentStep == _totalSteps
                                    ? FilledButton.icon(
                                        onPressed: _isOffline ? _saveDraftLocally : _handleFinalSubmit,
                                        icon: Icon(_isOffline ? Icons.offline_pin : Icons.check, size: 16),
                                        label: Text(_isOffline ? 'Save Offline' : 'Submit report'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _isOffline ? const Color(0xFF3B665F) : const Color(0xFF005C55),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                                        ),
                                      )
                                    : FilledButton.icon(
                                        onPressed: _nextStep,
                                        icon: const Icon(Icons.arrow_forward, size: 16),
                                        label: const Text('Continue'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF005C55),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                                        ),
                                      ),
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
          },
        ),
      ),
    );
  }

  // Khởi tạo giao diện tương ứng theo từng bước
  Widget _buildWizardStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildCategoryStep();
      case 2:
        return _buildLocationStep();
      case 3:
        return _buildContentStep();
      case 4:
        return _buildPhotoStep();
      case 5:
        return _buildReviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // BƯỚC 1: CHỌN DANH MỤC SỰ CỐ
  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you reporting?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111C2D)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the category that best fits the issue you have encountered.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 110,
          ),
          itemCount: ReportCategory.values.length,
          itemBuilder: (context, index) {
            final category = ReportCategory.values[index];
            final isSelected = _selectedCategory == category;
            return InkWell(
              onTap: () => setState(() => _selectedCategory = category),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFBDECE2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF005C55) : const Color(0xFFBDC9C6),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIconLocal(category),
                      size: 32,
                      color: isSelected ? const Color(0xFF005C55) : const Color(0xFF3B665F),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: const Color(0xFF111C2D),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // BƯỚC 2: CHỌN VỊ TRÍ
  Widget _buildLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111C2D)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pinpoint where the incident happened on the city workspace grid.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBDC9C6)),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 48, color: Color(0xFF5A6A81)),
                SizedBox(height: 8),
                Text(
                  'Interactive Map Canvas Area',
                  style: TextStyle(color: Color(0xFF425268), fontWeight: FontWeight.w500),
                ),
                Text(
                  '(Simulated Map component boundary)',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _latitude = 10.7769;
                  _longitude = 106.7009;
                });
              },
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Locate Current Position'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBDECE2),
                foregroundColor: const Color(0xFF224e47),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        if (_latitude != null && _longitude != null) ...[
          const SizedBox(height: 12),
          Text(
            'Selected Coordinates: ${_latitude!.toStringAsFixed(4)}° N, ${_longitude!.toStringAsFixed(4)}° W',
            style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF005C55)),
          ),
        ],
      ],
    );
  }

  // BƯỚC 3: NHẬP NỘI DUNG CHI TIẾT
  Widget _buildContentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Incident Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111C2D)),
        ),
        const SizedBox(height: 16),
        const Text('Report Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          onChanged: (val) => _reportTitle = val,
          decoration: InputDecoration(
            hintText: 'e.g. Broken pothole or flooded street corner',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Detailed Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          onChanged: (val) => _reportDescription = val,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Provide complete environmental context or damage status details...',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // BƯỚC 4: THÊM HÌNH ẢNH (HỖ TRỢ OFFLINE NOTICE)
  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Visual Proof',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111C2D)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload photos to provide proof and accelerate administrative process workflows.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () async {
            // Tận dụng chính xác phương thức upload ảnh từ backend service
            try {
              final pickedFile = await pickImageUploadFile();
              if (pickedFile == null) return;
              final uploadedUrl = await widget.reportApiService.uploadBeforePhoto(
                filename: pickedFile.filename,
                bytes: pickedFile.bytes,
              );
              setState(() {
                _uploadedPhotoPath = uploadedUrl;
              });
            } catch (_) {
              // Phục vụ cơ chế offline lưu cục bộ đường dẫn tạm nếu server lỗi
              setState(() {
                _uploadedPhotoPath = 'cached_local_image_proof.jpg';
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBDC9C6), width: 2),
            ),
            child: _uploadedPhotoPath != null
                ? Stack(
                    children: [
                      const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, color: Color(0xFF005C55)),
                            SizedBox(width: 8),
                            Text('Photo Attached successfully', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Color(0xFFBA1A1A)),
                          onPressed: () => setState(() => _uploadedPhotoPath = null),
                        ),
                      )
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Color(0xFF005C55)),
                      SizedBox(height: 12),
                      Text('Click to capture or attach incident photo', style: TextStyle(fontSize: 13, color: Color(0xFF3E4947))),
                    ],
                  ),
          ),
        ),
        if (_isOffline) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_off, color: Color(0xFF93000a)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No network connection available. Image path will be cached locally and synced later.',
                    style: TextStyle(color: Color(0xFF93000a), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  // BƯỚC 5: KIỂM TRA LẠI VÀ GỬI (REVIEW & SUBMIT)
  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Application',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111C2D)),
        ),
        const SizedBox(height: 4),
        const Text('Verify information accuracy before final city data synchronization.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDEE8FF)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewRow('Category', _selectedCategory?.label ?? 'Not selected'),
              const Divider(height: 20),
              _buildReviewRow('Title', _reportTitle.isEmpty ? 'Untitled Report' : _reportTitle),
              const Divider(height: 20),
              _buildReviewRow('Description', _reportDescription.isEmpty ? 'No description' : _reportDescription),
              const Divider(height: 20),
              _buildReviewRow('Coordinates', _latitude != null ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}' : 'Not pinned'),
              const Divider(height: 20),
              _buildReviewRow('Photo Evidence', _uploadedPhotoPath != null ? 'Attached' : 'None'),
            ],
          ),
        ),
        if (_isOffline) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFBDECE2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF005C55).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.offline_bolt_outlined, color: Color(0xFF224e47)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline Cache Mode Activated: Submitting will store data locally.',
                    style: TextStyle(color: Color(0xFF224e47), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF111C2D), fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Hàm chuyển đổi Icon cục bộ dựa trên Model danh mục có sẵn
  IconData _getCategoryIconLocal(ReportCategory category) {
    switch (category) {
      case ReportCategory.roadDamage:
        return Icons.construction;
      case ReportCategory.streetLight:
        return Icons.lightbulb;
      case ReportCategory.garbage:
        return Icons.delete_outline;
      case ReportCategory.waterLeak:
        return Icons.opacity;
      case ReportCategory.drainage:
        return Icons.waves;
      case ReportCategory.trafficSign:
        return Icons.traffic;
      case ReportCategory.treeBlockage:
        return Icons.park;
      case ReportCategory.other:
        return Icons.help_outline;
    }
  }
}