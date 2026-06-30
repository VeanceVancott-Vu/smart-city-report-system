class AppRoutes {
  const AppRoutes._();

  static const login = '/';
  static const register = '/register';
  static const citizenHome = '/citizen';
  static const staffHome = '/staff';
  static const overseerHome = '/overseer';
  static const citizenReports = '/citizen/reports';
  static const citizenCreateReport = '/citizen/reports/create';
  static const citizenReportDetail = '/citizen/reports/detail';
  static const citizenEditReport = '/citizen/reports/edit';
  static const citizenMap = '/citizen/map';
  static const createReport = citizenCreateReport;
  static const overseerMap = '/overseer/map';
  static const overseerReports = '/overseer/reports';
  static const overseerCreateUser = '/overseer/users/create';
  static const overseerReportDetail = '/overseer/reports/detail';
  static const overseerTasks = '/overseer/tasks';
  static const overseerCreateTask = '/overseer/tasks/create';
  static const overseerTaskDetail = '/overseer/tasks/detail';
  static const overseerAssignStaff = '/overseer/tasks/assign';
  static const staffTasks = '/staff/tasks';
  static const staffTaskDetail = '/staff/tasks/detail';
  static const staffReportDetail = '/staff/reports/detail';
  static const staffCompleteTask = '/staff/tasks/complete';
}
