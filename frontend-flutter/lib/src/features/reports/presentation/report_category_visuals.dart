import 'package:flutter/material.dart';

import '../domain/report.dart';

IconData reportCategoryIcon(ReportCategory category) {
  switch (category) {
    case ReportCategory.roadDamage:
      return Icons.construction;
    case ReportCategory.streetLight:
      return Icons.lightbulb;
    case ReportCategory.garbage:
      return Icons.delete_outline;
    case ReportCategory.waterLeak:
      return Icons.opacity;
    case ReportCategory.drainage:
      return Icons.waves;
    case ReportCategory.trafficSign:
      return Icons.traffic;
    case ReportCategory.treeBlockage:
      return Icons.park;
    case ReportCategory.other:
      return Icons.help_outline;
  }
}
