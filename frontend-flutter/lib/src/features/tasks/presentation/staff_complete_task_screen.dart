import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../data/task_api_service.dart';
import '../../../core/files/upload_file_picker.dart';
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
  bool _hasLinkedReports = false;
  bool _didReadArgs = false;
  UploadFilePick? _afterPhoto;
  String? _afterPhotoError;

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
      _hasLinkedReports = arguments['hasLinkedReports'] == true;
    } else {
      _taskId = arguments as String?;
    }
  }

  @override
  void dispose() {
    _staffNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickAfterPhoto() async {
    if (_isSaving) {
      return;
    }

    try {
      final picked = await pickImageUploadFile();
      if (picked == null || !mounted) {
        return;
      }
      setState(() {
        _afterPhoto = picked;
        _afterPhotoError = null;
      });
    } on FilePickerException catch (error) {
      _setAfterPhotoError(error.message);
    } catch (_) {
      _setAfterPhotoError(context.l10n.staffAfterPhotoUploadFailed);
    }
  }

  void _setAfterPhotoError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _afterPhotoError = message);
    _showError(message);
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

    if (!_hasLinkedReports && _afterPhoto == null) {
      _setAfterPhotoError(context.l10n.staffAfterPhotoRequired);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      String? afterPhotoUrl;
      if (!_hasLinkedReports) {
        final picked = _afterPhoto!;
        afterPhotoUrl = await widget.taskApiService.uploadAfterPhoto(
          filename: picked.filename,
          bytes: picked.bytes,
        );
      }

      final draft = TaskCompletionDraft(
        afterPhotoUrl: afterPhotoUrl,
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
              if (!_hasLinkedReports)
                _AfterPhotoPicker(
                  file: _afterPhoto,
                  errorText: _afterPhotoError,
                  onPick: _pickAfterPhoto,
                ),
              if (!_hasLinkedReports) const SizedBox(height: 20),

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

class _AfterPhotoPicker extends StatelessWidget {
  const _AfterPhotoPicker({
    required this.file,
    required this.errorText,
    required this.onPick,
  });

  final UploadFilePick? file;
  final String? errorText;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.commonAfterPhoto,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (file != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(file!.bytes),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        if (file != null) const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('staffTaskAfterPhotoPicker'),
          onPressed: onPick,
          icon: Icon(file == null ? Icons.upload_file : Icons.swap_horiz),
          label: Text(
            file == null ? context.l10n.photoUpload : context.l10n.photoReplace,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
