package com.smartcity.reports.user.api;

import com.smartcity.reports.report.domain.ReportStatus;

import java.util.Map;

public record CitizenReportAnalyticsResponse(
        long totalReports,
        Map<ReportStatus, Long> byStatus
) {
}
