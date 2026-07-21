import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/features/overseer/presentation/overseer_task_list_screen.dart';
import 'package:smart_city_report_frontend/src/features/tasks/data/task_api_service.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';

void main() {
  testWidgets('mobile overseer task cards handle long metadata', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SafeArea(
            child: OverseerTaskListScreen(
              taskApiService: _LongAddressTaskApiService(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();

    expect(find.text('Inspect broken streetlight'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _LongAddressTaskApiService extends MockTaskApiService {
  @override
  Future<List<Task>> fetchTasks() async {
    final tasks = await super.fetchTasks();
    return <Task>[
      tasks.last.copyWith(
        addressText: 'Khu phố 8, Saigon, Thủ Đức, Hồ Chí Minh City, Việt Nam',
      ),
    ];
  }
}
