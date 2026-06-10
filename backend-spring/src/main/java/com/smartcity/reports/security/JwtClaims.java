package com.smartcity.reports.security;

import com.smartcity.reports.user.UserRole;

import java.time.Instant;
import java.util.UUID;

public record JwtClaims(
        UUID userId,
        String email,
        UserRole role,
        Instant issuedAt,
        Instant expiresAt
) {
}
