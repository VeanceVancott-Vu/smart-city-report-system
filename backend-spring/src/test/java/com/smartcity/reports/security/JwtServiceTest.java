package com.smartcity.reports.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class JwtServiceTest {

    private final JwtService jwtService = new JwtService(
            new ObjectMapper(),
            new JwtProperties("test-secret-with-at-least-32-characters", 120)
    );

    @Test
    void generateTokenCanBeParsedAndValidated() {
        UUID userId = UUID.randomUUID();
        User user = new User(
                "citizen@example.local",
                "Citizen User",
                "$2a$10$abcdefghijklmnopqrstuu",
                UserRole.CITIZEN
        );
        user.setId(userId);

        String token = jwtService.generateToken(user);

        JwtClaims claims = jwtService.parseAndValidate(token);

        assertThat(claims.userId()).isEqualTo(userId);
        assertThat(claims.email()).isEqualTo("citizen@example.local");
        assertThat(claims.role()).isEqualTo(UserRole.CITIZEN);
        assertThat(claims.expiresAt()).isAfter(claims.issuedAt());
    }

    @Test
    void parseRejectsTamperedToken() {
        UUID userId = UUID.randomUUID();
        User user = new User("staff@example.local", "Staff User", "hash", UserRole.STAFF);
        user.setId(userId);
        String token = jwtService.generateToken(user);
        String tamperedToken = token.substring(0, token.length() - 2) + "xx";

        assertThatThrownBy(() -> jwtService.parseAndValidate(tamperedToken))
                .isInstanceOf(InvalidJwtException.class)
                .hasMessageContaining("signature");
    }
}
