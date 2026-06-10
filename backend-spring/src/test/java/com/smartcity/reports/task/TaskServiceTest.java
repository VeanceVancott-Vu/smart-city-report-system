package com.smartcity.reports.task;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.Report;
import com.smartcity.reports.report.ReportRepository;
import com.smartcity.reports.report.ReportStatus;
import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRepository;
import com.smartcity.reports.user.UserRole;
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
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    private static final Instant NOW = Instant.parse("2026-06-09T04:00:00Z");

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private UserRepository userRepository;

    private final TaskMapper taskMapper = new TaskMapper();

    private TaskService taskService;

    @BeforeEach
    void setUp() {
        taskService = new TaskService(
                taskRepository,
                reportRepository,
                userRepository,
                taskMapper,
                Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    @Test
    void createTaskWithAssignedStaffSetsAssignedStatusAndLinksReports() {
        User overseer = user(UserRole.OVERSEER);
        User staff = user(UserRole.STAFF);
        Report report = reportFor(user(UserRole.CITIZEN));
        UUID taskId = UUID.randomUUID();
        report.setId(UUID.randomUUID());

        CreateTaskRequest request = new CreateTaskRequest(
                "Fix pothole",
                "Repair the pothole reported by citizens.",
                IssueCategory.ROAD_DAMAGE,
                10.762622,
                106.660172,
                "District 1",
                4,
                staff.getId(),
                "https://example.local/before.jpg",
                List.of(report.getId())
        );

        when(userRepository.findById(staff.getId())).thenReturn(Optional.of(staff));
        when(userRepository.getReferenceById(overseer.getId())).thenReturn(overseer);
        when(taskRepository.saveAndFlush(any(Task.class))).thenAnswer(invocation -> {
            Task task = invocation.getArgument(0);
            task.setId(taskId);
            task.setCreatedAt(NOW);
            task.setUpdatedAt(NOW);
            return task;
        });
        when(reportRepository.findAllById(any())).thenReturn(List.of(report));

        TaskResponse response = taskService.createTask(request, overseer);

        assertThat(response.status()).isEqualTo(TaskStatus.ASSIGNED);
        assertThat(response.assignedStaff().id()).isEqualTo(staff.getId());
        assertThat(response.reportIds()).containsExactly(report.getId());
        assertThat(report.getLinkedTaskId()).isEqualTo(taskId);
    }

    @Test
    void createTaskWithoutAssignedStaffDefaultsToNew() {
        User overseer = user(UserRole.OVERSEER);
        UUID taskId = UUID.randomUUID();
        CreateTaskRequest request = new CreateTaskRequest(
                "Review drainage issue",
                "Inspect the drainage issue before assignment.",
                IssueCategory.DRAINAGE,
                10.762622,
                106.660172,
                null,
                null,
                null,
                null,
                null
        );

        when(userRepository.getReferenceById(overseer.getId())).thenReturn(overseer);
        when(taskRepository.saveAndFlush(any(Task.class))).thenAnswer(invocation -> {
            Task task = invocation.getArgument(0);
            task.setId(taskId);
            task.setCreatedAt(NOW);
            task.setUpdatedAt(NOW);
            return task;
        });

        TaskResponse response = taskService.createTask(request, overseer);

        assertThat(response.status()).isEqualTo(TaskStatus.NEW);
        assertThat(response.assignedStaff()).isNull();
        assertThat(response.priorityScore()).isZero();
    }

    @Test
    void citizenCannotCreateTask() {
        CreateTaskRequest request = new CreateTaskRequest(
                "Review drainage issue",
                "Inspect the drainage issue before assignment.",
                IssueCategory.DRAINAGE,
                10.762622,
                106.660172,
                null,
                null,
                null,
                null,
                null
        );

        assertThatThrownBy(() -> taskService.createTask(request, user(UserRole.CITIZEN)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only overseers can manage tasks");
    }

    @Test
    void citizenCannotAccessTasks() {
        assertThatThrownBy(() -> taskService.getTasks(user(UserRole.CITIZEN)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void staffOnlyListsAssignedTasks() {
        User staff = user(UserRole.STAFF);
        Task task = taskFor(user(UserRole.OVERSEER), staff);
        task.setId(UUID.randomUUID());
        task.setCreatedAt(NOW);
        task.setUpdatedAt(NOW);

        when(taskRepository.findByAssignedStaff_IdOrderByCreatedAtDesc(staff.getId())).thenReturn(List.of(task));

        TaskListResponse response = taskService.getTasks(staff);

        assertThat(response.tasks()).hasSize(1);
        verify(taskRepository).findByAssignedStaff_IdOrderByCreatedAtDesc(staff.getId());
    }

    @Test
    void staffCanStartAssignedTask() {
        User staff = user(UserRole.STAFF);
        Task task = taskFor(user(UserRole.OVERSEER), staff);
        UUID taskId = UUID.randomUUID();
        task.setId(taskId);
        task.setCreatedAt(NOW);
        task.setUpdatedAt(NOW);

        when(taskRepository.findById(taskId)).thenReturn(Optional.of(task));

        TaskResponse response = taskService.startTask(taskId, staff);

        assertThat(response.status()).isEqualTo(TaskStatus.IN_PROGRESS);
        assertThat(response.startedAt()).isEqualTo(NOW);
    }

    @Test
    void staffCanCompleteOwnInProgressTask() {
        User staff = user(UserRole.STAFF);
        Task task = taskFor(user(UserRole.OVERSEER), staff);
        UUID taskId = UUID.randomUUID();
        task.setId(taskId);
        task.setCreatedAt(NOW);
        task.setUpdatedAt(NOW);
        task.start(NOW.minusSeconds(60));

        when(taskRepository.findById(taskId)).thenReturn(Optional.of(task));

        TaskResponse response = taskService.completeTask(
                taskId,
                new CompleteTaskRequest("https://example.local/after.jpg", "Done"),
                staff
        );

        assertThat(response.status()).isEqualTo(TaskStatus.DONE);
        assertThat(response.submittedAt()).isEqualTo(NOW);
        assertThat(response.afterPhotoUrl()).isEqualTo("https://example.local/after.jpg");
        assertThat(response.staffNote()).isEqualTo("Done");
    }

    @Test
    void closeTaskFixesRelatedReports() {
        User overseer = user(UserRole.OVERSEER);
        User staff = user(UserRole.STAFF);
        Report report = reportFor(user(UserRole.CITIZEN));
        Task task = taskFor(overseer, staff);
        UUID taskId = UUID.randomUUID();
        UUID reportId = UUID.randomUUID();
        task.setId(taskId);
        task.setCreatedAt(NOW);
        task.setUpdatedAt(NOW);
        report.setId(reportId);
        task.linkReport(report);
        report.linkToTask(taskId);

        when(taskRepository.findById(taskId)).thenReturn(Optional.of(task));

        TaskResponse response = taskService.closeTask(taskId, overseer);

        assertThat(response.status()).isEqualTo(TaskStatus.CLOSED);
        assertThat(response.closedAt()).isEqualTo(NOW);
        assertThat(report.getStatus()).isEqualTo(ReportStatus.FIXED);
    }

    @Test
    void staffCannotCloseTask() {
        assertThatThrownBy(() -> taskService.closeTask(UUID.randomUUID(), user(UserRole.STAFF)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only overseers can manage tasks");
    }

    @Test
    void assignTaskRequiresStaffRole() {
        User overseer = user(UserRole.OVERSEER);
        User citizen = user(UserRole.CITIZEN);
        UUID taskId = UUID.randomUUID();
        Task task = taskFor(overseer, null);

        when(taskRepository.findById(taskId)).thenReturn(Optional.of(task));
        when(userRepository.findById(citizen.getId())).thenReturn(Optional.of(citizen));

        assertThatThrownBy(() -> taskService.assignTask(taskId, new AssignTaskRequest(citizen.getId()), overseer))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Assigned user must have STAFF role");
    }

    private User user(UserRole role) {
        User user = new User(role.name().toLowerCase() + "@example.local", role.name(), "hash", role);
        user.setId(UUID.randomUUID());
        return user;
    }

    private Task taskFor(User overseer, User staff) {
        return new Task(
                "Fix pothole",
                "Repair the pothole reported by citizens.",
                IssueCategory.ROAD_DAMAGE,
                10.762622,
                106.660172,
                "District 1",
                4,
                staff,
                overseer,
                "https://example.local/before.jpg"
        );
    }

    private Report reportFor(User user) {
        return new Report(
                "Pothole",
                "Large pothole in the right lane.",
                IssueCategory.ROAD_DAMAGE,
                10.762622,
                106.660172,
                "District 1",
                null,
                false,
                user
        );
    }
}
