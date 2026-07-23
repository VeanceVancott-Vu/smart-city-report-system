package com.smartcity.reports.priority.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.time.Duration;

@ConfigurationProperties(prefix = "app.priority-ai")
public record PriorityAiProperties(
        String baseUrl,
        boolean enabled,
        Duration connectTimeout,
        Duration readTimeout
) {
}
