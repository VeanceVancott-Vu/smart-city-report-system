import 'package:flutter/material.dart';

import '../data/task_api_service.dart';
import '../domain/staff_task.dart';

class StaffTaskListScreen extends StatelessWidget {
  const StaffTaskListScreen({super.key, required this.taskApiService});

  final TaskApiService taskApiService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Tasks')),
      body: FutureBuilder<List<StaffTask>>(
        future: taskApiService.fetchStaffTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data ?? const <StaffTask>[];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _TaskTile(task: tasks[index]),
          );
        },
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final StaffTask task;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5E2)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE2F3EE),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.engineering_outlined),
        ),
        title: Text(
          task.reportTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TaskChip(
                icon: Icons.confirmation_number_outlined,
                label: task.id,
              ),
              _TaskChip(icon: Icons.category_outlined, label: task.category),
              _TaskChip(icon: Icons.place_outlined, label: task.area),
              _TaskChip(
                icon: Icons.event_outlined,
                label: _formatDate(task.dueDate),
              ),
            ],
          ),
        ),
        trailing: _TaskStatus(label: task.status.label),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
    );
  }
}

class _TaskStatus extends StatelessWidget {
  const _TaskStatus({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      side: BorderSide.none,
      backgroundColor: const Color(0xFFF6E7C8),
    );
  }
}
