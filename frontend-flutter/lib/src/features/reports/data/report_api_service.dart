import '../../../core/services/api_service.dart';
import '../domain/report.dart';

abstract class ReportApiService {
  Future<List<Report>> fetchCitizenReports();

  Future<Report> createReport(NewReportRequest request);
}

class MockReportApiService extends ApiService implements ReportApiService {
  MockReportApiService()
    : _reports = [
        Report(
          id: 'RPT-1004',
          title: 'Broken streetlight near Nguyen Hue',
          description: 'The light has been off for two nights.',
          category: ReportCategory.lighting,
          latitude: 10.7769,
          longitude: 106.7009,
          status: ReportStatus.assigned,
          photoLabel: 'streetlight_before.jpg',
          createdAt: DateTime(2026, 6, 7, 19, 20),
        ),
        Report(
          id: 'RPT-1003',
          title: 'Pothole beside the bus stop',
          description: 'Cars swerve around it during rush hour.',
          category: ReportCategory.road,
          latitude: 10.7827,
          longitude: 106.6994,
          status: ReportStatus.inProgress,
          photoLabel: 'pothole_before.jpg',
          createdAt: DateTime(2026, 6, 6, 8, 15),
        ),
        Report(
          id: 'RPT-1002',
          title: 'Overflowing public bin',
          description: 'Waste is spilling onto the sidewalk.',
          category: ReportCategory.sanitation,
          latitude: 10.7712,
          longitude: 106.7043,
          status: ReportStatus.submitted,
          photoLabel: 'bin_before.jpg',
          createdAt: DateTime(2026, 6, 5, 16, 45),
        ),
      ];

  final List<Report> _reports;

  @override
  Future<List<Report>> fetchCitizenReports() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_reports);
  }

  @override
  Future<Report> createReport(NewReportRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final report = Report(
      id: 'RPT-${1000 + _reports.length + 1}',
      title: request.title,
      description: request.description,
      category: request.category,
      latitude: request.latitude,
      longitude: request.longitude,
      status: ReportStatus.submitted,
      photoLabel: request.photoLabel,
      createdAt: DateTime.now(),
    );

    _reports.insert(0, report);
    return report;
  }
}
