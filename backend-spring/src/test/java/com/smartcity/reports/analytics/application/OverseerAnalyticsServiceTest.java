package com.smartcity.reports.analytics.application;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.domain.TaskStatus;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import com.smartcity.reports.user.persistence.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class OverseerAnalyticsServiceTest {

    private static final Instant NOW = Instant.parse("2026-07-22T08:00:00Z");

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private UserRepository userRepository;

    private OverseerAnalyticsService analyticsService;

    @BeforeEach
    void setUp() {
        analyticsService = new OverseerAnalyticsService(
                reportRepository,
                taskRepository,
                userRepository,
                Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    @Test
    void buildsCompleteOperationalAnalytics() {
        User staff = user(UserRole.STAFF, "Demo Staff");
        Report submitted = report("Broken light", IssueCategory.STREET_LIGHT, "District 1", NOW.minusSeconds(20 * 86400L));
        submitted.updateUpvoteCount(4);
        submitted.updatePriorityScore(4);
        Report fixed = report("Fixed road", IssueCategory.ROAD_DAMAGE, "District 3", NOW.minusSeconds(15 * 86400L));
        fixed.fix();
        fixed.setUpdatedAt(NOW.minusSeconds(3 * 86400L));

        Task unassigned = task("Unassigned task", IssueCategory.GARBAGE, "District 1", null, NOW.minusSeconds(2 * 86400L));
        Task stale = task("Stale task", IssueCategory.STREET_LIGHT, "District 1", staff, NOW.minusSeconds(10 * 86400L));
        stale.setUpdatedAt(NOW.minusSeconds(9 * 86400L));
        Task closed = task("Closed task", IssueCategory.ROAD_DAMAGE, "District 3", staff, NOW.minusSeconds(8 * 86400L));
        closed.start(NOW.minusSeconds(6 * 86400L));
        closed.complete(NOW.minusSeconds(5 * 86400L), "Finished");
        closed.approve(NOW.minusSeconds(4 * 86400L));
        closed.close(NOW.minusSeconds(3 * 86400L));
        closed.setUpdatedAt(NOW.minusSeconds(3 * 86400L));

        when(reportRepository.findAll()).thenReturn(List.of(submitted, fixed));
        when(taskRepository.findAll()).thenReturn(List.of(unassigned, stale, closed));
        when(userRepository.findByRoleOrderByFullNameAsc(UserRole.STAFF)).thenReturn(List.of(staff));

        var response = analyticsService.getAnalytics(
                NOW.minusSeconds(30 * 86400L),
                NOW,
                null,
                null,
                null,
                user(UserRole.OVERSEER, "Overseer")
        );

        assertThat(response.reports().totalReports()).isEqualTo(2);
        assertThat(response.reports().byStatus())
                .containsEntry(ReportStatus.SUBMITTED, 1L)
                .containsEntry(ReportStatus.FIXED, 1L)
                .containsEntry(ReportStatus.CANCELLED, 0L);
        assertThat(response.reports().totalUpvotes()).isEqualTo(4);
        assertThat(response.reports().fixedRate()).isEqualTo(50);

        assertThat(response.tasks().totalTasks()).isEqualTo(3);
        assertThat(response.tasks().byStatus())
                .containsEntry(TaskStatus.NEW, 1L)
                .containsEntry(TaskStatus.ASSIGNED, 1L)
                .containsEntry(TaskStatus.CLOSED, 1L)
                .containsEntry(TaskStatus.PENDING_REVIEW, 0L);
        assertThat(response.tasks().unassignedTasks()).isEqualTo(1);
        assertThat(response.tasks().activeTasks()).isEqualTo(1);
        assertThat(response.tasks().completedTasks()).isEqualTo(1);
        assertThat(response.tasks().averageWorkHours()).isEqualTo(24);

        assertThat(response.staffWorkloads()).singleElement().satisfies(workload -> {
            assertThat(workload.staffId()).isEqualTo(staff.getId());
            assertThat(workload.totalTasks()).isEqualTo(2);
            assertThat(workload.activeTasks()).isEqualTo(1);
            assertThat(workload.completedTasks()).isEqualTo(1);
        });
        assertThat(response.attentionItems())
                .extracting(item -> item.reason())
                .contains("HIGH_PRIORITY_UNASSIGNED_REPORT", "UNASSIGNED_TASK", "STALE_ACTIVE_TASK");
        assertThat(response.categories()).hasSize(IssueCategory.values().length);
        assertThat(response.mapPoints()).hasSize(2);
        assertThat(response.trends()).isNotEmpty();
    }

    @Test
    void appliesDateCategoryStaffAndAreaFilters() {
        User selectedStaff = user(UserRole.STAFF, "Selected Staff");
        User otherStaff = user(UserRole.STAFF, "Other Staff");
        Task selectedTask = task(
                "Selected task",
                IssueCategory.ROAD_DAMAGE,
                "Central District 1",
                selectedStaff,
                NOW.minusSeconds(2 * 86400L)
        );
        Task otherTask = task(
                "Other task",
                IssueCategory.GARBAGE,
                "District 5",
                otherStaff,
                NOW.minusSeconds(2 * 86400L)
        );
        Report selectedReport = report(
                "Selected report",
                IssueCategory.ROAD_DAMAGE,
                "Central District 1",
                NOW.minusSeconds(3 * 86400L)
        );
        selectedTask.linkReport(selectedReport);
        selectedReport.linkToTask(selectedTask.getId());
        Report otherReport = report(
                "Other report",
                IssueCategory.GARBAGE,
                "District 5",
                NOW.minusSeconds(3 * 86400L)
        );

        when(taskRepository.findAll()).thenReturn(List.of(selectedTask, otherTask));
        when(reportRepository.findAll()).thenReturn(List.of(selectedReport, otherReport));
        when(userRepository.findByRoleOrderByFullNameAsc(UserRole.STAFF))
                .thenReturn(List.of(selectedStaff, otherStaff));

        var response = analyticsService.getAnalytics(
                NOW.minusSeconds(7 * 86400L),
                NOW,
                IssueCategory.ROAD_DAMAGE,
                selectedStaff.getId(),
                " district 1 ",
                user(UserRole.OVERSEER, "Overseer")
        );

        assertThat(response.reports().totalReports()).isEqualTo(1);
        assertThat(response.tasks().totalTasks()).isEqualTo(1);
        assertThat(response.staffWorkloads()).singleElement()
                .extracting(workload -> workload.staffId())
                .isEqualTo(selectedStaff.getId());
        assertThat(response.filters().area()).isEqualTo("district 1");
    }

    @Test
    void rejectsInvalidRangeAndNonOverseerUsers() {
        User overseer = user(UserRole.OVERSEER, "Overseer");

        assertThatThrownBy(() -> analyticsService.getAnalytics(
                NOW,
                NOW.minusSeconds(1),
                null,
                null,
                null,
                overseer
        ))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Analytics start date must not be after end date");

        assertThatThrownBy(() -> analyticsService.getAnalytics(
                null,
                null,
                null,
                null,
                null,
                user(UserRole.CITIZEN, "Citizen")
        ))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only overseers can view system analytics");
    }

    private Report report(
            String title,
            IssueCategory category,
            String address,
            Instant createdAt
    ) {
        Report report = new Report(
                title,
                "Description",
                category,
                10.7769,
                106.7009,
                address,
                null,
                false,
                user(UserRole.CITIZEN, "Citizen")
        );
        report.setId(UUID.randomUUID());
        report.setCreatedAt(createdAt);
        report.setUpdatedAt(createdAt);
        return report;
    }

    private Task task(
            String title,
            IssueCategory category,
            String address,
            User staff,
            Instant createdAt
    ) {
        Task task = new Task(
                title,
                "Description",
                category,
                10.7769,
                106.7009,
                address,
                2,
                staff,
                user(UserRole.OVERSEER, "Overseer")
        );
        task.setId(UUID.randomUUID());
        task.setCreatedAt(createdAt);
        task.setUpdatedAt(createdAt);
        return task;
    }

    private User user(UserRole role, String name) {
        User user = new User(name.toLowerCase().replace(' ', '.') + "@test.com", name, "hash", role);
        user.setId(UUID.randomUUID());
        return user;
    }
}
