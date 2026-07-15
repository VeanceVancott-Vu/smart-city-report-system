package com.smartcity.reports.task.api;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CompleteTaskRequest(
        @Size(max = 2048, message = "After photo URL must be 2048 characters or fewer")
        @Pattern(
                regexp = "^$|" + TaskPhotoUrls.TASK_AFTER_URL_PATTERN,
                message = TaskPhotoUrls.TASK_AFTER_URL_MESSAGE
        )
        String afterPhotoUrl,

        @Size(max = 4000, message = "Staff note must be 4000 characters or fewer")
        String staffNote
) {
}
