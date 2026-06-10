import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/src/app.dart';
import 'package:smart_city_report_frontend/src/features/auth/data/auth_api_service.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/auth_session.dart';
import 'package:smart_city_report_frontend/src/features/auth/domain/current_user.dart';
import 'package:smart_city_report_frontend/src/features/reports/data/report_api_service.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/tasks/data/task_api_service.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/task.dart';

void main() {
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
      'beforePhotoUrl': 'photo_placeholder.jpg',
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
        beforePhotoUrl: 'streetlight_before.jpg',
        afterPhotoUrl: null,
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
      const TaskCompletionDraft(
        afterPhotoUrl: 'https://example.local/after.jpg',
        staffNote: 'Done',
      ),
    );

    expect(completed.status, TaskStatus.done);
    expect(completed.afterPhotoUrl, 'https://example.local/after.jpg');
    expect(completed.staffNote, 'Done');
  });

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

    expect(find.text('My Reports'), findsOneWidget);
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

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Create Report'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(0), 'Blocked drain');
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Water is pooling after rain.',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();

    expect(find.text('My Reports'), findsOneWidget);
    expect(find.text('Blocked drain'), findsOneWidget);
  });

  testWidgets('routes staff users to staff home after login', (tester) async {
    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(loginRole: UserRole.staff),
        taskApiService: MockTaskApiService(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'staff@test.com');
    await tester.enterText(find.byType(EditableText).at(1), 'Password123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Task Inbox'), findsOneWidget);
  });

  testWidgets('staff can start and complete an assigned task', (tester) async {
    await tester.pumpWidget(
      SmartCityReportApp(
        authApiService: FakeAuthApiService(loginRole: UserRole.staff),
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

    expect(find.text('Task Details'), findsOneWidget);
    expect(find.text('Assigned'), findsWidgets);

    await tester.tap(find.text('Start task'));
    await tester.pumpAndSettle();

    expect(find.text('In progress'), findsOneWidget);

    await tester.tap(find.text('Complete task'));
    await tester.pumpAndSettle();

    expect(find.text('Complete Task'), findsOneWidget);

    await tester.enterText(
      find.byType(EditableText).at(0),
      'https://example.local/after.jpg',
    );
    await tester.enterText(find.byType(EditableText).at(1), 'Done');
    await tester.tap(find.text('Complete task'));
    await tester.pumpAndSettle();

    expect(find.text('https://example.local/after.jpg'), findsOneWidget);
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
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Report Dashboard'), findsOneWidget);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();

    expect(authApiService.loggedOut, isTrue);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('overseer can open task creation from selected reports', (
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();

    expect(find.text('Create Task'), findsOneWidget);
  });
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
