import 'package:flutter/material.dart';

import '../../tasks/data/task_api_service.dart';

class OverseerAssignStaffScreen extends StatefulWidget {
  const OverseerAssignStaffScreen({super.key, required this.taskApiService});

  final TaskApiService taskApiService;

  @override
  State<OverseerAssignStaffScreen> createState() =>
      _OverseerAssignStaffScreenState();
}

class _OverseerAssignStaffScreenState extends State<OverseerAssignStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _staffIdController = TextEditingController();
  bool _isSaving = false;

  String get _taskId => ModalRoute.of(context)!.settings.arguments! as String;

  @override
  void dispose() {
    _staffIdController.dispose();
    super.dispose();
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
        staffId: _staffIdController.text.trim(),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _staffIdController,
                decoration: const InputDecoration(
                  labelText: 'Staff UUID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
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
        ),
      ),
    );
  }
}
