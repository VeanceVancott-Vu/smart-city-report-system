import 'package:flutter/material.dart';
import 'package:smart_city_report_frontend/l10n/app_localizations.dart';

import 'core/localization/app_localizations_extension.dart';
import 'core/localization/locale_controller.dart';
import 'core/localization/locale_scope.dart';
import 'core/localization/locale_storage.dart';
import 'core/routing/app_routes.dart';
import 'features/auth/data/auth_api_service.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/home/presentation/citizen_home_screen.dart';
import 'features/home/presentation/overseer_home_screen.dart';
import 'features/home/presentation/staff_home_screen.dart';
import 'features/map/presentation/overseer_map_screen.dart';
import 'features/overseer/presentation/overseer_assign_staff_screen.dart';
import 'features/overseer/presentation/overseer_create_task_screen.dart';
import 'features/overseer/presentation/overseer_report_detail_screen.dart';
import 'features/overseer/presentation/overseer_task_detail_screen.dart';
import 'features/reports/data/report_api_service.dart';
import 'features/reports/presentation/citizen_create_report_screen.dart';
import 'features/reports/presentation/citizen_edit_report_screen.dart';
import 'features/reports/presentation/citizen_report_detail_screen.dart';
import 'features/tasks/data/task_api_service.dart';
import 'features/tasks/presentation/staff_complete_task_screen.dart';
import 'features/tasks/presentation/staff_task_detail_screen.dart';
import 'features/tasks/presentation/staff_report_detail_screen.dart';
import 'features/tasks/presentation/staff_task_inbox_screen.dart';
import 'features/tasks/presentation/staff_task_route_map_screen.dart';
import 'features/users/data/user_api_service.dart';
import 'features/users/presentation/overseer_create_user_screen.dart';
import 'features/users/presentation/overseer_staff_profile_screen.dart';
import 'features/users/presentation/my_profile_screen.dart';
import 'features/users/presentation/staff_public_profile_screen.dart';

class SmartCityReportApp extends StatelessWidget {
  SmartCityReportApp({
    super.key,
    AuthApiService? authApiService,
    ReportApiService? reportApiService,
    TaskApiService? taskApiService,
    UserApiService? userApiService,
    RoadRouteService? roadRouteService,
    LocaleController? localeController,
  }) : authApiService = authApiService ?? BackendAuthApiService(),
       reportApiService = reportApiService ?? BackendReportApiService(),
       taskApiService = taskApiService ?? BackendTaskApiService(),
       userApiService = userApiService ?? BackendUserApiService(),
       roadRouteService = roadRouteService ?? OsrmRoadRouteService(),
       localeController =
           localeController ?? LocaleController(storage: MemoryLocaleStorage());

  final AuthApiService authApiService;
  final ReportApiService reportApiService;
  final TaskApiService taskApiService;
  final UserApiService userApiService;
  final RoadRouteService roadRouteService;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) => LocaleScope(
        controller: localeController,
        child: MaterialApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          locale: localeController.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
            AppRoutes.login: (_) => LoginScreen(authApiService: authApiService),
            AppRoutes.register: (_) =>
                RegisterScreen(authApiService: authApiService),
            AppRoutes.citizenHome: (_) => CitizenHomeScreen(
              authApiService: authApiService,
              reportApiService: reportApiService,
            ),
            AppRoutes.citizenReports: (_) => CitizenHomeScreen(
              authApiService: authApiService,
              reportApiService: reportApiService,
            ),
            AppRoutes.staffHome: (_) => StaffHomeScreen(
              authApiService: authApiService,
              taskApiService: taskApiService,
              reportApiService: reportApiService,
            ),
            AppRoutes.overseerHome: (_) => OverseerHomeScreen(
              authApiService: authApiService,
              reportApiService: reportApiService,
              taskApiService: taskApiService,
              userApiService: userApiService,
            ),
            AppRoutes.overseerCreateUser: (_) =>
                OverseerCreateUserScreen(userApiService: userApiService),
            AppRoutes.overseerStaffProfile: (_) =>
                OverseerStaffProfileScreen(userApiService: userApiService),
            AppRoutes.myProfile: (_) =>
                MyProfileScreen(userApiService: userApiService),
            AppRoutes.staffPublicProfile: (_) =>
                StaffPublicProfileScreen(userApiService: userApiService),
            AppRoutes.citizenCreateReport: (_) =>
                CitizenCreateReportScreen(reportApiService: reportApiService),
            AppRoutes.citizenReportDetail: (_) =>
                CitizenReportDetailScreen(reportApiService: reportApiService),
            AppRoutes.citizenEditReport: (_) =>
                CitizenEditReportScreen(reportApiService: reportApiService),
            AppRoutes.overseerReportDetail: (_) =>
                OverseerReportDetailScreen(reportApiService: reportApiService),
            AppRoutes.overseerCreateTask: (_) => OverseerCreateTaskScreen(
              taskApiService: taskApiService,
              reportApiService: reportApiService,
              userApiService: userApiService,
            ),
            AppRoutes.overseerTaskDetail: (_) => OverseerTaskDetailScreen(
              taskApiService: taskApiService,
              reportApiService: reportApiService,
            ),
            AppRoutes.overseerAssignStaff: (_) => OverseerAssignStaffScreen(
              taskApiService: taskApiService,
              userApiService: userApiService,
            ),
            AppRoutes.overseerMap: (_) => OverseerMapScreen(
              reportApiService: reportApiService,
              authApiService: authApiService,
            ),
            AppRoutes.staffTasks: (_) => StaffTaskInboxScreen(
              taskApiService: taskApiService,
              reportApiService: reportApiService,
            ),
            AppRoutes.staffTaskDetail: (_) => StaffTaskDetailScreen(
              taskApiService: taskApiService,
              reportApiService: reportApiService,
            ),
            AppRoutes.staffTaskRoute: (_) => StaffTaskRouteMapScreen(
              taskApiService: taskApiService,
              reportApiService: reportApiService,
            ),
            AppRoutes.staffReportDetail: (_) =>
                StaffReportDetailScreen(reportApiService: reportApiService),
            AppRoutes.staffCompleteTask: (_) =>
                StaffCompleteTaskScreen(taskApiService: taskApiService),
          },
        ),
      ),
    );
  }
}
