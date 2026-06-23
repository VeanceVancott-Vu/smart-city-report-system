import '../../auth/domain/current_user.dart';
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
