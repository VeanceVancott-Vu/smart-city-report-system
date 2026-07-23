package com.smartcity.reports.priority.infrastructure;

import com.smartcity.reports.priority.application.PriorityScoringClient;
import com.smartcity.reports.priority.config.PriorityAiProperties;
import com.smartcity.reports.report.domain.Report;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class FastApiPriorityScoringClient implements PriorityScoringClient {

    private static final Logger LOGGER = LoggerFactory.getLogger(FastApiPriorityScoringClient.class);

    private final RestClient restClient;
    private final boolean enabled;

    @Autowired
    public FastApiPriorityScoringClient(
            RestClient.Builder restClientBuilder,
            PriorityAiProperties properties
    ) {
        this(createRestClient(restClientBuilder, properties), properties.enabled());
    }

    FastApiPriorityScoringClient(RestClient restClient, boolean enabled) {
        this.restClient = restClient;
        this.enabled = enabled;
    }

    @Override
    public Map<UUID, Integer> calculatePriorities(List<Report> reports) {
        if (!enabled || reports.isEmpty()) {
            return Map.of();
        }

        PriorityBatchRequest request = new PriorityBatchRequest(
                reports.stream().map(PriorityReportRequest::from).toList()
        );

        try {
            PriorityBatchResponse response = restClient.post()
                    .uri("/ai/priorities")
                    .body(request)
                    .retrieve()
                    .body(PriorityBatchResponse.class);
            return validScores(response, reports);
        } catch (RestClientException exception) {
            LOGGER.warn("Priority AI service is unavailable; keeping stored report scores: {}",
                    exception.getMessage());
            return Map.of();
        }
    }

    private static RestClient createRestClient(
            RestClient.Builder builder,
            PriorityAiProperties properties
    ) {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(properties.connectTimeout());
        requestFactory.setReadTimeout(properties.readTimeout());
        return builder
                .baseUrl(stripTrailingSlash(properties.baseUrl()))
                .requestFactory(requestFactory)
                .build();
    }

    private static Map<UUID, Integer> validScores(
            PriorityBatchResponse response,
            List<Report> reports
    ) {
        if (response == null || response.results() == null) {
            return Map.of();
        }

        Set<UUID> requestedIds = reports.stream()
                .map(Report::getId)
                .collect(Collectors.toSet());
        Map<UUID, Integer> scores = new LinkedHashMap<>();
        for (PriorityScoreResult result : response.results()) {
            if (result == null
                    || result.reportId() == null
                    || result.priorityScore() == null
                    || !requestedIds.contains(result.reportId())) {
                continue;
            }
            scores.put(result.reportId(), Math.max(0, Math.min(result.priorityScore(), 100)));
        }
        return Map.copyOf(scores);
    }

    private static String stripTrailingSlash(String value) {
        if (value.endsWith("/")) {
            return value.substring(0, value.length() - 1);
        }
        return value;
    }

    private record PriorityBatchRequest(List<PriorityReportRequest> reports) {
    }

    private record PriorityReportRequest(
            UUID reportId,
            String title,
            String description,
            String category,
            String status,
            double latitude,
            double longitude,
            String addressText,
            int upvoteCount,
            Instant createdAt
    ) {
        private static PriorityReportRequest from(Report report) {
            return new PriorityReportRequest(
                    report.getId(),
                    report.getTitle(),
                    report.getDescription(),
                    report.getCategory().name(),
                    report.getStatus().name(),
                    report.getLatitude(),
                    report.getLongitude(),
                    report.getAddressText(),
                    report.getUpvoteCount(),
                    report.getCreatedAt()
            );
        }
    }

    private record PriorityBatchResponse(
            String modelVersion,
            List<PriorityScoreResult> results
    ) {
    }

    private record PriorityScoreResult(
            UUID reportId,
            Integer priorityScore
    ) {
    }
}
