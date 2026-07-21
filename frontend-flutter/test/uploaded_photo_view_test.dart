import 'package:flutter/material.dart';
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

  testWidgets('does not render stored photo URLs', (tester) async {
    const photoUrl = '/uploads/report-before/before.jpg';
    await tester.pumpWidget(
      const MaterialApp(home: UploadedPhotoView(fileUrl: photoUrl)),
    );

    expect(find.text(photoUrl), findsNothing);
  });

  testWidgets('full-screen viewer closes with its button and system back', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('openPhoto'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => const UploadedPhotoFullscreenView(
                        fileUrl: 'https://example.test/photo.jpg',
                      ),
                    ),
                  );
                },
                child: const Text('Open photo'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('openPhoto')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close photo'), findsOneWidget);

    await tester.tap(find.byTooltip('Close photo'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Close photo'), findsNothing);
    expect(find.text('Open photo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openPhoto')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Close photo'), findsNothing);
    expect(find.text('Open photo'), findsOneWidget);
  });
}
