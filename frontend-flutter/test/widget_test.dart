import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';
import 'package:smart_city_report_frontend/src/app.dart';
import 'package:smart_city_report_frontend/src/core/localization/locale_controller.dart';
import 'package:smart_city_report_frontend/src/core/localization/locale_storage.dart';
import 'package:smart_city_report_frontend/src/core/routing/app_routes.dart';
import 'package:smart_city_report_frontend/src/features/auth/data/auth_api_service.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/auth_session.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/overseer/presentation/overseer_create_task_screen.dart';
import 'package:smart_city_report_frontend/src/features/overseer/presentation/overseer_report_dashboard_screen.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/tasks/data/task_api_service.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/staff_task.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';
import 'package:smart_city_report_frontend/src/features/tasks/presentation/staff_task_route_map_screen.dart';
import 'package:smart_city_report_frontend/src/features/users/data/user_api_service.dart';
import 'package:smart_city_report_frontend/src/features/users/domain/app_user.dart';

void main() {
  const filePickerChannel = MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
    StandardMethodCodec(),
  );
  const pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
    StandardMethodCodec(),
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel, (call) async {
          if (call.method != 'custom') {
            return null;
          }

          final bytes = Uint8List.fromList(<int>[137, 80, 78, 71]);
          return <Map<String, Object?>>[
            <String, Object?>{
              'name': 'picked.png',
              'path': null,
              'bytes': bytes,
              'size': bytes.length,
              'identifier': null,
            },
          ];
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          switch (call.method) {
            case 'getApplicationCacheDirectory':
            case 'getTemporaryDirectory':
              return '.dart_tool/test-cache';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  testWidgets('switches between English and Vietnamese and persists it', (
    tester,
  ) async {
    final storage = MemoryLocaleStorage();
    final localeController = LocaleController(storage: storage);

    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(),
        reportApiService: MockReportApiService(),
        localeController: localeController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckedPopupMenuItem<String>).last);
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(localeController.locale, const Locale('vi'));
    expect(storage.languageCode, 'vi');
  });

  testWidgets('localizes structured road route maneuvers', (tester) async {
    const step = RoadRouteStep(
      instruction: 'Turn right onto Le Loi',
      distanceMeters: 120,
      maneuverType: 'turn',
      maneuverModifier: 'right',
      roadName: 'Đường Lê Lợi',
    );

    Future<void> pumpForLocale(Locale locale) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) =>
                Text(localizeRoadRouteInstruction(context, step)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpForLocale(const Locale('vi'));
    expect(find.text('Rẽ phải vào Đường Lê Lợi'), findsOneWidget);

    await pumpForLocale(const Locale('en'));
    expect(find.text('Turn right onto Đường Lê Lợi'), findsOneWidget);
  });

  test('parses backend report user summary displayName', () {
    final report = Report.fromJson({
      'id': '11111111-1111-1111-1111-000000000001',
      'title': 'Blocked drain',
      'description': 'Water is pooling after rain.',
      'category': 'DRAINAGE',
      'status': 'SUBMITTED',
      'latitude': 10.7769,
      'longitude': 106.7009,
      'addressText': 'Nguyen Hue',
      'beforePhotoUrl': '/uploads/report-before/blocked-drain.jpg',
      'anonymous': false,
      'upvoteCount': 0,
      'priorityScore': 0,
      'createdAt': '2026-06-10T08:00:00Z',
      'updatedAt': '2026-06-10T08:00:00Z',
      'createdBy': {
        'id': '22222222-2222-2222-2222-222222222222',
        'displayName': 'Test Citizen',
        'role': 'CITIZEN',
      },
    });

    expect(report.createdBy?.fullName, 'Test Citizen');
    expect(report.createdBy?.role, 'CITIZEN');
  });

  test('parses ReportMapPin creatorId correctly', () {
    final pin = ReportMapPin.fromJson({
      'id': '11111111-1111-1111-1111-000000000001',
      'title': 'Blocked drain',
      'category': 'DRAINAGE',
      'status': 'SUBMITTED',
      'latitude': 10.7769,
      'longitude': 106.7009,
      'upvoteCount': 2,
      'priorityScore': 2,
      'creatorId': 'user-1234',
    });

    expect(pin.creatorId, 'user-1234');
    expect(pin.upvoteCount, 2);

    final copied = pin.copyWith(upvoteCount: 5);
    expect(copied.upvoteCount, 5);
    expect(copied.creatorId, 'user-1234');
  });

  test('mock task service creates task from selected reports', () async {
    final taskApiService = MockTaskApiService();

    final task = await taskApiService.createTask(
      const TaskDraft(
        title: 'Repair light',
        description: 'Replace the broken lamp.',
        category: ReportCategory.streetLight,
        latitude: 10.7769,
        longitude: 106.7009,
        addressText: 'Nguyen Hue',
        priorityScore: 3,
        assignedStaffId: null,
        staffNote: null,
        reportIds: ['11111111-1111-1111-1111-000000000004'],
      ),
    );

    expect(task.title, 'Repair light');
    expect(task.reportIds, contains('11111111-1111-1111-1111-000000000004'));
    expect(task.status, TaskStatus.newTask);
  });

  test('mock staff task service starts and completes a task', () async {
    final taskApiService = MockTaskApiService();
    final inbox = await taskApiService.fetchStaffTasks();
    final taskId = inbox.first.id;

    final started = await taskApiService.startTask(taskId);
    expect(started.status, TaskStatus.inProgress);

    final completed = await taskApiService.completeTask(
      taskId,
      const TaskCompletionDraft(staffNote: 'Done'),
    );

    expect(completed.status, TaskStatus.done);
    expect(completed.staffNote, 'Done');
  });

  test(
    'mock task service approves a completed task and blocks deletion',
    () async {
      final taskApiService = MockTaskApiService();
      final taskId = (await taskApiService.fetchStaffTasks()).first.id;

      await taskApiService.startTask(taskId);
      final completed = await taskApiService.completeTask(
        taskId,
        const TaskCompletionDraft(staffNote: 'Done'),
      );
      expect(completed.status, TaskStatus.done);

      final approved = await taskApiService.approveTask(taskId);
      expect(approved.status, TaskStatus.approved);
      expect(approved.reviewedAt, isNotNull);

      await expectLater(
        taskApiService.deleteTask(taskId),
        throwsA(isA<TaskApiException>()),
      );
    },
  );

  test('mock task service denies completion and allows staff rework', () async {
    final taskApiService = MockTaskApiService();
    final taskId = (await taskApiService.fetchStaffTasks()).first.id;

    await taskApiService.startTask(taskId);
    await taskApiService.completeTask(
      taskId,
      const TaskCompletionDraft(staffNote: 'First attempt'),
    );
    final denied = await taskApiService.denyTask(
      taskId,
      ' Repair the damaged edge too ',
    );

    expect(denied.status, TaskStatus.denied);
    expect(denied.description, 'Repair the damaged edge too');
    expect(StaffTask.fromTask(denied).status, StaffTaskStatus.denied);
    expect(denied.status.canStart, isTrue);

    final restarted = await taskApiService.startTask(taskId);
    expect(restarted.status, TaskStatus.inProgress);
  });

  test('task action rules follow the overseer workflow', () {
    expect(TaskStatus.newTask.canAssign, isTrue);
    expect(TaskStatus.newTask.canEdit, isTrue);
    expect(TaskStatus.assigned.canAssign, isFalse);
    expect(TaskStatus.assigned.canEdit, isTrue);
    expect(TaskStatus.inProgress.canAssign, isFalse);
    expect(TaskStatus.inProgress.canEdit, isFalse);
    expect(TaskStatus.inProgress.canDelete, isTrue);
    expect(TaskStatus.done.canAssign, isFalse);
    expect(TaskStatus.done.canEdit, isFalse);
    expect(TaskStatus.done.canDelete, isFalse);
    expect(TaskStatus.done.canApprove, isTrue);
    expect(TaskStatus.done.canDeny, isTrue);
  });
  test(
    'mock user service creates and returns staff dropdown options',
    () async {
      final userApiService = MockUserApiService();
      await userApiService.createUser(
        const UserDraft(
          fullName: 'New Staff',
          email: 'new.staff@test.com',
          password: 'Password123',
          role: UserRole.staff,
        ),
      );

      final users = await userApiService.fetchStaffUsers();

      expect(users, hasLength(2));
      expect(users.first.fullName, 'Test Staff');
      expect(users.first.email, 'staff@test.com');
      expect(users.last.fullName, 'New Staff');
      expect(users.last.email, 'new.staff@test.com');
    },
  );

  testWidgets('logs in a citizen and opens citizen home', (tester) async {
    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(loginRole: UserRole.citizen),
        reportApiService: MockReportApiService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart City Reports'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'citizen@test.com');
    await tester.enterText(find.byType(EditableText).at(1), 'Password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('My reports'), findsOneWidget);
    expect(find.text('Broken streetlight near Nguyen Hue'), findsOneWidget);
  });

  testWidgets('citizen can create a report from home', (tester) async {
    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(loginRole: UserRole.citizen),
        reportApiService: MockReportApiService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'citizen@test.com');
    await tester.enterText(find.byType(EditableText).at(1), 'Password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report an issue'));
    await tester.pumpAndSettle();

    expect(find.text('Create report'), findsOneWidget);

    final titleField = find.byKey(const Key('report_title_field'));
    final descriptionField = find.byKey(const Key('report_description_field'));
    final formScrollable = find
        .descendant(
          of: find.byKey(const Key('report_form_list')),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      titleField,
      300,
      scrollable: formScrollable,
    );
    await tester.enterText(titleField, 'Blocked drain');
    await tester.ensureVisible(descriptionField);
    await tester.enterText(descriptionField, 'Water is pooling after rain.');
    final uploadControl = find.byKey(const Key('report_photo_upload'));
    await tester.scrollUntilVisible(
      uploadControl,
      -300,
      scrollable: formScrollable,
    );
    await tester.tap(uploadControl);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    final submitButton = find.text('Submit report');
    await tester.scrollUntilVisible(
      submitButton,
      300,
      scrollable: formScrollable,
    );
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('My reports'), findsOneWidget);
    expect(find.text('Report submitted'), findsOneWidget);
    expect(find.text('Blocked drain'), findsWidgets);
  });

  testWidgets('routes staff users to staff home after login', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(loginRole: UserRole.staff),
        reportApiService: MockReportApiService(),
        taskApiService: MockTaskApiService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'staff@test.com');
    await tester.enterText(find.byType(EditableText).at(1), 'Password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('My tasks'), findsOneWidget);
    expect(find.text('1 task'), findsOneWidget);

    expect(find.text('Task queue'), findsOneWidget);
    expect(find.text('Fix pothole'), findsOneWidget);
    expect(find.text('2 reports'), findsWidgets);
    expect(find.text('Cracked curb near Le Loi crossing'), findsNothing);

    final reportsToggle = find.byKey(
      const ValueKey('taskReportsToggle-33333333-3333-3333-3333-000000000001'),
    );
    expect(reportsToggle, findsOneWidget);

    await tester.tap(reportsToggle);
    await tester.pumpAndSettle();

    expect(find.text('Pothole beside the bus stop'), findsWidgets);
    expect(find.text('Cracked curb near Le Loi crossing'), findsOneWidget);
    expect(find.text('Inspect broken streetlight'), findsNothing);
  });

  testWidgets('staff can open a linked report from task details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(loginRole: UserRole.staff),
        reportApiService: MockReportApiService(),
        taskApiService: MockTaskApiService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'staff@test.com');
    await tester.enterText(find.byType(EditableText).at(1), 'Password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix pothole'));
    await tester.pumpAndSettle();

    expect(find.text('Task details'), findsOneWidget);
    expect(find.text('Linked reports'), findsOneWidget);
    expect(find.text('Pothole beside the bus stop'), findsWidgets);

    await tester.tap(find.text('Pothole beside the bus stop'));
    await tester.pumpAndSettle();

    expect(find.text('Report details'), findsOneWidget);
    expect(
      find.text('Cars swerve around it during rush hour.'),
      findsOneWidget,
    );
    expect(find.text('Bus stop near Le Loi'), findsWidgets);
  });
  testWidgets('staff can start and complete an assigned task', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(loginRole: UserRole.staff),
        reportApiService: MockReportApiService(),
        taskApiService: MockTaskApiService(),
        roadRouteService: FakeRoadRouteService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'staff@test.com');
    await tester.enterText(find.byType(EditableText).at(1), 'Password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix pothole'));
    await tester.pumpAndSettle();

    expect(find.text('Task details'), findsOneWidget);
    expect(find.text('Assigned'), findsWidgets);

    await tester.tap(find.text('Start task'));
    await tester.pumpAndSettle();

    expect(find.text('Route map'), findsOneWidget);
    expect(find.text('Visit order'), findsOneWidget);
    expect(find.text('Current address'), findsOneWidget);
    expect(find.text('Pothole beside the bus stop'), findsWidgets);
    expect(find.text('Cracked curb near Le Loi crossing'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('staffRouteStartAddressField')),
      'Le Loi pedestrian crossing',
    );
    await tester.tap(find.byTooltip('Route from address'));
    await tester.pumpAndSettle();

    expect(
      find.text('Route starts from Le Loi pedestrian crossing.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Route map'), findsOneWidget);

    await tester.tap(find.text('Complete task'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Complete task'),
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(EditableText).first, 'Done');
    await tester.tap(find.text('Complete task').last);
    await tester.pumpAndSettle();

    expect(find.text('Done'), findsWidgets);
  });

  testWidgets('restores an overseer session and supports logout', (
    tester,
  ) async {
    final authApiService = FakeAuthApiService(
      currentUser: fakeUser(UserRole.overseer),
    );

    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: authApiService,
        reportApiService: MockReportApiService(),
        taskApiService: MockTaskApiService(),
        userApiService: MockUserApiService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report dashboard'), findsOneWidget);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    expect(authApiService.loggedOut, isTrue);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('overseer task tab refreshes when selected', (tester) async {
    final authApiService = FakeAuthApiService(
      currentUser: fakeUser(UserRole.overseer),
    );
    final taskApiService = MockTaskApiService();

    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: authApiService,
        reportApiService: MockReportApiService(),
        taskApiService: taskApiService,
        userApiService: MockUserApiService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report dashboard'), findsOneWidget);
    expect(find.text('Fresh drainage task'), findsNothing);

    await tester.runAsync(
      () => taskApiService.createTask(
        const TaskDraft(
          title: 'Fresh drainage task',
          description: 'Clear the blocked drain from the linked report.',
          category: ReportCategory.drainage,
          latitude: 10.7769,
          longitude: 106.7009,
          addressText: 'Nguyen Hue',
          priorityScore: 2,
          assignedStaffId: null,
          staffNote: null,
          reportIds: ['11111111-1111-1111-1111-000000000004'],
        ),
      ),
    );

    await tester.tap(find.text('Tasks'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Fresh drainage task'), findsOneWidget);
  });
  testWidgets('linked report item opens report details', (tester) async {
    await tester.pumpWidget(
      overseerCreateTaskHarness(
        reportIds: const ['11111111-1111-1111-1111-000000000004'],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open create task'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Broken streetlight near Nguyen Hue'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Broken streetlight near Nguyen Hue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Report details'), findsOneWidget);
    expect(
      find.text('Report detail 11111111-1111-1111-1111-000000000004'),
      findsOneWidget,
    );
  });
  testWidgets('overseer cannot create a task from reports already handled', (
    tester,
  ) async {
    await tester.pumpWidget(
      overseerCreateTaskHarness(
        reportIds: const ['11111111-1111-1111-1111-000000000003'],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open create task'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Only submitted reports'), findsOneWidget);
    expect(find.byKey(const Key('overseerTaskSubmitButton')), findsNothing);
  });

  testWidgets(
    'overseer creates a task from selected reports with report data',
    (tester) async {
      final taskApiService = MockTaskApiService();

      await tester.pumpWidget(
        overseerCreateTaskHarness(
          reportIds: const ['11111111-1111-1111-1111-000000000004'],
          taskApiService: taskApiService,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open create task'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Create task'),
        ),
        findsOneWidget,
      );
      expect(find.text('Report IDs'), findsNothing);
      expect(find.text('Assigned staff'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).at(0), 'Repair light');
      await tester.enterText(
        find.byType(EditableText).at(1),
        'Replace the broken lamp.',
      );
      await tester.ensureVisible(find.text('Assigned staff'));
      await tester.tap(find.byIcon(Icons.person_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Staff (staff@test.com)').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('overseerTaskSubmitButton')),
      );
      await tester.tap(find.byKey(const Key('overseerTaskSubmitButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      final tasks = await tester.runAsync(taskApiService.fetchTasks);
      expect(tasks, isNotNull);
      final createdTask = tasks!.first;
      expect(createdTask.title, 'Repair light');
      expect(createdTask.description, 'Replace the broken lamp.');
      expect(createdTask.status, TaskStatus.assigned);
      expect(
        createdTask.assignedStaff?.id,
        '44444444-4444-4444-4444-444444444444',
      );
      expect(createdTask.category, ReportCategory.streetLight);
      expect(createdTask.latitude, 10.7769);
      expect(createdTask.longitude, 106.7009);
      expect(createdTask.priorityScore, 3);
      expect(
        createdTask.reportIds,
        contains('11111111-1111-1111-1111-000000000004'),
      );
    },
  );
}

Widget overseerCreateTaskHarness({
  required List<String> reportIds,
  TaskApiService? taskApiService,
  ReportApiService? reportApiService,
  UserApiService? userApiService,
}) {
  final tasks = taskApiService ?? MockTaskApiService();
  final reports = reportApiService ?? MockReportApiService();
  final users = userApiService ?? MockUserApiService();

  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    onGenerateRoute: (settings) {
      if (settings.name == AppRoutes.overseerCreateTask) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => OverseerCreateTaskScreen(
            taskApiService: tasks,
            reportApiService: reports,
            userApiService: users,
          ),
        );
      }

      if (settings.name == AppRoutes.overseerReportDetail) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Report details')),
            body: Text('Report detail ${settings.arguments}'),
          ),
        );
      }

      return MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.overseerCreateTask,
                arguments: OverseerTaskFormArgs(reportIds: reportIds),
              ),
              child: const Text('Open create task'),
            ),
          ),
        ),
      );
    },
  );
}

class FakeRoadRouteService implements RoadRouteService {
  @override
  Future<RoadRouteResult> fetchRoute(List<LatLng> waypoints) async {
    return RoadRouteResult(
      points: waypoints.length < 2
          ? waypoints
          : <LatLng>[
              waypoints.first,
              LatLng(
                (waypoints.first.latitude + waypoints.last.latitude) / 2,
                (waypoints.first.longitude + waypoints.last.longitude) / 2,
              ),
              waypoints.last,
            ],
      distanceMeters: 1800,
      durationSeconds: 420,
      steps: const <RoadRouteStep>[
        RoadRouteStep(
          instruction: 'Head toward Le Loi',
          distanceMeters: 500,
          maneuverType: 'depart',
          roadName: 'Le Loi',
        ),
        RoadRouteStep(
          instruction: 'Turn right onto the crossing',
          distanceMeters: 1300,
          maneuverType: 'turn',
          maneuverModifier: 'right',
          roadName: 'Đường Lê Lợi',
        ),
      ],
    );
  }
}

class FakeAuthApiService implements AuthApiService {
  FakeAuthApiService({this.loginRole = UserRole.citizen, this.currentUser});

  final UserRole loginRole;
  CurrentUser? currentUser;
  bool loggedOut = false;

  @override
  Future<CurrentUser?> getCurrentUser() async {
    return currentUser;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final user = fakeUser(loginRole, email: email);
    currentUser = user;
    return AuthSession(
      token: 'signed.jwt.token',
      tokenType: 'Bearer',
      user: user,
    );
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final user = fakeUser(UserRole.citizen, email: email, fullName: fullName);
    currentUser = user;
    return AuthSession(
      token: 'signed.jwt.token',
      tokenType: 'Bearer',
      user: user,
    );
  }

  @override
  Future<void> logout() async {
    loggedOut = true;
    currentUser = null;
  }
}

CurrentUser fakeUser(
  UserRole role, {
  String email = 'user@test.com',
  String fullName = 'Test User',
}) {
  return CurrentUser(
    id: '11111111-1111-1111-1111-111111111111',
    fullName: fullName,
    email: email,
    role: role,
  );
}
