package com.smartcity.reports.priority.infrastructure;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.priority.config.PriorityAiProperties;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.ExpectedCount.once;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.jsonPath;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class FastApiPriorityScoringClientTest {

    @Test
    void springConstructorIsExplicitlyAutowired() throws NoSuchMethodException {
        var constructor = FastApiPriorityScoringClient.class.getConstructor(
                RestClient.Builder.class,
                PriorityAiProperties.class
        );

        assertThat(constructor.isAnnotationPresent(Autowired.class)).isTrue();
    }

    @Test
    void sendsBatchContractAndReturnsValidScores() {
        RestClient.Builder builder = RestClient.builder().baseUrl("http://priority.test");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        FastApiPriorityScoringClient client = new FastApiPriorityScoringClient(
                builder.build(),
                true
        );
        Report report = report();

        server.expect(once(), requestTo("http://priority.test/ai/priorities"))
                .andExpect(method(org.springframework.http.HttpMethod.POST))
                .andExpect(jsonPath("$.reports[0].reportId").value(report.getId().toString()))
                .andExpect(jsonPath("$.reports[0].category").value("WATER_LEAK"))
                .andExpect(jsonPath("$.reports[0].upvoteCount").value(3))
                .andRespond(withSuccess(
                        """
                        {
                          "modelVersion": "priority-lite-v1",
                          "results": [
                            {
                              "reportId": "%s",
                              "priorityScore": 84,
                              "priorityLevel": "critical",
                              "components": {
                                "upvoteScore": 30,
                                "crowdScore": 24,
                                "urgencyScore": 30
                              },
                              "reasons": ["High urgency"]
                            }
                          ]
                        }
                        """.formatted(report.getId()),
                        MediaType.APPLICATION_JSON
                ));

        Map<UUID, Integer> scores = client.calculatePriorities(List.of(report));

        assertThat(scores).containsEntry(report.getId(), 84);
        server.verify();
    }

    @Test
    void returnsEmptyScoresWhenFastApiIsUnavailable() {
        RestClient.Builder builder = RestClient.builder().baseUrl("http://priority.test");
        MockRestServiceServer server = MockRestServiceServer.bindTo(builder).build();
        FastApiPriorityScoringClient client = new FastApiPriorityScoringClient(
                builder.build(),
                true
        );
        server.expect(once(), requestTo("http://priority.test/ai/priorities"))
                .andRespond(withServerError());

        Map<UUID, Integer> scores = client.calculatePriorities(List.of(report()));

        assertThat(scores).isEmpty();
        server.verify();
    }

    private Report report() {
        User creator = new User(
                "citizen@example.local",
                "Citizen",
                "hash",
                UserRole.CITIZEN
        );
        creator.setId(UUID.randomUUID());
        Report report = new Report(
                "Burst water pipe",
                "Urgent flooding outside the market.",
                IssueCategory.WATER_LEAK,
                10.7769,
                106.7009,
                "Ben Thanh Market",
                "/uploads/report-before/leak.jpg",
                false,
                creator
        );
        report.setId(UUID.randomUUID());
        report.setCreatedAt(Instant.parse("2026-07-23T04:00:00Z"));
        report.setUpdatedAt(Instant.parse("2026-07-23T04:00:00Z"));
        report.updateUpvoteCount(3);
        return report;
    }
}
