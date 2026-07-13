package com.smartcity.reports.files.application;

import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;

public record FileDownload(
        Resource resource,
        MediaType contentType,
        long contentLength
) {
}
