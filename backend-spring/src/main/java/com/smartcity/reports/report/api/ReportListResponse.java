package com.smartcity.reports.report.api;

import java.util.List;

public record ReportListResponse(
        List<ReportResponse> reports
) {
}