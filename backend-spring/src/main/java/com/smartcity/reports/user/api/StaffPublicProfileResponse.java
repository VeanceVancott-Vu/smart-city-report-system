package com.smartcity.reports.user.api;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;

import java.time.Instant;
import java.util.UUID;

public record StaffPublicProfileResponse(
        UUID id,
        String fullName,
        String email,
        UserRole role,
        boolean active,
        Instant createdAt
) {
    public static StaffPublicProfileResponse from(User staff) {
        return new StaffPublicProfileResponse(
                staff.getId(),
                staff.getFullName(),
                staff.getEmail(),
                staff.getRole(),
                staff.isActive(),
                staff.getCreatedAt()
        );
    }
}
