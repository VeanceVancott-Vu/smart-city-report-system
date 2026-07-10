package com.smartcity.reports.report.api;

import java.util.UUID;

public record ReportUpvoteResponse(
        UUID id,
        int upvoteCount,
        int priorityScore,
        boolean hasUpvoted
) {
}