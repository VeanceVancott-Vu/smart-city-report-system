package com.smartcity.reports.task.api;

import com.smartcity.reports.task.application.TaskService;

import com.smartcity.reports.user.domain.User;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.UUID;

@Validated
@RestController
@RequestMapping("/api/tasks")
public class TaskController {

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @PostMapping
    public ResponseEntity<TaskResponse> createTask(
            @Valid @RequestBody CreateTaskRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        TaskResponse response = taskService.createTask(request, currentUser);
        return ResponseEntity.created(URI.create("/api/tasks/" + response.id())).body(response);
    }

    @GetMapping
    public TaskListResponse getTasks(@AuthenticationPrincipal User currentUser) {
        return taskService.getTasks(currentUser);
    }

    @GetMapping("/{id}")
    public TaskResponse getTask(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.getTask(id, currentUser);
    }

    @PutMapping("/{id}")
    public TaskResponse updateTask(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateTaskRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.updateTask(id, request, currentUser);
    }

    @PatchMapping("/{id}/assign")
    public TaskResponse assignTask(
            @PathVariable UUID id,
            @Valid @RequestBody AssignTaskRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.assignTask(id, request, currentUser);
    }

    @PatchMapping("/{id}/start")
    public TaskResponse startTask(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.startTask(id, currentUser);
    }

    @PatchMapping("/{id}/complete")
    public TaskResponse completeTask(
            @PathVariable UUID id,
            @Valid @RequestBody(required = false) CompleteTaskRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.completeTask(id, request, currentUser);
    }

    @PatchMapping("/{id}/approve")
    public TaskResponse approveTask(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.approveTask(id, currentUser);
    }

    @PatchMapping("/{id}/deny")
    public TaskResponse denyTask(
            @PathVariable UUID id,
            @Valid @RequestBody DenyTaskRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.denyTask(id, request, currentUser);
    }

    @PatchMapping("/{id}/close")
    public TaskResponse closeTask(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.closeTask(id, currentUser);
    }

    @PatchMapping("/{id}/cancel")
    public TaskResponse cancelTask(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return taskService.cancelTask(id, currentUser);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTask(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        taskService.deleteTask(id, currentUser);
        return ResponseEntity.noContent().build();
    }
}
