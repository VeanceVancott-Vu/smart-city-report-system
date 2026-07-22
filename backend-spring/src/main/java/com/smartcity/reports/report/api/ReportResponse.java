package com.smartcity.reports.report.api;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.user.api.UserSummaryResponse;
import com.smartcity.reports.report.domain.ReportStatus;

import java.time.Instant;
import java.util.UUID;

public record ReportResponse(
        UUID id,
        String title,
        String description,
        IssueCategory category,
        ReportStatus status,
        double latitude,
        double longitude,
        String addressText,
        String beforePhotoUrl,
        String afterPhotoUrl,
        boolean anonymous,
        int upvoteCount,
        int priorityScore,
        Instant createdAt,
        Instant updatedAt,
        UserSummaryResponse createdBy,
        UserSummaryResponse assignedStaff
) {

    public ReportResponse(
            UUID id,
            String title,
            String description,
            IssueCategory category,
            ReportStatus status,
            double latitude,
            double longitude,
            String addressText,
            String beforePhotoUrl,
            String afterPhotoUrl,
            boolean anonymous,
            int upvoteCount,
            int priorityScore,
            Instant createdAt,
            Instant updatedAt,
            UserSummaryResponse createdBy
    ) {
        this(
                id,
                title,
                description,
                category,
                status,
                latitude,
                longitude,
                addressText,
                beforePhotoUrl,
                afterPhotoUrl,
                anonymous,
                upvoteCount,
                priorityScore,
                createdAt,
                updatedAt,
                createdBy,
                null
        );
    }

    public ReportResponse(
            UUID id,
            String title,
            String description,
            IssueCategory category,
            ReportStatus status,
            double latitude,
            double longitude,
            String addressText,
            String beforePhotoUrl,
            boolean anonymous,
            int upvoteCount,
            int priorityScore,
            Instant createdAt,
            Instant updatedAt,
            UserSummaryResponse createdBy
    ) {
        this(
                id,
                title,
                description,
                category,
                status,
                latitude,
                longitude,
                addressText,
                beforePhotoUrl,
                null,
                anonymous,
                upvoteCount,
                priorityScore,
                createdAt,
                updatedAt,
                createdBy,
                null
        );
    }
}
