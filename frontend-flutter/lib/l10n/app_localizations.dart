import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart City Reports'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @commonEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get commonEmail;

  /// No description provided for @commonPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get commonPassword;

  /// No description provided for @commonFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get commonFullName;

  /// No description provided for @commonRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get commonRole;

  /// No description provided for @commonReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get commonReports;

  /// No description provided for @commonMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get commonMap;

  /// No description provided for @commonTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get commonTasks;

  /// No description provided for @commonStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get commonStaff;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get commonLogout;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get commonApprove;

  /// No description provided for @commonDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get commonDeny;

  /// No description provided for @commonAssign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get commonAssign;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get commonTitle;

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get commonCategory;

  /// No description provided for @commonLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get commonLocation;

  /// No description provided for @commonCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get commonCoordinates;

  /// No description provided for @commonAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get commonAddress;

  /// No description provided for @commonLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get commonLatitude;

  /// No description provided for @commonLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get commonLongitude;

  /// No description provided for @commonBeforePhoto.
  ///
  /// In en, this message translates to:
  /// **'Before photo'**
  String get commonBeforePhoto;

  /// No description provided for @commonAfterPhoto.
  ///
  /// In en, this message translates to:
  /// **'After photo'**
  String get commonAfterPhoto;

  /// No description provided for @commonUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get commonUnknownUser;

  /// No description provided for @commonUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get commonUnassigned;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get commonAnonymous;

  /// No description provided for @commonActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActive;

  /// No description provided for @commonInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get commonInactive;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonUnexpectedErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonUnexpectedErrorTitle;

  /// No description provided for @priorityValue.
  ///
  /// In en, this message translates to:
  /// **'Priority {score}'**
  String priorityValue(Object score);

  /// No description provided for @statusValue.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusValue(Object status);

  /// No description provided for @coordinatesValue.
  ///
  /// In en, this message translates to:
  /// **'Coordinates: {latitude}, {longitude}'**
  String coordinatesValue(Object latitude, Object longitude);

  /// No description provided for @upvoteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No upvotes} =1{1 upvote} other{{count} upvotes}}'**
  String upvoteCount(num count);

  /// No description provided for @reportCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reports} =1{1 report} other{{count} reports}}'**
  String reportCount(num count);

  /// No description provided for @taskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks} =1{1 task} other{{count} tasks}}'**
  String taskCount(num count);

  /// No description provided for @roleCitizen.
  ///
  /// In en, this message translates to:
  /// **'Citizen'**
  String get roleCitizen;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get roleStaff;

  /// No description provided for @roleOverseer.
  ///
  /// In en, this message translates to:
  /// **'Overseer'**
  String get roleOverseer;

  /// No description provided for @reportCategoryRoadDamage.
  ///
  /// In en, this message translates to:
  /// **'Road damage'**
  String get reportCategoryRoadDamage;

  /// No description provided for @reportCategoryStreetLight.
  ///
  /// In en, this message translates to:
  /// **'Street light'**
  String get reportCategoryStreetLight;

  /// No description provided for @reportCategoryGarbage.
  ///
  /// In en, this message translates to:
  /// **'Garbage'**
  String get reportCategoryGarbage;

  /// No description provided for @reportCategoryWaterLeak.
  ///
  /// In en, this message translates to:
  /// **'Water leak'**
  String get reportCategoryWaterLeak;

  /// No description provided for @reportCategoryDrainage.
  ///
  /// In en, this message translates to:
  /// **'Drainage'**
  String get reportCategoryDrainage;

  /// No description provided for @reportCategoryTrafficSign.
  ///
  /// In en, this message translates to:
  /// **'Traffic sign'**
  String get reportCategoryTrafficSign;

  /// No description provided for @reportCategoryTreeBlockage.
  ///
  /// In en, this message translates to:
  /// **'Tree blockage'**
  String get reportCategoryTreeBlockage;

  /// No description provided for @reportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportCategoryOther;

  /// No description provided for @reportStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get reportStatusSubmitted;

  /// No description provided for @reportStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get reportStatusInProgress;

  /// No description provided for @reportStatusFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get reportStatusFixed;

  /// No description provided for @reportStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reportStatusCancelled;

  /// No description provided for @taskStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get taskStatusNew;

  /// No description provided for @taskStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get taskStatusAssigned;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskStatusDone;

  /// No description provided for @taskStatusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get taskStatusPendingReview;

  /// No description provided for @taskStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get taskStatusDenied;

  /// No description provided for @taskStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get taskStatusApproved;

  /// No description provided for @taskStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get taskStatusClosed;

  /// No description provided for @taskStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelled;

  /// No description provided for @staffTaskStatusQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get staffTaskStatusQueued;

  /// No description provided for @staffTaskStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get staffTaskStatusAssigned;

  /// No description provided for @staffTaskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get staffTaskStatusInProgress;

  /// No description provided for @staffTaskStatusAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get staffTaskStatusAwaitingReview;

  /// No description provided for @staffTaskStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get staffTaskStatusDenied;

  /// No description provided for @staffTaskStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get staffTaskStatusApproved;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginButton;

  /// No description provided for @authCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountTitle;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountButton;

  /// No description provided for @authBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get authBackToLogin;

  /// No description provided for @authFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get authFullNameRequired;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters'**
  String authPasswordMinLength(Object count);

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to log in. Please try again.'**
  String get authLoginFailed;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create account. Please try again.'**
  String get authRegistrationFailed;

  /// No description provided for @homeMyReports.
  ///
  /// In en, this message translates to:
  /// **'My reports'**
  String get homeMyReports;

  /// No description provided for @homePinsMap.
  ///
  /// In en, this message translates to:
  /// **'Report map'**
  String get homePinsMap;

  /// No description provided for @homeCreateReport.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get homeCreateReport;

  /// No description provided for @homeReportDashboard.
  ///
  /// In en, this message translates to:
  /// **'Report dashboard'**
  String get homeReportDashboard;

  /// No description provided for @homeCityMap.
  ///
  /// In en, this message translates to:
  /// **'City map'**
  String get homeCityMap;

  /// No description provided for @homeCreateUser.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get homeCreateUser;

  /// No description provided for @mapSearchPlacesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search places'**
  String get mapSearchPlacesTooltip;

  /// No description provided for @mapViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Map view'**
  String get mapViewTitle;

  /// No description provided for @reportListViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Report list view'**
  String get reportListViewTitle;

  /// No description provided for @mapRefreshVisibleArea.
  ///
  /// In en, this message translates to:
  /// **'Refresh visible area'**
  String get mapRefreshVisibleArea;

  /// No description provided for @mapAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get mapAllCategories;

  /// No description provided for @mapHideMyReports.
  ///
  /// In en, this message translates to:
  /// **'Hide my reports'**
  String get mapHideMyReports;

  /// No description provided for @mapOpenPinsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load open report pins.'**
  String get mapOpenPinsLoadFailed;

  /// No description provided for @mapSearchedLocation.
  ///
  /// In en, this message translates to:
  /// **'Searched location'**
  String get mapSearchedLocation;

  /// No description provided for @mapSearchedPlace.
  ///
  /// In en, this message translates to:
  /// **'Searched place'**
  String get mapSearchedPlace;

  /// No description provided for @mapNoOpenPins.
  ///
  /// In en, this message translates to:
  /// **'No open report pins in this area'**
  String get mapNoOpenPins;

  /// No description provided for @mapCitizenSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search reports, categories, or addresses…'**
  String get mapCitizenSearchHint;

  /// No description provided for @mapNoSearchMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching reports or addresses found'**
  String get mapNoSearchMatches;

  /// No description provided for @mapReportsHeader.
  ///
  /// In en, this message translates to:
  /// **'REPORTS'**
  String get mapReportsHeader;

  /// No description provided for @mapPlacesHeader.
  ///
  /// In en, this message translates to:
  /// **'ADDRESSES & PLACES'**
  String get mapPlacesHeader;

  /// No description provided for @mapViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get mapViewDetails;

  /// No description provided for @mapRemoveUpvote.
  ///
  /// In en, this message translates to:
  /// **'Remove upvote'**
  String get mapRemoveUpvote;

  /// No description provided for @mapSeeThisToo.
  ///
  /// In en, this message translates to:
  /// **'I see this too'**
  String get mapSeeThisToo;

  /// No description provided for @mapUpvoteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update upvote.'**
  String get mapUpvoteUpdateFailed;

  /// No description provided for @mapCategoryValue.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String mapCategoryValue(Object category);

  /// No description provided for @mapPinLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin location'**
  String get mapPinLocationTitle;

  /// No description provided for @mapConfirmLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get mapConfirmLocationTooltip;

  /// No description provided for @mapPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search address or open reports…'**
  String get mapPickerSearchHint;

  /// No description provided for @mapActiveReportsHeader.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE REPORTS'**
  String get mapActiveReportsHeader;

  /// No description provided for @mapAddressFallback.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get mapAddressFallback;

  /// No description provided for @mapSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get mapSelectedLocation;

  /// No description provided for @mapLoadingAddress.
  ///
  /// In en, this message translates to:
  /// **'Loading address…'**
  String get mapLoadingAddress;

  /// No description provided for @mapConfirmPinnedLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm pinned location'**
  String get mapConfirmPinnedLocation;

  /// No description provided for @reportCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create report'**
  String get reportCreateTitle;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @reportSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get reportSubmittedTitle;

  /// No description provided for @reportCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create report.'**
  String get reportCreateFailed;

  /// No description provided for @reportSubmitFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not submit report'**
  String get reportSubmitFailedTitle;

  /// No description provided for @reportEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit report'**
  String get reportEditTitle;

  /// No description provided for @reportUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Report updated'**
  String get reportUpdatedTitle;

  /// No description provided for @reportUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update report.'**
  String get reportUpdateFailed;

  /// No description provided for @reportUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not update report'**
  String get reportUpdateFailedTitle;

  /// No description provided for @reportLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load report.'**
  String get reportLoadFailed;

  /// No description provided for @reportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reports.'**
  String get reportsLoadFailed;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports yet'**
  String get reportsEmpty;

  /// No description provided for @reportSubmittedOnlyEditable.
  ///
  /// In en, this message translates to:
  /// **'Only submitted reports can be edited.'**
  String get reportSubmittedOnlyEditable;

  /// No description provided for @reportSubmittedOnlyTaskable.
  ///
  /// In en, this message translates to:
  /// **'Only submitted reports can be turned into tasks.'**
  String get reportSubmittedOnlyTaskable;

  /// No description provided for @reportDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportDetailsTitle;

  /// No description provided for @reportCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Report cancelled'**
  String get reportCancelledTitle;

  /// No description provided for @reportCancelFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel report'**
  String get reportCancelFailedTitle;

  /// No description provided for @reportSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get reportSubmittedAt;

  /// No description provided for @reportLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get reportLastUpdated;

  /// No description provided for @reportReporter.
  ///
  /// In en, this message translates to:
  /// **'Reporter'**
  String get reportReporter;

  /// No description provided for @reportCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get reportCreatedBy;

  /// No description provided for @reportId.
  ///
  /// In en, this message translates to:
  /// **'Report ID'**
  String get reportId;

  /// No description provided for @reportSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get reportSaveChanges;

  /// No description provided for @reportSubmitAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Submit anonymously'**
  String get reportSubmitAnonymously;

  /// No description provided for @beforePhotoRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Upload a before photo first'**
  String get beforePhotoRequiredError;

  /// No description provided for @beforePhotoRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Before photo required'**
  String get beforePhotoRequiredTitle;

  /// No description provided for @beforePhotoRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo before submitting the report.'**
  String get beforePhotoRequiredMessage;

  /// No description provided for @beforePhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Before photo uploaded'**
  String get beforePhotoUploaded;

  /// No description provided for @beforePhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload before photo.'**
  String get beforePhotoUploadFailed;

  /// No description provided for @photoUploadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed'**
  String get photoUploadFailedTitle;

  /// No description provided for @photoUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload photo'**
  String get photoUpload;

  /// No description provided for @photoReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace photo'**
  String get photoReplace;

  /// No description provided for @photoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Photo not available'**
  String get photoNotAvailable;

  /// No description provided for @reportLocationSelection.
  ///
  /// In en, this message translates to:
  /// **'Location selection'**
  String get reportLocationSelection;

  /// No description provided for @reportSelectLocationMap.
  ///
  /// In en, this message translates to:
  /// **'Select location on map'**
  String get reportSelectLocationMap;

  /// No description provided for @validationLatitudeRange.
  ///
  /// In en, this message translates to:
  /// **'Use -90 to 90'**
  String get validationLatitudeRange;

  /// No description provided for @validationLongitudeRange.
  ///
  /// In en, this message translates to:
  /// **'Use -180 to 180'**
  String get validationLongitudeRange;

  /// No description provided for @validationNumber.
  ///
  /// In en, this message translates to:
  /// **'Use a number'**
  String get validationNumber;

  /// No description provided for @selectedReportCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 report selected} other{{count} reports selected}}'**
  String selectedReportCount(num count);

  /// No description provided for @taskCreate.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get taskCreate;

  /// No description provided for @taskCreateFromReport.
  ///
  /// In en, this message translates to:
  /// **'Create task from report'**
  String get taskCreateFromReport;

  /// No description provided for @overseerReportFixed.
  ///
  /// In en, this message translates to:
  /// **'Report marked as fixed'**
  String get overseerReportFixed;

  /// No description provided for @overseerReportUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update report: {error}'**
  String overseerReportUpdateFailed(Object error);

  /// No description provided for @reportMarkFixed.
  ///
  /// In en, this message translates to:
  /// **'Mark fixed'**
  String get reportMarkFixed;

  /// No description provided for @reportCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel report'**
  String get reportCancel;

  /// No description provided for @reportNoPhotoUrl.
  ///
  /// In en, this message translates to:
  /// **'No photo URL'**
  String get reportNoPhotoUrl;

  /// No description provided for @taskOnlySubmittedReports.
  ///
  /// In en, this message translates to:
  /// **'Only submitted reports can be turned into tasks.'**
  String get taskOnlySubmittedReports;

  /// No description provided for @mapAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get mapAllStatuses;

  /// No description provided for @mapAllPriorities.
  ///
  /// In en, this message translates to:
  /// **'All priorities'**
  String get mapAllPriorities;

  /// No description provided for @mapMinimumPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority ≥ {score}'**
  String mapMinimumPriority(Object score);

  /// No description provided for @mapCreateRepairTask.
  ///
  /// In en, this message translates to:
  /// **'Create repair task'**
  String get mapCreateRepairTask;

  /// No description provided for @mapMetricVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get mapMetricVisible;

  /// No description provided for @mapMetricHighPriority.
  ///
  /// In en, this message translates to:
  /// **'High priority'**
  String get mapMetricHighPriority;

  /// No description provided for @mapMetricAveragePriority.
  ///
  /// In en, this message translates to:
  /// **'Avg priority'**
  String get mapMetricAveragePriority;

  /// No description provided for @mapMetricTopCategory.
  ///
  /// In en, this message translates to:
  /// **'Top category'**
  String get mapMetricTopCategory;

  /// No description provided for @mapMetricClosedOut.
  ///
  /// In en, this message translates to:
  /// **'Closed out'**
  String get mapMetricClosedOut;

  /// No description provided for @mapOperationsQueue.
  ///
  /// In en, this message translates to:
  /// **'Operations queue'**
  String get mapOperationsQueue;

  /// No description provided for @mapSelectMultipleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select multiple for task'**
  String get mapSelectMultipleTooltip;

  /// No description provided for @mapNoReportsInView.
  ///
  /// In en, this message translates to:
  /// **'No reports in view'**
  String get mapNoReportsInView;

  /// No description provided for @mapTableCategory.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get mapTableCategory;

  /// No description provided for @mapTableReport.
  ///
  /// In en, this message translates to:
  /// **'REPORT'**
  String get mapTableReport;

  /// No description provided for @mapTableStatus.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get mapTableStatus;

  /// No description provided for @mapTablePriority.
  ///
  /// In en, this message translates to:
  /// **'PRI'**
  String get mapTablePriority;

  /// No description provided for @mapTableVotes.
  ///
  /// In en, this message translates to:
  /// **'VOTES'**
  String get mapTableVotes;

  /// No description provided for @mapTaskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Task unavailable'**
  String get mapTaskUnavailable;

  /// No description provided for @mapOverseerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search reports or addresses…'**
  String get mapOverseerSearchHint;

  /// No description provided for @mapCategoryAndStatus.
  ///
  /// In en, this message translates to:
  /// **'{category} — {status}'**
  String mapCategoryAndStatus(Object category, Object status);

  /// No description provided for @mapViewFullDetails.
  ///
  /// In en, this message translates to:
  /// **'View full details'**
  String get mapViewFullDetails;

  /// No description provided for @mapMarkFixed.
  ///
  /// In en, this message translates to:
  /// **'Mark fixed'**
  String get mapMarkFixed;

  /// No description provided for @taskQueueTitle.
  ///
  /// In en, this message translates to:
  /// **'Task queue'**
  String get taskQueueTitle;

  /// No description provided for @taskAllStatuses.
  ///
  /// In en, this message translates to:
  /// **'All statuses'**
  String get taskAllStatuses;

  /// No description provided for @tasksLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load tasks.'**
  String get tasksLoadFailed;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmpty;

  /// No description provided for @tasksNoStatusMatches.
  ///
  /// In en, this message translates to:
  /// **'No tasks match this status'**
  String get tasksNoStatusMatches;

  /// No description provided for @taskCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get taskCreateTitle;

  /// No description provided for @taskEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEditTitle;

  /// No description provided for @taskCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task created'**
  String get taskCreatedTitle;

  /// No description provided for @taskUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task updated'**
  String get taskUpdatedTitle;

  /// No description provided for @taskCreateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not create task'**
  String get taskCreateFailedTitle;

  /// No description provided for @taskUpdateFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not update task'**
  String get taskUpdateFailedTitle;

  /// No description provided for @taskSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save task.'**
  String get taskSaveFailed;

  /// No description provided for @taskNoReportsSelected.
  ///
  /// In en, this message translates to:
  /// **'No reports were selected.'**
  String get taskNoReportsSelected;

  /// No description provided for @taskLinkedReportsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load linked reports.'**
  String get taskLinkedReportsLoadFailed;

  /// No description provided for @taskUnavailableReports.
  ///
  /// In en, this message translates to:
  /// **'Only submitted reports can be used to create a task. Already handled: {reports}'**
  String taskUnavailableReports(Object reports);

  /// No description provided for @taskNoActiveStaff.
  ///
  /// In en, this message translates to:
  /// **'No active staff users found.'**
  String get taskNoActiveStaff;

  /// No description provided for @taskBrief.
  ///
  /// In en, this message translates to:
  /// **'Task brief'**
  String get taskBrief;

  /// No description provided for @taskData.
  ///
  /// In en, this message translates to:
  /// **'Task data'**
  String get taskData;

  /// No description provided for @taskNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'No photo'**
  String get taskNoPhoto;

  /// No description provided for @taskReportPhoto.
  ///
  /// In en, this message translates to:
  /// **'Report photo'**
  String get taskReportPhoto;

  /// No description provided for @taskAssignedStaff.
  ///
  /// In en, this message translates to:
  /// **'Assigned staff'**
  String get taskAssignedStaff;

  /// No description provided for @taskCompletedBy.
  ///
  /// In en, this message translates to:
  /// **'Completed by'**
  String get taskCompletedBy;

  /// No description provided for @taskCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by overseer'**
  String get taskCreatedBy;

  /// No description provided for @taskCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get taskCreatedAt;

  /// No description provided for @taskStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Started at'**
  String get taskStartedAt;

  /// No description provided for @taskSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted at'**
  String get taskSubmittedAt;

  /// No description provided for @taskReviewedAt.
  ///
  /// In en, this message translates to:
  /// **'Reviewed at'**
  String get taskReviewedAt;

  /// No description provided for @taskClosedAt.
  ///
  /// In en, this message translates to:
  /// **'Closed at'**
  String get taskClosedAt;

  /// No description provided for @taskReportIds.
  ///
  /// In en, this message translates to:
  /// **'Report IDs'**
  String get taskReportIds;

  /// No description provided for @validationWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Use a whole number'**
  String get validationWholeNumber;

  /// No description provided for @validationNonnegative.
  ///
  /// In en, this message translates to:
  /// **'Use 0 or higher'**
  String get validationNonnegative;

  /// No description provided for @validationOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get validationOutOfRange;

  /// No description provided for @taskDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Task details'**
  String get taskDetailsTitle;

  /// No description provided for @taskApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task approved'**
  String get taskApprovedTitle;

  /// No description provided for @taskDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task completion denied'**
  String get taskDeniedTitle;

  /// No description provided for @taskDenyTitle.
  ///
  /// In en, this message translates to:
  /// **'Deny task completion'**
  String get taskDenyTitle;

  /// No description provided for @taskDenyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Write what the staff member must redo. This note will replace the task description.'**
  String get taskDenyPrompt;

  /// No description provided for @taskDenyNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Rework note'**
  String get taskDenyNoteLabel;

  /// No description provided for @taskDenyNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a rework note'**
  String get taskDenyNoteRequired;

  /// No description provided for @taskReworkInstructions.
  ///
  /// In en, this message translates to:
  /// **'Rework instructions'**
  String get taskReworkInstructions;

  /// No description provided for @taskClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task closed'**
  String get taskClosedTitle;

  /// No description provided for @taskDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get taskDeleteQuestion;

  /// No description provided for @taskDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete “{title}” and unlink its reports.'**
  String taskDeleteWarning(Object title);

  /// No description provided for @taskKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep task'**
  String get taskKeep;

  /// No description provided for @taskDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get taskDeletedTitle;

  /// No description provided for @taskDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete task.'**
  String get taskDeleteFailed;

  /// No description provided for @taskUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update task.'**
  String get taskUpdateFailed;

  /// No description provided for @taskLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load task.'**
  String get taskLoadFailed;

  /// No description provided for @taskStaffNote.
  ///
  /// In en, this message translates to:
  /// **'Staff note'**
  String get taskStaffNote;

  /// No description provided for @taskReviewEvidence.
  ///
  /// In en, this message translates to:
  /// **'Review evidence'**
  String get taskReviewEvidence;

  /// No description provided for @taskNoBeforePhoto.
  ///
  /// In en, this message translates to:
  /// **'No before photo uploaded'**
  String get taskNoBeforePhoto;

  /// No description provided for @taskNoAfterPhoto.
  ///
  /// In en, this message translates to:
  /// **'No after photo uploaded'**
  String get taskNoAfterPhoto;

  /// No description provided for @staffMyTasksTitle.
  ///
  /// In en, this message translates to:
  /// **'My tasks'**
  String get staffMyTasksTitle;

  /// No description provided for @staffAssignedToYou.
  ///
  /// In en, this message translates to:
  /// **'Assigned to you'**
  String get staffAssignedToYou;

  /// No description provided for @staffInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get staffInProgress;

  /// No description provided for @staffReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get staffReview;

  /// No description provided for @staffApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get staffApproved;

  /// No description provided for @staffTopPriority.
  ///
  /// In en, this message translates to:
  /// **'Top priority'**
  String get staffTopPriority;

  /// No description provided for @staffReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get staffReady;

  /// No description provided for @staffNoTaskLocations.
  ///
  /// In en, this message translates to:
  /// **'No task locations'**
  String get staffNoTaskLocations;

  /// No description provided for @staffTaskQueue.
  ///
  /// In en, this message translates to:
  /// **'Task queue'**
  String get staffTaskQueue;

  /// No description provided for @staffNoAssignedTasks.
  ///
  /// In en, this message translates to:
  /// **'No assigned tasks yet.'**
  String get staffNoAssignedTasks;

  /// No description provided for @staffTaskSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tasks by title, area, or category...'**
  String get staffTaskSearchHint;

  /// No description provided for @staffTaskSort.
  ///
  /// In en, this message translates to:
  /// **'Sort tasks'**
  String get staffTaskSort;

  /// No description provided for @staffTaskSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get staffTaskSortNewest;

  /// No description provided for @staffTaskSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get staffTaskSortOldest;

  /// No description provided for @staffTaskSortPriority.
  ///
  /// In en, this message translates to:
  /// **'Most priority'**
  String get staffTaskSortPriority;

  /// No description provided for @staffNoTaskMatches.
  ///
  /// In en, this message translates to:
  /// **'No tasks match your search.'**
  String get staffNoTaskMatches;

  /// No description provided for @staffHideReports.
  ///
  /// In en, this message translates to:
  /// **'Hide reports'**
  String get staffHideReports;

  /// No description provided for @staffShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get staffShowOnMap;

  /// No description provided for @staffTaskStarted.
  ///
  /// In en, this message translates to:
  /// **'{title} started'**
  String staffTaskStarted(Object title);

  /// No description provided for @staffStartTask.
  ///
  /// In en, this message translates to:
  /// **'Start task'**
  String get staffStartTask;

  /// No description provided for @staffRedoTask.
  ///
  /// In en, this message translates to:
  /// **'Start rework'**
  String get staffRedoTask;

  /// No description provided for @staffRouteMap.
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get staffRouteMap;

  /// No description provided for @staffCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Complete task'**
  String get staffCompleteTask;

  /// No description provided for @staffNoLinkedReportDetails.
  ///
  /// In en, this message translates to:
  /// **'No linked report details found.'**
  String get staffNoLinkedReportDetails;

  /// No description provided for @staffTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'{title} completed'**
  String staffTaskCompleted(Object title);

  /// No description provided for @staffAfterPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Upload an after photo first'**
  String get staffAfterPhotoRequired;

  /// No description provided for @staffAfterPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'After photo uploaded'**
  String get staffAfterPhotoUploaded;

  /// No description provided for @staffAfterPhotoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to upload after photo.'**
  String get staffAfterPhotoUploadFailed;

  /// No description provided for @validationMaximumCharacters.
  ///
  /// In en, this message translates to:
  /// **'Use {maxLength} characters or fewer'**
  String validationMaximumCharacters(Object maxLength);

  /// No description provided for @routeMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get routeMapTitle;

  /// No description provided for @routeUsingTaskAddress.
  ///
  /// In en, this message translates to:
  /// **'Using the task address as the route start.'**
  String get routeUsingTaskAddress;

  /// No description provided for @routeAddressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Address not found locally. Try a linked report address or latitude,longitude.'**
  String get routeAddressNotFound;

  /// No description provided for @routeStartsFrom.
  ///
  /// In en, this message translates to:
  /// **'Route starts from {location}.'**
  String routeStartsFrom(Object location);

  /// No description provided for @routeCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'Current address'**
  String get routeCurrentAddress;

  /// No description provided for @routeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current address, e.g. bus stop near Lê Lợi'**
  String get routeAddressHint;

  /// No description provided for @routeFromAddress.
  ///
  /// In en, this message translates to:
  /// **'Route from address'**
  String get routeFromAddress;

  /// No description provided for @routeUseTaskAddress.
  ///
  /// In en, this message translates to:
  /// **'Use task address'**
  String get routeUseTaskAddress;

  /// No description provided for @routeKnownAddressesHelp.
  ///
  /// In en, this message translates to:
  /// **'Known task/report addresses and latitude,longitude are supported.'**
  String get routeKnownAddressesHelp;

  /// No description provided for @routeVisitOrder.
  ///
  /// In en, this message translates to:
  /// **'Visit order'**
  String get routeVisitOrder;

  /// No description provided for @routeNoStops.
  ///
  /// In en, this message translates to:
  /// **'No linked report stops.'**
  String get routeNoStops;

  /// No description provided for @routeDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get routeDirections;

  /// No description provided for @routeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load route map.'**
  String get routeLoadFailed;

  /// No description provided for @routeStartMarker.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get routeStartMarker;

  /// No description provided for @routeSummary.
  ///
  /// In en, this message translates to:
  /// **'From {start} — {count, plural, =1{1 stop} other{{count} stops}} — {distance}'**
  String routeSummary(num count, Object distance, Object start);

  /// No description provided for @userCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create user'**
  String get userCreateTitle;

  /// No description provided for @userCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {name}'**
  String userCreated(Object name);

  /// No description provided for @userCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to create user right now.'**
  String get userCreateFailed;

  /// No description provided for @userPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters'**
  String userPasswordMinLength(Object count);

  /// No description provided for @staffActiveMetric.
  ///
  /// In en, this message translates to:
  /// **'Active staff'**
  String get staffActiveMetric;

  /// No description provided for @staffInactiveMetric.
  ///
  /// In en, this message translates to:
  /// **'Inactive staff'**
  String get staffInactiveMetric;

  /// No description provided for @staffOngoingTasksMetric.
  ///
  /// In en, this message translates to:
  /// **'Ongoing tasks'**
  String get staffOngoingTasksMetric;

  /// No description provided for @staffCompletedTasksMetric.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks'**
  String get staffCompletedTasksMetric;

  /// No description provided for @staffSummariesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load staff summaries.'**
  String get staffSummariesLoadFailed;

  /// No description provided for @staffEmpty.
  ///
  /// In en, this message translates to:
  /// **'No staff members registered yet'**
  String get staffEmpty;

  /// No description provided for @staffActiveTasksHeader.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE TASKS'**
  String get staffActiveTasksHeader;

  /// No description provided for @staffCompletedTasksHeader.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED TASKS'**
  String get staffCompletedTasksHeader;

  /// No description provided for @staffNoAssignedTasksForMember.
  ///
  /// In en, this message translates to:
  /// **'No tasks assigned to this staff member.'**
  String get staffNoAssignedTasksForMember;

  /// No description provided for @staffAssignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String staffAssignedTo(Object name);

  /// No description provided for @staffUsersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load staff users.'**
  String get staffUsersLoadFailed;

  /// No description provided for @taskLinkedReports.
  ///
  /// In en, this message translates to:
  /// **'Linked reports'**
  String get taskLinkedReports;

  /// No description provided for @taskPriorityScore.
  ///
  /// In en, this message translates to:
  /// **'Priority score'**
  String get taskPriorityScore;

  /// No description provided for @commonList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get commonList;

  /// No description provided for @reportCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to cancel report.'**
  String get reportCancelFailed;

  /// No description provided for @staffTaskMarkerLabel.
  ///
  /// In en, this message translates to:
  /// **'Task {number} {title}'**
  String staffTaskMarkerLabel(Object number, Object title);

  /// No description provided for @staffActiveTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String staffActiveTaskCount(Object count);

  /// No description provided for @staffCompletedTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String staffCompletedTaskCount(Object count);

  /// No description provided for @routeManeuverHeadOut.
  ///
  /// In en, this message translates to:
  /// **'Head out'**
  String get routeManeuverHeadOut;

  /// No description provided for @routeManeuverArrive.
  ///
  /// In en, this message translates to:
  /// **'Arrive'**
  String get routeManeuverArrive;

  /// No description provided for @routeManeuverTurnGeneric.
  ///
  /// In en, this message translates to:
  /// **'Turn'**
  String get routeManeuverTurnGeneric;

  /// No description provided for @routeManeuverTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn {direction}'**
  String routeManeuverTurn(Object direction);

  /// No description provided for @routeManeuverContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get routeManeuverContinue;

  /// No description provided for @routeManeuverMergeGeneric.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get routeManeuverMergeGeneric;

  /// No description provided for @routeManeuverMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge {direction}'**
  String routeManeuverMerge(Object direction);

  /// No description provided for @routeManeuverTakeRamp.
  ///
  /// In en, this message translates to:
  /// **'Take the ramp'**
  String get routeManeuverTakeRamp;

  /// No description provided for @routeManeuverTakeExit.
  ///
  /// In en, this message translates to:
  /// **'Take the exit'**
  String get routeManeuverTakeExit;

  /// No description provided for @routeManeuverKeepGeneric.
  ///
  /// In en, this message translates to:
  /// **'Keep course'**
  String get routeManeuverKeepGeneric;

  /// No description provided for @routeManeuverKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep {direction}'**
  String routeManeuverKeep(Object direction);

  /// No description provided for @routeManeuverEnterRoundabout.
  ///
  /// In en, this message translates to:
  /// **'Enter the roundabout'**
  String get routeManeuverEnterRoundabout;

  /// No description provided for @routeManeuverOnto.
  ///
  /// In en, this message translates to:
  /// **'{action} onto {roadName}'**
  String routeManeuverOnto(Object action, Object roadName);

  /// No description provided for @routeDirectionUTurn.
  ///
  /// In en, this message translates to:
  /// **'a U-turn'**
  String get routeDirectionUTurn;

  /// No description provided for @routeDirectionSharpRight.
  ///
  /// In en, this message translates to:
  /// **'sharp right'**
  String get routeDirectionSharpRight;

  /// No description provided for @routeDirectionRight.
  ///
  /// In en, this message translates to:
  /// **'right'**
  String get routeDirectionRight;

  /// No description provided for @routeDirectionSlightRight.
  ///
  /// In en, this message translates to:
  /// **'slight right'**
  String get routeDirectionSlightRight;

  /// No description provided for @routeDirectionStraight.
  ///
  /// In en, this message translates to:
  /// **'straight'**
  String get routeDirectionStraight;

  /// No description provided for @routeDirectionSlightLeft.
  ///
  /// In en, this message translates to:
  /// **'slight left'**
  String get routeDirectionSlightLeft;

  /// No description provided for @routeDirectionLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get routeDirectionLeft;

  /// No description provided for @routeDirectionSharpLeft.
  ///
  /// In en, this message translates to:
  /// **'sharp left'**
  String get routeDirectionSharpLeft;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
