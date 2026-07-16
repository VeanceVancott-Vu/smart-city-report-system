// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart City Reports';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Password';

  @override
  String get commonFullName => 'Full name';

  @override
  String get commonRole => 'Role';

  @override
  String get commonReports => 'Reports';

  @override
  String get commonMap => 'Map';

  @override
  String get commonTasks => 'Tasks';

  @override
  String get commonStaff => 'Staff';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonLogout => 'Log out';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonApprove => 'Approve';

  @override
  String get commonAssign => 'Assign';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonTitle => 'Title';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonCategory => 'Category';

  @override
  String get commonLocation => 'Location';

  @override
  String get commonCoordinates => 'Coordinates';

  @override
  String get commonAddress => 'Address';

  @override
  String get commonLatitude => 'Latitude';

  @override
  String get commonLongitude => 'Longitude';

  @override
  String get commonBeforePhoto => 'Before photo';

  @override
  String get commonAfterPhoto => 'After photo';

  @override
  String get commonUnknownUser => 'Unknown user';

  @override
  String get commonUnassigned => 'Unassigned';

  @override
  String get commonNone => 'None';

  @override
  String get commonAnonymous => 'Anonymous';

  @override
  String get commonActive => 'Active';

  @override
  String get commonInactive => 'Inactive';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonUnexpectedErrorTitle => 'Something went wrong';

  @override
  String priorityValue(Object score) {
    return 'Priority $score';
  }

  @override
  String statusValue(Object status) {
    return 'Status: $status';
  }

  @override
  String coordinatesValue(Object latitude, Object longitude) {
    return 'Coordinates: $latitude, $longitude';
  }

  @override
  String upvoteCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count upvotes',
      one: '1 upvote',
      zero: 'No upvotes',
    );
    return '$_temp0';
  }

  @override
  String reportCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports',
      one: '1 report',
      zero: 'No reports',
    );
    return '$_temp0';
  }

  @override
  String taskCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String get roleCitizen => 'Citizen';

  @override
  String get roleStaff => 'Staff';

  @override
  String get roleOverseer => 'Overseer';

  @override
  String get reportCategoryRoadDamage => 'Road damage';

  @override
  String get reportCategoryStreetLight => 'Street light';

  @override
  String get reportCategoryGarbage => 'Garbage';

  @override
  String get reportCategoryWaterLeak => 'Water leak';

  @override
  String get reportCategoryDrainage => 'Drainage';

  @override
  String get reportCategoryTrafficSign => 'Traffic sign';

  @override
  String get reportCategoryTreeBlockage => 'Tree blockage';

  @override
  String get reportCategoryOther => 'Other';

  @override
  String get reportStatusSubmitted => 'Submitted';

  @override
  String get reportStatusInProgress => 'In progress';

  @override
  String get reportStatusFixed => 'Fixed';

  @override
  String get reportStatusCancelled => 'Cancelled';

  @override
  String get taskStatusNew => 'New';

  @override
  String get taskStatusAssigned => 'Assigned';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get taskStatusPendingReview => 'Pending review';

  @override
  String get taskStatusApproved => 'Approved';

  @override
  String get taskStatusClosed => 'Closed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get staffTaskStatusQueued => 'Queued';

  @override
  String get staffTaskStatusAssigned => 'Assigned';

  @override
  String get staffTaskStatusInProgress => 'In progress';

  @override
  String get staffTaskStatusAwaitingReview => 'Awaiting review';

  @override
  String get staffTaskStatusApproved => 'Approved';

  @override
  String get authLoginButton => 'Log in';

  @override
  String get authCreateAccountTitle => 'Create account';

  @override
  String get authCreateAccountButton => 'Create account';

  @override
  String get authBackToLogin => 'Back to login';

  @override
  String get authFullNameRequired => 'Full name is required';

  @override
  String get authEmailRequired => 'Email is required';

  @override
  String get authEmailInvalid => 'Enter a valid email';

  @override
  String get authPasswordRequired => 'Password is required';

  @override
  String authPasswordMinLength(Object count) {
    return 'Use at least $count characters';
  }

  @override
  String get authLoginFailed => 'Unable to log in. Please try again.';

  @override
  String get authRegistrationFailed =>
      'Unable to create account. Please try again.';

  @override
  String get homeMyReports => 'My reports';

  @override
  String get homePinsMap => 'Report map';

  @override
  String get homeCreateReport => 'Report an issue';

  @override
  String get homeReportDashboard => 'Report dashboard';

  @override
  String get homeCityMap => 'City map';

  @override
  String get homeCreateUser => 'Create user';

  @override
  String get mapSearchPlacesTooltip => 'Search places';

  @override
  String get mapViewTitle => 'Map view';

  @override
  String get reportListViewTitle => 'Report list view';

  @override
  String get mapRefreshVisibleArea => 'Refresh visible area';

  @override
  String get mapAllCategories => 'All categories';

  @override
  String get mapHideMyReports => 'Hide my reports';

  @override
  String get mapOpenPinsLoadFailed => 'Unable to load open report pins.';

  @override
  String get mapSearchedLocation => 'Searched location';

  @override
  String get mapSearchedPlace => 'Searched place';

  @override
  String get mapNoOpenPins => 'No open report pins in this area';

  @override
  String get mapCitizenSearchHint =>
      'Search reports, categories, or addresses…';

  @override
  String get mapNoSearchMatches => 'No matching reports or addresses found';

  @override
  String get mapReportsHeader => 'REPORTS';

  @override
  String get mapPlacesHeader => 'ADDRESSES & PLACES';

  @override
  String get mapViewDetails => 'View details';

  @override
  String get mapRemoveUpvote => 'Remove upvote';

  @override
  String get mapSeeThisToo => 'I see this too';

  @override
  String get mapUpvoteUpdateFailed => 'Unable to update upvote.';

  @override
  String mapCategoryValue(Object category) {
    return 'Category: $category';
  }

  @override
  String get mapPinLocationTitle => 'Pin location';

  @override
  String get mapConfirmLocationTooltip => 'Confirm location';

  @override
  String get mapPickerSearchHint => 'Search address or open reports…';

  @override
  String get mapActiveReportsHeader => 'ACTIVE REPORTS';

  @override
  String get mapAddressFallback => 'Address';

  @override
  String get mapSelectedLocation => 'Selected location';

  @override
  String get mapLoadingAddress => 'Loading address…';

  @override
  String get mapConfirmPinnedLocation => 'Confirm pinned location';

  @override
  String get reportCreateTitle => 'Create report';

  @override
  String get reportSubmit => 'Submit report';

  @override
  String get reportSubmittedTitle => 'Report submitted';

  @override
  String get reportCreateFailed => 'Unable to create report.';

  @override
  String get reportSubmitFailedTitle => 'Could not submit report';

  @override
  String get reportEditTitle => 'Edit report';

  @override
  String get reportUpdatedTitle => 'Report updated';

  @override
  String get reportUpdateFailed => 'Unable to update report.';

  @override
  String get reportUpdateFailedTitle => 'Could not update report';

  @override
  String get reportLoadFailed => 'Unable to load report.';

  @override
  String get reportsLoadFailed => 'Unable to load reports.';

  @override
  String get reportsEmpty => 'No reports yet';

  @override
  String get reportSubmittedOnlyEditable =>
      'Only submitted reports can be edited.';

  @override
  String get reportSubmittedOnlyTaskable =>
      'Only submitted reports can be turned into tasks.';

  @override
  String get reportDetailsTitle => 'Report details';

  @override
  String get reportCancelledTitle => 'Report cancelled';

  @override
  String get reportCancelFailedTitle => 'Could not cancel report';

  @override
  String get reportSubmittedAt => 'Submitted';

  @override
  String get reportLastUpdated => 'Last updated';

  @override
  String get reportReporter => 'Reporter';

  @override
  String get reportCreatedBy => 'Created by';

  @override
  String get reportId => 'Report ID';

  @override
  String get reportSaveChanges => 'Save changes';

  @override
  String get reportSubmitAnonymously => 'Submit anonymously';

  @override
  String get beforePhotoRequiredError => 'Upload a before photo first';

  @override
  String get beforePhotoRequiredTitle => 'Before photo required';

  @override
  String get beforePhotoRequiredMessage =>
      'Upload a photo before submitting the report.';

  @override
  String get beforePhotoUploaded => 'Before photo uploaded';

  @override
  String get beforePhotoUploadFailed => 'Unable to upload before photo.';

  @override
  String get photoUploadFailedTitle => 'Photo upload failed';

  @override
  String get photoUpload => 'Upload photo';

  @override
  String get photoReplace => 'Replace photo';

  @override
  String get photoNotAvailable => 'Photo not available';

  @override
  String get reportLocationSelection => 'Location selection';

  @override
  String get reportSelectLocationMap => 'Select location on map';

  @override
  String get validationLatitudeRange => 'Use -90 to 90';

  @override
  String get validationLongitudeRange => 'Use -180 to 180';

  @override
  String get validationNumber => 'Use a number';

  @override
  String selectedReportCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reports selected',
      one: '1 report selected',
    );
    return '$_temp0';
  }

  @override
  String get taskCreate => 'Create task';

  @override
  String get taskCreateFromReport => 'Create task from report';

  @override
  String get overseerReportFixed => 'Report marked as fixed';

  @override
  String overseerReportUpdateFailed(Object error) {
    return 'Failed to update report: $error';
  }

  @override
  String get reportMarkFixed => 'Mark fixed';

  @override
  String get reportCancel => 'Cancel report';

  @override
  String get reportNoPhotoUrl => 'No photo URL';

  @override
  String get taskOnlySubmittedReports =>
      'Only submitted reports can be turned into tasks.';

  @override
  String get mapAllStatuses => 'All statuses';

  @override
  String get mapAllPriorities => 'All priorities';

  @override
  String mapMinimumPriority(Object score) {
    return 'Priority ≥ $score';
  }

  @override
  String get mapCreateRepairTask => 'Create repair task';

  @override
  String get mapMetricVisible => 'Visible';

  @override
  String get mapMetricHighPriority => 'High priority';

  @override
  String get mapMetricAveragePriority => 'Avg priority';

  @override
  String get mapMetricTopCategory => 'Top category';

  @override
  String get mapMetricClosedOut => 'Closed out';

  @override
  String get mapOperationsQueue => 'Operations queue';

  @override
  String get mapSelectMultipleTooltip => 'Select multiple for task';

  @override
  String get mapNoReportsInView => 'No reports in view';

  @override
  String get mapTableCategory => 'CATEGORY';

  @override
  String get mapTableReport => 'REPORT';

  @override
  String get mapTableStatus => 'STATUS';

  @override
  String get mapTablePriority => 'PRI';

  @override
  String get mapTableVotes => 'VOTES';

  @override
  String get mapTaskUnavailable => 'Task unavailable';

  @override
  String get mapOverseerSearchHint => 'Search reports or addresses…';

  @override
  String mapCategoryAndStatus(Object category, Object status) {
    return '$category — $status';
  }

  @override
  String get mapViewFullDetails => 'View full details';

  @override
  String get mapMarkFixed => 'Mark fixed';

  @override
  String get taskQueueTitle => 'Task queue';

  @override
  String get taskAllStatuses => 'All statuses';

  @override
  String get tasksLoadFailed => 'Unable to load tasks.';

  @override
  String get tasksEmpty => 'No tasks yet';

  @override
  String get tasksNoStatusMatches => 'No tasks match this status';

  @override
  String get taskCreateTitle => 'Create task';

  @override
  String get taskEditTitle => 'Edit task';

  @override
  String get taskCreatedTitle => 'Task created';

  @override
  String get taskUpdatedTitle => 'Task updated';

  @override
  String get taskCreateFailedTitle => 'Could not create task';

  @override
  String get taskUpdateFailedTitle => 'Could not update task';

  @override
  String get taskSaveFailed => 'Unable to save task.';

  @override
  String get taskNoReportsSelected => 'No reports were selected.';

  @override
  String get taskLinkedReportsLoadFailed => 'Unable to load linked reports.';

  @override
  String taskUnavailableReports(Object reports) {
    return 'Only submitted reports can be used to create a task. Already handled: $reports';
  }

  @override
  String get taskNoActiveStaff => 'No active staff users found.';

  @override
  String get taskBrief => 'Task brief';

  @override
  String get taskData => 'Task data';

  @override
  String get taskNoPhoto => 'No photo';

  @override
  String get taskReportPhoto => 'Report photo';

  @override
  String get taskAssignedStaff => 'Assigned staff';

  @override
  String get taskReportIds => 'Report IDs';

  @override
  String get validationWholeNumber => 'Use a whole number';

  @override
  String get validationNonnegative => 'Use 0 or higher';

  @override
  String get validationOutOfRange => 'Out of range';

  @override
  String get taskDetailsTitle => 'Task details';

  @override
  String get taskApprovedTitle => 'Task approved';

  @override
  String get taskClosedTitle => 'Task closed';

  @override
  String get taskDeleteQuestion => 'Delete task?';

  @override
  String taskDeleteWarning(Object title) {
    return 'This will permanently delete “$title” and unlink its reports.';
  }

  @override
  String get taskKeep => 'Keep task';

  @override
  String get taskDeletedTitle => 'Task deleted';

  @override
  String get taskDeleteFailed => 'Unable to delete task.';

  @override
  String get taskUpdateFailed => 'Unable to update task.';

  @override
  String get taskLoadFailed => 'Unable to load task.';

  @override
  String get taskStaffNote => 'Staff note';

  @override
  String get taskReviewEvidence => 'Review evidence';

  @override
  String get taskNoBeforePhoto => 'No before photo uploaded';

  @override
  String get taskNoAfterPhoto => 'No after photo uploaded';

  @override
  String get staffMyTasksTitle => 'My tasks';

  @override
  String get staffAssignedToYou => 'Assigned to you';

  @override
  String get staffInProgress => 'In progress';

  @override
  String get staffReview => 'Review';

  @override
  String get staffApproved => 'Approved';

  @override
  String get staffTopPriority => 'Top priority';

  @override
  String get staffReady => 'Ready';

  @override
  String get staffNoTaskLocations => 'No task locations';

  @override
  String get staffTaskQueue => 'Task queue';

  @override
  String get staffNoAssignedTasks => 'No assigned tasks yet.';

  @override
  String get staffTaskSearchHint =>
      'Search tasks by title, area, or category...';

  @override
  String get staffTaskSort => 'Sort tasks';

  @override
  String get staffTaskSortNewest => 'Newest';

  @override
  String get staffTaskSortOldest => 'Oldest';

  @override
  String get staffTaskSortPriority => 'Most priority';

  @override
  String get staffNoTaskMatches => 'No tasks match your search.';

  @override
  String get staffHideReports => 'Hide reports';

  @override
  String get staffShowOnMap => 'Show on map';

  @override
  String staffTaskStarted(Object title) {
    return '$title started';
  }

  @override
  String get staffStartTask => 'Start task';

  @override
  String get staffRouteMap => 'Route map';

  @override
  String get staffCompleteTask => 'Complete task';

  @override
  String get staffNoLinkedReportDetails => 'No linked report details found.';

  @override
  String staffTaskCompleted(Object title) {
    return '$title completed';
  }

  @override
  String get staffAfterPhotoRequired => 'Upload an after photo first';

  @override
  String get staffAfterPhotoUploaded => 'After photo uploaded';

  @override
  String get staffAfterPhotoUploadFailed => 'Unable to upload after photo.';

  @override
  String validationMaximumCharacters(Object maxLength) {
    return 'Use $maxLength characters or fewer';
  }

  @override
  String get routeMapTitle => 'Route map';

  @override
  String get routeUsingTaskAddress =>
      'Using the task address as the route start.';

  @override
  String get routeAddressNotFound =>
      'Address not found locally. Try a linked report address or latitude,longitude.';

  @override
  String routeStartsFrom(Object location) {
    return 'Route starts from $location.';
  }

  @override
  String get routeCurrentAddress => 'Current address';

  @override
  String get routeAddressHint =>
      'Enter current address, e.g. bus stop near Lê Lợi';

  @override
  String get routeFromAddress => 'Route from address';

  @override
  String get routeUseTaskAddress => 'Use task address';

  @override
  String get routeKnownAddressesHelp =>
      'Known task/report addresses and latitude,longitude are supported.';

  @override
  String get routeVisitOrder => 'Visit order';

  @override
  String get routeNoStops => 'No linked report stops.';

  @override
  String get routeDirections => 'Directions';

  @override
  String get routeLoadFailed => 'Unable to load route map.';

  @override
  String get routeStartMarker => 'Start';

  @override
  String routeSummary(num count, Object distance, Object start) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return 'From $start — $_temp0 — $distance';
  }

  @override
  String get userCreateTitle => 'Create user';

  @override
  String userCreated(Object name) {
    return 'Created $name';
  }

  @override
  String get userCreateFailed => 'Unable to create user right now.';

  @override
  String userPasswordMinLength(Object count) {
    return 'Use at least $count characters';
  }

  @override
  String get staffActiveMetric => 'Active staff';

  @override
  String get staffInactiveMetric => 'Inactive staff';

  @override
  String get staffOngoingTasksMetric => 'Ongoing tasks';

  @override
  String get staffCompletedTasksMetric => 'Completed tasks';

  @override
  String get staffSummariesLoadFailed => 'Unable to load staff summaries.';

  @override
  String get staffEmpty => 'No staff members registered yet';

  @override
  String get staffActiveTasksHeader => 'ACTIVE TASKS';

  @override
  String get staffCompletedTasksHeader => 'COMPLETED TASKS';

  @override
  String get staffNoAssignedTasksForMember =>
      'No tasks assigned to this staff member.';

  @override
  String staffAssignedTo(Object name) {
    return 'Assigned to $name';
  }

  @override
  String get staffUsersLoadFailed => 'Unable to load staff users.';

  @override
  String get taskLinkedReports => 'Linked reports';

  @override
  String get taskPriorityScore => 'Priority score';

  @override
  String get commonList => 'List';

  @override
  String get reportCancelFailed => 'Unable to cancel report.';

  @override
  String staffTaskMarkerLabel(Object number, Object title) {
    return 'Task $number $title';
  }

  @override
  String staffActiveTaskCount(Object count) {
    return '$count active';
  }

  @override
  String staffCompletedTaskCount(Object count) {
    return '$count completed';
  }

  @override
  String get routeManeuverHeadOut => 'Head out';

  @override
  String get routeManeuverArrive => 'Arrive';

  @override
  String get routeManeuverTurnGeneric => 'Turn';

  @override
  String routeManeuverTurn(Object direction) {
    return 'Turn $direction';
  }

  @override
  String get routeManeuverContinue => 'Continue';

  @override
  String get routeManeuverMergeGeneric => 'Merge';

  @override
  String routeManeuverMerge(Object direction) {
    return 'Merge $direction';
  }

  @override
  String get routeManeuverTakeRamp => 'Take the ramp';

  @override
  String get routeManeuverTakeExit => 'Take the exit';

  @override
  String get routeManeuverKeepGeneric => 'Keep course';

  @override
  String routeManeuverKeep(Object direction) {
    return 'Keep $direction';
  }

  @override
  String get routeManeuverEnterRoundabout => 'Enter the roundabout';

  @override
  String routeManeuverOnto(Object action, Object roadName) {
    return '$action onto $roadName';
  }

  @override
  String get routeDirectionUTurn => 'a U-turn';

  @override
  String get routeDirectionSharpRight => 'sharp right';

  @override
  String get routeDirectionRight => 'right';

  @override
  String get routeDirectionSlightRight => 'slight right';

  @override
  String get routeDirectionStraight => 'straight';

  @override
  String get routeDirectionSlightLeft => 'slight left';

  @override
  String get routeDirectionLeft => 'left';

  @override
  String get routeDirectionSharpLeft => 'sharp left';
}
