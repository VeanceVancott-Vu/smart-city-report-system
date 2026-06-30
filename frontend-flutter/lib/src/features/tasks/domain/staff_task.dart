import 'task.dart';

enum StaffTaskStatus { queued, assigned, inProgress, awaitingReview }

extension StaffTaskStatusLabel on StaffTaskStatus {
  String get label {
    return switch (this) {
      StaffTaskStatus.queued => 'Queued',
      StaffTaskStatus.assigned => 'Assigned',
      StaffTaskStatus.inProgress => 'In progress',
      StaffTaskStatus.awaitingReview => 'Awaiting review',
    };
  }
}

class StaffTask {
  const StaffTask({
    required this.id,
    required this.reportTitle,
    required this.category,
    required this.status,
    required this.area,
    required this.dueDate,
    required this.latitude,
    required this.longitude,
    required this.priorityScore,
    required this.reportIds,
  });

  final String id;
  final String reportTitle;
  final String category;
  final StaffTaskStatus status;
  final String area;
  final DateTime dueDate;
  final double latitude;
  final double longitude;
  final int priorityScore;
  final List<String> reportIds;

  factory StaffTask.fromTask(Task task) {
    return StaffTask(
      id: task.id,
      reportTitle: task.title,
      category: task.category.label,
      status: switch (task.status) {
        TaskStatus.assigned => StaffTaskStatus.assigned,
        TaskStatus.inProgress => StaffTaskStatus.inProgress,
        TaskStatus.done ||
        TaskStatus.pendingReview ||
        TaskStatus.approved => StaffTaskStatus.awaitingReview,
        _ => StaffTaskStatus.queued,
      },
      area: task.locationLabel,
      dueDate: task.createdAt,
      latitude: task.latitude,
      longitude: task.longitude,
      priorityScore: task.priorityScore,
      reportIds: task.reportIds,
    );
  }
}
