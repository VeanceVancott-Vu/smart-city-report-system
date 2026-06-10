import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/src/app.dart';

void main() {
  testWidgets('starts at login and opens citizen reports', (tester) async {
    await tester.pumpWidget(SmartCityReportApp());

    expect(find.text('Smart City Reports'), findsOneWidget);
    expect(find.text('Citizen'), findsOneWidget);

    await tester.tap(find.text('Citizen'));
    await tester.pumpAndSettle();

    expect(find.text('Citizen Reports'), findsOneWidget);
    expect(find.text('Broken streetlight near Nguyen Hue'), findsOneWidget);
  });
}
