import '../../../core/services/api_service.dart';
import '../domain/staff_task.dart';

abstract class TaskApiService {
  Future<List<StaffTask>> fetchStaffTasks();
}

class MockTaskApiService extends ApiService implements TaskApiService {
  const MockTaskApiService();

  @override
  Future<List<StaffTask>> fetchStaffTasks() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return [
      StaffTask(
        id: 'TSK-4401',
        reportTitle: 'Pothole beside the bus stop',
        category: 'Road',
        status: StaffTaskStatus.inProgress,
        area: 'District 1',
        dueDate: DateTime(2026, 6, 9),
      ),
      StaffTask(
        id: 'TSK-4402',
        reportTitle: 'Broken streetlight near Nguyen Hue',
        category: 'Lighting',
        status: StaffTaskStatus.assigned,
        area: 'District 1',
        dueDate: DateTime(2026, 6, 10),
      ),
      StaffTask(
        id: 'TSK-4403',
        reportTitle: 'Drain cover missing',
        category: 'Water',
        status: StaffTaskStatus.awaitingReview,
        area: 'District 3',
        dueDate: DateTime(2026, 6, 11),
      ),
    ];
  }
}
