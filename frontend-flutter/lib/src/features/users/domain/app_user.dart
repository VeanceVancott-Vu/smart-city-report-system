import '../../auth/domain/current_user.dart';
import '../../reports/domain/report.dart';
import '../../tasks/domain/task.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.fromJson(json['role'] as String),
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.active,
    required this.createdAt,
    required this.citizenReportAnalytics,
    required this.staffTaskAnalytics,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;
  final CitizenReportAnalytics? citizenReportAnalytics;
  final StaffTaskAnalytics? staffTaskAnalytics;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.fromJson(json['role'] as String),
      active: json['active'] as bool? ?? true,
      createdAt: _dateTime(json['createdAt']),
      citizenReportAnalytics: json['citizenReportAnalytics'] == null
          ? null
          : CitizenReportAnalytics.fromJson(
              json['citizenReportAnalytics'] as Map<String, dynamic>,
            ),
      staffTaskAnalytics: json['staffTaskAnalytics'] == null
          ? null
          : StaffTaskAnalytics.fromJson(
              json['staffTaskAnalytics'] as Map<String, dynamic>,
            ),
    );
  }
}

class CitizenReportAnalytics {
  const CitizenReportAnalytics({
    required this.totalReports,
    required this.byStatus,
  });

  final int totalReports;
  final Map<ReportStatus, int> byStatus;

  factory CitizenReportAnalytics.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['byStatus'] as Map<String, dynamic>? ?? const {};
    return CitizenReportAnalytics(
      totalReports: json['totalReports'] as int? ?? 0,
      byStatus: {
        for (final status in ReportStatus.values)
          status: rawCounts[status.wireName] as int? ?? 0,
      },
    );
  }
}

class StaffTaskAnalytics {
  const StaffTaskAnalytics({required this.totalTasks, required this.byStatus});

  final int totalTasks;
  final Map<TaskStatus, int> byStatus;

  factory StaffTaskAnalytics.fromJson(Map<String, dynamic> json) {
    final rawCounts = json['byStatus'] as Map<String, dynamic>? ?? const {};
    return StaffTaskAnalytics(
      totalTasks: json['totalTasks'] as int? ?? 0,
      byStatus: {
        for (final status in TaskStatus.values)
          status: rawCounts[status.wireName] as int? ?? 0,
      },
    );
  }
}

class StaffPublicProfile {
  const StaffPublicProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;

  factory StaffPublicProfile.fromJson(Map<String, dynamic> json) {
    return StaffPublicProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.fromJson(json['role'] as String),
      active: json['active'] as bool? ?? true,
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class StaffDetailProfile {
  const StaffDetailProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.active,
    required this.createdAt,
    required this.taskAnalytics,
    required this.tasks,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;
  final StaffTaskAnalytics taskAnalytics;
  final List<Task> tasks;

  factory StaffDetailProfile.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['tasks'] as List<dynamic>? ?? const <dynamic>[];
    return StaffDetailProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.fromJson(json['role'] as String),
      active: json['active'] as bool? ?? true,
      createdAt: _dateTime(json['createdAt']),
      taskAnalytics: StaffTaskAnalytics.fromJson(
        json['taskAnalytics'] as Map<String, dynamic>,
      ),
      tasks: rawTasks
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

DateTime? _dateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}

class UserDraft {
  const UserDraft({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String fullName;
  final String email;
  final String password;
  final UserRole role;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role.wireName,
    };
  }
}

class StaffSummary {
  const StaffSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.active,
    required this.activeTasksCount,
    required this.completedTasksCount,
    required this.tasks,
  });

  final String id;
  final String fullName;
  final String email;
  final bool active;
  final int activeTasksCount;
  final int completedTasksCount;
  final List<Task> tasks;

  factory StaffSummary.fromJson(Map<String, dynamic> json) {
    final tasksList = json['tasks'] as List<dynamic>? ?? const <dynamic>[];
    return StaffSummary(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      active: json['active'] as bool? ?? true,
      activeTasksCount: json['activeTasksCount'] as int? ?? 0,
      completedTasksCount: json['completedTasksCount'] as int? ?? 0,
      tasks: tasksList
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
