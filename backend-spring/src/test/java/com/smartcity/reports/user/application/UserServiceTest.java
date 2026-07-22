package com.smartcity.reports.user.application;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.task.api.TaskResponse;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.domain.TaskStatus;
import com.smartcity.reports.user.api.CreateUserRequest;
import com.smartcity.reports.user.api.StaffListResponse;
import com.smartcity.reports.user.api.UserListResponse;
import com.smartcity.reports.user.api.UserResponse;
import com.smartcity.reports.user.api.UserProfileResponse;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import com.smartcity.reports.user.persistence.UserRepository;

import com.smartcity.reports.common.DuplicateResourceException;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.report.persistence.ReportRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.task.application.TaskMapper;

import java.util.List;
import java.util.UUID;
import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private TaskRepository taskRepository;

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private TaskMapper taskMapper;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    private UserService userService;

    @BeforeEach
    void setUp() {
        userService = new UserService(userRepository, passwordEncoder, reportRepository, taskRepository, taskMapper);
    }

    @Test
    void overseerCanListActiveStaffUsers() {
        User staff = user(UserRole.STAFF);
        when(userRepository.findByRoleAndActiveTrueOrderByFullNameAsc(UserRole.STAFF))
                .thenReturn(List.of(staff));

        UserListResponse response = userService.getUsers(UserRole.STAFF, user(UserRole.OVERSEER));

        assertThat(response.users()).hasSize(1);
        assertThat(response.users().get(0).id()).isEqualTo(staff.getId());
        assertThat(response.users().get(0).fullName()).isEqualTo(staff.getFullName());
        assertThat(response.users().get(0).email()).isEqualTo(staff.getEmail());
        assertThat(response.users().get(0).role()).isEqualTo(UserRole.STAFF);
        verify(userRepository).findByRoleAndActiveTrueOrderByFullNameAsc(UserRole.STAFF);
    }

    @Test
    void citizenCannotListUsers() {
        assertThatThrownBy(() -> userService.getUsers(UserRole.STAFF, user(UserRole.CITIZEN)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only overseers can manage users");
    }

    @Test
    void onlyStaffListingIsSupported() {
        assertThatThrownBy(() -> userService.getUsers(UserRole.CITIZEN, user(UserRole.OVERSEER)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only STAFF user listing is supported");
    }

    @Test
    void authenticatedUserCanFetchOwnProfile() {
        User currentUser = user(UserRole.CITIZEN);

        UserResponse response = userService.getCurrentUser(currentUser);

        assertThat(response.id()).isEqualTo(currentUser.getId());
        assertThat(response.fullName()).isEqualTo(currentUser.getFullName());
        assertThat(response.email()).isEqualTo(currentUser.getEmail());
        assertThat(response.role()).isEqualTo(UserRole.CITIZEN);
    }

    @Test
    void currentUserRequiresAuthentication() {
        assertThatThrownBy(() -> userService.getCurrentUser(null))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Authentication required");
    }

    @Test
    void citizenProfileIncludesReportCountsAndZeroStatuses() {
        User citizen = user(UserRole.CITIZEN);
        ReportRepository.ReportStatusCount submitted = reportStatusCount(ReportStatus.SUBMITTED, 3);
        ReportRepository.ReportStatusCount fixed = reportStatusCount(ReportStatus.FIXED, 2);
        when(reportRepository.countByCreatorGroupedByStatus(citizen.getId()))
                .thenReturn(List.of(submitted, fixed));

        UserProfileResponse response = userService.getCurrentUserProfile(citizen);

        assertThat(response.citizenReportAnalytics()).isNotNull();
        assertThat(response.staffTaskAnalytics()).isNull();
        assertThat(response.citizenReportAnalytics().totalReports()).isEqualTo(5);
        assertThat(response.citizenReportAnalytics().byStatus())
                .containsEntry(ReportStatus.SUBMITTED, 3L)
                .containsEntry(ReportStatus.IN_PROGRESS, 0L)
                .containsEntry(ReportStatus.FIXED, 2L)
                .containsEntry(ReportStatus.CANCELLED, 0L);
    }

    @Test
    void staffProfileIncludesTaskCountsAndZeroStatuses() {
        User staff = user(UserRole.STAFF);
        TaskRepository.TaskStatusCount assigned = taskStatusCount(TaskStatus.ASSIGNED, 4);
        TaskRepository.TaskStatusCount done = taskStatusCount(TaskStatus.DONE, 1);
        when(taskRepository.countByAssignedStaffGroupedByStatus(staff.getId()))
                .thenReturn(List.of(assigned, done));

        UserProfileResponse response = userService.getCurrentUserProfile(staff);

        assertThat(response.citizenReportAnalytics()).isNull();
        assertThat(response.staffTaskAnalytics()).isNotNull();
        assertThat(response.staffTaskAnalytics().totalTasks()).isEqualTo(5);
        assertThat(response.staffTaskAnalytics().byStatus())
                .containsEntry(TaskStatus.ASSIGNED, 4L)
                .containsEntry(TaskStatus.IN_PROGRESS, 0L)
                .containsEntry(TaskStatus.DONE, 1L)
                .containsEntry(TaskStatus.CLOSED, 0L);
    }

    @Test
    void overseerProfileContainsOnlyBasicInformation() {
        User overseer = user(UserRole.OVERSEER);

        UserProfileResponse response = userService.getCurrentUserProfile(overseer);

        assertThat(response.id()).isEqualTo(overseer.getId());
        assertThat(response.role()).isEqualTo(UserRole.OVERSEER);
        assertThat(response.citizenReportAnalytics()).isNull();
        assertThat(response.staffTaskAnalytics()).isNull();
    }

    @Test
    void citizenCanViewStaffAssignedToOwnReport() {
        User citizen = user(UserRole.CITIZEN);
        User staff = user(UserRole.STAFF);
        when(userRepository.findById(staff.getId())).thenReturn(java.util.Optional.of(staff));
        when(taskRepository.existsAssignmentForCitizenReport(staff.getId(), citizen.getId())).thenReturn(true);

        var response = userService.getStaffPublicProfile(staff.getId(), citizen);

        assertThat(response.id()).isEqualTo(staff.getId());
        assertThat(response.fullName()).isEqualTo(staff.getFullName());
        assertThat(response.role()).isEqualTo(UserRole.STAFF);
    }

    @Test
    void citizenCannotViewUnassignedStaff() {
        User citizen = user(UserRole.CITIZEN);
        User staff = user(UserRole.STAFF);
        when(userRepository.findById(staff.getId())).thenReturn(java.util.Optional.of(staff));
        when(taskRepository.existsAssignmentForCitizenReport(staff.getId(), citizen.getId())).thenReturn(false);

        assertThatThrownBy(() -> userService.getStaffPublicProfile(staff.getId(), citizen))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("You can only view staff assigned to your reports");
    }

    @Test
    void overseerCanViewDetailedStaffProfile() {
        User overseer = user(UserRole.OVERSEER);
        User staff = user(UserRole.STAFF);
        TaskRepository.TaskStatusCount assigned = taskStatusCount(TaskStatus.ASSIGNED, 2);
        when(userRepository.findById(staff.getId())).thenReturn(java.util.Optional.of(staff));
        when(taskRepository.countByAssignedStaffGroupedByStatus(staff.getId()))
                .thenReturn(List.of(assigned));
        when(taskRepository.findByAssignedStaff_IdOrderByCreatedAtDesc(staff.getId()))
                .thenReturn(List.of());

        var response = userService.getStaffDetailProfile(staff.getId(), overseer);

        assertThat(response.id()).isEqualTo(staff.getId());
        assertThat(response.taskAnalytics().totalTasks()).isEqualTo(2);
        assertThat(response.taskAnalytics().byStatus())
                .containsEntry(TaskStatus.ASSIGNED, 2L)
                .containsEntry(TaskStatus.CLOSED, 0L);
        assertThat(response.tasks()).isEmpty();
    }

    @Test
    void citizenCannotViewDetailedStaffProfile() {
        assertThatThrownBy(() -> userService.getStaffDetailProfile(
                UUID.randomUUID(),
                user(UserRole.CITIZEN)
        ))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only overseers can manage users");
    }

    @Test
    void overseerCanCreateStaffUser() {
        CreateUserRequest request = new CreateUserRequest(
                "New Staff",
                "NEW.STAFF@example.local",
                "correct-password",
                UserRole.STAFF
        );

        when(userRepository.existsByEmailIgnoreCase("new.staff@example.local")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(UUID.randomUUID());
            return user;
        });

        UserResponse response = userService.createUser(request, user(UserRole.OVERSEER));

        assertThat(response.fullName()).isEqualTo("New Staff");
        assertThat(response.email()).isEqualTo("new.staff@example.local");
        assertThat(response.role()).isEqualTo(UserRole.STAFF);
    }

    @Test
    void createdUserPasswordIsHashed() {
        CreateUserRequest request = new CreateUserRequest(
                "New Overseer",
                "new.overseer@example.local",
                "correct-password",
                UserRole.OVERSEER
        );

        when(userRepository.existsByEmailIgnoreCase("new.overseer@example.local")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        userService.createUser(request, user(UserRole.OVERSEER));

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        User savedUser = userCaptor.getValue();

        assertThat(savedUser.getPasswordHash()).isNotEqualTo("correct-password");
        assertThat(passwordEncoder.matches("correct-password", savedUser.getPasswordHash())).isTrue();
    }

    @Test
    void citizenCannotCreateUsers() {
        CreateUserRequest request = new CreateUserRequest(
                "New Staff",
                "staff@example.local",
                "correct-password",
                UserRole.STAFF
        );

        assertThatThrownBy(() -> userService.createUser(request, user(UserRole.CITIZEN)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only overseers can manage users");
    }

    @Test
    void managedUserCreationRejectsCitizenRole() {
        CreateUserRequest request = new CreateUserRequest(
                "New Citizen",
                "citizen@example.local",
                "correct-password",
                UserRole.CITIZEN
        );

        assertThatThrownBy(() -> userService.createUser(request, user(UserRole.OVERSEER)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only STAFF or OVERSEER users can be created here");
    }

    @Test
    void managedUserCreationRejectsDuplicateEmail() {
        CreateUserRequest request = new CreateUserRequest(
                "New Staff",
                "staff@example.local",
                "correct-password",
                UserRole.STAFF
        );

        when(userRepository.existsByEmailIgnoreCase("staff@example.local")).thenReturn(true);

        assertThatThrownBy(() -> userService.createUser(request, user(UserRole.OVERSEER)))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessage("Email is already registered");
    }

    @Test
    void overseerCanGetStaffSummary() {
        User overseer = user(UserRole.OVERSEER);
        User staff = user(UserRole.STAFF);
        when(userRepository.findByRoleOrderByFullNameAsc(UserRole.STAFF))
                .thenReturn(List.of(staff));
        when(taskRepository.findByAssignedStaff_IdOrderByCreatedAtDesc(staff.getId()))
                .thenReturn(List.of());

        StaffListResponse response = userService.getStaffSummary(overseer);

        assertThat(response.staff()).hasSize(1);
        assertThat(response.staff().get(0).id()).isEqualTo(staff.getId());
        assertThat(response.staff().get(0).activeTasksCount()).isZero();
        assertThat(response.staff().get(0).completedTasksCount()).isZero();
    }

    @Test
    void deniedTaskCountsAsActiveStaffWork() {
        User overseer = user(UserRole.OVERSEER);
        User staff = user(UserRole.STAFF);
        Task task = new Task(
                "Fix pothole",
                "Repair the pothole.",
                IssueCategory.ROAD_DAMAGE,
                10.762622,
                106.660172,
                "District 1",
                4,
                staff,
                overseer
        );
        Instant now = Instant.parse("2026-07-17T04:00:00Z");
        task.start(now.minusSeconds(120));
        task.complete(now.minusSeconds(60), "First attempt");
        task.deny(now, "Repair the damaged edge too");

        when(userRepository.findByRoleOrderByFullNameAsc(UserRole.STAFF))
                .thenReturn(List.of(staff));
        when(taskRepository.findByAssignedStaff_IdOrderByCreatedAtDesc(staff.getId()))
                .thenReturn(List.of(task));

        StaffListResponse response = userService.getStaffSummary(overseer);

        assertThat(response.staff().get(0).activeTasksCount()).isEqualTo(1);
        assertThat(response.staff().get(0).completedTasksCount()).isZero();
    }

    private User user(UserRole role) {
        User user = new User(role.name().toLowerCase() + "@example.local", role.name(), "hash", role);
        user.setId(UUID.randomUUID());
        return user;
    }

    private ReportRepository.ReportStatusCount reportStatusCount(ReportStatus status, long count) {
        return new ReportRepository.ReportStatusCount() {
            public ReportStatus getStatus() {
                return status;
            }

            public long getCount() {
                return count;
            }
        };
    }

    private TaskRepository.TaskStatusCount taskStatusCount(TaskStatus status, long count) {
        return new TaskRepository.TaskStatusCount() {
            public TaskStatus getStatus() {
                return status;
            }

            public long getCount() {
                return count;
            }
        };
    }
}
