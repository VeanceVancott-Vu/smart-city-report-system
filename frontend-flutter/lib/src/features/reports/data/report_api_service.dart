import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/files/upload_content_type.dart';
import '../../../core/services/api_service.dart';
import '../../auth/data/token_storage.dart';
import '../domain/report.dart';

abstract class ReportApiService {
  Future<String> uploadBeforePhoto({
    required String filename,
    required List<int> bytes,
  });

  Future<List<Report>> fetchCitizenReports();

  Future<List<Report>> fetchReports();

  Future<Report> fetchReport(String id);

  Future<Report> createReport(ReportDraft draft);

  Future<Report> updateReport(String id, ReportDraft draft);

  Future<Report> cancelReport(String id);

  Future<List<ReportMapPin>> fetchMapPins({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    bool includeAllStatuses = false,
  });

  Future<ReportUpvoteSummary> upvoteReport(String id);

  Future<ReportUpvoteSummary> removeUpvote(String id);

  Future<Report> fixReport(String id);
}

class BackendReportApiService extends ApiService implements ReportApiService {
  BackendReportApiService({
    TokenStorage tokenStorage = const SecureTokenStorage(),
    http.Client? client,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  @override
  Future<String> uploadBeforePhoto({
    required String filename,
    required List<int> bytes,
  }) async {
    final response = await _uploadFile(
      path: '/api/files/report-before',
      filename: filename,
      bytes: bytes,
    );
    final body = _decodeMap(response.body);
    final fileUrl = body['fileUrl'];
    if (fileUrl is String && fileUrl.isNotEmpty) {
      return fileUrl;
    }
    throw const ReportApiException('Upload response did not include fileUrl.');
  }

  @override
  Future<List<Report>> fetchCitizenReports() async {
    return _fetchReports(queryParameters: <String, String>{'mine': 'true'});
  }

  @override
  Future<List<Report>> fetchReports() async {
    return _fetchReports();
  }

  Future<List<Report>> _fetchReports({
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.get(
      _uri('/api/reports', queryParameters),
      headers: await _headers(),
    );
    _ensureSuccess(response);

    final body = _decodeMap(response.body);
    final reports = body['reports'] as List<dynamic>? ?? const <dynamic>[];
    return reports
        .map((item) => Report.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Report> fetchReport(String id) async {
    final response = await _client.get(
      _uri('/api/reports/$id'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return Report.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Report> createReport(ReportDraft draft) async {
    final response = await _client.post(
      _uri('/api/reports'),
      headers: await _headers(),
      body: jsonEncode(draft.toCreateJson()),
    );
    _ensureSuccess(response);
    return Report.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Report> updateReport(String id, ReportDraft draft) async {
    final response = await _client.put(
      _uri('/api/reports/$id'),
      headers: await _headers(),
      body: jsonEncode(draft.toUpdateJson()),
    );
    _ensureSuccess(response);
    return Report.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Report> cancelReport(String id) async {
    final response = await _client.patch(
      _uri('/api/reports/$id/cancel'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return Report.fromJson(_decodeMap(response.body));
  }

  @override
  Future<List<ReportMapPin>> fetchMapPins({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    bool includeAllStatuses = false,
  }) async {
    final response = await _client.get(
      _uri('/api/reports/map', <String, String>{
        'minLat': minLat.toString(),
        'minLng': minLng.toString(),
        'maxLat': maxLat.toString(),
        'maxLng': maxLng.toString(),
      }),
      headers: await _headers(),
    );
    _ensureSuccess(response);

    final decoded = jsonDecode(response.body);
    if (decoded is! List<dynamic>) {
      throw const ReportApiException('Expected a JSON array response.');
    }

    final list = decoded.map(
      (item) => ReportMapPin.fromJson(item as Map<String, dynamic>),
    );

    if (includeAllStatuses) {
      return list.toList(growable: false);
    } else {
      return list.where((pin) => pin.status.canUpvote).toList(growable: false);
    }
  }

  @override
  Future<Report> fixReport(String id) async {
    final response = await _client.patch(
      _uri('/api/reports/$id/fix'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return Report.fromJson(_decodeMap(response.body));
  }

  @override
  Future<ReportUpvoteSummary> upvoteReport(String id) async {
    final response = await _client.post(
      _uri('/api/reports/$id/upvote'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return ReportUpvoteSummary.fromJson(_decodeMap(response.body));
  }

  @override
  Future<ReportUpvoteSummary> removeUpvote(String id) async {
    final response = await _client.delete(
      _uri('/api/reports/$id/upvote'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return ReportUpvoteSummary.fromJson(_decodeMap(response.body));
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse('$cleanBaseUrl$path');
    return queryParameters == null
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const ReportApiException('Please log in again.');
    }

    return <String, String>{
      'Accept': 'application/json',
      if (includeContentType) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _uploadFile({
    required String path,
    required String filename,
    required List<int> bytes,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(await _headers(includeContentType: false))
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          contentType: uploadContentTypeForFilename(filename),
        ),
      );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    _ensureSuccess(response);
    return response;
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw ReportApiException(_errorMessage(response));
  }

  Map<String, dynamic> _decodeMap(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ReportApiException('Expected a JSON object response.');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = _decodeMap(response.body);
      final errors = body['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        return errors.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
      }
      final message = body['message'] ?? body['error'] ?? body['detail'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    } on Object {
      // Fall through to the status-based message.
    }

    return 'Request failed with status ${response.statusCode}.';
  }
}

class MockReportApiService extends ApiService implements ReportApiService {
  MockReportApiService() : _reports = _seedReports();

  final List<Report> _reports;
  final Set<String> _upvotedReportIds = <String>{};

  @override
  Future<String> uploadBeforePhoto({
    required String filename,
    required List<int> bytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (bytes.isEmpty) {
      throw const ReportApiException('Selected image is empty.');
    }
    return '/uploads/report-before/$filename';
  }

  @override
  Future<List<Report>> fetchCitizenReports() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_reports);
  }

  @override
  Future<List<Report>> fetchReports() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_reports);
  }

  @override
  Future<Report> fetchReport(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _findReport(id);
  }

  @override
  Future<Report> createReport(ReportDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final report = Report(
      id: _nextReportId(),
      title: draft.title,
      description: draft.description,
      category: draft.category,
      status: ReportStatus.submitted,
      latitude: draft.latitude,
      longitude: draft.longitude,
      addressText: draft.addressText,
      beforePhotoUrl: draft.beforePhotoUrl,
      anonymous: draft.anonymous,
      upvoteCount: 0,
      priorityScore: 0,
      createdAt: now,
      updatedAt: now,
      createdBy: _demoUser,
    );

    _reports.insert(0, report);
    return report;
  }

  @override
  Future<Report> updateReport(String id, ReportDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final index = _reports.indexWhere((report) => report.id == id);
    if (index == -1) {
      throw const ReportApiException('Report not found.');
    }

    final existing = _reports[index];
    final updated = existing.copyWith(
      title: draft.title,
      description: draft.description,
      category: draft.category,
      latitude: draft.latitude,
      longitude: draft.longitude,
      addressText: draft.addressText,
      beforePhotoUrl: draft.beforePhotoUrl,
      updatedAt: DateTime.now(),
    );
    _reports[index] = updated;
    return updated;
  }

  @override
  Future<Report> cancelReport(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final index = _reports.indexWhere((report) => report.id == id);
    if (index == -1) {
      throw const ReportApiException('Report not found.');
    }

    final removed = _reports.removeAt(index);
    return removed;
  }

  @override
  Future<List<ReportMapPin>> fetchMapPins({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    bool includeAllStatuses = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    return _reports
        .where(
          (report) =>
              (includeAllStatuses || report.status.canUpvote) &&
              report.latitude >= minLat &&
              report.latitude <= maxLat &&
              report.longitude >= minLng &&
              report.longitude <= maxLng,
        )
        .map(
          (report) => ReportMapPin(
            id: report.id,
            title: report.title,
            category: report.category,
            status: report.status,
            latitude: report.latitude,
            longitude: report.longitude,
            upvoteCount: report.upvoteCount,
            priorityScore: report.priorityScore,
            creatorId: report.createdBy?.id ?? '',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<Report> fixReport(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _reports.indexWhere((report) => report.id == id);
    if (index == -1) {
      throw const ReportApiException('Report not found.');
    }
    final existing = _reports[index];
    final updated = existing.copyWith(
      status: ReportStatus.fixed,
      updatedAt: DateTime.now(),
    );
    _reports[index] = updated;
    return updated;
  }

  @override
  Future<ReportUpvoteSummary> upvoteReport(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final report = _findReport(id);
    if (report.createdBy?.id == _demoUser.id) {
      throw const ReportApiException(
        'Creators cannot upvote their own reports',
      );
    }
    _upvotedReportIds.add(id);
    return _syncUpvote(id, hasUpvoted: true);
  }

  @override
  Future<ReportUpvoteSummary> removeUpvote(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _upvotedReportIds.remove(id);
    return _syncUpvote(id, hasUpvoted: false);
  }

  String _nextReportId() {
    var nextNumber = _reports.length + 1;
    while (_reports.any(
      (report) => report.id.endsWith(nextNumber.toString().padLeft(12, '0')),
    )) {
      nextNumber++;
    }
    return '11111111-1111-1111-1111-${nextNumber.toString().padLeft(12, '0')}';
  }

  Report _findReport(String id) {
    return _reports.firstWhere(
      (report) => report.id == id,
      orElse: () => throw const ReportApiException('Report not found.'),
    );
  }

  ReportUpvoteSummary _syncUpvote(String id, {required bool hasUpvoted}) {
    final index = _reports.indexWhere((report) => report.id == id);
    if (index == -1) {
      throw const ReportApiException('Report not found.');
    }

    final report = _reports[index];
    final nextCount = _upvotedReportIds.contains(id) ? 1 : 0;
    final updated = report.copyWith(
      upvoteCount: nextCount,
      priorityScore: nextCount,
      updatedAt: DateTime.now(),
    );
    _reports[index] = updated;
    return ReportUpvoteSummary(
      id: id,
      upvoteCount: updated.upvoteCount,
      priorityScore: updated.priorityScore,
      hasUpvoted: hasUpvoted,
    );
  }

  static List<Report> _seedReports() {
    return <Report>[
      Report(
        id: '11111111-1111-1111-1111-000000000004',
        title: 'Broken streetlight near Nguyen Hue',
        description: 'The light has been off for two nights.',
        category: ReportCategory.streetLight,
        status: ReportStatus.submitted,
        latitude: 10.7769,
        longitude: 106.7009,
        addressText: 'Nguyen Hue, District 1',
        beforePhotoUrl: '/uploads/report-before/streetlight-before.jpg',
        anonymous: false,
        upvoteCount: 3,
        priorityScore: 3,
        createdAt: DateTime(2026, 6, 7, 19, 20),
        updatedAt: DateTime(2026, 6, 7, 19, 20),
        createdBy: _demoUser,
      ),
      Report(
        id: '11111111-1111-1111-1111-000000000003',
        title: 'Pothole beside the bus stop',
        description: 'Cars swerve around it during rush hour.',
        category: ReportCategory.roadDamage,
        status: ReportStatus.fixed,
        latitude: 10.7827,
        longitude: 106.6994,
        addressText: 'Bus stop near Le Loi',
        beforePhotoUrl: '/uploads/report-before/pothole-before.jpg',
        anonymous: false,
        upvoteCount: 5,
        priorityScore: 5,
        createdAt: DateTime(2026, 6, 6, 8, 15),
        updatedAt: DateTime(2026, 6, 8, 14, 30),
        createdBy: _demoUser,
      ),
      Report(
        id: '11111111-1111-1111-1111-000000000005',
        title: 'Cracked curb near Le Loi crossing',
        description:
            'The curb edge is broken and difficult for wheelchairs to pass.',
        category: ReportCategory.roadDamage,
        status: ReportStatus.submitted,
        latitude: 10.7831,
        longitude: 106.6991,
        addressText: 'Le Loi pedestrian crossing',
        beforePhotoUrl: '/uploads/report-before/curb-before.jpg',
        anonymous: false,
        upvoteCount: 2,
        priorityScore: 2,
        createdAt: DateTime(2026, 6, 6, 9, 10),
        updatedAt: DateTime(2026, 6, 6, 9, 10),
        createdBy: _demoUser,
      ),
      Report(
        id: '11111111-1111-1111-1111-000000000002',
        title: 'Overflowing public bin',
        description: 'Waste is spilling onto the sidewalk.',
        category: ReportCategory.garbage,
        status: ReportStatus.cancelled,
        latitude: 10.7712,
        longitude: 106.7043,
        addressText: 'Corner of Ham Nghi',
        beforePhotoUrl: '/uploads/report-before/bin-before.jpg',
        anonymous: true,
        upvoteCount: 0,
        priorityScore: 0,
        createdAt: DateTime(2026, 6, 5, 16, 45),
        updatedAt: DateTime(2026, 6, 5, 18, 0),
        createdBy: _demoUser,
      ),
    ];
  }

  static const _demoUser = ReportUserSummary(
    id: '22222222-2222-2222-2222-222222222222',
    fullName: 'Test Citizen',
    role: 'CITIZEN',
  );
}

class ReportApiException implements Exception {
  const ReportApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
