import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_api_service.dart';
import '../../tasks/data/task_api_service.dart';
import '../../tasks/presentation/staff_task_inbox_screen.dart';

class StaffHomeScreen extends StatelessWidget {
  const StaffHomeScreen({
    super.key,
    required this.authApiService,
    required this.taskApiService,
  });

  final AuthApiService authApiService;
  final TaskApiService taskApiService;

  @override
  Widget build(BuildContext context) {
    return StaffTaskInboxScreen(
      taskApiService: taskApiService,
      onLogout: () => _logout(context),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await authApiService.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }
}
