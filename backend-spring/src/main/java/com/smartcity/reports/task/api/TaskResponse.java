package com.smartcity.reports.task.api;

import com.smartcity.reports.task.domain.TaskStatus;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.user.api.UserSummaryResponse;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record TaskResponse(
        UUID id,
        String title,
        String description,
        IssueCategory category,
        TaskStatus status,
        double latitude,
        double longitude,
        String addressText,
        int priorityScore,
        UserSummaryResponse assignedStaff,
        UserSummaryResponse createdByOverseer,
        String beforePhotoUrl,
        String afterPhotoUrl,
        String staffNote,
        Double aiConfidenceScore,
        String aiDecision,
        Instant startedAt,
        Instant submittedAt,
        Instant reviewedAt,
        Instant closedAt,
        Instant createdAt,
        Instant updatedAt,
        List<UUID> reportIds
) {
}
