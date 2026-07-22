import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';

void main() {
  test('new UI copy is available in English and Vietnamese', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final vietnamese = await AppLocalizations.delegate.load(const Locale('vi'));

    expect(english.authFeatureGuidedReporting, 'Guided reporting');
    expect(vietnamese.authFeatureGuidedReporting, 'Hướng dẫn báo cáo');

    expect(english.reportCreateIntroTitle, 'Report a city issue');
    expect(vietnamese.reportCreateIntroTitle, 'Báo cáo sự cố đô thị');
    expect(english.reportPhotoAddedCount(1, 1), '1 of 1 added');
    expect(vietnamese.reportPhotoAddedCount(1, 1), 'Đã thêm 1/1 ảnh');

    expect(english.confirmationCount(2), '2 confirmations');
    expect(vietnamese.confirmationCount(2), '2 lượt xác nhận');
    expect(
      english.mapSelectedLocationCoordinates('10.1', '106.2'),
      'Selected coordinates: 10.1, 106.2',
    );
    expect(
      vietnamese.mapSelectedLocationCoordinates('10.1', '106.2'),
      'Tọa độ đã chọn: 10.1, 106.2',
    );
    expect(
      english.mapNearbyReportCount(2, 100),
      '2 existing reports were found within 100 metres.',
    );
    expect(
      vietnamese.mapNearbyReportCount(2, 100),
      'Tìm thấy 2 báo cáo hiện có trong phạm vi 100 mét.',
    );

    expect(english.staffCompleteChecklistTitle, 'Before submitting');
    expect(vietnamese.staffCompleteChecklistTitle, 'Trước khi gửi');
    expect(english.taskCompletedBy, 'Completed by');
    expect(vietnamese.taskCompletedBy, 'Người hoàn thành');
  });
}
