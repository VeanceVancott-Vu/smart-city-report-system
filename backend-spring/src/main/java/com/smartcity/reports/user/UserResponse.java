package com.smartcity.reports.user;

import java.util.UUID;

public record UserResponse(
        UUID id,
        String fullName,
        String email,
        UserRole role
) {
    static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getFullName(),
                user.getEmail(),
                user.getRole()
        );
    }
}
