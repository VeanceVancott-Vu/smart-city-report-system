import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
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
  final _staffNoteController = TextEditingController();
  bool _isSaving = false;
  String? _taskId;
  bool _didReadArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) {
      return;
    }
    _didReadArgs = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map) {
      _taskId = arguments['taskId'] as String?;
    } else {
      _taskId = arguments as String?;
    }
  }

  @override
  void dispose() {
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

    try {
      final draft = TaskCompletionDraft(
        staffNote: _nullableText(_staffNoteController),
      );
      final task = await widget.taskApiService.completeTask(taskId, draft);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.staffTaskCompleted(task.title))),
      );
      Navigator.of(context).pop(true);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError(context.l10n.taskUpdateFailed);
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
      return context.l10n.validationMaximumCharacters(maxLength);
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
      appBar: AppBar(title: Text(context.l10n.staffCompleteTask)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _staffNoteController,
                decoration: InputDecoration(
                  labelText: context.l10n.taskStaffNote,
                  prefixIcon: const Icon(Icons.note_alt_outlined),
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
                label: Text(context.l10n.staffCompleteTask),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
