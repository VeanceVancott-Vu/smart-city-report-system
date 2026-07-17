package com.smartcity.reports.task.api;

import jakarta.validation.constraints.Size;

public record CompleteTaskRequest(
        @Size(max = 4000, message = "Staff note must be 4000 characters or fewer")
        String staffNote
) {
}
