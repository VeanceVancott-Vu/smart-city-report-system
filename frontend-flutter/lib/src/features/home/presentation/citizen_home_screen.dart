import 'package:flutter/material.dart';

import '../../../core/routing/app_routes.dart';
import '../../auth/data/auth_api_service.dart';
import '../../reports/data/report_api_service.dart';
import '../../reports/presentation/citizen_map_screen.dart';
import '../../reports/presentation/citizen_report_list_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  CitizenHomeScreen({
    super.key,
    required this.authApiService,
    required this.reportApiService,
  }) : _reportListKey = GlobalKey<CitizenReportListScreenState>();

  final AuthApiService authApiService;
  final ReportApiService reportApiService;
  final GlobalKey<CitizenReportListScreenState> _reportListKey;

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['My Reports', 'Pins Map'];

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
          CitizenReportListScreen(
            key: widget._reportListKey,
            reportApiService: widget.reportApiService,
          ),
          CitizenMapScreen(
            reportApiService: widget.reportApiService,
            authApiService: widget.authApiService,
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () =>
                  widget._reportListKey.currentState?.openCreateReport(),
              icon: const Icon(Icons.add),
              label: const Text('Report'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
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
