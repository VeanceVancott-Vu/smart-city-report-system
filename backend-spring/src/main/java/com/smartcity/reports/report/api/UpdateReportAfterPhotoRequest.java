package com.smartcity.reports.report.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateReportAfterPhotoRequest(
        @NotBlank(message = "After photo is required")
        @Size(max = 2048, message = "After photo URL must be 2048 characters or fewer")
        @Pattern(
                regexp = ReportPhotoUrls.REPORT_AFTER_URL_PATTERN,
                message = ReportPhotoUrls.REPORT_AFTER_URL_MESSAGE
        )
        String afterPhotoUrl
) {
}
