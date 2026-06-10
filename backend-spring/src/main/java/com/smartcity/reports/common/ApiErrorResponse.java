package com.smartcity.reports.common;

import java.time.Instant;
import java.util.Map;

public record ApiErrorResponse(
        Instant timestamp,
        int status,
        String message,
        Map<String, String> errors
) {
    public static ApiErrorResponse of(int status, String message) {
        return new ApiErrorResponse(Instant.now(), status, message, Map.of());
    }

    public static ApiErrorResponse of(int status, String message, Map<String, String> errors) {
        return new ApiErrorResponse(Instant.now(), status, message, errors);
    }
}
