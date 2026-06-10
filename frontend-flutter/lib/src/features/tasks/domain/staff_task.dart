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
  });

  final String id;
  final String reportTitle;
  final String category;
  final StaffTaskStatus status;
  final String area;
  final DateTime dueDate;
}
