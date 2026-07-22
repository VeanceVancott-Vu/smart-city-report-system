package com.smartcity.reports.user.application;

import com.smartcity.reports.user.api.CreateUserRequest;
import com.smartcity.reports.user.api.CitizenReportAnalyticsResponse;
import com.smartcity.reports.user.api.StaffDetailProfileResponse;
import com.smartcity.reports.user.api.StaffPublicProfileResponse;
import com.smartcity.reports.user.api.StaffListResponse;
import com.smartcity.reports.user.api.StaffSummaryResponse;
import com.smartcity.reports.user.api.StaffTaskAnalyticsResponse;
import com.smartcity.reports.user.api.UserListResponse;
import com.smartcity.reports.user.api.UserProfileResponse;
import com.smartcity.reports.user.api.UserResponse;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import com.smartcity.reports.user.persistence.UserRepository;

import com.smartcity.reports.common.DuplicateResourceException;
import com.smartcity.reports.common.ResourceNotFoundException;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.application.TaskMapper;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.task.api.TaskResponse;
import com.smartcity.reports.task.domain.TaskStatus;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.EnumMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final ReportRepository reportRepository;
    private final TaskRepository taskRepository;
    private final TaskMapper taskMapper;

    public UserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            ReportRepository reportRepository,
            TaskRepository taskRepository,
            TaskMapper taskMapper
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.reportRepository = reportRepository;
        this.taskRepository = taskRepository;
        this.taskMapper = taskMapper;
    }

    @Transactional(readOnly = true)
    public StaffListResponse getStaffSummary(User currentUser) {
        requireOverseer(currentUser);

        List<User> staffUsers = userRepository.findByRoleOrderByFullNameAsc(UserRole.STAFF);
        List<StaffSummaryResponse> staffSummaries = new ArrayList<>();

        for (User staff : staffUsers) {
            List<Task> tasks = taskRepository.findByAssignedStaff_IdOrderByCreatedAtDesc(staff.getId());
            List<TaskResponse> taskResponses = tasks.stream()
                    .map(taskMapper::toResponse)
                    .toList();

            int activeTasksCount = 0;
            int completedTasksCount = 0;

            for (Task task : tasks) {
                TaskStatus status = task.getStatus();
                if (status == TaskStatus.ASSIGNED || status == TaskStatus.IN_PROGRESS || status == TaskStatus.DENIED) {
                    activeTasksCount++;
                } else if (status == TaskStatus.DONE || status == TaskStatus.CLOSED || status == TaskStatus.APPROVED || status == TaskStatus.PENDING_REVIEW) {
                    completedTasksCount++;
                }
            }

            staffSummaries.add(new StaffSummaryResponse(
                    staff.getId(),
                    staff.getFullName(),
                    staff.getEmail(),
                    staff.isActive(),
                    activeTasksCount,
                    completedTasksCount,
                    taskResponses
            ));
        }

        return new StaffListResponse(staffSummaries);
    }

    @Transactional(readOnly = true)
    public UserListResponse getUsers(UserRole role, User currentUser) {
        requireOverseer(currentUser);
        if (role != UserRole.STAFF) {
            throw new IllegalArgumentException("Only STAFF user listing is supported");
        }

        return new UserListResponse(userRepository.findByRoleAndActiveTrueOrderByFullNameAsc(UserRole.STAFF)
                .stream()
                .map(UserResponse::from)
                .toList());
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(User currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
        return UserResponse.from(currentUser);
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getCurrentUserProfile(User currentUser) {
        requireAuthenticated(currentUser);

        if (currentUser.getRole() == UserRole.CITIZEN) {
            Map<ReportStatus, Long> counts = reportCounts(currentUser.getId());
            return new UserProfileResponse(
                    currentUser.getId(),
                    currentUser.getFullName(),
                    currentUser.getEmail(),
                    currentUser.getRole(),
                    currentUser.isActive(),
                    currentUser.getCreatedAt(),
                    new CitizenReportAnalyticsResponse(total(counts), counts),
                    null
            );
        }

        if (currentUser.getRole() == UserRole.STAFF) {
            Map<TaskStatus, Long> counts = taskCounts(currentUser.getId());
            return new UserProfileResponse(
                    currentUser.getId(),
                    currentUser.getFullName(),
                    currentUser.getEmail(),
                    currentUser.getRole(),
                    currentUser.isActive(),
                    currentUser.getCreatedAt(),
                    null,
                    new StaffTaskAnalyticsResponse(total(counts), counts)
            );
        }

        return UserProfileResponse.basic(currentUser);
    }

    @Transactional(readOnly = true)
    public StaffPublicProfileResponse getStaffPublicProfile(UUID staffId, User currentUser) {
        requireAuthenticated(currentUser);

        User staff = userRepository.findById(staffId)
                .filter(user -> user.getRole() == UserRole.STAFF)
                .orElseThrow(() -> new ResourceNotFoundException("Staff user not found"));

        boolean canView = switch (currentUser.getRole()) {
            case OVERSEER -> true;
            case STAFF -> currentUser.getId().equals(staffId);
            case CITIZEN -> taskRepository.existsAssignmentForCitizenReport(staffId, currentUser.getId());
        };
        if (!canView) {
            throw new AccessDeniedException("You can only view staff assigned to your reports");
        }

        return StaffPublicProfileResponse.from(staff);
    }

    @Transactional(readOnly = true)
    public StaffDetailProfileResponse getStaffDetailProfile(UUID staffId, User currentUser) {
        requireOverseer(currentUser);

        User staff = findStaff(staffId);
        Map<TaskStatus, Long> counts = taskCounts(staffId);
        List<TaskResponse> tasks = taskRepository.findByAssignedStaff_IdOrderByCreatedAtDesc(staffId)
                .stream()
                .map(taskMapper::toResponse)
                .toList();

        return new StaffDetailProfileResponse(
                staff.getId(),
                staff.getFullName(),
                staff.getEmail(),
                staff.getRole(),
                staff.isActive(),
                staff.getCreatedAt(),
                new StaffTaskAnalyticsResponse(total(counts), counts),
                tasks
        );
    }

    @Transactional
    public UserResponse createUser(CreateUserRequest request, User currentUser) {
        requireOverseer(currentUser);
        if (request.role() != UserRole.STAFF && request.role() != UserRole.OVERSEER) {
            throw new IllegalArgumentException("Only STAFF or OVERSEER users can be created here");
        }

        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new DuplicateResourceException("Email is already registered");
        }

        User user = new User(
                email,
                request.fullName().trim(),
                passwordEncoder.encode(request.password()),
                request.role()
        );

        try {
            return UserResponse.from(userRepository.save(user));
        } catch (DataIntegrityViolationException exception) {
            throw new DuplicateResourceException("Email is already registered");
        }
    }

    private void requireOverseer(User currentUser) {
        requireAuthenticated(currentUser);
        if (currentUser.getRole() != UserRole.OVERSEER) {
            throw new AccessDeniedException("Only overseers can manage users");
        }
    }

    private void requireAuthenticated(User currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
    }

    private User findStaff(UUID staffId) {
        return userRepository.findById(staffId)
                .filter(user -> user.getRole() == UserRole.STAFF)
                .orElseThrow(() -> new ResourceNotFoundException("Staff user not found"));
    }

    private Map<ReportStatus, Long> reportCounts(UUID creatorId) {
        EnumMap<ReportStatus, Long> counts = zeroCounts(ReportStatus.class);
        for (ReportRepository.ReportStatusCount count : reportRepository.countByCreatorGroupedByStatus(creatorId)) {
            counts.put(count.getStatus(), count.getCount());
        }
        return Collections.unmodifiableMap(counts);
    }

    private Map<TaskStatus, Long> taskCounts(UUID staffId) {
        EnumMap<TaskStatus, Long> counts = zeroCounts(TaskStatus.class);
        for (TaskRepository.TaskStatusCount count : taskRepository.countByAssignedStaffGroupedByStatus(staffId)) {
            counts.put(count.getStatus(), count.getCount());
        }
        return Collections.unmodifiableMap(counts);
    }

    private <E extends Enum<E>> EnumMap<E, Long> zeroCounts(Class<E> enumType) {
        EnumMap<E, Long> counts = new EnumMap<>(enumType);
        for (E status : enumType.getEnumConstants()) {
            counts.put(status, 0L);
        }
        return counts;
    }

    private long total(Map<?, Long> counts) {
        return counts.values().stream().mapToLong(Long::longValue).sum();
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
