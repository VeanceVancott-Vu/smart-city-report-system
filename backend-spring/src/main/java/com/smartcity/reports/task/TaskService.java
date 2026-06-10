package com.smartcity.reports.task;

import com.smartcity.reports.common.ResourceNotFoundException;
import com.smartcity.reports.report.Report;
import com.smartcity.reports.report.ReportRepository;
import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRepository;
import com.smartcity.reports.user.UserRole;
import org.springframework.data.domain.Sort;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Instant;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final TaskMapper taskMapper;
    private final Clock clock;

    public TaskService(
            TaskRepository taskRepository,
            ReportRepository reportRepository,
            UserRepository userRepository,
            TaskMapper taskMapper,
            Clock clock
    ) {
        this.taskRepository = taskRepository;
        this.reportRepository = reportRepository;
        this.userRepository = userRepository;
        this.taskMapper = taskMapper;
        this.clock = clock;
    }

    @Transactional
    public TaskResponse createTask(CreateTaskRequest request, User currentUser) {
        requireOverseer(currentUser);
        User assignedStaff = resolveStaff(request.assignedStaffId());
        User overseer = userRepository.getReferenceById(currentUser.getId());

        Task task = new Task(
                request.title(),
                request.description(),
                request.category(),
                request.latitude(),
                request.longitude(),
                request.addressText(),
                request.priorityScoreOrZero(),
                assignedStaff,
                overseer,
                request.beforePhotoUrl()
        );

        Task savedTask = taskRepository.saveAndFlush(task);
        syncReports(savedTask, request.reportIds());
        return taskMapper.toResponse(savedTask);
    }

    @Transactional(readOnly = true)
    public TaskListResponse getTasks(User currentUser) {
        requireAuthenticated(currentUser);
        if (currentUser.getRole() == UserRole.CITIZEN) {
            throw new AccessDeniedException("Citizens cannot access tasks");
        }

        List<Task> tasks = currentUser.getRole() == UserRole.OVERSEER
                ? taskRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                : taskRepository.findByAssignedStaff_IdOrderByCreatedAtDesc(currentUser.getId());

        return new TaskListResponse(tasks.stream()
                .map(taskMapper::toResponse)
                .toList());
    }

    @Transactional(readOnly = true)
    public TaskResponse getTask(UUID id, User currentUser) {
        requireAuthenticated(currentUser);
        Task task = getTaskEntity(id);
        ensureCanView(task, currentUser);
        return taskMapper.toResponse(task);
    }

    @Transactional
    public TaskResponse updateTask(UUID id, UpdateTaskRequest request, User currentUser) {
        requireOverseer(currentUser);
        Task task = getTaskEntity(id);
        task.updateDetails(
                request.title(),
                request.description(),
                request.category(),
                request.latitude(),
                request.longitude(),
                request.addressText(),
                request.priorityScore(),
                request.beforePhotoUrl(),
                request.afterPhotoUrl(),
                request.staffNote()
        );

        if (request.reportIds() != null) {
            syncReports(task, request.reportIds());
        }
        return taskMapper.toResponse(task);
    }

    @Transactional
    public TaskResponse assignTask(UUID id, AssignTaskRequest request, User currentUser) {
        requireOverseer(currentUser);
        Task task = getTaskEntity(id);
        task.assign(resolveStaff(request.assignedStaffId()));
        return taskMapper.toResponse(task);
    }

    @Transactional
    public TaskResponse startTask(UUID id, User currentUser) {
        requireStaff(currentUser);
        Task task = getTaskEntity(id);
        ensureAssignedStaff(task, currentUser);
        if (task.getStatus() != TaskStatus.ASSIGNED) {
            throw new IllegalArgumentException("Only assigned tasks can be started");
        }

        task.start(Instant.now(clock));
        return taskMapper.toResponse(task);
    }

    @Transactional
    public TaskResponse completeTask(UUID id, CompleteTaskRequest request, User currentUser) {
        requireStaff(currentUser);
        Task task = getTaskEntity(id);
        ensureAssignedStaff(task, currentUser);
        if (task.getStatus() != TaskStatus.IN_PROGRESS) {
            throw new IllegalArgumentException("Only in-progress tasks can be completed");
        }

        CompleteTaskRequest safeRequest = request == null ? new CompleteTaskRequest(null, null) : request;
        task.complete(Instant.now(clock), safeRequest.afterPhotoUrl(), safeRequest.staffNote());
        return taskMapper.toResponse(task);
    }

    @Transactional
    public TaskResponse closeTask(UUID id, User currentUser) {
        requireOverseer(currentUser);
        Task task = getTaskEntity(id);
        task.close(Instant.now(clock));
        task.getReports().forEach(Report::fix);
        return taskMapper.toResponse(task);
    }

    @Transactional
    public TaskResponse cancelTask(UUID id, User currentUser) {
        requireOverseer(currentUser);
        Task task = getTaskEntity(id);
        task.cancel();
        return taskMapper.toResponse(task);
    }

    private void syncReports(Task task, Collection<UUID> reportIds) {
        Set<UUID> desiredIds = reportIds == null ? Set.of() : new LinkedHashSet<>(reportIds);

        List<Report> currentReports = List.copyOf(task.getReports());
        for (Report report : currentReports) {
            if (!desiredIds.contains(report.getId())) {
                task.unlinkReport(report);
                report.unlinkFromTask(task.getId());
            }
        }

        List<Report> desiredReports = loadReports(desiredIds);
        for (Report report : desiredReports) {
            ensureReportCanLinkToTask(report, task.getId());
            task.linkReport(report);
            report.linkToTask(task.getId());
        }
    }

    private List<Report> loadReports(Set<UUID> reportIds) {
        if (reportIds.isEmpty()) {
            return List.of();
        }

        List<Report> reports = reportRepository.findAllById(reportIds);
        if (reports.size() != reportIds.size()) {
            throw new ResourceNotFoundException("One or more reports were not found");
        }
        return reports;
    }

    private void ensureReportCanLinkToTask(Report report, UUID taskId) {
        UUID linkedTaskId = report.getLinkedTaskId();
        if (linkedTaskId != null && !linkedTaskId.equals(taskId)) {
            throw new IllegalArgumentException("Report is already linked to another task: " + report.getId());
        }
    }

    private User resolveStaff(UUID staffId) {
        if (staffId == null) {
            return null;
        }

        User staff = userRepository.findById(staffId)
                .filter(User::isActive)
                .orElseThrow(() -> new ResourceNotFoundException("Staff user not found: " + staffId));
        if (staff.getRole() != UserRole.STAFF) {
            throw new IllegalArgumentException("Assigned user must have STAFF role");
        }
        return staff;
    }

    private Task getTaskEntity(UUID id) {
        return taskRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found: " + id));
    }

    private void ensureCanView(Task task, User currentUser) {
        if (currentUser.getRole() == UserRole.OVERSEER) {
            return;
        }
        if (currentUser.getRole() == UserRole.STAFF && isAssignedTo(task, currentUser)) {
            return;
        }
        throw new AccessDeniedException("Task is not visible to this user");
    }

    private void ensureAssignedStaff(Task task, User currentUser) {
        if (!isAssignedTo(task, currentUser)) {
            throw new AccessDeniedException("Task is not assigned to this staff user");
        }
    }

    private boolean isAssignedTo(Task task, User currentUser) {
        return task.getAssignedStaff() != null
                && task.getAssignedStaff().getId().equals(currentUser.getId());
    }

    private void requireOverseer(User currentUser) {
        requireAuthenticated(currentUser);
        if (currentUser.getRole() != UserRole.OVERSEER) {
            throw new AccessDeniedException("Only overseers can manage tasks");
        }
    }

    private void requireStaff(User currentUser) {
        requireAuthenticated(currentUser);
        if (currentUser.getRole() != UserRole.STAFF) {
            throw new AccessDeniedException("Only staff can update assigned task progress");
        }
    }

    private void requireAuthenticated(User currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
    }
}
