package com.smartcity.reports.task;

import jakarta.validation.constraints.Size;

public record CompleteTaskRequest(
        @Size(max = 2048)
        String afterPhotoUrl,

        @Size(max = 4000)
        String staffNote
) {
}
