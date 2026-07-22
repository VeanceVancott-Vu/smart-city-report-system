// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Phản ánh đô thị thông minh';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonPassword => 'Mật khẩu';

  @override
  String get commonFullName => 'Họ và tên';

  @override
  String get commonRole => 'Vai trò';

  @override
  String get commonReports => 'Báo cáo';

  @override
  String get commonMap => 'Bản đồ';

  @override
  String get commonTasks => 'Công việc';

  @override
  String get commonStaff => 'Nhân viên';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get commonRefresh => 'Làm mới';

  @override
  String get commonLogout => 'Đăng xuất';

  @override
  String get commonEdit => 'Chỉnh sửa';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonApprove => 'Phê duyệt';

  @override
  String get commonDeny => 'Từ chối';

  @override
  String get commonAssign => 'Phân công';

  @override
  String get commonOpen => 'Mở';

  @override
  String get commonRequired => 'Bắt buộc';

  @override
  String get commonTitle => 'Tiêu đề';

  @override
  String get commonDescription => 'Mô tả';

  @override
  String get commonCategory => 'Danh mục';

  @override
  String get commonLocation => 'Vị trí';

  @override
  String get commonCoordinates => 'Tọa độ';

  @override
  String get commonAddress => 'Địa chỉ';

  @override
  String get commonLatitude => 'Vĩ độ';

  @override
  String get commonLongitude => 'Kinh độ';

  @override
  String get commonBeforePhoto => 'Ảnh trước khi xử lý';

  @override
  String get commonAfterPhoto => 'Ảnh sau khi xử lý';

  @override
  String get commonUnknownUser => 'Người dùng không xác định';

  @override
  String get commonUnassigned => 'Chưa phân công';

  @override
  String get commonNone => 'Không có';

  @override
  String get commonAnonymous => 'Ẩn danh';

  @override
  String get commonActive => 'Đang hoạt động';

  @override
  String get commonInactive => 'Ngừng hoạt động';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonSearch => 'Tìm kiếm';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get commonUnexpectedErrorTitle => 'Đã xảy ra lỗi';

  @override
  String priorityValue(Object score) {
    return 'Ưu tiên $score';
  }

  @override
  String statusValue(Object status) {
    return 'Trạng thái: $status';
  }

  @override
  String coordinatesValue(Object latitude, Object longitude) {
    return 'Tọa độ: $latitude, $longitude';
  }

  @override
  String upvoteCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt đồng tình',
      zero: 'Chưa có lượt đồng tình',
    );
    return '$_temp0';
  }

  @override
  String reportCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count báo cáo',
      zero: 'Không có báo cáo',
    );
    return '$_temp0';
  }

  @override
  String taskCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count công việc',
      zero: 'Không có công việc',
    );
    return '$_temp0';
  }

  @override
  String get roleCitizen => 'Người dân';

  @override
  String get roleStaff => 'Nhân viên';

  @override
  String get roleOverseer => 'Giám sát viên';

  @override
  String get reportCategoryRoadDamage => 'Hư hỏng đường';

  @override
  String get reportCategoryStreetLight => 'Đèn đường';

  @override
  String get reportCategoryGarbage => 'Rác thải';

  @override
  String get reportCategoryWaterLeak => 'Rò rỉ nước';

  @override
  String get reportCategoryDrainage => 'Thoát nước';

  @override
  String get reportCategoryTrafficSign => 'Biển báo giao thông';

  @override
  String get reportCategoryTreeBlockage => 'Cây chắn đường';

  @override
  String get reportCategoryOther => 'Khác';

  @override
  String get reportStatusSubmitted => 'Đã gửi';

  @override
  String get reportStatusInProgress => 'Đang xử lý';

  @override
  String get reportStatusFixed => 'Đã khắc phục';

  @override
  String get reportStatusCancelled => 'Đã hủy';

  @override
  String get taskStatusNew => 'Mới';

  @override
  String get taskStatusAssigned => 'Đã phân công';

  @override
  String get taskStatusInProgress => 'Đang thực hiện';

  @override
  String get taskStatusDone => 'Đã hoàn thành';

  @override
  String get taskStatusPendingReview => 'Chờ duyệt';

  @override
  String get taskStatusDenied => 'Bị từ chối';

  @override
  String get taskStatusApproved => 'Đã phê duyệt';

  @override
  String get taskStatusClosed => 'Đã đóng';

  @override
  String get taskStatusCancelled => 'Đã hủy';

  @override
  String get staffTaskStatusQueued => 'Trong hàng đợi';

  @override
  String get staffTaskStatusAssigned => 'Đã phân công';

  @override
  String get staffTaskStatusInProgress => 'Đang thực hiện';

  @override
  String get staffTaskStatusAwaitingReview => 'Đang chờ duyệt';

  @override
  String get staffTaskStatusDenied => 'Bị từ chối';

  @override
  String get staffTaskStatusApproved => 'Đã phê duyệt';

  @override
  String get authLoginButton => 'Đăng nhập';

  @override
  String get authCreateAccountTitle => 'Tạo tài khoản';

  @override
  String get authCreateAccountButton => 'Tạo tài khoản';

  @override
  String get authBackToLogin => 'Quay lại đăng nhập';

  @override
  String get authFullNameRequired => 'Vui lòng nhập họ và tên';

  @override
  String get authEmailRequired => 'Vui lòng nhập email';

  @override
  String get authEmailInvalid => 'Nhập email hợp lệ';

  @override
  String get authPasswordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String authPasswordMinLength(Object count) {
    return 'Dùng ít nhất $count ký tự';
  }

  @override
  String get authLoginFailed => 'Không thể đăng nhập. Vui lòng thử lại.';

  @override
  String get authRegistrationFailed =>
      'Không thể tạo tài khoản. Vui lòng thử lại.';

  @override
  String get homeMyReports => 'Báo cáo của tôi';

  @override
  String get homePinsMap => 'Bản đồ báo cáo';

  @override
  String get homeCreateReport => 'Báo cáo sự cố';

  @override
  String get homeReportDashboard => 'Bảng điều khiển báo cáo';

  @override
  String get homeCityMap => 'Bản đồ thành phố';

  @override
  String get homeCreateUser => 'Tạo người dùng';

  @override
  String get mapSearchPlacesTooltip => 'Tìm địa điểm';

  @override
  String get mapViewTitle => 'Chế độ bản đồ';

  @override
  String get reportListViewTitle => 'Chế độ danh sách';

  @override
  String get mapRefreshVisibleArea => 'Làm mới khu vực đang hiển thị';

  @override
  String get mapAllCategories => 'Tất cả danh mục';

  @override
  String get mapHideMyReports => 'Ẩn báo cáo của tôi';

  @override
  String get mapOpenPinsLoadFailed => 'Không thể tải các điểm báo cáo đang mở.';

  @override
  String get mapSearchedLocation => 'Vị trí đã tìm';

  @override
  String get mapSearchedPlace => 'Địa điểm đã tìm';

  @override
  String get mapNoOpenPins => 'Không có báo cáo đang mở trong khu vực này';

  @override
  String get mapCitizenSearchHint => 'Tìm báo cáo, danh mục hoặc địa chỉ…';

  @override
  String get mapNoSearchMatches =>
      'Không tìm thấy báo cáo hoặc địa chỉ phù hợp';

  @override
  String get mapReportsHeader => 'BÁO CÁO';

  @override
  String get mapPlacesHeader => 'ĐỊA CHỈ VÀ ĐỊA ĐIỂM';

  @override
  String get mapViewDetails => 'Xem chi tiết';

  @override
  String get mapRemoveUpvote => 'Bỏ đồng tình';

  @override
  String get mapSeeThisToo => 'Tôi cũng thấy vấn đề này';

  @override
  String get mapUpvoteUpdateFailed => 'Không thể cập nhật lượt đồng tình.';

  @override
  String mapCategoryValue(Object category) {
    return 'Danh mục: $category';
  }

  @override
  String get mapPinLocationTitle => 'Ghim vị trí';

  @override
  String get mapConfirmLocationTooltip => 'Xác nhận vị trí';

  @override
  String get mapPickerSearchHint => 'Tìm địa chỉ hoặc địa điểm…';

  @override
  String get mapActiveReportsHeader => 'BÁO CÁO ĐANG HOẠT ĐỘNG';

  @override
  String get mapAddressFallback => 'Địa chỉ';

  @override
  String get mapSelectedLocation => 'Vị trí đã chọn';

  @override
  String get mapLoadingAddress => 'Đang tải địa chỉ…';

  @override
  String get mapConfirmPinnedLocation => 'Dùng vị trí này';

  @override
  String get reportCreateTitle => 'Tạo báo cáo';

  @override
  String get reportSubmit => 'Gửi báo cáo';

  @override
  String get reportSubmittedTitle => 'Đã gửi báo cáo';

  @override
  String get reportCreateFailed => 'Không thể tạo báo cáo.';

  @override
  String get reportSubmitFailedTitle => 'Không thể gửi báo cáo';

  @override
  String get reportEditTitle => 'Chỉnh sửa báo cáo';

  @override
  String get reportUpdatedTitle => 'Đã cập nhật báo cáo';

  @override
  String get reportUpdateFailed => 'Không thể cập nhật báo cáo.';

  @override
  String get reportUpdateFailedTitle => 'Không thể cập nhật báo cáo';

  @override
  String get reportLoadFailed => 'Không thể tải báo cáo.';

  @override
  String get reportsLoadFailed => 'Không thể tải danh sách báo cáo.';

  @override
  String get reportsEmpty => 'Chưa có báo cáo';

  @override
  String get reportSubmittedOnlyEditable =>
      'Chỉ báo cáo đã gửi mới có thể chỉnh sửa.';

  @override
  String get reportSubmittedOnlyTaskable =>
      'Chỉ báo cáo đã gửi mới có thể chuyển thành công việc.';

  @override
  String get reportDetailsTitle => 'Chi tiết báo cáo';

  @override
  String get reportCancelledTitle => 'Đã hủy báo cáo';

  @override
  String get reportCancelFailedTitle => 'Không thể hủy báo cáo';

  @override
  String get reportSubmittedAt => 'Thời gian gửi';

  @override
  String get reportLastUpdated => 'Cập nhật lần cuối';

  @override
  String get reportReporter => 'Người báo cáo';

  @override
  String get reportCreatedBy => 'Người tạo';

  @override
  String get reportId => 'Mã báo cáo';

  @override
  String get reportSaveChanges => 'Lưu thay đổi';

  @override
  String get reportSubmitAnonymously => 'Gửi ẩn danh';

  @override
  String get beforePhotoRequiredError => 'Hãy tải ảnh trước khi xử lý lên';

  @override
  String get beforePhotoRequiredTitle => 'Cần ảnh trước khi xử lý';

  @override
  String get beforePhotoRequiredMessage =>
      'Hãy tải ảnh lên trước khi gửi báo cáo.';

  @override
  String get beforePhotoUploaded => 'Đã tải ảnh trước khi xử lý';

  @override
  String get beforePhotoUploadFailed => 'Không thể tải ảnh trước khi xử lý.';

  @override
  String get photoUploadFailedTitle => 'Tải ảnh thất bại';

  @override
  String get photoUpload => 'Tải ảnh lên';

  @override
  String get photoReplace => 'Thay ảnh';

  @override
  String get photoNotAvailable => 'Không có ảnh';

  @override
  String get reportLocationSelection => 'Chọn vị trí';

  @override
  String get reportSelectLocationMap => 'Chọn vị trí trên bản đồ';

  @override
  String get validationLatitudeRange => 'Nhập giá trị từ -90 đến 90';

  @override
  String get validationLongitudeRange => 'Nhập giá trị từ -180 đến 180';

  @override
  String get validationNumber => 'Hãy nhập số';

  @override
  String selectedReportCount(num count) {
    return 'Đã chọn $count báo cáo';
  }

  @override
  String get taskCreate => 'Tạo công việc';

  @override
  String get taskCreateFromReport => 'Tạo công việc từ báo cáo';

  @override
  String get overseerReportFixed => 'Đã đánh dấu báo cáo là đã khắc phục';

  @override
  String overseerReportUpdateFailed(Object error) {
    return 'Không thể cập nhật báo cáo: $error';
  }

  @override
  String get reportMarkFixed => 'Đánh dấu đã khắc phục';

  @override
  String get reportCancel => 'Hủy báo cáo';

  @override
  String get reportNoPhotoUrl => 'Không có đường dẫn ảnh';

  @override
  String get taskOnlySubmittedReports =>
      'Chỉ báo cáo đã gửi mới có thể chuyển thành công việc.';

  @override
  String get mapAllStatuses => 'Tất cả trạng thái';

  @override
  String get mapAllPriorities => 'Tất cả mức ưu tiên';

  @override
  String mapMinimumPriority(Object score) {
    return 'Ưu tiên ≥ $score';
  }

  @override
  String get mapCreateRepairTask => 'Tạo công việc sửa chữa';

  @override
  String get mapMetricVisible => 'Đang hiển thị';

  @override
  String get mapMetricHighPriority => 'Ưu tiên cao';

  @override
  String get mapMetricAveragePriority => 'Ưu tiên TB';

  @override
  String get mapMetricTopCategory => 'Danh mục nổi bật';

  @override
  String get mapMetricClosedOut => 'Đã xử lý';

  @override
  String get mapOperationsQueue => 'Hàng đợi xử lý';

  @override
  String get mapSelectMultipleTooltip => 'Chọn nhiều báo cáo để tạo công việc';

  @override
  String get mapNoReportsInView => 'Không có báo cáo trong vùng hiển thị';

  @override
  String get mapTableCategory => 'DANH MỤC';

  @override
  String get mapTableReport => 'BÁO CÁO';

  @override
  String get mapTableStatus => 'TRẠNG THÁI';

  @override
  String get mapTablePriority => 'ƯU TIÊN';

  @override
  String get mapTableVotes => 'LƯỢT BÌNH CHỌN';

  @override
  String get mapTaskUnavailable => 'Không thể tạo công việc';

  @override
  String get mapOverseerSearchHint => 'Tìm báo cáo hoặc địa chỉ…';

  @override
  String mapCategoryAndStatus(Object category, Object status) {
    return '$category — $status';
  }

  @override
  String get mapViewFullDetails => 'Xem đầy đủ thông tin';

  @override
  String get mapMarkFixed => 'Đánh dấu đã khắc phục';

  @override
  String get taskQueueTitle => 'Hàng đợi công việc';

  @override
  String get taskAllStatuses => 'Tất cả trạng thái';

  @override
  String get tasksLoadFailed => 'Không thể tải danh sách công việc.';

  @override
  String get tasksEmpty => 'Chưa có công việc';

  @override
  String get tasksNoStatusMatches =>
      'Không có công việc phù hợp trạng thái này';

  @override
  String get taskCreateTitle => 'Tạo công việc';

  @override
  String get taskEditTitle => 'Chỉnh sửa công việc';

  @override
  String get taskCreatedTitle => 'Đã tạo công việc';

  @override
  String get taskUpdatedTitle => 'Đã cập nhật công việc';

  @override
  String get taskCreateFailedTitle => 'Không thể tạo công việc';

  @override
  String get taskUpdateFailedTitle => 'Không thể cập nhật công việc';

  @override
  String get taskSaveFailed => 'Không thể lưu công việc.';

  @override
  String get taskNoReportsSelected => 'Chưa chọn báo cáo nào.';

  @override
  String get taskLinkedReportsLoadFailed => 'Không thể tải báo cáo liên kết.';

  @override
  String taskUnavailableReports(Object reports) {
    return 'Chỉ báo cáo đã gửi mới có thể dùng để tạo công việc. Đã được xử lý: $reports';
  }

  @override
  String get taskNoActiveStaff => 'Không tìm thấy nhân viên đang hoạt động.';

  @override
  String get taskBrief => 'Tóm tắt công việc';

  @override
  String get taskData => 'Dữ liệu công việc';

  @override
  String get taskNoPhoto => 'Không có ảnh';

  @override
  String get taskReportPhoto => 'Ảnh báo cáo';

  @override
  String get taskAssignedStaff => 'Nhân viên được giao';

  @override
  String get taskCompletedBy => 'Người hoàn thành';

  @override
  String get taskCreatedBy => 'Người giám sát tạo';

  @override
  String get taskCreatedAt => 'Thời gian tạo';

  @override
  String get taskStartedAt => 'Thời gian bắt đầu';

  @override
  String get taskSubmittedAt => 'Thời gian gửi duyệt';

  @override
  String get taskReviewedAt => 'Thời gian xét duyệt';

  @override
  String get taskClosedAt => 'Thời gian đóng';

  @override
  String get taskReportIds => 'Mã báo cáo';

  @override
  String get validationWholeNumber => 'Hãy nhập số nguyên';

  @override
  String get validationNonnegative => 'Nhập giá trị từ 0 trở lên';

  @override
  String get validationOutOfRange => 'Ngoài phạm vi hợp lệ';

  @override
  String get taskDetailsTitle => 'Chi tiết công việc';

  @override
  String get taskApprovedTitle => 'Đã phê duyệt công việc';

  @override
  String get taskDeniedTitle => 'Đã từ chối hoàn thành công việc';

  @override
  String get taskDenyTitle => 'Từ chối hoàn thành công việc';

  @override
  String get taskDenyPrompt =>
      'Ghi rõ nội dung nhân viên cần làm lại. Ghi chú này sẽ thay thế mô tả công việc.';

  @override
  String get taskDenyNoteLabel => 'Ghi chú làm lại';

  @override
  String get taskDenyNoteRequired => 'Vui lòng nhập ghi chú làm lại';

  @override
  String get taskReworkInstructions => 'Yêu cầu làm lại';

  @override
  String get taskClosedTitle => 'Đã đóng công việc';

  @override
  String get taskDeleteQuestion => 'Xóa công việc?';

  @override
  String taskDeleteWarning(Object title) {
    return 'Thao tác này sẽ xóa vĩnh viễn “$title” và gỡ liên kết các báo cáo.';
  }

  @override
  String get taskKeep => 'Giữ công việc';

  @override
  String get taskDeletedTitle => 'Đã xóa công việc';

  @override
  String get taskDeleteFailed => 'Không thể xóa công việc.';

  @override
  String get taskUpdateFailed => 'Không thể cập nhật công việc.';

  @override
  String get taskLoadFailed => 'Không thể tải công việc.';

  @override
  String get taskStaffNote => 'Ghi chú của nhân viên';

  @override
  String get taskReviewEvidence => 'Xem xét bằng chứng';

  @override
  String get taskNoBeforePhoto => 'Chưa tải ảnh trước xử lý';

  @override
  String get taskNoAfterPhoto => 'Chưa tải ảnh sau xử lý';

  @override
  String get staffMyTasksTitle => 'Công việc của tôi';

  @override
  String get staffAssignedToYou => 'Được giao cho bạn';

  @override
  String get staffInProgress => 'Đang thực hiện';

  @override
  String get staffReview => 'Chờ duyệt';

  @override
  String get staffApproved => 'Đã phê duyệt';

  @override
  String get staffTopPriority => 'Ưu tiên cao nhất';

  @override
  String get staffReady => 'Sẵn sàng';

  @override
  String get staffNoTaskLocations => 'Không có vị trí công việc';

  @override
  String get staffTaskQueue => 'Hàng đợi công việc';

  @override
  String get staffNoAssignedTasks => 'Chưa có công việc được giao.';

  @override
  String get staffTaskSearchHint =>
      'Tìm công việc theo tiêu đề, khu vực hoặc danh mục…';

  @override
  String get staffTaskSort => 'Sắp xếp công việc';

  @override
  String get staffTaskSortNewest => 'Mới nhất';

  @override
  String get staffTaskSortOldest => 'Cũ nhất';

  @override
  String get staffTaskSortPriority => 'Ưu tiên cao nhất';

  @override
  String get staffNoTaskMatches => 'Không có công việc phù hợp với tìm kiếm.';

  @override
  String get staffHideReports => 'Ẩn báo cáo';

  @override
  String get staffShowOnMap => 'Hiển thị trên bản đồ';

  @override
  String staffTaskStarted(Object title) {
    return 'Đã bắt đầu $title';
  }

  @override
  String get staffStartTask => 'Bắt đầu công việc';

  @override
  String get staffRedoTask => 'Bắt đầu làm lại';

  @override
  String get staffRouteMap => 'Bản đồ lộ trình';

  @override
  String get staffCompleteTask => 'Hoàn thành công việc';

  @override
  String get staffNoLinkedReportDetails =>
      'Không tìm thấy chi tiết báo cáo liên kết.';

  @override
  String staffTaskCompleted(Object title) {
    return 'Đã hoàn thành $title';
  }

  @override
  String get staffAfterPhotoRequired => 'Hãy tải ảnh sau xử lý lên trước';

  @override
  String get staffAfterPhotoUploaded => 'Đã tải ảnh sau xử lý';

  @override
  String get staffAfterPhotoUploadFailed => 'Không thể tải ảnh sau xử lý.';

  @override
  String validationMaximumCharacters(Object maxLength) {
    return 'Dùng tối đa $maxLength ký tự';
  }

  @override
  String get routeMapTitle => 'Bản đồ lộ trình';

  @override
  String get routeUsingTaskAddress =>
      'Đang dùng địa chỉ công việc làm điểm xuất phát.';

  @override
  String get routeAddressNotFound =>
      'Không tìm thấy địa chỉ. Hãy thử địa chỉ báo cáo liên kết hoặc vĩ độ,kinh độ.';

  @override
  String routeStartsFrom(Object location) {
    return 'Lộ trình bắt đầu từ $location.';
  }

  @override
  String get routeCurrentAddress => 'Địa chỉ hiện tại';

  @override
  String get routeAddressHint =>
      'Nhập địa chỉ hiện tại, ví dụ: trạm xe buýt gần Lê Lợi';

  @override
  String get routeFromAddress => 'Tạo lộ trình từ địa chỉ';

  @override
  String get routeUseTaskAddress => 'Dùng địa chỉ công việc';

  @override
  String get routePickOnMap => 'Chọn trên bản đồ';

  @override
  String get routeTapMapToChooseStart =>
      'Chạm vào bản đồ để chọn điểm bắt đầu lộ trình.';

  @override
  String get routeKnownAddressesHelp =>
      'Hỗ trợ địa chỉ công việc, báo cáo và vĩ độ,kinh độ đã biết.';

  @override
  String get routeVisitOrder => 'Thứ tự ghé thăm';

  @override
  String get routeNoStops => 'Không có điểm dừng từ báo cáo liên kết.';

  @override
  String get routeDirections => 'Chỉ đường';

  @override
  String get routeLoadFailed => 'Không thể tải bản đồ lộ trình.';

  @override
  String get routeStartMarker => 'Bắt đầu';

  @override
  String routeSummary(num count, Object distance, Object start) {
    return 'Từ $start — $count điểm dừng — $distance';
  }

  @override
  String get userCreateTitle => 'Tạo người dùng';

  @override
  String userCreated(Object name) {
    return 'Đã tạo $name';
  }

  @override
  String get userCreateFailed => 'Hiện không thể tạo người dùng.';

  @override
  String userPasswordMinLength(Object count) {
    return 'Dùng ít nhất $count ký tự';
  }

  @override
  String get staffActiveMetric => 'Nhân viên hoạt động';

  @override
  String get staffInactiveMetric => 'Nhân viên ngừng hoạt động';

  @override
  String get staffOngoingTasksMetric => 'Công việc đang thực hiện';

  @override
  String get staffCompletedTasksMetric => 'Công việc đã hoàn thành';

  @override
  String get staffSummariesLoadFailed => 'Không thể tải tổng quan nhân viên.';

  @override
  String get staffEmpty => 'Chưa có nhân viên nào được đăng ký';

  @override
  String get staffActiveTasksHeader => 'CÔNG VIỆC ĐANG THỰC HIỆN';

  @override
  String get staffCompletedTasksHeader => 'CÔNG VIỆC ĐÃ HOÀN THÀNH';

  @override
  String get staffNoAssignedTasksForMember =>
      'Chưa có công việc nào được giao cho nhân viên này.';

  @override
  String staffAssignedTo(Object name) {
    return 'Đã giao cho $name';
  }

  @override
  String get staffUsersLoadFailed => 'Không thể tải danh sách nhân viên.';

  @override
  String get taskLinkedReports => 'Báo cáo liên kết';

  @override
  String get taskPriorityScore => 'Điểm ưu tiên';

  @override
  String get commonList => 'Danh sách';

  @override
  String get reportCancelFailed => 'Không thể hủy báo cáo.';

  @override
  String staffTaskMarkerLabel(Object number, Object title) {
    return 'Công việc $number $title';
  }

  @override
  String staffActiveTaskCount(Object count) {
    return '$count đang thực hiện';
  }

  @override
  String staffCompletedTaskCount(Object count) {
    return '$count đã hoàn thành';
  }

  @override
  String get routeManeuverHeadOut => 'Khởi hành';

  @override
  String get routeManeuverArrive => 'Đến nơi';

  @override
  String get routeManeuverTurnGeneric => 'Rẽ';

  @override
  String routeManeuverTurn(Object direction) {
    return 'Rẽ $direction';
  }

  @override
  String get routeManeuverContinue => 'Tiếp tục';

  @override
  String get routeManeuverMergeGeneric => 'Nhập làn';

  @override
  String routeManeuverMerge(Object direction) {
    return 'Nhập làn $direction';
  }

  @override
  String get routeManeuverTakeRamp => 'Đi vào đường dẫn';

  @override
  String get routeManeuverTakeExit => 'Đi theo lối ra';

  @override
  String get routeManeuverKeepGeneric => 'Đi theo hướng hiện tại';

  @override
  String routeManeuverKeep(Object direction) {
    return 'Đi theo hướng $direction';
  }

  @override
  String get routeManeuverEnterRoundabout => 'Đi vào vòng xuyến';

  @override
  String routeManeuverOnto(Object action, Object roadName) {
    return '$action vào $roadName';
  }

  @override
  String get routeDirectionUTurn => 'quay đầu';

  @override
  String get routeDirectionSharpRight => 'gấp sang phải';

  @override
  String get routeDirectionRight => 'phải';

  @override
  String get routeDirectionSlightRight => 'chếch phải';

  @override
  String get routeDirectionStraight => 'thẳng';

  @override
  String get routeDirectionSlightLeft => 'chếch trái';

  @override
  String get routeDirectionLeft => 'trái';

  @override
  String get routeDirectionSharpLeft => 'gấp sang trái';

  @override
  String get commonShowPassword => 'Hiện mật khẩu';

  @override
  String get commonHidePassword => 'Ẩn mật khẩu';

  @override
  String get commonOk => 'Đồng ý';

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonGoBack => 'Quay lại';

  @override
  String get commonClearSearch => 'Xóa tìm kiếm';

  @override
  String get commonAll => 'Tất cả';

  @override
  String get commonAddressUnavailable => 'Không có địa chỉ';

  @override
  String get commonPriorityScore => 'Điểm ưu tiên';

  @override
  String get commonConfirmations => 'Lượt xác nhận';

  @override
  String get commonClearFilters => 'Xóa bộ lọc';

  @override
  String confirmationCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lượt xác nhận',
      one: '1 lượt xác nhận',
      zero: 'Chưa có lượt xác nhận',
    );
    return '$_temp0';
  }

  @override
  String get brandSmartCityLabel => 'ĐÔ THỊ THÔNG MINH';

  @override
  String get photoCloseTooltip => 'Đóng ảnh';

  @override
  String get photoRemove => 'Xóa ảnh';

  @override
  String get photoUploading => 'Đang tải ảnh lên…';

  @override
  String get photoAdd => 'Thêm ảnh';

  @override
  String get authLoginHeroDescription =>
      'Báo cáo sự cố tại địa phương và theo dõi tiến độ tại một nơi.';

  @override
  String get authFeatureIncidentMap => 'Bản đồ sự cố';

  @override
  String get authFeatureResolutionTracking => 'Theo dõi xử lý';

  @override
  String get authFeatureGuidedReporting => 'Hướng dẫn báo cáo';

  @override
  String get authRegisterHeroDescription =>
      'Tham gia cùng cộng đồng và góp phần giúp dịch vụ đô thị phản hồi nhanh hơn.';

  @override
  String get authBenefitQuickReportTitle => 'Báo cáo sự cố nhanh chóng';

  @override
  String get authBenefitQuickReportDescription =>
      'Thêm ảnh và vị trí để đúng đội ngũ có thể xử lý.';

  @override
  String get authBenefitStatusTrackingTitle => 'Theo dõi mọi cập nhật';

  @override
  String get authBenefitStatusTrackingDescription =>
      'Theo dõi báo cáo từ lúc gửi đến khi được xử lý xong.';

  @override
  String get authBenefitProtectedInfoTitle => 'Kiểm soát quyền riêng tư';

  @override
  String get authBenefitProtectedInfoDescription =>
      'Chọn có hiển thị danh tính trên báo cáo công khai hay không.';

  @override
  String get reportCreateIntroTitle => 'Báo cáo sự cố đô thị';

  @override
  String get reportCreateIntroDescription =>
      'Chia sẻ sự cố, thêm ảnh rõ ràng và xác nhận vị trí để đội ngũ thành phố có thể xử lý nhanh hơn.';

  @override
  String get reportCreateStepCategoryTitle => 'Chọn loại sự cố';

  @override
  String get reportCreateStepCategoryDescription =>
      'Chọn danh mục phù hợp nhất với vấn đề.';

  @override
  String get reportCreateStepPhotoTitle => 'Thêm ảnh rõ ràng';

  @override
  String get reportCreateStepPhotoDescription =>
      'Sử dụng ảnh thể hiện rõ sự cố.';

  @override
  String get reportCreateStepLocationTitle => 'Xác nhận vị trí';

  @override
  String get reportCreateStepLocationDescription =>
      'Ghim đúng vị trí trước khi gửi.';

  @override
  String get reportEditIntroTitle => 'Cập nhật báo cáo của bạn';

  @override
  String get reportEditIntroDescription =>
      'Xem lại thông tin hiện có và chỉ cập nhật những nội dung đã thay đổi trước khi lưu.';

  @override
  String get reportEditPhotoHintTitle => 'Giữ ảnh rõ ràng';

  @override
  String get reportEditPhotoHintDescription =>
      'Chỉ thay ảnh khi có góc chụp tốt hơn.';

  @override
  String get reportEditLocationHintTitle => 'Kiểm tra vị trí';

  @override
  String get reportEditLocationHintDescription =>
      'Xác nhận ghim vẫn đúng với sự cố đã báo cáo.';

  @override
  String get reportEditDetailsHintTitle => 'Lưu thông tin chính xác';

  @override
  String get reportEditDetailsHintDescription =>
      'Thông tin rõ ràng giúp đội ngũ thành phố xử lý chính xác.';

  @override
  String get reportLoadingTitle => 'Đang tải báo cáo';

  @override
  String get reportLoadingMessage =>
      'Vui lòng chờ trong khi thông tin mới nhất được chuẩn bị.';

  @override
  String get reportEditingUnavailable => 'Không thể chỉnh sửa';

  @override
  String get reportFormCreateHeading =>
      'Hãy cho chúng tôi biết chuyện gì đã xảy ra';

  @override
  String get reportFormEditHeading => 'Cập nhật thông tin báo cáo';

  @override
  String get reportFormDescription =>
      'Hoàn thành từng phần bên dưới. Thông tin rõ ràng giúp đội ngũ thành phố xử lý nhanh hơn.';

  @override
  String get reportFormCategoryTitle => 'Loại sự cố';

  @override
  String get reportFormCategoryDescription =>
      'Chọn phương án phù hợp nhất với vấn đề.';

  @override
  String get reportFormPhotoTitle => 'Ảnh minh chứng';

  @override
  String get reportFormPhotoDescription =>
      'Thêm một ảnh rõ ràng thể hiện sự cố.';

  @override
  String reportPhotoAddedCount(Object added, Object total) {
    return 'Đã thêm $added/$total ảnh';
  }

  @override
  String get reportBeforePhotoHelp =>
      'Tải ảnh chụp trước khi có bất kỳ hoạt động xử lý nào';

  @override
  String get reportFormLocationDescription =>
      'Xác nhận chính xác vị trí của sự cố.';

  @override
  String get reportStreetAddress => 'Địa chỉ đường phố';

  @override
  String get reportStreetAddressHint => 'Thêm địa danh gần đó hoặc tên đường';

  @override
  String get reportFormDetailsDescription =>
      'Dùng tiêu đề ngắn và mô tả điều bạn quan sát được.';

  @override
  String get reportFormTitleLabel => 'Tiêu đề báo cáo';

  @override
  String get reportFormTitleHint => 'Ví dụ: Đèn đường bị hỏng';

  @override
  String get reportFormDescriptionHint =>
      'Mô tả sự cố, thời điểm bạn phát hiện và các chi tiết hữu ích.';

  @override
  String get reportPrivacyTitle => 'Quyền riêng tư';

  @override
  String get reportPrivacyDescription =>
      'Chọn có hiển thị danh tính công khai hay không.';

  @override
  String get reportAnonymousHelp =>
      'Thông tin cá nhân của bạn sẽ được ẩn khỏi báo cáo công khai.';

  @override
  String get reportReviewBeforeSubmit =>
      'Vui lòng xem lại thông tin trước khi gửi.';

  @override
  String get reportNew => 'Báo cáo mới';

  @override
  String get reportsTrackProgressDescription =>
      'Theo dõi tiến độ của những sự cố bạn đã báo cáo.';

  @override
  String get reportsSearchHint => 'Tìm kiếm báo cáo';

  @override
  String get reportsSortTooltip => 'Sắp xếp báo cáo';

  @override
  String get reportsSortNewest => 'Mới nhất trước';

  @override
  String get reportsSortOldest => 'Cũ nhất trước';

  @override
  String get reportsSortPriority => 'Ưu tiên cao nhất';

  @override
  String get reportsLoading => 'Đang tải báo cáo của bạn…';

  @override
  String get reportsNoMatches => 'Không có báo cáo phù hợp';

  @override
  String get reportsNoMatchesHelp =>
      'Hãy thay đổi nội dung tìm kiếm hoặc bộ lọc.';

  @override
  String get reportsEmptyHelp =>
      'Tạo báo cáo đầu tiên để bắt đầu theo dõi một sự cố.';

  @override
  String get reportViewPhoto => 'Xem ảnh';

  @override
  String get reportCurrentStatusTitle => 'Trạng thái hiện tại';

  @override
  String get reportCurrentStatusDescription =>
      'Xem tiến độ xử lý sự cố của đội ngũ thành phố.';

  @override
  String get reportStaffAssignment => 'Phân công nhân viên';

  @override
  String get reportStaffUnassigned => 'Chưa phân công nhân viên';

  @override
  String get reportDescriptionSectionHelp =>
      'Thông tin chi tiết được cung cấp cùng báo cáo.';

  @override
  String get reportNoDescription => 'Chưa có mô tả.';

  @override
  String get reportSubmittedAnonymously => 'Đã gửi ẩn danh';

  @override
  String get reportSubmittedPublicly => 'Đã gửi công khai';

  @override
  String get reportLocationSectionHelp => 'Vị trí sự cố được báo cáo.';

  @override
  String mapSelectedLocationCoordinates(Object latitude, Object longitude) {
    return 'Tọa độ đã chọn: $latitude, $longitude';
  }

  @override
  String get reportOverviewTitle => 'Tổng quan báo cáo';

  @override
  String get reportOverviewDescription => 'Thông tin chính về sự cố này.';

  @override
  String get mapExploreCityIssuesTitle => 'Khám phá sự cố đô thị';

  @override
  String get mapExploreCityIssuesDescription =>
      'Tìm kiếm trên bản đồ và xem các báo cáo gần bạn.';

  @override
  String get mapNearbyReportsTitle => 'Báo cáo lân cận';

  @override
  String get mapNearbyReportsDescription =>
      'Xem các sự cố đang mở trong khu vực hiển thị.';

  @override
  String get mapShowMyReports => 'Hiện báo cáo của tôi';

  @override
  String get mapLoadingNearbyReports => 'Đang tải báo cáo lân cận…';

  @override
  String get mapNoReportsHelp =>
      'Di chuyển bản đồ hoặc đổi bộ lọc để khám phá khu vực khác.';

  @override
  String get mapUnavailableTitle => 'Không thể hiển thị bản đồ';

  @override
  String get mapCheckNearbyReportsTooltip => 'Kiểm tra báo cáo lân cận';

  @override
  String get mapUseCurrentLocationTooltip => 'Dùng vị trí hiện tại';

  @override
  String get mapMovePinInstruction =>
      'Di chuyển bản đồ đến khi ghim nằm chính xác trên sự cố.';

  @override
  String mapNearbyReportCount(num count, Object distance) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tìm thấy $count báo cáo hiện có trong phạm vi $distance mét.',
      one: 'Tìm thấy 1 báo cáo hiện có trong phạm vi $distance mét.',
      zero: 'Không tìm thấy báo cáo nào trong phạm vi $distance mét.',
    );
    return '$_temp0';
  }

  @override
  String get mapCloseTooltip => 'Đóng bản đồ';

  @override
  String get staffCompleteIntro =>
      'Bổ sung bằng chứng rõ ràng để giám sát viên có thể xem xét công việc đã hoàn thành.';

  @override
  String get staffCompleteChecklistTitle => 'Trước khi gửi';

  @override
  String get staffCompleteChecklistWorkDone =>
      'Xác nhận công việc được giao đã hoàn thành.';

  @override
  String get staffCompleteChecklistPhotosAdded =>
      'Tải lên ảnh rõ ràng sau khi xử lý.';

  @override
  String get staffCompleteChecklistNoteClear =>
      'Thêm ghi chú hoàn thành ngắn gọn.';

  @override
  String get staffCompleteNoteHelp =>
      'Mô tả nội dung đã hoàn thành và những điều người duyệt cần biết.';

  @override
  String get staffCompleteNoteHint =>
      'Ví dụ: Đã thay đèn bị hỏng và kiểm tra hoạt động.';

  @override
  String get overseerReportOperations => 'Thao tác báo cáo';

  @override
  String get profileTitle => 'Hồ sơ của tôi';

  @override
  String get profileLoadFailed => 'Không thể tải hồ sơ của bạn.';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileMemberSince => 'Thành viên từ';

  @override
  String get profileActive => 'Đang hoạt động';

  @override
  String get profileInactive => 'Ngừng hoạt động';

  @override
  String get profileAccountStatus => 'Trạng thái tài khoản';

  @override
  String get profileReportAnalytics => 'Thống kê báo cáo';

  @override
  String get profileTotalReports => 'Tổng số báo cáo';

  @override
  String get profileTaskAnalytics => 'Thống kê công việc';

  @override
  String get profileTotalTasks => 'Tổng công việc được giao';

  @override
  String get profileOverseerAnalyticsNote =>
      'Bảng phân tích đầy đủ cho giám sát viên sẽ nằm trên một trang riêng.';

  @override
  String get staffProfileTitle => 'Hồ sơ nhân viên';

  @override
  String get staffProfileLoadFailed => 'Không thể tải hồ sơ nhân viên này.';
}
