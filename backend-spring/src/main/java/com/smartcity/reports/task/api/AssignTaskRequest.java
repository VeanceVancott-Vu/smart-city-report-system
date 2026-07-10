package com.smartcity.reports.task.api;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record AssignTaskRequest(
        @NotNull
        UUID assignedStaffId
) {
}
