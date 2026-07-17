import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
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
            context.l10n.staffAssignedTo(
              task.assignedStaff?.fullName ?? context.l10n.commonStaff,
            ),
          ),
        ),
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
      backgroundColor: const Color(0xFFF6F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text('${context.l10n.commonAssign} ${context.l10n.commonStaff}'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<AppUser>>(
          future: _staffFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: context.l10n.staffUsersLoadFailed,
                onRetry: _retryLoadStaff,
              );
            }

            final staffUsers = snapshot.data ?? const <AppUser>[];
            if (staffUsers.isEmpty) {
              return Center(child: Text(context.l10n.taskNoActiveStaff));
            }

            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(color: const Color(0xFF123B38), borderRadius: BorderRadius.circular(24)),
                          child: Row(children: [
                            Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.groups_2_outlined, color: Colors.white)),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${context.l10n.commonAssign} ${context.l10n.commonStaff}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(context.l10n.taskNoActiveStaff, style: const TextStyle(color: Color(0xFFCFE0DE)))])),
                          ]),
                        ),
                        const SizedBox(height: 18),
                        DropdownButtonFormField<String>(
                          value: _selectedStaffId,
                          decoration: InputDecoration(labelText: context.l10n.commonStaff, prefixIcon: const Icon(Icons.person_search_outlined), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
                          items: staffUsers.map((staff) => DropdownMenuItem<String>(value: staff.id, child: Text('${staff.fullName} (${staff.email})', overflow: TextOverflow.ellipsis))).toList(growable: false),
                          onChanged: _isSaving ? null : (staffId) => setState(() => _selectedStaffId = staffId),
                          validator: (value) => (value ?? '').isEmpty ? context.l10n.commonRequired : null,
                        ),
                        const SizedBox(height: 18),
                        Text(context.l10n.commonStaff, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        ...staffUsers.map((staff) {
                          final selected = staff.id == _selectedStaffId;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: _isSaving ? null : () => setState(() => _selectedStaffId = staff.id),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: selected ? const Color(0xFFE7F4F1) : Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? const Color(0xFF0F766E) : const Color(0xFFDCE6E3), width: selected ? 1.5 : 1)),
                                child: Row(children: [CircleAvatar(backgroundColor: selected ? const Color(0xFF0F766E) : const Color(0xFFE8EFED), foregroundColor: selected ? Colors.white : const Color(0xFF516965), child: Text(staff.fullName.isEmpty ? '?' : staff.fullName[0].toUpperCase())), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(staff.email, style: const TextStyle(color: Color(0xFF687B77)))])), Radio<String>(value: staff.id, groupValue: _selectedStaffId, onChanged: _isSaving ? null : (value) => setState(() => _selectedStaffId = value))]),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFDCE6E3)))),
                    child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _isSaving ? null : _assign, icon: _isSaving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.person_add_alt_1), label: Text(context.l10n.commonAssign), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
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
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
