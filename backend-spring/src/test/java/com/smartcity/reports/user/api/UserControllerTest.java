package com.smartcity.reports.user.api;

import com.smartcity.reports.user.application.UserService;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;

import com.smartcity.reports.common.ApiExceptionHandler;
import com.smartcity.reports.security.JwtAuthenticationFilter;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(UserController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(ApiExceptionHandler.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    void getUsersReturnsStaffWithoutPasswordHash() throws Exception {
        User overseer = user(UserRole.OVERSEER);
        UUID staffId = UUID.randomUUID();
        when(userService.getUsers(eq(UserRole.STAFF), nullable(User.class)))
                .thenReturn(new UserListResponse(List.of(
                        new UserResponse(staffId, "Test Staff", "staff@test.com", UserRole.STAFF)
                )));

        mockMvc.perform(get("/api/users")
                        .with(authentication(authenticationToken(overseer)))
                        .queryParam("role", "STAFF"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.users[0].id").value(staffId.toString()))
                .andExpect(jsonPath("$.users[0].fullName").value("Test Staff"))
                .andExpect(jsonPath("$.users[0].email").value("staff@test.com"))
                .andExpect(jsonPath("$.users[0].role").value("STAFF"))
                .andExpect(jsonPath("$.users[0].passwordHash").doesNotExist());
    }

    @Test
    void getStaffSummaryReturnsSummaryPayload() throws Exception {
        User overseer = user(UserRole.OVERSEER);
        UUID staffId = UUID.randomUUID();
        when(userService.getStaffSummary(nullable(User.class)))
                .thenReturn(new StaffListResponse(List.of(
                        new StaffSummaryResponse(
                                staffId,
                                "Test Staff",
                                "staff@test.com",
                                true,
                                2,
                                5,
                                List.of()
                        )
                )));

        mockMvc.perform(get("/api/users/staff-summary")
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.staff[0].id").value(staffId.toString()))
                .andExpect(jsonPath("$.staff[0].fullName").value("Test Staff"))
                .andExpect(jsonPath("$.staff[0].email").value("staff@test.com"))
                .andExpect(jsonPath("$.staff[0].active").value(true))
                .andExpect(jsonPath("$.staff[0].activeTasksCount").value(2))
                .andExpect(jsonPath("$.staff[0].completedTasksCount").value(5))
                .andExpect(jsonPath("$.staff[0].tasks").isArray());
    }

    @Test
    void meReturnsCurrentUserWithoutPasswordHash() throws Exception {
        User citizen = user(UserRole.CITIZEN);
        when(userService.getCurrentUser(nullable(User.class)))
                .thenReturn(new UserResponse(citizen.getId(), "Test Citizen", "citizen@test.com", UserRole.CITIZEN));

        mockMvc.perform(get("/api/users/me")
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(citizen.getId().toString()))
                .andExpect(jsonPath("$.fullName").value("Test Citizen"))
                .andExpect(jsonPath("$.email").value("citizen@test.com"))
                .andExpect(jsonPath("$.role").value("CITIZEN"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
    }

    @Test
    void myProfileReturnsRoleSpecificAnalytics() throws Exception {
        User citizen = user(UserRole.CITIZEN);
        when(userService.getCurrentUserProfile(nullable(User.class)))
                .thenReturn(new UserProfileResponse(
                        citizen.getId(),
                        "Test Citizen",
                        "citizen@test.com",
                        UserRole.CITIZEN,
                        true,
                        null,
                        new CitizenReportAnalyticsResponse(3, Map.of(
                                com.smartcity.reports.report.domain.ReportStatus.SUBMITTED, 2L,
                                com.smartcity.reports.report.domain.ReportStatus.FIXED, 1L
                        )),
                        null
                ));

        mockMvc.perform(get("/api/users/me/profile")
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fullName").value("Test Citizen"))
                .andExpect(jsonPath("$.role").value("CITIZEN"))
                .andExpect(jsonPath("$.citizenReportAnalytics.totalReports").value(3))
                .andExpect(jsonPath("$.citizenReportAnalytics.byStatus.SUBMITTED").value(2))
                .andExpect(jsonPath("$.staffTaskAnalytics").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
    }

    @Test
    void staffProfileReturnsPublicBasicInformation() throws Exception {
        User citizen = user(UserRole.CITIZEN);
        UUID staffId = UUID.randomUUID();
        when(userService.getStaffPublicProfile(eq(staffId), nullable(User.class)))
                .thenReturn(new StaffPublicProfileResponse(
                        staffId,
                        "Assigned Staff",
                        "assigned.staff@test.com",
                        UserRole.STAFF,
                        true,
                        null
                ));

        mockMvc.perform(get("/api/users/staff/{staffId}/profile", staffId)
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(staffId.toString()))
                .andExpect(jsonPath("$.fullName").value("Assigned Staff"))
                .andExpect(jsonPath("$.email").value("assigned.staff@test.com"))
                .andExpect(jsonPath("$.role").value("STAFF"))
                .andExpect(jsonPath("$.active").value(true))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
    }

    @Test
    void staffDetailsReturnsAnalyticsAndTasks() throws Exception {
        User overseer = user(UserRole.OVERSEER);
        UUID staffId = UUID.randomUUID();
        when(userService.getStaffDetailProfile(eq(staffId), nullable(User.class)))
                .thenReturn(new StaffDetailProfileResponse(
                        staffId,
                        "Assigned Staff",
                        "assigned.staff@test.com",
                        UserRole.STAFF,
                        true,
                        null,
                        new StaffTaskAnalyticsResponse(2, Map.of(
                                com.smartcity.reports.task.domain.TaskStatus.ASSIGNED, 1L,
                                com.smartcity.reports.task.domain.TaskStatus.IN_PROGRESS, 1L
                        )),
                        List.of()
                ));

        mockMvc.perform(get("/api/users/staff/{staffId}/details", staffId)
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(staffId.toString()))
                .andExpect(jsonPath("$.taskAnalytics.totalTasks").value(2))
                .andExpect(jsonPath("$.taskAnalytics.byStatus.ASSIGNED").value(1))
                .andExpect(jsonPath("$.tasks").isArray())
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
    }

    @Test
    void postUsersCreatesStaffWithoutPasswordHash() throws Exception {
        User overseer = user(UserRole.OVERSEER);
        UUID staffId = UUID.randomUUID();
        when(userService.createUser(any(CreateUserRequest.class), nullable(User.class)))
                .thenReturn(new UserResponse(staffId, "New Staff", "new.staff@test.com", UserRole.STAFF));

        mockMvc.perform(post("/api/users")
                        .with(authentication(authenticationToken(overseer)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "fullName": "New Staff",
                                  "email": "new.staff@test.com",
                                  "password": "correct-password",
                                  "role": "STAFF"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().string(HttpHeaders.LOCATION, "/api/users/" + staffId))
                .andExpect(jsonPath("$.id").value(staffId.toString()))
                .andExpect(jsonPath("$.fullName").value("New Staff"))
                .andExpect(jsonPath("$.email").value("new.staff@test.com"))
                .andExpect(jsonPath("$.role").value("STAFF"))
                .andExpect(jsonPath("$.passwordHash").doesNotExist());
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
}
