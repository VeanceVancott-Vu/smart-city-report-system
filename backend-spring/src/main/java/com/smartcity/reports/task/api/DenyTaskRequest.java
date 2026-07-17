package com.smartcity.reports.task.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record DenyTaskRequest(
        @NotBlank(message = "Denial note is required")
        @Size(max = 2000, message = "Denial note must be 2000 characters or fewer")
        String note
) {
}
