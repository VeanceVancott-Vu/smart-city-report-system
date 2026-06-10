package com.smartcity.reports.task;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record AssignTaskRequest(
        @NotNull
        UUID assignedStaffId
) {
}
