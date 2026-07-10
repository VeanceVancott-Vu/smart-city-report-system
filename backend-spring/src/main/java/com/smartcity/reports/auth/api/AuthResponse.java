package com.smartcity.reports.auth.api;

public record AuthResponse(
        String token,
        String tokenType,
        CurrentUserResponse user
) {
    public static AuthResponse bearer(String token, CurrentUserResponse user) {
        return new AuthResponse(token, "Bearer", user);
    }
}
