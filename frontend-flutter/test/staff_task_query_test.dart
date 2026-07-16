import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/staff_task.dart';
import 'package:smart_city_report_frontend/src/features/tasks/domain/staff_task_query.dart';

StaffTask _task(String id, String title, DateTime dueDate, int priority) {
  return StaffTask(
    id: id,
    reportTitle: title,
    category: 'Road damage',
    status: StaffTaskStatus.assigned,
    area: 'District 1',
    dueDate: dueDate,
    latitude: 10.77,
    longitude: 106.70,
    priorityScore: priority,
    reportIds: const <String>[],
  );
}

void main() {
  final tasks = <StaffTask>[
    _task('old', 'Repair pothole', DateTime(2026, 7, 1), 2),
    _task('new', 'Inspect streetlight', DateTime(2026, 7, 3), 5),
    _task('middle', 'Clear drainage', DateTime(2026, 7, 2), 8),
  ];

  test('searches task title and sorts by newest, oldest, or priority', () {
    expect(
      filterAndSortStaffTasks(
        tasks,
        sort: StaffTaskSort.newest,
      ).map((task) => task.id).toList(),
      ['new', 'middle', 'old'],
    );
    expect(
      filterAndSortStaffTasks(
        tasks,
        sort: StaffTaskSort.oldest,
      ).map((task) => task.id).toList(),
      ['old', 'middle', 'new'],
    );
    expect(
      filterAndSortStaffTasks(
        tasks,
        query: 'streetlight',
        sort: StaffTaskSort.priority,
      ).map((task) => task.id).toList(),
      ['new'],
    );
  });
}
