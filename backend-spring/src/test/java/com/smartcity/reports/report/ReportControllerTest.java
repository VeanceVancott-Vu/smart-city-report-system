package com.smartcity.reports.report;

import com.smartcity.reports.common.ApiExceptionHandler;
import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.security.JwtAuthenticationFilter;
import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
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

@WebMvcTest(ReportController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(ApiExceptionHandler.class)
class ReportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ReportService reportService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    void createReportReturnsCreatedResponse() throws Exception {
        UUID reportId = UUID.randomUUID();
        User citizen = user(UserRole.CITIZEN);
        ReportResponse response = response(reportId, citizen);

        when(reportService.createReport(any(CreateReportRequest.class), nullable(User.class))).thenReturn(response);

        mockMvc.perform(post("/api/reports")
                        .with(authentication(authenticationToken(citizen)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken street light",
                                  "description": "The street light near the park is not working.",
                                  "category": "STREET_LIGHT",
                                  "latitude": 10.762622,
                                  "longitude": 106.660172,
                                  "addressText": "Near the park",
                                  "beforePhotoUrl": "/uploads/report-before/before.jpg"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(header().string("Location", "/api/reports/" + reportId))
                .andExpect(jsonPath("$.id").value(reportId.toString()))
                .andExpect(jsonPath("$.status").value("SUBMITTED"))
                .andExpect(jsonPath("$.addressText").value("Near the park"))
                .andExpect(jsonPath("$.upvoteCount").value(0))
                .andExpect(jsonPath("$.priorityScore").value(0));
    }

    @Test
    void createReportValidatesRequestBody() throws Exception {
        User citizen = user(UserRole.CITIZEN);

        mockMvc.perform(post("/api/reports")
                        .with(authentication(authenticationToken(citizen)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "",
                                  "description": "Missing useful title.",
                                  "category": "ROAD_DAMAGE",
                                  "latitude": 10.762622,
                                  "longitude": 106.660172
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.errors.title").value("Title is required"))
                .andExpect(jsonPath("$.errors.beforePhotoUrl").value("Before photo is required"));
    }

    @Test
    void createReportValidatesUploadedBeforePhotoUrl() throws Exception {
        User citizen = user(UserRole.CITIZEN);

        mockMvc.perform(post("/api/reports")
                        .with(authentication(authenticationToken(citizen)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken street light",
                                  "description": "The street light near the park is not working.",
                                  "category": "STREET_LIGHT",
                                  "latitude": 10.762622,
                                  "longitude": 106.660172,
                                  "beforePhotoUrl": "before.jpg"
                                }
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.errors.beforePhotoUrl")
                        .value("Before photo must be uploaded with /api/files/report-before"));
    }

    @Test
    void accessDeniedErrorsKeepUsefulMessage() throws Exception {
        User staff = user(UserRole.STAFF);

        when(reportService.createReport(any(CreateReportRequest.class), nullable(User.class)))
                .thenThrow(new AccessDeniedException("Only citizens can create reports"));

        mockMvc.perform(post("/api/reports")
                        .with(authentication(authenticationToken(staff)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken street light",
                                  "description": "The street light near the park is not working.",
                                  "category": "STREET_LIGHT",
                                  "latitude": 10.762622,
                                  "longitude": 106.660172,
                                  "beforePhotoUrl": "/uploads/report-before/before.jpg"
                                }
                                """))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Only citizens can create reports"));
    }

    @Test
    void createReportReturnsUsefulErrorForMalformedJson() throws Exception {
        User citizen = user(UserRole.CITIZEN);

        mockMvc.perform(post("/api/reports")
                        .with(authentication(authenticationToken(citizen)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{bad-json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Request body is not valid JSON"));
    }

    @Test
    void getReportReturnsReport() throws Exception {
        UUID reportId = UUID.randomUUID();
        User citizen = user(UserRole.CITIZEN);
        when(reportService.getReport(eq(reportId), nullable(User.class))).thenReturn(response(reportId, citizen));

        mockMvc.perform(get("/api/reports/{id}", reportId)
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(reportId.toString()))
                .andExpect(jsonPath("$.category").value("ROAD_DAMAGE"));
    }

    @Test
    void getReportsReturnsFilteredListResponse() throws Exception {
        UUID reportId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);
        when(reportService.getReports(nullable(User.class), eq(true), eq(ReportStatus.SUBMITTED), eq(IssueCategory.ROAD_DAMAGE)))
                .thenReturn(new ReportListResponse(List.of(response(reportId, overseer))));

        mockMvc.perform(get("/api/reports")
                        .with(authentication(authenticationToken(overseer)))
                        .queryParam("mine", "true")
                        .queryParam("status", "SUBMITTED")
                        .queryParam("category", "ROAD_DAMAGE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.reports[0].id").value(reportId.toString()))
                .andExpect(jsonPath("$.reports[0].status").value("SUBMITTED"));
    }

    @Test
    void updateReportReturnsUpdatedReport() throws Exception {
        UUID reportId = UUID.randomUUID();
        User citizen = user(UserRole.CITIZEN);
        when(reportService.updateReport(eq(reportId), any(UpdateReportRequest.class), nullable(User.class)))
                .thenReturn(response(reportId, citizen));

        mockMvc.perform(put("/api/reports/{id}", reportId)
                        .with(authentication(authenticationToken(citizen)))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Pothole",
                                  "description": "Large pothole in the right lane.",
                                  "category": "ROAD_DAMAGE",
                                  "latitude": 10.762622,
                                  "longitude": 106.660172,
                                  "addressText": "District 1",
                                  "beforePhotoUrl": "/uploads/report-before/before.jpg"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(reportId.toString()));
    }

    @Test
    void cancelReportReturnsCancelledReport() throws Exception {
        UUID reportId = UUID.randomUUID();
        User citizen = user(UserRole.CITIZEN);
        ReportResponse response = new ReportResponse(
                reportId,
                "Pothole",
                "Large pothole in the right lane.",
                IssueCategory.ROAD_DAMAGE,
                ReportStatus.CANCELLED,
                10.762622,
                106.660172,
                "District 1",
                "/uploads/report-before/before.jpg",
                false,
                0,
                0,
                Instant.parse("2026-06-08T05:00:00Z"),
                Instant.parse("2026-06-08T05:00:00Z"),
                new UserSummaryResponse(citizen.getId(), citizen.getDisplayName(), UserRole.CITIZEN)
        );
        when(reportService.cancelReport(eq(reportId), nullable(User.class))).thenReturn(response);

        mockMvc.perform(patch("/api/reports/{id}/cancel", reportId)
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("CANCELLED"));
    }

    @Test
    void fixReportReturnsFixedReport() throws Exception {
        UUID reportId = UUID.randomUUID();
        User overseer = user(UserRole.OVERSEER);
        ReportResponse response = new ReportResponse(
                reportId,
                "Pothole",
                "Large pothole in the right lane.",
                IssueCategory.ROAD_DAMAGE,
                ReportStatus.FIXED,
                10.762622,
                106.660172,
                "District 1",
                "/uploads/report-before/before.jpg",
                false,
                0,
                0,
                Instant.parse("2026-06-08T05:00:00Z"),
                Instant.parse("2026-06-08T05:00:00Z"),
                new UserSummaryResponse(overseer.getId(), overseer.getDisplayName(), UserRole.OVERSEER)
        );
        when(reportService.fixReport(eq(reportId), nullable(User.class))).thenReturn(response);

        mockMvc.perform(patch("/api/reports/{id}/fix", reportId)
                        .with(authentication(authenticationToken(overseer))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("FIXED"));
    }

    @Test
    void upvoteReportReturnsUpdatedCounts() throws Exception {
        UUID reportId = UUID.randomUUID();
        User citizen = user(UserRole.CITIZEN);
        when(reportService.upvoteReport(eq(reportId), nullable(User.class)))
                .thenReturn(new ReportUpvoteResponse(reportId, 1, 1, true));

        mockMvc.perform(post("/api/reports/{id}/upvote", reportId)
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(reportId.toString()))
                .andExpect(jsonPath("$.upvoteCount").value(1))
                .andExpect(jsonPath("$.priorityScore").value(1))
                .andExpect(jsonPath("$.hasUpvoted").value(true));
    }

    @Test
    void removeUpvoteReturnsUpdatedCounts() throws Exception {
        UUID reportId = UUID.randomUUID();
        User citizen = user(UserRole.CITIZEN);
        when(reportService.removeUpvote(eq(reportId), nullable(User.class)))
                .thenReturn(new ReportUpvoteResponse(reportId, 0, 0, false));

        mockMvc.perform(delete("/api/reports/{id}/upvote", reportId)
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(reportId.toString()))
                .andExpect(jsonPath("$.upvoteCount").value(0))
                .andExpect(jsonPath("$.priorityScore").value(0))
                .andExpect(jsonPath("$.hasUpvoted").value(false));
    }

    @Test
    void getReportsForMapReturnsReportsInsideBoundingBox() throws Exception {
        UUID reportId = UUID.randomUUID();
        User citizen = user(UserRole.CITIZEN);
        when(reportService.getReportsForMap(eq(10.7), eq(106.6), eq(10.8), eq(106.8), nullable(User.class)))
                .thenReturn(List.of(mapPinResponse(reportId)));

        mockMvc.perform(get("/api/reports/map")
                        .with(authentication(authenticationToken(citizen)))
                        .queryParam("minLat", "10.7")
                        .queryParam("minLng", "106.6")
                        .queryParam("maxLat", "10.8")
                        .queryParam("maxLng", "106.8"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(reportId.toString()))
                .andExpect(jsonPath("$[0].latitude").value(10.762622))
                .andExpect(jsonPath("$[0].longitude").value(106.660172))
                .andExpect(jsonPath("$[0].upvoteCount").value(3))
                .andExpect(jsonPath("$[0].priorityScore").value(3))
                .andExpect(jsonPath("$[0].description").doesNotExist())
                .andExpect(jsonPath("$[0].createdBy").doesNotExist());

        verify(reportService).getReportsForMap(eq(10.7), eq(106.6), eq(10.8), eq(106.8), nullable(User.class));
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

    private ReportResponse response(UUID reportId, User user) {
        return response(reportId, user, 0, 0);
    }

    private ReportResponse response(UUID reportId, User user, int upvoteCount, int priorityScore) {
        return new ReportResponse(
                reportId,
                "Pothole",
                "Large pothole in the right lane.",
                IssueCategory.ROAD_DAMAGE,
                ReportStatus.SUBMITTED,
                10.762622,
                106.660172,
                "Near the park",
                "/uploads/report-before/before.jpg",
                false,
                upvoteCount,
                priorityScore,
                Instant.parse("2026-06-08T05:00:00Z"),
                Instant.parse("2026-06-08T05:00:00Z"),
                new UserSummaryResponse(user.getId(), user.getDisplayName(), user.getRole())
        );
    }

    private ReportMapPinResponse mapPinResponse(UUID reportId) {
        return new ReportMapPinResponse(
                reportId,
                "Pothole",
                IssueCategory.ROAD_DAMAGE,
                ReportStatus.SUBMITTED,
                10.762622,
                106.660172,
                3,
                3,
                UUID.randomUUID()
        );
    }
}
