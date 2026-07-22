import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_extension.dart';
import '../../../core/localization/language_menu_button.dart';
import '../../../core/routing/app_routes.dart';
import '../../analytics/data/analytics_api_service.dart';
import '../../analytics/presentation/overseer_analytics_screen.dart';
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
    required this.analyticsApiService,
  });

  final AuthApiService authApiService;
  final ReportApiService reportApiService;
  final TaskApiService taskApiService;
  final UserApiService userApiService;
  final AnalyticsApiService analyticsApiService;

  @override
  State<OverseerHomeScreen> createState() => _OverseerHomeScreenState();
}

class _OverseerHomeScreenState extends State<OverseerHomeScreen> {
  final _taskListKey = GlobalKey<OverseerTaskListScreenState>();
  final Set<int> _visitedTabs = {0};
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = [
      context.l10n.homeReportDashboard,
      context.l10n.analyticsTitle,
      context.l10n.homeCityMap,
      context.l10n.commonTasks,
      context.l10n.commonStaff,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: context.l10n.profileTitle,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.myProfile),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const LanguageMenuButton(),
          IconButton(
            tooltip: context.l10n.homeCreateUser,
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.overseerCreateUser);
            },
            icon: const Icon(Icons.person_add_alt_1),
          ),
          IconButton(
            tooltip: context.l10n.commonLogout,
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          if (_visitedTabs.contains(0))
            OverseerReportDashboardScreen(
              reportApiService: widget.reportApiService,
            )
          else
            const SizedBox.shrink(),
          if (_visitedTabs.contains(1))
            OverseerAnalyticsScreen(
              analyticsApiService: widget.analyticsApiService,
              userApiService: widget.userApiService,
            )
          else
            const SizedBox.shrink(),
          if (_visitedTabs.contains(2))
            OverseerMapScreen(
              reportApiService: widget.reportApiService,
              authApiService: widget.authApiService,
            )
          else
            const SizedBox.shrink(),
          if (_visitedTabs.contains(3))
            OverseerTaskListScreen(
              key: _taskListKey,
              taskApiService: widget.taskApiService,
            )
          else
            const SizedBox.shrink(),
          if (_visitedTabs.contains(4))
            OverseerStaffListScreen(userApiService: widget.userApiService)
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            _visitedTabs.add(index);
          });
          if (index == 3) {
            _taskListKey.currentState?.reload();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: context.l10n.commonReports,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: context.l10n.analyticsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: context.l10n.commonMap,
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment),
            label: context.l10n.commonTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: context.l10n.commonStaff,
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
