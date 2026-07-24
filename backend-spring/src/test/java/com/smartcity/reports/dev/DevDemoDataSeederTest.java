package com.smartcity.reports.dev;

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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DevDemoDataSeederTest {

    private static final Instant NOW = Instant.parse("2026-07-23T12:00:00Z");

    @Mock
    private UserRepository userRepository;

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private TaskRepository taskRepository;

    @Test
    void seederOnlyRunsForLocalAndDevProfilesAfterUsers() {
        Profile profile = DevDemoDataSeeder.class.getAnnotation(Profile.class);
        Order order = DevDemoDataSeeder.class.getAnnotation(Order.class);

        assertThat(profile).isNotNull();
        assertThat(profile.value()).containsExactlyInAnyOrder("local", "dev");
        assertThat(order).isNotNull();
        assertThat(order.value()).isEqualTo(2);
    }

    @Test
    void seedDemoDataCreatesNaturalAnalyticsDistributionWithStableIds() {
        DevDemoDataSeeder seeder = new DevDemoDataSeeder(
                userRepository,
                reportRepository,
                taskRepository,
                Clock.fixed(NOW, ZoneOffset.UTC)
        );
        List<User> citizens = List.of(
                user("00000000-0000-0000-0000-000000000101", "citizen@test.com", UserRole.CITIZEN),
                user("00000000-0000-0000-0000-000000000102", "linh.nguyen@test.com", UserRole.CITIZEN),
                user("00000000-0000-0000-0000-000000000103", "minh.tran@test.com", UserRole.CITIZEN),
                user("00000000-0000-0000-0000-000000000104", "an.le@test.com", UserRole.CITIZEN)
        );
        List<User> staff = List.of(
                user("00000000-0000-0000-0000-000000000201", "staff@test.com", UserRole.STAFF),
                user("00000000-0000-0000-0000-000000000202", "mai.nguyen.staff@test.com", UserRole.STAFF),
                user("00000000-0000-0000-0000-000000000203", "quang.tran.staff@test.com", UserRole.STAFF),
                user("00000000-0000-0000-0000-000000000204", "thuy.le.staff@test.com", UserRole.STAFF)
        );
        User overseer = user(
                "00000000-0000-0000-0000-000000000301",
                "overseer@test.com",
                UserRole.OVERSEER
        );
        stubUsers(citizens, staff, overseer);
        when(reportRepository.findById(any(UUID.class))).thenReturn(Optional.empty());
        when(taskRepository.findById(any(UUID.class))).thenReturn(Optional.empty());
        when(reportRepository.save(any(Report.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(reportRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        seeder.seedDemoData();

        ArgumentCaptor<Report> reportCaptor = ArgumentCaptor.forClass(Report.class);
        verify(reportRepository, atLeast(DevDemoDataSeeder.ANALYTICS_REPORT_COUNT))
                .save(reportCaptor.capture());
        Map<UUID, Report> reportsById = reportCaptor.getAllValues().stream()
                .collect(Collectors.toMap(
                        Report::getId,
                        Function.identity(),
                        (previous, replacement) -> replacement
                ));
        List<Report> analyticsReports = IntStream.range(0, DevDemoDataSeeder.ANALYTICS_REPORT_COUNT)
                .mapToObj(index -> reportsById.get(DevDemoDataSeeder.analyticsReportId(index)))
                .toList();

        assertThat(analyticsReports).doesNotContainNull();
        assertThat(analyticsReports).hasSize(96);
        assertThat(new HashSet<>(analyticsReports.stream().map(Report::getCategory).toList()))
                .containsExactlyInAnyOrder(IssueCategory.values());
        assertThat(new HashSet<>(analyticsReports.stream().map(Report::getStatus).toList()))
                .containsExactlyInAnyOrder(ReportStatus.values());
        assertThat(analyticsReports).filteredOn(report -> report.getLinkedTaskId() != null).hasSize(64);
        assertThat(analyticsReports).filteredOn(report -> report.getStatus() == ReportStatus.FIXED).hasSize(20);
        assertThat(analyticsReports).filteredOn(report -> !report.getCreatedAt().isBefore(NOW.minus(Duration.ofDays(30))))
                .hasSize(20);
        assertThat(analyticsReports.stream().map(Report::getCreatedAt).min(Instant::compareTo).orElseThrow())
                .isBefore(NOW.minus(Duration.ofDays(180)));
        assertThat(analyticsReports.stream().map(Report::getCreatedAt).max(Instant::compareTo).orElseThrow())
                .isAfter(NOW.minus(Duration.ofDays(5)));
        assertThat(analyticsReports).extracting(Report::getUpvoteCount)
                .contains(0)
                .anyMatch(upvotes -> upvotes >= 12);
        assertThat(new HashSet<>(analyticsReports.stream()
                .map(report -> report.getCreatedBy().getEmail())
                .toList()))
                .containsExactlyInAnyOrder(
                        "citizen@test.com",
                        "linh.nguyen@test.com",
                        "minh.tran@test.com",
                        "an.le@test.com"
                );
        assertThat(analyticsReports).extracting(Report::getAddressText)
                .anyMatch(address -> address.contains("Hai Chau District"))
                .anyMatch(address -> address.contains("Son Tra District"))
                .anyMatch(address -> address.contains("Thanh Khe District"))
                .anyMatch(address -> address.contains("Ngu Hanh Son District"))
                .anyMatch(address -> address.contains("Hoa Hai Ward"))
                .anyMatch(address -> address.contains("Cam Le District"))
                .anyMatch(address -> address.contains("Lien Chieu District"));
        assertThat(analyticsReports).allSatisfy(report -> {
            assertThat(report.getLatitude()).isBetween(15.9, 16.2);
            assertThat(report.getLongitude()).isBetween(108.1, 108.3);
        });

        ArgumentCaptor<Task> taskCaptor = ArgumentCaptor.forClass(Task.class);
        verify(taskRepository, atLeast(DevDemoDataSeeder.ANALYTICS_TASK_COUNT))
                .save(taskCaptor.capture());
        Map<UUID, Task> tasksById = taskCaptor.getAllValues().stream()
                .collect(Collectors.toMap(
                        Task::getId,
                        Function.identity(),
                        (previous, replacement) -> replacement
                ));
        List<Task> analyticsTasks = IntStream.range(0, DevDemoDataSeeder.ANALYTICS_TASK_COUNT)
                .mapToObj(index -> tasksById.get(DevDemoDataSeeder.analyticsTaskId(index)))
                .toList();

        assertThat(analyticsTasks).doesNotContainNull();
        assertThat(analyticsTasks).hasSize(64);
        assertThat(analyticsTasks).extracting(Task::getTitle)
                .contains("Resolve repair the damaged road surface in Hai Chau District");
        assertThat(analyticsTasks).allSatisfy(task -> {
            assertThat(task.getLatitude()).isBetween(15.9, 16.2);
            assertThat(task.getLongitude()).isBetween(108.1, 108.3);
        });
        assertThat(new HashSet<>(analyticsTasks.stream().map(Task::getStatus).toList()))
                .containsExactlyInAnyOrder(
                        TaskStatus.NEW,
                        TaskStatus.ASSIGNED,
                        TaskStatus.IN_PROGRESS,
                        TaskStatus.DONE,
                        TaskStatus.DENIED,
                        TaskStatus.APPROVED,
                        TaskStatus.CLOSED,
                        TaskStatus.CANCELLED
                );
        assertThat(analyticsTasks).filteredOn(task -> task.getAssignedStaff() == null).hasSize(6);
        assertThat(new HashSet<>(analyticsTasks.stream()
                .filter(task -> task.getAssignedStaff() != null)
                .map(task -> task.getAssignedStaff().getEmail())
                .toList()))
                .containsExactlyInAnyOrder(
                        "staff@test.com",
                        "mai.nguyen.staff@test.com",
                        "quang.tran.staff@test.com",
                        "thuy.le.staff@test.com"
                );
        assertThat(analyticsTasks).allSatisfy(task -> {
            assertThat(task.getCreatedByOverseer()).isEqualTo(overseer);
            assertThat(task.getReports()).hasSize(1);
            assertThat(task.getReports().iterator().next().getLinkedTaskId()).isEqualTo(task.getId());
        });
        assertThat(analyticsTasks).filteredOn(task -> task.getStatus() == TaskStatus.CLOSED)
                .allSatisfy(task -> {
                    assertThat(task.getStartedAt()).isNotNull();
                    assertThat(task.getSubmittedAt()).isNotNull();
                    assertThat(task.getReviewedAt()).isNotNull();
                    assertThat(task.getClosedAt()).isNotNull();
                });

        verify(taskRepository).existsByTitleAndCreatedByOverseer_EmailIgnoreCase(
                "Resolve repair the damaged road surface in Hai Chau District",
                "overseer@test.com"
        );
        verify(reportRepository).findFirstByTitleAndCreatedBy_EmailIgnoreCase(
                "Pothole beside the bus stop",
                "citizen@test.com"
        );
        verify(taskRepository).findFirstByTitleAndCreatedByOverseer_EmailIgnoreCase(
                "Repair road damage near Bach Dang",
                "overseer@test.com"
        );
    }

    private void stubUsers(List<User> citizens, List<User> staff, User overseer) {
        for (User user : citizens) {
            when(userRepository.findByEmailIgnoreCase(user.getEmail())).thenReturn(Optional.of(user));
        }
        for (User user : staff) {
            when(userRepository.findByEmailIgnoreCase(user.getEmail())).thenReturn(Optional.of(user));
        }
        when(userRepository.findByEmailIgnoreCase(overseer.getEmail())).thenReturn(Optional.of(overseer));
    }

    private User user(String id, String email, UserRole role) {
        User user = new User(email, "Seed User", "hash", role);
        user.setId(UUID.fromString(id));
        return user;
    }
}
