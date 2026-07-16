import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_report_frontend/src/features/reports/domain/report.dart';
import 'package:smart_city_report_frontend/src/features/reports/presentation/report_category_visuals.dart';

void main() {
  test('uses the same category icons as the citizen map', () {
    expect(reportCategoryIcon(ReportCategory.roadDamage), Icons.construction);
    expect(reportCategoryIcon(ReportCategory.streetLight), Icons.lightbulb);
    expect(reportCategoryIcon(ReportCategory.garbage), Icons.delete_outline);
    expect(reportCategoryIcon(ReportCategory.waterLeak), Icons.opacity);
    expect(reportCategoryIcon(ReportCategory.drainage), Icons.waves);
    expect(reportCategoryIcon(ReportCategory.trafficSign), Icons.traffic);
    expect(reportCategoryIcon(ReportCategory.treeBlockage), Icons.park);
    expect(reportCategoryIcon(ReportCategory.other), Icons.help_outline);
  });
}
