import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/src/core/files/uploaded_photo_view.dart';

void main() {
  test('resolves relative upload URLs against backend base URL', () {
    expect(
      resolveUploadedPhotoUrl(
        '/uploads/report-before/before.jpg',
        baseUrl: 'http://127.0.0.1:8080',
      ),
      'http://127.0.0.1:8080/uploads/report-before/before.jpg',
    );
  });

  test('preserves absolute image URLs', () {
    expect(
      resolveUploadedPhotoUrl('https://example.test/uploads/before.jpg'),
      'https://example.test/uploads/before.jpg',
    );
  });

  test('does not resolve relative upload URLs without backend base URL', () {
    expect(
      resolveUploadedPhotoUrl('/uploads/report-before/before.jpg', baseUrl: ''),
      isNull,
    );
  });
}
