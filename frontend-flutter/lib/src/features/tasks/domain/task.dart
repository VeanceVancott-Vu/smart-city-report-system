import '../../reports/domain/report.dart';

enum TaskStatus {
  newTask('NEW', 'New'),
  assigned('ASSIGNED', 'Assigned'),
  inProgress('IN_PROGRESS', 'In progress'),
  done('DONE', 'Done'),
  pendingReview('PENDING_REVIEW', 'Pending review'),
  approved('APPROVED', 'Approved'),
  closed('CLOSED', 'Closed'),
  cancelled('CANCELLED', 'Cancelled');

  const TaskStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  bool get canAssign =>
      this != TaskStatus.closed && this != TaskStatus.cancelled;

  bool get canClose =>
      this != TaskStatus.closed && this != TaskStatus.cancelled;

  bool get canCancel =>
      this != TaskStatus.closed && this != TaskStatus.cancelled;

  bool get canStart => this == TaskStatus.assigned;

  bool get canComplete => this == TaskStatus.inProgress;

  static TaskStatus fromJson(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.wireName == value,
      orElse: () => TaskStatus.newTask,
    );
  }
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.priorityScore,
    required this.assignedStaff,
    required this.createdByOverseer,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
    required this.staffNote,
    required this.aiConfidenceScore,
    required this.aiDecision,
    required this.startedAt,
    required this.submittedAt,
    required this.reviewedAt,
    required this.closedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.reportIds,
  });

  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final TaskStatus status;
  final double latitude;
  final double longitude;
  final String? addressText;
  final int priorityScore;
  final ReportUserSummary? assignedStaff;
  final ReportUserSummary? createdByOverseer;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final String? staffNote;
  final double? aiConfidenceScore;
  final String? aiDecision;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> reportIds;

  String get locationLabel {
    final address = addressText?.trim();
    if (address != null && address.isNotEmpty) {
      return address;
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ReportCategory.fromJson(json['category'] as String),
      status: TaskStatus.fromJson(json['status'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      addressText: json['addressText'] as String?,
      priorityScore: json['priorityScore'] as int? ?? 0,
      assignedStaff: _userSummary(json['assignedStaff']),
      createdByOverseer: _userSummary(json['createdByOverseer']),
      beforePhotoUrl: json['beforePhotoUrl'] as String?,
      afterPhotoUrl: json['afterPhotoUrl'] as String?,
      staffNote: json['staffNote'] as String?,
      aiConfidenceScore: (json['aiConfidenceScore'] as num?)?.toDouble(),
      aiDecision: json['aiDecision'] as String?,
      startedAt: _dateTime(json['startedAt']),
      submittedAt: _dateTime(json['submittedAt']),
      reviewedAt: _dateTime(json['reviewedAt']),
      closedAt: _dateTime(json['closedAt']),
      createdAt: _dateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _dateTime(json['updatedAt']) ?? DateTime.now(),
      reportIds: (json['reportIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((id) => id as String)
          .toList(growable: false),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    ReportCategory? category,
    TaskStatus? status,
    double? latitude,
    double? longitude,
    String? addressText,
    int? priorityScore,
    ReportUserSummary? assignedStaff,
    ReportUserSummary? createdByOverseer,
    String? beforePhotoUrl,
    String? afterPhotoUrl,
    String? staffNote,
    double? aiConfidenceScore,
    String? aiDecision,
    DateTime? startedAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? reportIds,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressText: addressText ?? this.addressText,
      priorityScore: priorityScore ?? this.priorityScore,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      createdByOverseer: createdByOverseer ?? this.createdByOverseer,
      beforePhotoUrl: beforePhotoUrl ?? this.beforePhotoUrl,
      afterPhotoUrl: afterPhotoUrl ?? this.afterPhotoUrl,
      staffNote: staffNote ?? this.staffNote,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      aiDecision: aiDecision ?? this.aiDecision,
      startedAt: startedAt ?? this.startedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reportIds: reportIds ?? this.reportIds,
    );
  }
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.priorityScore,
    required this.assignedStaffId,
    required this.beforePhotoUrl,
    required this.afterPhotoUrl,
    required this.staffNote,
    required this.reportIds,
  });

  final String title;
  final String description;
  final ReportCategory category;
  final double latitude;
  final double longitude;
  final String? addressText;
  final int priorityScore;
  final String? assignedStaffId;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final String? staffNote;
  final List<String> reportIds;

  Map<String, Object?> toCreateJson() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'category': category.wireName,
      'latitude': latitude,
      'longitude': longitude,
      'addressText': addressText,
      'priorityScore': priorityScore,
      'assignedStaffId': assignedStaffId,
      'beforePhotoUrl': beforePhotoUrl,
      'reportIds': reportIds,
    };
  }

  Map<String, Object?> toUpdateJson() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'category': category.wireName,
      'latitude': latitude,
      'longitude': longitude,
      'addressText': addressText,
      'priorityScore': priorityScore,
      'beforePhotoUrl': beforePhotoUrl,
      'afterPhotoUrl': afterPhotoUrl,
      'staffNote': staffNote,
      'reportIds': reportIds,
    };
  }
}

class TaskCompletionDraft {
  const TaskCompletionDraft({
    required this.afterPhotoUrl,
    required this.staffNote,
  });

  final String? afterPhotoUrl;
  final String? staffNote;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'afterPhotoUrl': afterPhotoUrl,
      'staffNote': staffNote,
    };
  }
}

ReportUserSummary? _userSummary(Object? value) {
  if (value is Map<String, dynamic>) {
    return ReportUserSummary.fromJson(value);
  }
  return null;
}

DateTime? _dateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
