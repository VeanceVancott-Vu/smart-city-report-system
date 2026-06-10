package com.smartcity.reports.report;

import com.smartcity.reports.issue.IssueCategory;

import java.util.UUID;

public record ReportMapPinResponse(
        UUID id,
        String title,
        IssueCategory category,
        ReportStatus status,
        double latitude,
        double longitude,
        int upvoteCount,
        int priorityScore
) {
}
