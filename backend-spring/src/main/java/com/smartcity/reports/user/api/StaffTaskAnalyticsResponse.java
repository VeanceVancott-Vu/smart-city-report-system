package com.smartcity.reports.user.api;

import com.smartcity.reports.task.domain.TaskStatus;

import java.util.Map;

public record StaffTaskAnalyticsResponse(
        long totalTasks,
        Map<TaskStatus, Long> byStatus
) {
}
