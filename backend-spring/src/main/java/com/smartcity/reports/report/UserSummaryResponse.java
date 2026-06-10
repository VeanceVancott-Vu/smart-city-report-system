package com.smartcity.reports.report;

import com.smartcity.reports.user.UserRole;

import java.util.UUID;

public record UserSummaryResponse(
        UUID id,
        String displayName,
        UserRole role
) {
}
