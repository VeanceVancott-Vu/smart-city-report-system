package com.smartcity.reports.auth;

import com.smartcity.reports.user.UserRole;

import java.util.UUID;

public record CurrentUserResponse(
        UUID id,
        String fullName,
        String email,
        UserRole role
) {
}
