import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/src/core/files/upload_content_type.dart';

void main() {
  test('maps supported image filenames to upload content types', () {
    expect(uploadContentTypeForFilename('before.jpg').toString(), 'image/jpeg');
    expect(uploadContentTypeForFilename('before.JPEG').toString(), 'image/jpeg');
    expect(uploadContentTypeForFilename('before.png').toString(), 'image/png');
    expect(uploadContentTypeForFilename('before.webp').toString(), 'image/webp');
  });

  test('returns null for unsupported filenames', () {
    expect(uploadContentTypeForFilename('before.txt'), isNull);
    expect(uploadContentTypeForFilename('before'), isNull);
  });
}
