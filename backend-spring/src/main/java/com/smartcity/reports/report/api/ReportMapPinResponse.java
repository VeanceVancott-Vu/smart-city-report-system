package com.smartcity.reports.report.api;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.domain.ReportStatus;

import java.util.UUID;

public record ReportMapPinResponse(
        UUID id,
        String title,
        IssueCategory category,
        ReportStatus status,
        double latitude,
        double longitude,
        int upvoteCount,
        int priorityScore,
        UUID creatorId
) {
}
