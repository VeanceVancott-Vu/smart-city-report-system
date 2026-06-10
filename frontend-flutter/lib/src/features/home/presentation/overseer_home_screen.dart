import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_api_service.dart';
import '../../overseer/presentation/overseer_report_dashboard_screen.dart';
import '../../overseer/presentation/overseer_task_list_screen.dart';
import '../../reports/data/report_api_service.dart';
import '../../tasks/data/task_api_service.dart';

class OverseerHomeScreen extends StatefulWidget {
  const OverseerHomeScreen({
    super.key,
    required this.authApiService,
    required this.reportApiService,
    required this.taskApiService,
  });

  final AuthApiService authApiService;
  final ReportApiService reportApiService;
  final TaskApiService taskApiService;

  @override
  State<OverseerHomeScreen> createState() => _OverseerHomeScreenState();
}

class _OverseerHomeScreenState extends State<OverseerHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Report Dashboard', 'Tasks'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          OverseerReportDashboardScreen(
            reportApiService: widget.reportApiService,
          ),
          OverseerTaskListScreen(taskApiService: widget.taskApiService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await widget.authApiService.logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }
}
