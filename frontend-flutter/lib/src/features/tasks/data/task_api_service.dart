import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/files/upload_content_type.dart';
import '../../../core/services/api_service.dart';
import '../../auth/data/token_storage.dart';
import '../../reports/domain/report.dart';
import '../domain/staff_task.dart';
import '../domain/task.dart';

abstract class TaskApiService {
  Future<String> uploadAfterPhoto({
    required String filename,
    required List<int> bytes,
  });

  Future<List<StaffTask>> fetchStaffTasks();

  Future<List<Task>> fetchTasks();

  Future<Task> fetchTask(String id);

  Future<Task> createTask(TaskDraft draft);

  Future<Task> updateTask(String id, TaskDraft draft);

  Future<Task> assignTask({required String id, required String staffId});

  Future<Task> startTask(String id);

  Future<Task> completeTask(String id, TaskCompletionDraft draft);

  Future<Task> approveTask(String id);

  Future<Task> closeTask(String id);

  Future<Task> cancelTask(String id);

  Future<void> deleteTask(String id);
}

class BackendTaskApiService extends ApiService implements TaskApiService {
  BackendTaskApiService({
    TokenStorage tokenStorage = const SecureTokenStorage(),
    http.Client? client,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  @override
  Future<String> uploadAfterPhoto({
    required String filename,
    required List<int> bytes,
  }) async {
    final response = await _uploadFile(
      path: '/api/files/task-after',
      filename: filename,
      bytes: bytes,
    );
    final body = _decodeMap(response.body);
    final fileUrl = body['fileUrl'];
    if (fileUrl is String && fileUrl.isNotEmpty) {
      return fileUrl;
    }
    throw const TaskApiException('Upload response did not include fileUrl.');
  }

  @override
  Future<List<StaffTask>> fetchStaffTasks() async {
    final tasks = await _fetchTaskList('/api/tasks?assignedToMe=true');
    return tasks.map(StaffTask.fromTask).toList(growable: false);
  }

  @override
  Future<List<Task>> fetchTasks() async {
    return _fetchTaskList('/api/tasks');
  }

  Future<List<Task>> _fetchTaskList(String path) async {
    final response = await _client.get(_uri(path), headers: await _headers());
    _ensureSuccess(response);

    final body = _decodeMap(response.body);
    final tasks = body['tasks'] as List<dynamic>? ?? const <dynamic>[];
    return tasks
        .map((item) => Task.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Task> fetchTask(String id) async {
    final response = await _client.get(
      _uri('/api/tasks/$id'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return Task.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Task> createTask(TaskDraft draft) async {
    final response = await _client.post(
      _uri('/api/tasks'),
      headers: await _headers(),
      body: jsonEncode(draft.toCreateJson()),
    );
    _ensureSuccess(response);
    return Task.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Task> updateTask(String id, TaskDraft draft) async {
    final response = await _client.put(
      _uri('/api/tasks/$id'),
      headers: await _headers(),
      body: jsonEncode(draft.toUpdateJson()),
    );
    _ensureSuccess(response);
    return Task.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Task> assignTask({required String id, required String staffId}) async {
    final response = await _client.patch(
      _uri('/api/tasks/$id/assign'),
      headers: await _headers(),
      body: jsonEncode(<String, Object?>{'assignedStaffId': staffId}),
    );
    _ensureSuccess(response);
    return Task.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Task> startTask(String id) async {
    return _patchTask('/api/tasks/$id/start');
  }

  @override
  Future<Task> completeTask(String id, TaskCompletionDraft draft) async {
    final response = await _client.patch(
      _uri('/api/tasks/$id/complete'),
      headers: await _headers(),
      body: jsonEncode(draft.toJson()),
    );
    _ensureSuccess(response);
    return Task.fromJson(_decodeMap(response.body));
  }

  @override
  Future<Task> approveTask(String id) async {
    return _patchTask('/api/tasks/$id/approve');
  }

  @override
  Future<Task> closeTask(String id) async {
    return _patchTask('/api/tasks/$id/close');
  }

  @override
  Future<Task> cancelTask(String id) async {
    return _patchTask('/api/tasks/$id/cancel');
  }

  @override
  Future<void> deleteTask(String id) async {
    final response = await _client.delete(
      _uri('/api/tasks/$id'),
      headers: await _headers(includeContentType: false),
    );
    _ensureSuccess(response);
  }

  Future<Task> _patchTask(String path) async {
    final response = await _client.patch(_uri(path), headers: await _headers());
    _ensureSuccess(response);
    return Task.fromJson(_decodeMap(response.body));
  }

  Uri _uri(String path) {
    final cleanBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$cleanBaseUrl$path');
  }

  Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw const TaskApiException('Please log in again.');
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
    throw TaskApiException(_errorMessage(response));
  }

  Map<String, dynamic> _decodeMap(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const TaskApiException('Expected a JSON object response.');
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

class MockTaskApiService extends ApiService implements TaskApiService {
  MockTaskApiService() : _tasks = _seedTasks();

  final List<Task> _tasks;

  @override
  Future<String> uploadAfterPhoto({
    required String filename,
    required List<int> bytes,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (bytes.isEmpty) {
      throw const TaskApiException('Selected image is empty.');
    }
    return '/uploads/task-after/$filename';
  }

  @override
  Future<List<StaffTask>> fetchStaffTasks() async {
    final tasks = await fetchTasks();
    return tasks
        .where((task) => task.assignedStaff != null)
        .map(StaffTask.fromTask)
        .toList(growable: false);
  }

  @override
  Future<List<Task>> fetchTasks() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_tasks);
  }

  @override
  Future<Task> fetchTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _findTask(id);
  }

  @override
  Future<Task> createTask(TaskDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    final task = Task(
      id: '33333333-3333-3333-3333-${(_tasks.length + 1).toString().padLeft(12, '0')}',
      title: draft.title,
      description: draft.description,
      category: draft.category,
      status: draft.assignedStaffId == null || draft.assignedStaffId!.isEmpty
          ? TaskStatus.newTask
          : TaskStatus.assigned,
      latitude: draft.latitude,
      longitude: draft.longitude,
      addressText: draft.addressText,
      priorityScore: draft.priorityScore,
      assignedStaff: _staffSummary(draft.assignedStaffId),
      createdByOverseer: _overseerSummary,
      beforePhotoUrl: draft.beforePhotoUrl,
      afterPhotoUrl: null,
      staffNote: null,
      aiConfidenceScore: null,
      aiDecision: null,
      startedAt: null,
      submittedAt: null,
      reviewedAt: null,
      closedAt: null,
      createdAt: now,
      updatedAt: now,
      reportIds: draft.reportIds,
    );
    _tasks.insert(0, task);
    return task;
  }

  @override
  Future<Task> updateTask(String id, TaskDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _taskIndex(id);
    final existing = _tasks[index];
    final updated = existing.copyWith(
      title: draft.title,
      description: draft.description,
      category: draft.category,
      latitude: draft.latitude,
      longitude: draft.longitude,
      addressText: draft.addressText,
      priorityScore: draft.priorityScore,
      beforePhotoUrl: draft.beforePhotoUrl,
      afterPhotoUrl: draft.afterPhotoUrl,
      staffNote: draft.staffNote,
      reportIds: draft.reportIds,
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<Task> assignTask({required String id, required String staffId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _taskIndex(id);
    final updated = _tasks[index].copyWith(
      status: TaskStatus.assigned,
      assignedStaff: _staffSummary(staffId),
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<Task> startTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _taskIndex(id);
    final task = _tasks[index];
    if (task.status != TaskStatus.assigned) {
      throw const TaskApiException('Only assigned tasks can be started.');
    }
    final updated = task.copyWith(
      status: TaskStatus.inProgress,
      startedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<Task> completeTask(String id, TaskCompletionDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _taskIndex(id);
    final task = _tasks[index];
    if (task.status != TaskStatus.inProgress) {
      throw const TaskApiException('Only in-progress tasks can be completed.');
    }
    final updated = task.copyWith(
      status: TaskStatus.done,
      afterPhotoUrl: draft.afterPhotoUrl,
      staffNote: draft.staffNote,
      submittedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<Task> approveTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _taskIndex(id);
    final task = _tasks[index];
    if (!task.status.canApprove) {
      throw const TaskApiException(
        'Only done or pending-review tasks can be approved.',
      );
    }
    final updated = task.copyWith(
      status: TaskStatus.approved,
      reviewedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<Task> closeTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _taskIndex(id);
    final updated = _tasks[index].copyWith(
      status: TaskStatus.closed,
      closedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<Task> cancelTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final index = _taskIndex(id);
    final updated = _tasks[index].copyWith(
      status: TaskStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _tasks.removeAt(_taskIndex(id));
  }

  Task _findTask(String id) {
    return _tasks.firstWhere(
      (task) => task.id == id,
      orElse: () => throw const TaskApiException('Task not found.'),
    );
  }

  int _taskIndex(String id) {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      throw const TaskApiException('Task not found.');
    }
    return index;
  }

  static ReportUserSummary? _staffSummary(String? staffId) {
    if (staffId == null || staffId.trim().isEmpty) {
      return null;
    }
    return ReportUserSummary(
      id: staffId.trim(),
      fullName: 'Test Staff',
      role: 'STAFF',
    );
  }

  static List<Task> _seedTasks() {
    return <Task>[
      Task(
        id: '33333333-3333-3333-3333-000000000001',
        title: 'Fix pothole',
        description: 'Repair the pothole reported by citizens.',
        category: ReportCategory.roadDamage,
        status: TaskStatus.assigned,
        latitude: 10.7827,
        longitude: 106.6994,
        addressText: 'Bus stop near Le Loi',
        priorityScore: 5,
        assignedStaff: _staffSummary('44444444-4444-4444-4444-444444444444'),
        createdByOverseer: _overseerSummary,
        beforePhotoUrl: '/uploads/report-before/pothole-before.jpg',
        afterPhotoUrl: null,
        staffNote: null,
        aiConfidenceScore: null,
        aiDecision: null,
        startedAt: null,
        submittedAt: null,
        reviewedAt: null,
        closedAt: null,
        createdAt: DateTime(2026, 6, 9, 9),
        updatedAt: DateTime(2026, 6, 9, 9),
        reportIds: const ['11111111-1111-1111-1111-000000000003'],
      ),
      Task(
        id: '33333333-3333-3333-3333-000000000002',
        title: 'Inspect broken streetlight',
        description: 'Check wiring and replace the failed lamp.',
        category: ReportCategory.streetLight,
        status: TaskStatus.newTask,
        latitude: 10.7769,
        longitude: 106.7009,
        addressText: 'Nguyen Hue, District 1',
        priorityScore: 3,
        assignedStaff: null,
        createdByOverseer: _overseerSummary,
        beforePhotoUrl: '/uploads/report-before/streetlight-before.jpg',
        afterPhotoUrl: null,
        staffNote: null,
        aiConfidenceScore: null,
        aiDecision: null,
        startedAt: null,
        submittedAt: null,
        reviewedAt: null,
        closedAt: null,
        createdAt: DateTime(2026, 6, 9, 10),
        updatedAt: DateTime(2026, 6, 9, 10),
        reportIds: const ['11111111-1111-1111-1111-000000000004'],
      ),
    ];
  }

  static const _overseerSummary = ReportUserSummary(
    id: '55555555-5555-5555-5555-555555555555',
    fullName: 'Test Overseer',
    role: 'OVERSEER',
  );
}

class TaskApiException implements Exception {
  const TaskApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
