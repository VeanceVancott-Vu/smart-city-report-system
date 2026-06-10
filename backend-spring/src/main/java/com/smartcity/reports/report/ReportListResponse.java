package com.smartcity.reports.report;

import java.util.List;

public record ReportListResponse(
        List<ReportResponse> reports
) {
}
