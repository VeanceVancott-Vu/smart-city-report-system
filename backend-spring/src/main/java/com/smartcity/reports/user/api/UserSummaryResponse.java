package com.smartcity.reports.user.api;

import com.smartcity.reports.user.domain.UserRole;

import java.util.UUID;

public record UserSummaryResponse(
        UUID id,
        String displayName,
        UserRole role
) {
}