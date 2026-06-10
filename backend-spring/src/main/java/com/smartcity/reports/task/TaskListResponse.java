package com.smartcity.reports.task;

import java.util.List;

public record TaskListResponse(
        List<TaskResponse> tasks
) {
}
