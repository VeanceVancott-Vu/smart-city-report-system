package com.smartcity.reports.user.api;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;

import java.time.Instant;
import java.util.UUID;

public record UserProfileResponse(
        UUID id,
        String fullName,
        String email,
        UserRole role,
        boolean active,
        Instant createdAt,
        CitizenReportAnalyticsResponse citizenReportAnalytics,
        StaffTaskAnalyticsResponse staffTaskAnalytics
) {
    public static UserProfileResponse basic(User user) {
        return new UserProfileResponse(
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getRole(),
                user.isActive(),
                user.getCreatedAt(),
                null,
                null
        );
    }
}
