import 'staff_task.dart';

enum StaffTaskSort { newest, oldest, priority }

List<StaffTask> filterAndSortStaffTasks(
  List<StaffTask> tasks, {
  String query = '',
  StaffTaskSort sort = StaffTaskSort.newest,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final filtered = tasks.where((task) {
    if (normalizedQuery.isEmpty) {
      return true;
    }
    final haystack = <String>[
      task.id,
      task.reportTitle,
      task.category,
      task.area,
      task.status.label,
    ].join(' ').toLowerCase();
    return haystack.contains(normalizedQuery);
  }).toList();

  filtered.sort((a, b) {
    final newestFirst = b.dueDate.compareTo(a.dueDate);
    switch (sort) {
      case StaffTaskSort.newest:
        return newestFirst;
      case StaffTaskSort.oldest:
        return a.dueDate.compareTo(b.dueDate);
      case StaffTaskSort.priority:
        final byPriority = b.priorityScore.compareTo(a.priorityScore);
        if (byPriority != 0) {
          return byPriority;
        }
        return newestFirst;
    }
  });

  return List<StaffTask>.unmodifiable(filtered);
}
