package com.smartcity.reports.report;

import java.util.UUID;

public record ReportUpvoteResponse(
        UUID id,
        int upvoteCount,
        int priorityScore,
        boolean hasUpvoted
) {
}
