package com.smartcity.reports.files.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.util.unit.DataSize;

@ConfigurationProperties(prefix = "app.files")
public record FileStorageProperties(
        String uploadDir,
        DataSize maxUploadSize
) {
}
