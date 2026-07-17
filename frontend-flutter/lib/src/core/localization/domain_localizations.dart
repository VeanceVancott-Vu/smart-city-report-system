import 'package:flutter/widgets.dart';

import '../../features/auth/domain/current_user.dart';
import '../../features/reports/domain/report.dart';
import '../../features/tasks/domain/staff_task.dart';
import '../../features/tasks/domain/task.dart';
import 'app_localizations_extension.dart';

extension UserRoleLocalizations on UserRole {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      UserRole.citizen => context.l10n.roleCitizen,
      UserRole.staff => context.l10n.roleStaff,
      UserRole.overseer => context.l10n.roleOverseer,
    };
  }
}

extension ReportCategoryLocalizations on ReportCategory {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      ReportCategory.roadDamage => context.l10n.reportCategoryRoadDamage,
      ReportCategory.streetLight => context.l10n.reportCategoryStreetLight,
      ReportCategory.garbage => context.l10n.reportCategoryGarbage,
      ReportCategory.waterLeak => context.l10n.reportCategoryWaterLeak,
      ReportCategory.drainage => context.l10n.reportCategoryDrainage,
      ReportCategory.trafficSign => context.l10n.reportCategoryTrafficSign,
      ReportCategory.treeBlockage => context.l10n.reportCategoryTreeBlockage,
      ReportCategory.other => context.l10n.reportCategoryOther,
    };
  }
}

extension ReportStatusLocalizations on ReportStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      ReportStatus.submitted => context.l10n.reportStatusSubmitted,
      ReportStatus.inProgress => context.l10n.reportStatusInProgress,
      ReportStatus.fixed => context.l10n.reportStatusFixed,
      ReportStatus.cancelled => context.l10n.reportStatusCancelled,
    };
  }
}

extension TaskStatusLocalizations on TaskStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      TaskStatus.newTask => context.l10n.taskStatusNew,
      TaskStatus.assigned => context.l10n.taskStatusAssigned,
      TaskStatus.inProgress => context.l10n.taskStatusInProgress,
      TaskStatus.done => context.l10n.taskStatusDone,
      TaskStatus.pendingReview => context.l10n.taskStatusPendingReview,
      TaskStatus.denied => context.l10n.taskStatusDenied,
      TaskStatus.approved => context.l10n.taskStatusApproved,
      TaskStatus.closed => context.l10n.taskStatusClosed,
      TaskStatus.cancelled => context.l10n.taskStatusCancelled,
    };
  }
}

extension StaffTaskStatusLocalizations on StaffTaskStatus {
  String localizedLabel(BuildContext context) {
    return switch (this) {
      StaffTaskStatus.queued => context.l10n.staffTaskStatusQueued,
      StaffTaskStatus.assigned => context.l10n.staffTaskStatusAssigned,
      StaffTaskStatus.inProgress => context.l10n.staffTaskStatusInProgress,
      StaffTaskStatus.awaitingReview =>
        context.l10n.staffTaskStatusAwaitingReview,
      StaffTaskStatus.denied => context.l10n.staffTaskStatusDenied,
      StaffTaskStatus.approved => context.l10n.staffTaskStatusApproved,
    };
  }
}
