package com.smartcity.reports.user.api;

import com.smartcity.reports.task.api.TaskResponse;
import com.smartcity.reports.user.domain.UserRole;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record StaffDetailProfileResponse(
        UUID id,
        String fullName,
        String email,
        UserRole role,
        boolean active,
        Instant createdAt,
        StaffTaskAnalyticsResponse taskAnalytics,
        List<TaskResponse> tasks
) {
}
