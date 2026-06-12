import 'package:flutter/material.dart';

import '../../tasks/data/task_api_service.dart';
import '../../users/data/user_api_service.dart';
import '../../users/domain/app_user.dart';

class OverseerAssignStaffScreen extends StatefulWidget {
  const OverseerAssignStaffScreen({
    super.key,
    required this.taskApiService,
    required this.userApiService,
  });

  final TaskApiService taskApiService;
  final UserApiService userApiService;

  @override
  State<OverseerAssignStaffScreen> createState() =>
      _OverseerAssignStaffScreenState();
}

class _OverseerAssignStaffScreenState extends State<OverseerAssignStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<AppUser>> _staffFuture;
  String? _selectedStaffId;
  bool _isSaving = false;

  String get _taskId => ModalRoute.of(context)!.settings.arguments! as String;

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

  Future<void> _assign() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final task = await widget.taskApiService.assignTask(
        id: _taskId,
        staffId: _selectedStaffId!,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assigned to ${task.assignedStaff?.fullName ?? 'staff'}',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on TaskApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('Unable to assign staff.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
      appBar: AppBar(title: const Text('Assign Staff')),
      body: SafeArea(
        child: FutureBuilder<List<AppUser>>(
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
              return const Center(child: Text('No active staff users found.'));
            }

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedStaffId,
                    decoration: const InputDecoration(
                      labelText: 'Staff',
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
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _assign,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: const Text('Assign'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
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
