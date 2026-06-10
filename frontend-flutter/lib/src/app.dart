import 'package:flutter/material.dart';

import 'core/routing/app_routes.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/map/presentation/overseer_map_screen.dart';
import 'features/reports/data/report_api_service.dart';
import 'features/reports/presentation/create_report_screen.dart';
import 'features/reports/presentation/report_list_screen.dart';
import 'features/tasks/data/task_api_service.dart';
import 'features/tasks/presentation/staff_task_list_screen.dart';

class SmartCityReportApp extends StatelessWidget {
  SmartCityReportApp({
    super.key,
    ReportApiService? reportApiService,
    TaskApiService? taskApiService,
  }) : reportApiService = reportApiService ?? MockReportApiService(),
       taskApiService = taskApiService ?? MockTaskApiService();

  final ReportApiService reportApiService;
  final TaskApiService taskApiService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart City Reports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9F8),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.citizenReports: (_) =>
            ReportListScreen(reportApiService: reportApiService),
        AppRoutes.createReport: (_) =>
            CreateReportScreen(reportApiService: reportApiService),
        AppRoutes.overseerMap: (_) => const OverseerMapScreen(),
        AppRoutes.staffTasks: (_) =>
            StaffTaskListScreen(taskApiService: taskApiService),
      },
    );
  }
}
