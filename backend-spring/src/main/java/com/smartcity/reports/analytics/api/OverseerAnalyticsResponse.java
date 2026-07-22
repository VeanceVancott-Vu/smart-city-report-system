package com.smartcity.reports.analytics.api;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.task.domain.TaskStatus;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public record OverseerAnalyticsResponse(
        Instant generatedAt,
        AnalyticsFiltersResponse filters,
        ReportOverviewResponse reports,
        TaskOverviewResponse tasks,
        List<TrendPointResponse> trends,
        List<CategoryBreakdownResponse> categories,
        List<StaffWorkloadResponse> staffWorkloads,
        List<AttentionItemResponse> attentionItems,
        List<AnalyticsMapPointResponse> mapPoints
) {

    public record AnalyticsFiltersResponse(
            Instant from,
            Instant to,
            IssueCategory category,
            UUID staffId,
            String area
    ) {
    }

    public record ReportOverviewResponse(
            long totalReports,
            Map<ReportStatus, Long> byStatus,
            long totalUpvotes,
            double averagePriority,
            double fixedRate,
            double cancellationRate
    ) {
    }

    public record TaskOverviewResponse(
            long totalTasks,
            Map<TaskStatus, Long> byStatus,
            long unassignedTasks,
            long activeTasks,
            long pendingReviewTasks,
            long completedTasks,
            double completionRate,
            double averageWorkHours,
            double averageReviewHours,
            double averageResolutionHours
    ) {
    }

    public record TrendPointResponse(
            LocalDate periodStart,
            long reportsCreated,
            long reportsFixed,
            long tasksCreated,
            long tasksClosed
    ) {
    }

    public record CategoryBreakdownResponse(
            IssueCategory category,
            long reports,
            long fixedReports,
            long tasks,
            long closedTasks
    ) {
    }

    public record StaffWorkloadResponse(
            UUID staffId,
            String fullName,
            String email,
            boolean activeAccount,
            long totalTasks,
            long activeTasks,
            long pendingReviewTasks,
            long completedTasks,
            long deniedTasks,
            double completionRate,
            double averageCompletionHours
    ) {
    }

    public record AttentionItemResponse(
            String entityType,
            UUID id,
            String title,
            String status,
            String reason,
            int priorityScore,
            UUID staffId,
            String staffName,
            String addressText,
            Instant updatedAt
    ) {
    }

    public record AnalyticsMapPointResponse(
            UUID reportId,
            String title,
            IssueCategory category,
            ReportStatus status,
            double latitude,
            double longitude,
            String addressText,
            int priorityScore,
            int upvoteCount
    ) {
    }
}
