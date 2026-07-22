import '../../reports/domain/report.dart';
import '../../tasks/domain/task.dart';

class AnalyticsQuery {
  const AnalyticsQuery({
    this.from,
    this.to,
    this.category,
    this.staffId,
    this.area,
  });

  final DateTime? from;
  final DateTime? to;
  final ReportCategory? category;
  final String? staffId;
  final String? area;

  Map<String, String> toQueryParameters() {
    return <String, String>{
      if (from != null) 'from': from!.toUtc().toIso8601String(),
      if (to != null) 'to': to!.toUtc().toIso8601String(),
      if (category != null) 'category': category!.wireName,
      if ((staffId ?? '').isNotEmpty) 'staffId': staffId!,
      if ((area ?? '').trim().isNotEmpty) 'area': area!.trim(),
    };
  }
}

class OverseerAnalytics {
  const OverseerAnalytics({
    required this.generatedAt,
    required this.filters,
    required this.reports,
    required this.tasks,
    required this.trends,
    required this.categories,
    required this.staffWorkloads,
    required this.attentionItems,
    required this.mapPoints,
  });

  final DateTime generatedAt;
  final AppliedAnalyticsFilters filters;
  final ReportAnalyticsOverview reports;
  final TaskAnalyticsOverview tasks;
  final List<AnalyticsTrendPoint> trends;
  final List<CategoryAnalytics> categories;
  final List<StaffWorkloadAnalytics> staffWorkloads;
  final List<AnalyticsAttentionItem> attentionItems;
  final List<AnalyticsMapPoint> mapPoints;

  factory OverseerAnalytics.fromJson(Map<String, dynamic> json) {
    return OverseerAnalytics(
      generatedAt: _dateTime(json['generatedAt']) ?? DateTime.now(),
      filters: AppliedAnalyticsFilters.fromJson(_map(json['filters'])),
      reports: ReportAnalyticsOverview.fromJson(_map(json['reports'])),
      tasks: TaskAnalyticsOverview.fromJson(_map(json['tasks'])),
      trends: _list(json['trends'])
          .map((item) => AnalyticsTrendPoint.fromJson(_map(item)))
          .toList(growable: false),
      categories: _list(json['categories'])
          .map((item) => CategoryAnalytics.fromJson(_map(item)))
          .toList(growable: false),
      staffWorkloads: _list(json['staffWorkloads'])
          .map((item) => StaffWorkloadAnalytics.fromJson(_map(item)))
          .toList(growable: false),
      attentionItems: _list(json['attentionItems'])
          .map((item) => AnalyticsAttentionItem.fromJson(_map(item)))
          .toList(growable: false),
      mapPoints: _list(json['mapPoints'])
          .map((item) => AnalyticsMapPoint.fromJson(_map(item)))
          .toList(growable: false),
    );
  }
}

class AppliedAnalyticsFilters {
  const AppliedAnalyticsFilters({
    required this.from,
    required this.to,
    required this.category,
    required this.staffId,
    required this.area,
  });

  final DateTime? from;
  final DateTime? to;
  final ReportCategory? category;
  final String? staffId;
  final String? area;

  factory AppliedAnalyticsFilters.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    return AppliedAnalyticsFilters(
      from: _dateTime(json['from']),
      to: _dateTime(json['to']),
      category: category == null ? null : ReportCategory.fromJson(category),
      staffId: json['staffId'] as String?,
      area: json['area'] as String?,
    );
  }
}

class ReportAnalyticsOverview {
  const ReportAnalyticsOverview({
    required this.totalReports,
    required this.byStatus,
    required this.totalUpvotes,
    required this.averagePriority,
    required this.fixedRate,
    required this.cancellationRate,
  });

  final int totalReports;
  final Map<ReportStatus, int> byStatus;
  final int totalUpvotes;
  final double averagePriority;
  final double fixedRate;
  final double cancellationRate;

  factory ReportAnalyticsOverview.fromJson(Map<String, dynamic> json) {
    final counts = _map(json['byStatus']);
    return ReportAnalyticsOverview(
      totalReports: _integer(json['totalReports']),
      byStatus: {
        for (final status in ReportStatus.values)
          status: _integer(counts[status.wireName]),
      },
      totalUpvotes: _integer(json['totalUpvotes']),
      averagePriority: _decimal(json['averagePriority']),
      fixedRate: _decimal(json['fixedRate']),
      cancellationRate: _decimal(json['cancellationRate']),
    );
  }
}

class TaskAnalyticsOverview {
  const TaskAnalyticsOverview({
    required this.totalTasks,
    required this.byStatus,
    required this.unassignedTasks,
    required this.activeTasks,
    required this.pendingReviewTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.averageWorkHours,
    required this.averageReviewHours,
    required this.averageResolutionHours,
  });

  final int totalTasks;
  final Map<TaskStatus, int> byStatus;
  final int unassignedTasks;
  final int activeTasks;
  final int pendingReviewTasks;
  final int completedTasks;
  final double completionRate;
  final double averageWorkHours;
  final double averageReviewHours;
  final double averageResolutionHours;

  factory TaskAnalyticsOverview.fromJson(Map<String, dynamic> json) {
    final counts = _map(json['byStatus']);
    return TaskAnalyticsOverview(
      totalTasks: _integer(json['totalTasks']),
      byStatus: {
        for (final status in TaskStatus.values)
          status: _integer(counts[status.wireName]),
      },
      unassignedTasks: _integer(json['unassignedTasks']),
      activeTasks: _integer(json['activeTasks']),
      pendingReviewTasks: _integer(json['pendingReviewTasks']),
      completedTasks: _integer(json['completedTasks']),
      completionRate: _decimal(json['completionRate']),
      averageWorkHours: _decimal(json['averageWorkHours']),
      averageReviewHours: _decimal(json['averageReviewHours']),
      averageResolutionHours: _decimal(json['averageResolutionHours']),
    );
  }
}

class AnalyticsTrendPoint {
  const AnalyticsTrendPoint({
    required this.periodStart,
    required this.reportsCreated,
    required this.reportsFixed,
    required this.tasksCreated,
    required this.tasksClosed,
  });

  final DateTime periodStart;
  final int reportsCreated;
  final int reportsFixed;
  final int tasksCreated;
  final int tasksClosed;

  factory AnalyticsTrendPoint.fromJson(Map<String, dynamic> json) {
    return AnalyticsTrendPoint(
      periodStart: _dateTime(json['periodStart']) ?? DateTime.now(),
      reportsCreated: _integer(json['reportsCreated']),
      reportsFixed: _integer(json['reportsFixed']),
      tasksCreated: _integer(json['tasksCreated']),
      tasksClosed: _integer(json['tasksClosed']),
    );
  }
}

class CategoryAnalytics {
  const CategoryAnalytics({
    required this.category,
    required this.reports,
    required this.fixedReports,
    required this.tasks,
    required this.closedTasks,
  });

  final ReportCategory category;
  final int reports;
  final int fixedReports;
  final int tasks;
  final int closedTasks;

  factory CategoryAnalytics.fromJson(Map<String, dynamic> json) {
    return CategoryAnalytics(
      category: ReportCategory.fromJson(json['category'] as String),
      reports: _integer(json['reports']),
      fixedReports: _integer(json['fixedReports']),
      tasks: _integer(json['tasks']),
      closedTasks: _integer(json['closedTasks']),
    );
  }
}

class StaffWorkloadAnalytics {
  const StaffWorkloadAnalytics({
    required this.staffId,
    required this.fullName,
    required this.email,
    required this.activeAccount,
    required this.totalTasks,
    required this.activeTasks,
    required this.pendingReviewTasks,
    required this.completedTasks,
    required this.deniedTasks,
    required this.completionRate,
    required this.averageCompletionHours,
  });

  final String staffId;
  final String fullName;
  final String email;
  final bool activeAccount;
  final int totalTasks;
  final int activeTasks;
  final int pendingReviewTasks;
  final int completedTasks;
  final int deniedTasks;
  final double completionRate;
  final double averageCompletionHours;

  factory StaffWorkloadAnalytics.fromJson(Map<String, dynamic> json) {
    return StaffWorkloadAnalytics(
      staffId: json['staffId'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      activeAccount: json['activeAccount'] as bool? ?? true,
      totalTasks: _integer(json['totalTasks']),
      activeTasks: _integer(json['activeTasks']),
      pendingReviewTasks: _integer(json['pendingReviewTasks']),
      completedTasks: _integer(json['completedTasks']),
      deniedTasks: _integer(json['deniedTasks']),
      completionRate: _decimal(json['completionRate']),
      averageCompletionHours: _decimal(json['averageCompletionHours']),
    );
  }
}

class AnalyticsAttentionItem {
  const AnalyticsAttentionItem({
    required this.entityType,
    required this.id,
    required this.title,
    required this.status,
    required this.reason,
    required this.priorityScore,
    required this.staffId,
    required this.staffName,
    required this.addressText,
    required this.updatedAt,
  });

  final String entityType;
  final String id;
  final String title;
  final String status;
  final String reason;
  final int priorityScore;
  final String? staffId;
  final String? staffName;
  final String? addressText;
  final DateTime? updatedAt;

  bool get isReport => entityType == 'REPORT';

  factory AnalyticsAttentionItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsAttentionItem(
      entityType: json['entityType'] as String,
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      reason: json['reason'] as String,
      priorityScore: _integer(json['priorityScore']),
      staffId: json['staffId'] as String?,
      staffName: json['staffName'] as String?,
      addressText: json['addressText'] as String?,
      updatedAt: _dateTime(json['updatedAt']),
    );
  }
}

class AnalyticsMapPoint {
  const AnalyticsMapPoint({
    required this.reportId,
    required this.title,
    required this.category,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.priorityScore,
    required this.upvoteCount,
  });

  final String reportId;
  final String title;
  final ReportCategory category;
  final ReportStatus status;
  final double latitude;
  final double longitude;
  final String? addressText;
  final int priorityScore;
  final int upvoteCount;

  factory AnalyticsMapPoint.fromJson(Map<String, dynamic> json) {
    return AnalyticsMapPoint(
      reportId: json['reportId'] as String,
      title: json['title'] as String,
      category: ReportCategory.fromJson(json['category'] as String),
      status: ReportStatus.fromJson(json['status'] as String),
      latitude: _decimal(json['latitude']),
      longitude: _decimal(json['longitude']),
      addressText: json['addressText'] as String?,
      priorityScore: _integer(json['priorityScore']),
      upvoteCount: _integer(json['upvoteCount']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  return value is Map<String, dynamic> ? value : <String, dynamic>{};
}

List<dynamic> _list(Object? value) {
  return value is List<dynamic> ? value : const <dynamic>[];
}

int _integer(Object? value) => value is num ? value.toInt() : 0;

double _decimal(Object? value) => value is num ? value.toDouble() : 0;

DateTime? _dateTime(Object? value) {
  return value is String && value.isNotEmpty ? DateTime.parse(value) : null;
}
