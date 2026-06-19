enum ReportCategory {
  roadDamage('ROAD_DAMAGE', 'Road damage'),
  streetLight('STREET_LIGHT', 'Street light'),
  garbage('GARBAGE', 'Garbage'),
  waterLeak('WATER_LEAK', 'Water leak'),
  drainage('DRAINAGE', 'Drainage'),
  trafficSign('TRAFFIC_SIGN', 'Traffic sign'),
  treeBlockage('TREE_BLOCKAGE', 'Tree blockage'),
  other('OTHER', 'Other');

  const ReportCategory(this.wireName, this.label);

  final String wireName;
  final String label;

  static ReportCategory fromJson(String value) {
    return ReportCategory.values.firstWhere(
      (category) => category.wireName == value,
      orElse: () => ReportCategory.other,
    );
  }
}

enum ReportStatus {
  submitted('SUBMITTED', 'Submitted'),
  fixed('FIXED', 'Fixed'),
  cancelled('CANCELLED', 'Cancelled');

  const ReportStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  bool get canCitizenEdit => this == ReportStatus.submitted;

  bool get canCitizenCancel => this == ReportStatus.submitted;

  bool get canUpvote => this == ReportStatus.submitted;

  static ReportStatus fromJson(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.wireName == value,
      orElse: () => ReportStatus.submitted,
    );
  }
}

class Report {
  const Report({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.beforePhotoUrl,
    required this.anonymous,
    required this.upvoteCount,
    required this.priorityScore,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  final String id;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportStatus status;
  final double latitude;
  final double longitude;
  final String? addressText;
  final String? beforePhotoUrl;
  final bool anonymous;
  final int upvoteCount;
  final int priorityScore;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportUserSummary? createdBy;

  String get photoLabel {
    final value = beforePhotoUrl?.trim();
    return value == null || value.isEmpty ? 'No photo URL' : value;
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: ReportCategory.fromJson(json['category'] as String),
      status: ReportStatus.fromJson(json['status'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      addressText: json['addressText'] as String?,
      beforePhotoUrl: json['beforePhotoUrl'] as String?,
      anonymous: json['anonymous'] as bool? ?? false,
      upvoteCount: json['upvoteCount'] as int? ?? 0,
      priorityScore: json['priorityScore'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] == null
          ? null
          : ReportUserSummary.fromJson(
              json['createdBy'] as Map<String, dynamic>,
            ),
    );
  }

  Report copyWith({
    String? id,
    String? title,
    String? description,
    ReportCategory? category,
    ReportStatus? status,
    double? latitude,
    double? longitude,
    String? addressText,
    String? beforePhotoUrl,
    bool? anonymous,
    int? upvoteCount,
    int? priorityScore,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReportUserSummary? createdBy,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressText: addressText ?? this.addressText,
      beforePhotoUrl: beforePhotoUrl ?? this.beforePhotoUrl,
      anonymous: anonymous ?? this.anonymous,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      priorityScore: priorityScore ?? this.priorityScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

class ReportUserSummary {
  const ReportUserSummary({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String role;

  factory ReportUserSummary.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] ?? json['fullName'];

    return ReportUserSummary(
      id: json['id'] as String,
      fullName: displayName is String && displayName.isNotEmpty
          ? displayName
          : 'Unknown user',
      role: json['role'] as String? ?? '',
    );
  }
}

class ReportDraft {
  const ReportDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    required this.beforePhotoUrl,
    required this.anonymous,
  });

  final String title;
  final String description;
  final ReportCategory category;
  final double latitude;
  final double longitude;
  final String? addressText;
  final String? beforePhotoUrl;
  final bool anonymous;

  Map<String, Object?> toCreateJson() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'category': category.wireName,
      'latitude': latitude,
      'longitude': longitude,
      'addressText': addressText,
      'beforePhotoUrl': beforePhotoUrl,
      'anonymous': anonymous,
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
      'beforePhotoUrl': beforePhotoUrl,
    };
  }
}

class ReportMapPin {
  const ReportMapPin({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.upvoteCount,
    required this.priorityScore,
    required this.creatorId,
  });

  final String id;
  final String title;
  final ReportCategory category;
  final ReportStatus status;
  final double latitude;
  final double longitude;
  final int upvoteCount;
  final int priorityScore;
  final String creatorId;

  factory ReportMapPin.fromJson(Map<String, dynamic> json) {
    return ReportMapPin(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ReportCategory.fromJson(json['category'] as String),
      status: ReportStatus.fromJson(json['status'] as String),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      upvoteCount: json['upvoteCount'] as int? ?? 0,
      priorityScore: json['priorityScore'] as int? ?? 0,
      creatorId: json['creatorId'] as String? ?? '',
    );
  }

  ReportMapPin copyWith({int? upvoteCount, int? priorityScore}) {
    return ReportMapPin(
      id: id,
      title: title,
      category: category,
      status: status,
      latitude: latitude,
      longitude: longitude,
      upvoteCount: upvoteCount ?? this.upvoteCount,
      priorityScore: priorityScore ?? this.priorityScore,
      creatorId: creatorId,
    );
  }
}

class ReportUpvoteSummary {
  const ReportUpvoteSummary({
    required this.id,
    required this.upvoteCount,
    required this.priorityScore,
    required this.hasUpvoted,
  });

  final String id;
  final int upvoteCount;
  final int priorityScore;
  final bool hasUpvoted;

  factory ReportUpvoteSummary.fromJson(Map<String, dynamic> json) {
    return ReportUpvoteSummary(
      id: json['id'] as String,
      upvoteCount: json['upvoteCount'] as int? ?? 0,
      priorityScore: json['priorityScore'] as int? ?? 0,
      hasUpvoted: json['hasUpvoted'] as bool? ?? false,
    );
  }
}
