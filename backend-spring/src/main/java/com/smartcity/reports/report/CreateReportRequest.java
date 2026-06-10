package com.smartcity.reports.report;

import com.smartcity.reports.issue.IssueCategory;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateReportRequest(
        @NotBlank
        @Size(max = 120)
        String title,

        @NotBlank
        @Size(max = 2000)
        String description,

        @NotNull
        IssueCategory category,

        @NotNull
        @DecimalMin("-90.0")
        @DecimalMax("90.0")
        Double latitude,

        @NotNull
        @DecimalMin("-180.0")
        @DecimalMax("180.0")
        Double longitude,

        @Size(max = 255)
        String addressText,

        @Size(max = 2048)
        String beforePhotoUrl,

        Boolean anonymous
) {
    public boolean isAnonymous() {
        return Boolean.TRUE.equals(anonymous);
    }
}
