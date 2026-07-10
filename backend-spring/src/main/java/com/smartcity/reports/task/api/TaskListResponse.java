package com.smartcity.reports.task.api;

import java.util.List;

public record TaskListResponse(
        List<TaskResponse> tasks
) {
}
