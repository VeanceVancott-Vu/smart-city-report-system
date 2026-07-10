package com.smartcity.reports.user.api;

import com.smartcity.reports.task.api.TaskResponse;
import java.util.List;
import java.util.UUID;

public record StaffSummaryResponse(
        UUID id,
        String fullName,
        String email,
        boolean active,
        int activeTasksCount,
        int completedTasksCount,
        List<TaskResponse> tasks
) {}
