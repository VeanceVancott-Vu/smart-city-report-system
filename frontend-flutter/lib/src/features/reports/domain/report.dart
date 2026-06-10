enum ReportCategory { road, lighting, sanitation, water, other }

extension ReportCategoryLabel on ReportCategory {
  String get label {
    return switch (this) {
      ReportCategory.road => 'Road',
      ReportCategory.lighting => 'Lighting',
      ReportCategory.sanitation => 'Sanitation',
      ReportCategory.water => 'Water',
      ReportCategory.other => 'Other',
    };
  }
}

enum ReportStatus { submitted, assigned, inProgress, resolved }

extension ReportStatusLabel on ReportStatus {
  String get label {
    return switch (this) {
      ReportStatus.submitted => 'Submitted',
      ReportStatus.assigned => 'Assigned',
      ReportStatus.inProgress => 'In progress',
      ReportStatus.resolved => 'Resolved',
    };
  }
}

class Report {
  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.photoLabel,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final double latitude;
  final double longitude;
  final ReportStatus status;
  final String photoLabel;
  final DateTime createdAt;
}

class NewReportRequest {
  const NewReportRequest({
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.photoLabel,
  });

  final String title;
  final String description;
  final ReportCategory category;
  final double latitude;
  final double longitude;
  final String photoLabel;
}
