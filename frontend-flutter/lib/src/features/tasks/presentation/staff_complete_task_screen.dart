import 'package:flutter/material.dart';

import '../data/task_api_service.dart';
import '../domain/task.dart';

class StaffCompleteTaskScreen extends StatefulWidget {
  const StaffCompleteTaskScreen({super.key, required this.taskApiService});

  final TaskApiService taskApiService;

  @override
  State<StaffCompleteTaskScreen> createState() =>
      _StaffCompleteTaskScreenState();
}

class _StaffCompleteTaskScreenState extends State<StaffCompleteTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _afterPhotoController = TextEditingController();
  final _staffNoteController = TextEditingController();
  bool _isSaving = false;

  String? get _taskId => ModalRoute.of(context)?.settings.arguments as String?;

  @override
  void dispose() {
    _afterPhotoController.dispose();
    _staffNoteController.dispose();
    super.dispose();
  }

  Future<void> _completeTask() async {
    final taskId = _taskId;
    if (taskId == null || _isSaving) {
      return;
    }

    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final draft = TaskCompletionDraft(
      afterPhotoUrl: _nullableText(_afterPhotoController),
      staffNote: _nullableText(_staffNoteController),
    );

    try {
      final task = await widget.taskApiService.completeTask(taskId, draft);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${task.title} completed')));
      Navigator.of(context).pop(true);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to complete task.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String? _maxLength(String? value, int maxLength) {
    final raw = value ?? '';
    if (raw.length > maxLength) {
      return 'Use $maxLength characters or fewer';
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Task')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _afterPhotoController,
                decoration: const InputDecoration(
                  labelText: 'After photo URL',
                  prefixIcon: Icon(Icons.photo_library_outlined),
                ),
                validator: (value) => _maxLength(value, 2048),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _staffNoteController,
                decoration: const InputDecoration(
                  labelText: 'Staff note',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                minLines: 4,
                maxLines: 8,
                validator: (value) => _maxLength(value, 4000),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _completeTask,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.task_alt),
                label: const Text('Complete task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
