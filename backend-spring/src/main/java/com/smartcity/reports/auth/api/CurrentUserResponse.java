package com.smartcity.reports.auth.api;

import com.smartcity.reports.user.domain.UserRole;

import java.util.UUID;

public record CurrentUserResponse(
        UUID id,
        String fullName,
        String email,
        UserRole role
) {
}
