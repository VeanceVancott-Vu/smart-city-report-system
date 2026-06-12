import 'package:flutter/material.dart';

import '../../../core/files/upload_file_picker.dart';
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
  String? _afterPhotoUrl;
  String? _afterPhotoError;
  bool _isUploadingPhoto = false;
  bool _isSaving = false;

  String? get _taskId => ModalRoute.of(context)?.settings.arguments as String?;

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
    if ((_afterPhotoUrl ?? '').trim().isEmpty) {
      setState(() => _afterPhotoError = 'Upload an after photo first');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final draft = TaskCompletionDraft(
      afterPhotoUrl: _afterPhotoUrl,
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

  Future<void> _pickAndUploadAfterPhoto() async {
    if (_isSaving || _isUploadingPhoto) {
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
      _afterPhotoError = null;
    });

    try {
      final pickedFile = await pickImageUploadFile();
      if (pickedFile == null) {
        return;
      }

      final fileUrl = await widget.taskApiService.uploadAfterPhoto(
        filename: pickedFile.filename,
        bytes: pickedFile.bytes,
      );
      if (!mounted) {
        return;
      }
      setState(() => _afterPhotoUrl = fileUrl);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('After photo uploaded')));
    } on FilePickerException catch (error) {
      _setPhotoError(error.message);
    } catch (_) {
      _setPhotoError('Unable to upload after photo.');
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _setPhotoError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _afterPhotoError = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
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
              _PhotoUploadField(
                label: 'After photo',
                fileUrl: _afterPhotoUrl,
                errorText: _afterPhotoError,
                isUploading: _isUploadingPhoto,
                onUpload: _pickAndUploadAfterPhoto,
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
                onPressed: _isSaving || _isUploadingPhoto
                    ? null
                    : _completeTask,
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

class _PhotoUploadField extends StatelessWidget {
  const _PhotoUploadField({
    required this.label,
    required this.fileUrl,
    required this.errorText,
    required this.isUploading,
    required this.onUpload,
  });

  final String label;
  final String? fileUrl;
  final String? errorText;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final hasFile = (fileUrl ?? '').trim().isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isUploading ? null : onUpload,
          icon: isUploading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: Text(hasFile ? 'Replace photo' : 'Upload photo'),
        ),
        if (hasFile) ...[
          const SizedBox(height: 8),
          Text(
            fileUrl!,
            style: TextStyle(color: colorScheme.primary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText!, style: TextStyle(color: colorScheme.error)),
        ],
      ],
    );
  }
}
