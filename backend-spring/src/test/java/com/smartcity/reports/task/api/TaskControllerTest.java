package com.smartcity.reports.task.api;

import com.smartcity.reports.common.ApiExceptionHandler;
import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.security.JwtAuthenticationFilter;
import com.smartcity.reports.task.application.TaskService;
import com.smartcity.reports.task.domain.TaskStatus;
import com.smartcity.reports.user.api.UserSummaryResponse;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TaskController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(ApiExceptionHandler.class)
class TaskControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TaskService taskService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    void createTaskReturnsCreatedResponse() throws Exception {
        UUID taskId = UUID.randomUUID();
        UUID staffId = UUID.randomUUID();
        UUID reportId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.createTask(any(CreateTaskRequest.class), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.ASSIGNED, staffId, List.of(reportId)));

        mockMvc.perform(post("/api/tasks")
                        .with(authentication(authenticationToken(overseer)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Fix pothole",
                                  "description": "Repair the pothole reported by citizens.",
                                  "category": "ROAD_DAMAGE",
                                  "latitude": 10.762622,
                                  "longitude": 106.660172,
                                  "addressText": "District 1",
                                  "priorityScore": 4,
                                  "assignedStaffId": "%s",
                                  "reportIds": ["%s"]
                                }
                                """.formatted(staffId, reportId)))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "/api/tasks/" + taskId))
                .andExpect(jsonPath("$.id").value(taskId.toString()))
                .andExpect(jsonPath("$.status").value("ASSIGNED"))
                .andExpect(jsonPath("$.assignedStaff.id").value(staffId.toString()))
                .andExpect(jsonPath("$.reportIds[0]").value(reportId.toString()));
    }

    @Test
    void getTasksReturnsTaskList() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.getTasks(nullable(User.class)))
                .thenReturn(new TaskListResponse(List.of(response(taskId, TaskStatus.NEW, null, List.of()))));

        mockMvc.perform(get("/api/tasks")
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tasks[0].id").value(taskId.toString()))
                .andExpect(jsonPath("$.tasks[0].status").value("NEW"));
    }

    @Test
    void updateTaskReturnsUpdatedTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.updateTask(eq(taskId), any(UpdateTaskRequest.class), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.NEW, null, List.of()));

        mockMvc.perform(put("/api/tasks/{id}", taskId)
                        .with(authentication(authenticationToken(overseer)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Fix pothole",
                                  "description": "Repair the pothole reported by citizens.",
                                  "category": "ROAD_DAMAGE",
                                  "latitude": 10.762622,
                                  "longitude": 106.660172,
                                  "addressText": "District 1",
                                  "priorityScore": 4,
                                  "staffNote": null,
                                  "reportIds": []
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(taskId.toString()));
    }

    @Test
    void assignTaskReturnsAssignedTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        UUID staffId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.assignTask(eq(taskId), any(AssignTaskRequest.class), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.ASSIGNED, staffId, List.of()));

        mockMvc.perform(patch("/api/tasks/{id}/assign", taskId)
                        .with(authentication(authenticationToken(overseer)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                { "assignedStaffId": "%s" }
                                """.formatted(staffId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ASSIGNED"))
                .andExpect(jsonPath("$.assignedStaff.id").value(staffId.toString()));
    }

    @Test
    void startTaskReturnsInProgressTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        UUID staffId = UUID.randomUUID();
        User staff = user(UserRole.STAFF);

        when(taskService.startTask(eq(taskId), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.IN_PROGRESS, staffId, List.of()));

        mockMvc.perform(patch("/api/tasks/{id}/start", taskId)
                        .with(authentication(authenticationToken(staff))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"));
    }

    @Test
    void completeTaskReturnsDoneTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        UUID staffId = UUID.randomUUID();
        User staff = user(UserRole.STAFF);

        when(taskService.completeTask(eq(taskId), nullable(CompleteTaskRequest.class), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.DONE, staffId, List.of()));

        mockMvc.perform(patch("/api/tasks/{id}/complete", taskId)
                        .with(authentication(authenticationToken(staff)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "staffNote": "Done"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DONE"))
                .andExpect(jsonPath("$.aiConfidenceScore").doesNotExist())
                .andExpect(jsonPath("$.aiDecision").doesNotExist());
    }

    @Test
    void completeTaskAllowsStaffNoteOnly() throws Exception {
        UUID taskId = UUID.randomUUID();
        UUID staffId = UUID.randomUUID();
        User staff = user(UserRole.STAFF);

        when(taskService.completeTask(eq(taskId), nullable(CompleteTaskRequest.class), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.DONE, staffId, List.of(UUID.randomUUID())));

        mockMvc.perform(patch("/api/tasks/{id}/complete", taskId)
                        .with(authentication(authenticationToken(staff)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "staffNote": "Done"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DONE"));
    }


    @Test
    void approveTaskReturnsApprovedTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.approveTask(eq(taskId), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.APPROVED, null, List.of()));

        mockMvc.perform(patch("/api/tasks/{id}/approve", taskId)
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("APPROVED"));
    }

    @Test
    void denyTaskReturnsDeniedTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.denyTask(eq(taskId), any(DenyTaskRequest.class), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.DENIED, null, List.of()));

        mockMvc.perform(patch("/api/tasks/{id}/deny", taskId)
                        .with(authentication(authenticationToken(overseer)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "note": "Repair the damaged edge too"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DENIED"));
    }

    @Test
    void denyTaskRequiresNote() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        mockMvc.perform(patch("/api/tasks/{id}/deny", taskId)
                        .with(authentication(authenticationToken(overseer)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "note": " "
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.errors.note").value("Denial note is required"));
    }

    @Test
    void deleteTaskReturnsNoContent() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        mockMvc.perform(delete("/api/tasks/{id}", taskId)
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isNoContent());

        verify(taskService).deleteTask(eq(taskId), nullable(User.class));
    }

    @Test
    void closeTaskReturnsClosedTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.closeTask(eq(taskId), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.CLOSED, null, List.of()));

        mockMvc.perform(patch("/api/tasks/{id}/close", taskId)
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CLOSED"));
    }

    @Test
    void cancelTaskReturnsCancelledTask() throws Exception {
        UUID taskId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);

        when(taskService.cancelTask(eq(taskId), nullable(User.class)))
                .thenReturn(response(taskId, TaskStatus.CANCELLED, null, List.of()));

        mockMvc.perform(patch("/api/tasks/{id}/cancel", taskId)
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    private User user(UserRole role) {
        User user = new User(role.name().toLowerCase() + "@example.local", role.name(), "hash", role);
        user.setId(UUID.randomUUID());
        return user;
    }

    private UsernamePasswordAuthenticationToken authenticationToken(User user) {
        return new UsernamePasswordAuthenticationToken(
                user,
                null,
                List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
        );
    }

    private TaskResponse response(UUID taskId, TaskStatus status, UUID staffId, List<UUID> reportIds) {
        UserSummaryResponse assignedStaff = staffId == null
                ? null
                : new UserSummaryResponse(staffId, "Staff", UserRole.STAFF);
        String staffNote = status == TaskStatus.DONE ? "Done" : null;

        return new TaskResponse(
                taskId,
                "Fix pothole",
                "Repair the pothole reported by citizens.",
                IssueCategory.ROAD_DAMAGE,
                status,
                10.762622,
                106.660172,
                "District 1",
                4,
                assignedStaff,
                new UserSummaryResponse(UUID.randomUUID(), "Overseer", UserRole.OVERSEER),
                staffNote,
                null,
                null,
                Instant.parse("2026-06-09T04:00:00Z"),
                Instant.parse("2026-06-09T04:10:00Z"),
                null,
                Instant.parse("2026-06-09T04:20:00Z"),
                Instant.parse("2026-06-09T03:00:00Z"),
                Instant.parse("2026-06-09T03:30:00Z"),
                reportIds
        );
    }
}
