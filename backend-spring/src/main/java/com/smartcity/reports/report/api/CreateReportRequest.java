package com.smartcity.reports.report.api;

import com.smartcity.reports.issue.IssueCategory;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateReportRequest(
        @NotBlank(message = "Title is required")
        @Size(max = 120, message = "Title must be 120 characters or fewer")
        String title,

        @NotBlank(message = "Description is required")
        @Size(max = 2000, message = "Description must be 2000 characters or fewer")
        String description,

        @NotNull(message = "Category is required")
        IssueCategory category,

        @NotNull(message = "Latitude is required")
        @DecimalMin(value = "-90.0", message = "Latitude must be at least -90")
        @DecimalMax(value = "90.0", message = "Latitude must be at most 90")
        Double latitude,

        @NotNull(message = "Longitude is required")
        @DecimalMin(value = "-180.0", message = "Longitude must be at least -180")
        @DecimalMax(value = "180.0", message = "Longitude must be at most 180")
        Double longitude,

        @Size(max = 255, message = "Address text must be 255 characters or fewer")
        String addressText,

        @NotBlank(message = "Before photo is required")
        @Size(max = 2048, message = "Before photo URL must be 2048 characters or fewer")
        @Pattern(
                regexp = "^$|" + ReportPhotoUrls.REPORT_BEFORE_URL_PATTERN,
                message = ReportPhotoUrls.REPORT_BEFORE_URL_MESSAGE
        )
        String beforePhotoUrl,

        Boolean anonymous
) {
    public boolean isAnonymous() {
        return Boolean.TRUE.equals(anonymous);
    }
}