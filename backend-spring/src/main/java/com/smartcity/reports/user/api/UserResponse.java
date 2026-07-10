package com.smartcity.reports.user.api;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;

import java.util.UUID;

public record UserResponse(
        UUID id,
        String fullName,
        String email,
        UserRole role
) {
    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getRole()
        );
    }
}
