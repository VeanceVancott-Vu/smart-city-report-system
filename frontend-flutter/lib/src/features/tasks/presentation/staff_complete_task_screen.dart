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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.l10n.staffCompleteTask),
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF123C3A),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.task_alt_rounded, color: Color(0xFF82D5C5), size: 28),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.staffCompleteTask,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Review the work, leave a useful handover, and send it to the reviewer.',
                                style: TextStyle(color: Color(0xFFB7D5D0), height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fact_check_outlined, color: colors.primary),
                            const SizedBox(width: 10),
                            Text(
                              'Before submitting',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _ChecklistItem(text: 'The assigned work has been completed.'),
                        const _ChecklistItem(text: 'After photos were added to every linked report.'),
                        const _ChecklistItem(text: 'The note below is clear for the reviewer.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4F1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.taskStaffNote,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mention what was done, any remaining concern, or information the reviewer should know.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _staffNoteController,
                          minLines: 5,
                          maxLines: 9,
                          maxLength: 4000,
                          validator: (value) => _maxLength(value, 4000),
                          decoration: InputDecoration(
                            hintText: 'Example: Replaced the damaged cover and cleared the surrounding area.',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: colors.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: colors.outlineVariant),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _completeTask,
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.task_alt_outlined),
                      label: Text(context.l10n.staffCompleteTask),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 19, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}
