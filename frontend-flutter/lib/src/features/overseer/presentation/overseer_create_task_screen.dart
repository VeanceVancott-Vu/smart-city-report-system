import 'package:flutter/material.dart';

import '../../reports/domain/report.dart';
import '../../tasks/data/task_api_service.dart';
import '../../tasks/domain/task.dart';
import '../../users/data/user_api_service.dart';
import '../../users/domain/app_user.dart';
import 'overseer_report_dashboard_screen.dart';

class OverseerCreateTaskScreen extends StatefulWidget {
  const OverseerCreateTaskScreen({
    super.key,
    required this.taskApiService,
    required this.userApiService,
  });

  final TaskApiService taskApiService;
  final UserApiService userApiService;

  @override
  State<OverseerCreateTaskScreen> createState() =>
      _OverseerCreateTaskScreenState();
}

class _OverseerCreateTaskScreenState extends State<OverseerCreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController(text: '10.7769');
  final _longitudeController = TextEditingController(text: '106.7009');
  final _addressController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');
  final _reportIdsController = TextEditingController();

  ReportCategory _category = ReportCategory.roadDamage;
  late Future<List<AppUser>> _staffFuture;
  OverseerTaskFormArgs? _args;
  Task? _loadedTask;
  String? _selectedStaffId;
  bool _didReadArgs = false;
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEditing => (_args?.taskId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  void _loadStaff() {
    _staffFuture = widget.userApiService.fetchStaffUsers();
  }

  Future<void> _retryLoadStaff() async {
    setState(_loadStaff);
    await _staffFuture;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) {
      return;
    }
    _didReadArgs = true;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    _args = rawArgs is OverseerTaskFormArgs
        ? rawArgs
        : rawArgs is List<String>
        ? OverseerTaskFormArgs(reportIds: rawArgs)
        : const OverseerTaskFormArgs();

    _reportIdsController.text = _args!.reportIds.join('\n');
    if (_isEditing) {
      _loadTask(_args!.taskId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _priorityController.dispose();
    _reportIdsController.dispose();
    super.dispose();
  }

  Future<void> _loadTask(String taskId) async {
    setState(() => _isLoading = true);
    try {
      final task = await widget.taskApiService.fetchTask(taskId);
      if (!mounted) {
        return;
      }
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _category = task.category;
      _latitudeController.text = task.latitude.toString();
      _longitudeController.text = task.longitude.toString();
      _addressController.text = task.addressText ?? '';
      _priorityController.text = task.priorityScore.toString();
      _reportIdsController.text = task.reportIds.join('\n');
      _loadedTask = task;
      _selectedStaffId = task.assignedStaff?.id;
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to load task.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final draft = TaskDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      latitude: double.parse(_latitudeController.text.trim()),
      longitude: double.parse(_longitudeController.text.trim()),
      addressText: _nullableText(_addressController),
      priorityScore: int.parse(_priorityController.text.trim()),
      assignedStaffId: _selectedStaffId,
      beforePhotoUrl: _loadedTask?.beforePhotoUrl,
      afterPhotoUrl: _loadedTask?.afterPhotoUrl,
      staffNote: _loadedTask?.staffNote,
      reportIds: _reportIds(),
    );

    try {
      final task = _isEditing
          ? await widget.taskApiService.updateTask(_args!.taskId!, draft)
          : await widget.taskApiService.createTask(draft);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${task.title} saved')));
      Navigator.of(context).pop(true);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to save task.');
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

  List<String> _reportIds() {
    return _reportIdsController.text
        .split(RegExp(r'[\s,]+'))
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'Create Task')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<List<AppUser>>(
                future: _staffFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: 'Unable to load staff users.',
                      onRetry: _retryLoadStaff,
                    );
                  }

                  final staffUsers = snapshot.data ?? const <AppUser>[];
                  if (staffUsers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No active staff users found.'),
                      ),
                    );
                  }

                  final selectedStaffId =
                      staffUsers.any((staff) => staff.id == _selectedStaffId)
                      ? _selectedStaffId
                      : null;

                  return Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            prefixIcon: Icon(Icons.title),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                          minLines: 3,
                          maxLines: 5,
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ReportCategory>(
                          value: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: ReportCategory.values
                              .map(
                                (category) => DropdownMenuItem<ReportCategory>(
                                  value: category,
                                  child: Text(category.label),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _isSaving
                              ? null
                              : (category) {
                                  if (category != null) {
                                    setState(() => _category = category);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 560;
                            final latitude = TextFormField(
                              controller: _latitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                prefixIcon: Icon(Icons.my_location_outlined),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              validator: _latitude,
                            );
                            final longitude = TextFormField(
                              controller: _longitudeController,
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                prefixIcon: Icon(Icons.explore_outlined),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              validator: _longitude,
                            );

                            return isWide
                                ? Row(
                                    children: [
                                      Expanded(child: latitude),
                                      const SizedBox(width: 12),
                                      Expanded(child: longitude),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      latitude,
                                      const SizedBox(height: 12),
                                      longitude,
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address text',
                            prefixIcon: Icon(Icons.place_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priorityController,
                          decoration: const InputDecoration(
                            labelText: 'Priority score',
                            prefixIcon: Icon(Icons.trending_up),
                          ),
                          keyboardType: TextInputType.number,
                          validator: _nonNegativeInt,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedStaffId,
                          decoration: const InputDecoration(
                            labelText: 'Assigned staff',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: staffUsers
                              .map(
                                (staff) => DropdownMenuItem<String>(
                                  value: staff.id,
                                  child: Text(
                                    '${staff.fullName} (${staff.email})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _isSaving
                              ? null
                              : (staffId) {
                                  setState(() => _selectedStaffId = staffId);
                                },
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reportIdsController,
                          decoration: const InputDecoration(
                            labelText: 'Report IDs',
                            prefixIcon: Icon(Icons.link_outlined),
                          ),
                          minLines: 2,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const Key('overseerTaskSubmitButton'),
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _isEditing ? 'Save changes' : 'Create task',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _latitude(String? value) {
    return _boundedNumber(value, min: -90, max: 90);
  }

  String? _longitude(String? value) {
    return _boundedNumber(value, min: -180, max: 180);
  }

  String? _boundedNumber(
    String? value, {
    required double min,
    required double max,
  }) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Required';
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      return 'Use a number';
    }
    if (parsed < min || parsed > max) {
      return 'Out of range';
    }
    return null;
  }

  String? _nonNegativeInt(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      return 'Use a whole number';
    }
    if (parsed < 0) {
      return 'Use 0 or higher';
    }
    return null;
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
