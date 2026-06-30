import 'staff_task_inbox_screen.dart';

class StaffTaskListScreen extends StaffTaskInboxScreen {
  const StaffTaskListScreen({
    super.key,
    required super.taskApiService,
    required super.reportApiService,
    super.onLogout,
  });
}
