package com.smartcity.reports.user.application;

import com.smartcity.reports.user.api.CreateUserRequest;
import com.smartcity.reports.user.api.StaffListResponse;
import com.smartcity.reports.user.api.StaffSummaryResponse;
import com.smartcity.reports.user.api.UserListResponse;
import com.smartcity.reports.user.api.UserResponse;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import com.smartcity.reports.user.persistence.UserRepository;

import com.smartcity.reports.common.DuplicateResourceException;
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
import java.util.List;
import java.util.Locale;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final TaskRepository taskRepository;
    private final TaskMapper taskMapper;

    public UserService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            TaskRepository taskRepository,
            TaskMapper taskMapper
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
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
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
        if (currentUser.getRole() != UserRole.OVERSEER) {
            throw new AccessDeniedException("Only overseers can manage users");
        }
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
