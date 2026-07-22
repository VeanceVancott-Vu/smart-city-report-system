package com.smartcity.reports.analytics.api;

import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.AnalyticsFiltersResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.ReportOverviewResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.TaskOverviewResponse;
import com.smartcity.reports.analytics.application.OverseerAnalyticsService;
import com.smartcity.reports.common.ApiExceptionHandler;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.security.JwtAuthenticationFilter;
import com.smartcity.reports.task.domain.TaskStatus;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.EnumMap;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(OverseerAnalyticsController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(ApiExceptionHandler.class)
class OverseerAnalyticsControllerTest {

    private static final Instant TO = Instant.parse("2026-07-22T08:00:00Z");

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OverseerAnalyticsService analyticsService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    void returnsCompleteAnalyticsContract() throws Exception {
        User overseer = user();
        EnumMap<ReportStatus, Long> reportCounts = zeroReportCounts();
        reportCounts.put(ReportStatus.SUBMITTED, 3L);
        EnumMap<TaskStatus, Long> taskCounts = zeroTaskCounts();
        taskCounts.put(TaskStatus.IN_PROGRESS, 2L);
        when(analyticsService.getAnalytics(
                nullable(Instant.class),
                eq(TO),
                nullable(com.smartcity.reports.issue.IssueCategory.class),
                nullable(UUID.class),
                eq("District 1"),
                nullable(User.class)
        )).thenReturn(new OverseerAnalyticsResponse(
                TO,
                new AnalyticsFiltersResponse(null, TO, null, null, "district 1"),
                new ReportOverviewResponse(3, reportCounts, 5, 1.67, 0, 0),
                new TaskOverviewResponse(2, taskCounts, 0, 2, 0, 0, 0, 0, 0, 0),
                List.of(),
                List.of(),
                List.of(),
                List.of(),
                List.of()
        ));

        mockMvc.perform(get("/api/analytics/overseer")
                        .with(authentication(authenticationToken(overseer)))
                        .queryParam("to", TO.toString())
                        .queryParam("area", "District 1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.generatedAt").value(TO.toString()))
                .andExpect(jsonPath("$.reports.totalReports").value(3))
                .andExpect(jsonPath("$.reports.byStatus.SUBMITTED").value(3))
                .andExpect(jsonPath("$.tasks.totalTasks").value(2))
                .andExpect(jsonPath("$.tasks.byStatus.IN_PROGRESS").value(2))
                .andExpect(jsonPath("$.filters.area").value("district 1"))
                .andExpect(jsonPath("$.staffWorkloads").isArray())
                .andExpect(jsonPath("$.attentionItems").isArray())
                .andExpect(jsonPath("$.mapPoints").isArray());
    }

    private EnumMap<ReportStatus, Long> zeroReportCounts() {
        EnumMap<ReportStatus, Long> counts = new EnumMap<>(ReportStatus.class);
        for (ReportStatus status : ReportStatus.values()) {
            counts.put(status, 0L);
        }
        return counts;
    }

    private EnumMap<TaskStatus, Long> zeroTaskCounts() {
        EnumMap<TaskStatus, Long> counts = new EnumMap<>(TaskStatus.class);
        for (TaskStatus status : TaskStatus.values()) {
            counts.put(status, 0L);
        }
        return counts;
    }

    private User user() {
        User user = new User("overseer@test.com", "Overseer", "hash", UserRole.OVERSEER);
        user.setId(UUID.randomUUID());
        return user;
    }

    private UsernamePasswordAuthenticationToken authenticationToken(User user) {
        return new UsernamePasswordAuthenticationToken(
                user,
                null,
                List.of(new SimpleGrantedAuthority("ROLE_OVERSEER"))
        );
    }
}
