package com.smartcity.reports.dev;

import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.persistence.UserRepository;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DevDemoDataSeederTest {

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
    void seedDemoDataCreatesAssignedTasksAndLinkedReports() {
        DevDemoDataSeeder seeder = new DevDemoDataSeeder(
                userRepository,
                reportRepository,
                taskRepository
        );
        User citizen = user("00000000-0000-0000-0000-000000000101", "citizen@test.com", UserRole.CITIZEN);
        User staff = user("00000000-0000-0000-0000-000000000102", "staff@test.com", UserRole.STAFF);
        User overseer = user("00000000-0000-0000-0000-000000000103", "overseer@test.com", UserRole.OVERSEER);

        when(userRepository.findByEmailIgnoreCase("citizen@test.com")).thenReturn(Optional.of(citizen));
        when(userRepository.findByEmailIgnoreCase("staff@test.com")).thenReturn(Optional.of(staff));
        when(userRepository.findByEmailIgnoreCase("overseer@test.com")).thenReturn(Optional.of(overseer));
        when(reportRepository.findById(any(UUID.class))).thenReturn(Optional.empty());
        when(taskRepository.findById(any(UUID.class))).thenReturn(Optional.empty());
        when(reportRepository.save(any(Report.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(reportRepository.saveAll(any())).thenAnswer(invocation -> invocation.getArgument(0));

        seeder.seedDemoData();

        ArgumentCaptor<Report> reportCaptor = ArgumentCaptor.forClass(Report.class);
        verify(reportRepository, times(6)).save(reportCaptor.capture());
        assertThat(reportCaptor.getAllValues()).extracting(Report::getId)
                .containsExactlyInAnyOrder(
                        DevDemoDataSeeder.POTHOLE_REPORT_ID,
                        DevDemoDataSeeder.STREETLIGHT_REPORT_ID,
                        DevDemoDataSeeder.CURB_REPORT_ID,
                        DevDemoDataSeeder.DRAIN_REPORT_ID,
                        DevDemoDataSeeder.MANHOLE_REPORT_ID,
                        DevDemoDataSeeder.FLOODING_REPORT_ID
                );
        assertThat(reportCaptor.getAllValues()).allSatisfy(report -> {
            assertThat(report.getCreatedBy()).isEqualTo(citizen);
            assertThat(report.getPriorityScore()).isEqualTo(report.getUpvoteCount());
        });

        ArgumentCaptor<Task> taskCaptor = ArgumentCaptor.forClass(Task.class);
        verify(taskRepository, times(6)).save(taskCaptor.capture());
        List<Task> savedTasks = taskCaptor.getAllValues();
        Task roadTask = lastSavedTask(savedTasks, DevDemoDataSeeder.ROAD_TASK_ID);
        Task streetlightTask = lastSavedTask(savedTasks, DevDemoDataSeeder.STREETLIGHT_TASK_ID);
        Task drainageTask = lastSavedTask(savedTasks, DevDemoDataSeeder.DRAINAGE_TASK_ID);

        assertThat(roadTask.getAssignedStaff()).isEqualTo(staff);
        assertThat(roadTask.getCreatedByOverseer()).isEqualTo(overseer);
        assertThat(roadTask.getReports()).extracting(Report::getId)
                .containsExactlyInAnyOrder(
                        DevDemoDataSeeder.POTHOLE_REPORT_ID,
                        DevDemoDataSeeder.CURB_REPORT_ID
                );
        assertThat(streetlightTask.getAssignedStaff()).isEqualTo(staff);
        assertThat(streetlightTask.getReports()).extracting(Report::getId)
                .containsExactly(DevDemoDataSeeder.STREETLIGHT_REPORT_ID);
        assertThat(drainageTask.getAssignedStaff()).isEqualTo(staff);
        assertThat(drainageTask.getReports()).extracting(Report::getId)
                .containsExactlyInAnyOrder(
                        DevDemoDataSeeder.DRAIN_REPORT_ID,
                        DevDemoDataSeeder.MANHOLE_REPORT_ID,
                        DevDemoDataSeeder.FLOODING_REPORT_ID
                );
    }

    private Task lastSavedTask(List<Task> tasks, UUID id) {
        for (int index = tasks.size() - 1; index >= 0; index--) {
            Task task = tasks.get(index);
            if (task.getId().equals(id)) {
                return task;
            }
        }
        throw new IllegalStateException("Saved task not found: " + id);
    }

    private User user(String id, String email, UserRole role) {
        User user = new User(email, "Seed User", "hash", role);
        user.setId(UUID.fromString(id));
        return user;
    }
}