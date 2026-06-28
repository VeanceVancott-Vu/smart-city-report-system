import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_api_service.dart';
import '../../overseer/presentation/overseer_report_dashboard_screen.dart';
import '../../overseer/presentation/overseer_task_list_screen.dart';
import '../../reports/data/report_api_service.dart';
import '../../tasks/data/task_api_service.dart';
import '../../users/data/user_api_service.dart';
import '../../map/presentation/overseer_map_screen.dart';
import '../../users/presentation/overseer_staff_list_screen.dart';

class OverseerHomeScreen extends StatefulWidget {
  const OverseerHomeScreen({
    super.key,
    required this.authApiService,
    required this.reportApiService,
    required this.taskApiService,
    required this.userApiService,
  });

  final AuthApiService authApiService;
  final ReportApiService reportApiService;
  final TaskApiService taskApiService;
  final UserApiService userApiService;

  @override
  State<OverseerHomeScreen> createState() => _OverseerHomeScreenState();
}

class _OverseerHomeScreenState extends State<OverseerHomeScreen> {
  final _taskListKey = GlobalKey<OverseerTaskListScreenState>();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Report Dashboard', 'City Map', 'Tasks', 'Staff'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Create user',
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.overseerCreateUser);
            },
            icon: const Icon(Icons.person_add_alt_1),
          ),
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
          OverseerMapScreen(
            reportApiService: widget.reportApiService,
            authApiService: widget.authApiService,
          ),
          OverseerTaskListScreen(
            key: _taskListKey,
            taskApiService: widget.taskApiService,
          ),
          OverseerStaffListScreen(userApiService: widget.userApiService),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 2) {
            _taskListKey.currentState?.reload();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Staff',
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
