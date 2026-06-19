package com.smartcity.reports.report;

import com.smartcity.reports.common.ResourceNotFoundException;
import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReportServiceTest {

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private ReportUpvoteRepository reportUpvoteRepository;

    private final ReportMapper reportMapper = new ReportMapper();

    private ReportService reportService;

    @BeforeEach
    void setUp() {
        reportService = new ReportService(reportRepository, reportUpvoteRepository, reportMapper);
    }

    @Test
    void createReportDefaultsStatusPriorityAndUpvotes() {
        User user = user(UserRole.CITIZEN);

        CreateReportRequest request = new CreateReportRequest(
                "Broken street light",
                "The street light near the park is not working.",
                IssueCategory.STREET_LIGHT,
                10.762622,
                106.660172,
                "Near the park",
                "/uploads/report-before/before.jpg",
                null
        );

        when(reportRepository.save(org.mockito.ArgumentMatchers.any(Report.class))).thenAnswer(invocation -> {
            Report report = invocation.getArgument(0);
            report.setId(UUID.randomUUID());
            report.setCreatedAt(Instant.parse("2026-06-08T05:00:00Z"));
            report.setUpdatedAt(Instant.parse("2026-06-08T05:00:00Z"));
            return report;
        });

        ReportResponse response = reportService.createReport(request, user);

        ArgumentCaptor<Report> reportCaptor = ArgumentCaptor.forClass(Report.class);
        verify(reportRepository).save(reportCaptor.capture());
        assertThat(reportCaptor.getValue().getStatus()).isEqualTo(ReportStatus.SUBMITTED);
        assertThat(reportCaptor.getValue().getUpvoteCount()).isZero();
        assertThat(reportCaptor.getValue().getPriorityScore()).isZero();
        assertThat(reportCaptor.getValue().getAddressText()).isEqualTo("Near the park");
        assertThat(response.status()).isEqualTo(ReportStatus.SUBMITTED);
        assertThat(response.createdBy().id()).isEqualTo(user.getId());
    }

    @Test
    void createReportRejectsNonCitizenUser() {
        CreateReportRequest request = new CreateReportRequest(
                "Pothole",
                "Large pothole in the right lane.",
                IssueCategory.ROAD_DAMAGE,
                10.762622,
                106.660172,
                null,
                "/uploads/report-before/before.jpg",
                null
        );

        assertThatThrownBy(() -> reportService.createReport(request, user(UserRole.STAFF)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void getReportsForMapRejectsInvalidBounds() {
        assertThatThrownBy(() -> reportService.getReportsForMap(11, 106, 10, 107, user(UserRole.OVERSEER)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("minLat must be less than or equal to maxLat");
    }

    @Test
    void submittedReportCanReplaceBeforePhoto() {
        UUID reportId = UUID.randomUUID();
        Report report = reportFor(user(UserRole.CITIZEN));
        report.setId(reportId);
        report.setCreatedAt(Instant.parse("2026-06-08T05:00:00Z"));
        report.setUpdatedAt(Instant.parse("2026-06-08T05:00:00Z"));

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        ReportResponse response = reportService.updateReport(
                reportId,
                new UpdateReportRequest(
                        "Updated pothole",
                        "Large pothole in the right lane.",
                        IssueCategory.ROAD_DAMAGE,
                        10.762622,
                        106.660172,
                        null,
                        "/uploads/report-before/replacement.png"
                ),
                report.getCreatedBy()
        );

        assertThat(response.beforePhotoUrl()).isEqualTo("/uploads/report-before/replacement.png");
    }

    @Test
    void fixedReportCannotReplaceBeforePhoto() {
        UUID reportId = UUID.randomUUID();
        Report report = reportFor(user(UserRole.CITIZEN));
        report.fix();

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> reportService.updateReport(
                reportId,
                new UpdateReportRequest(
                        "Updated pothole",
                        "Large pothole in the right lane.",
                        IssueCategory.ROAD_DAMAGE,
                        10.762622,
                        106.660172,
                        null,
                        "/uploads/report-before/replacement.png"
                ),
                user(UserRole.OVERSEER)
        ))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Before photo can only be replaced while report is SUBMITTED");
    }

    @Test
    void fixedReportCanBeUpdatedWhenBeforePhotoIsUnchanged() {
        UUID reportId = UUID.randomUUID();
        Report report = reportFor(user(UserRole.CITIZEN));
        report.setId(reportId);
        report.setCreatedAt(Instant.parse("2026-06-08T05:00:00Z"));
        report.setUpdatedAt(Instant.parse("2026-06-08T05:00:00Z"));
        report.fix();

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        ReportResponse response = reportService.updateReport(
                reportId,
                new UpdateReportRequest(
                        "Updated pothole",
                        "Large pothole in the right lane.",
                        IssueCategory.ROAD_DAMAGE,
                        10.762622,
                        106.660172,
                        null,
                        report.getBeforePhotoUrl()
                ),
                user(UserRole.OVERSEER)
        );

        assertThat(response.beforePhotoUrl()).isEqualTo(report.getBeforePhotoUrl());
    }

    @Test
    void getReportsForMapReturnsSubmittedPinSummary() {
        User citizen = user(UserRole.CITIZEN);
        User otherCitizen = user(UserRole.CITIZEN);
        Report report = reportFor(otherCitizen);
        report.setId(UUID.randomUUID());

        when(reportRepository.findSubmittedWithinBounds(10.7, 106.6, 10.8, 106.8))
                .thenReturn(List.of(report));

        List<ReportMapPinResponse> response = reportService.getReportsForMap(
                10.7,
                106.6,
                10.8,
                106.8,
                citizen
        );

        assertThat(response).hasSize(1);
        assertThat(response.get(0).id()).isEqualTo(report.getId());
        assertThat(response.get(0).title()).isEqualTo("Pothole");
        assertThat(response.get(0).status()).isEqualTo(ReportStatus.SUBMITTED);
        verify(reportRepository).findSubmittedWithinBounds(10.7, 106.6, 10.8, 106.8);
    }

    @Test
    void citizenCannotViewAnotherUsersReport() {
        UUID reportId = UUID.randomUUID();
        Report report = reportFor(user(UserRole.CITIZEN));

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> reportService.getReport(reportId, user(UserRole.CITIZEN)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void overseerCanFixReport() {
        UUID reportId = UUID.randomUUID();
        Report report = reportFor(user(UserRole.CITIZEN));
        report.setId(reportId);
        report.setCreatedAt(Instant.parse("2026-06-08T05:00:00Z"));
        report.setUpdatedAt(Instant.parse("2026-06-08T05:00:00Z"));

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        ReportResponse response = reportService.fixReport(reportId, user(UserRole.OVERSEER));

        assertThat(report.getStatus()).isEqualTo(ReportStatus.FIXED);
        assertThat(response.status()).isEqualTo(ReportStatus.FIXED);
    }

    @Test
    void citizenCannotFixReport() {
        UUID reportId = UUID.randomUUID();

        assertThatThrownBy(() -> reportService.fixReport(reportId, user(UserRole.CITIZEN)))
                .isInstanceOf(AccessDeniedException.class);
    }

    @Test
    void upvoteReportCreatesOneUpvoteAndUpdatesPriorityScore() {
        UUID reportId = UUID.randomUUID();
        User currentUser = user(UserRole.CITIZEN);
        Report report = reportFor(user(UserRole.CITIZEN));
        report.setId(reportId);
        report.setCreatedAt(Instant.parse("2026-06-08T05:00:00Z"));
        report.setUpdatedAt(Instant.parse("2026-06-08T05:00:00Z"));

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));
        when(reportUpvoteRepository.insertIfAbsent(reportId, currentUser.getId())).thenReturn(1);
        when(reportUpvoteRepository.countByReport_Id(reportId)).thenReturn(1L);

        ReportUpvoteResponse response = reportService.upvoteReport(reportId, currentUser);

        verify(reportUpvoteRepository).insertIfAbsent(reportId, currentUser.getId());
        assertThat(response.upvoteCount()).isEqualTo(1);
        assertThat(response.priorityScore()).isEqualTo(1);
        assertThat(response.hasUpvoted()).isTrue();
    }

    @Test
    void upvoteReportDoesNotDoubleCountSameUser() {
        UUID reportId = UUID.randomUUID();
        User currentUser = user(UserRole.CITIZEN);
        Report report = reportFor(user(UserRole.CITIZEN));
        report.setId(reportId);
        report.setCreatedAt(Instant.parse("2026-06-08T05:00:00Z"));
        report.setUpdatedAt(Instant.parse("2026-06-08T05:00:00Z"));

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));
        when(reportUpvoteRepository.insertIfAbsent(reportId, currentUser.getId())).thenReturn(0);
        when(reportUpvoteRepository.countByReport_Id(reportId)).thenReturn(2L);

        ReportUpvoteResponse response = reportService.upvoteReport(reportId, currentUser);

        verify(reportUpvoteRepository, never()).save(any(ReportUpvote.class));
        assertThat(response.upvoteCount()).isEqualTo(2);
        assertThat(response.priorityScore()).isEqualTo(2);
        assertThat(response.hasUpvoted()).isTrue();
    }

    @Test
    void removeUpvoteDeletesOneUpvoteAndUpdatesPriorityScore() {
        UUID reportId = UUID.randomUUID();
        User currentUser = user(UserRole.CITIZEN);
        Report report = reportFor(user(UserRole.CITIZEN));
        report.setId(reportId);

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));
        when(reportUpvoteRepository.deleteByReport_IdAndUser_Id(reportId, currentUser.getId())).thenReturn(1L);
        when(reportUpvoteRepository.countByReport_Id(reportId)).thenReturn(0L);

        ReportUpvoteResponse response = reportService.removeUpvote(reportId, currentUser);

        verify(reportUpvoteRepository).deleteByReport_IdAndUser_Id(reportId, currentUser.getId());
        assertThat(response.upvoteCount()).isZero();
        assertThat(response.priorityScore()).isZero();
        assertThat(response.hasUpvoted()).isFalse();
    }

    @Test
    void upvoteReportRejectsSelfUpvote() {
        UUID reportId = UUID.randomUUID();
        User currentUser = user(UserRole.CITIZEN);
        Report report = reportFor(currentUser);
        report.setId(reportId);

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> reportService.upvoteReport(reportId, currentUser))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Creators cannot upvote their own reports");
    }

    @Test
    void upvoteReportRejectsCancelledReport() {
        UUID reportId = UUID.randomUUID();
        Report report = reportFor(user(UserRole.CITIZEN));
        report.cancel();

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> reportService.upvoteReport(reportId, user(UserRole.CITIZEN)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Cancelled reports cannot be upvoted");
    }

    @Test
    void upvoteReportRejectsFixedReport() {
        UUID reportId = UUID.randomUUID();
        Report report = reportFor(user(UserRole.CITIZEN));
        report.fix();

        when(reportRepository.findById(reportId)).thenReturn(Optional.of(report));

        assertThatThrownBy(() -> reportService.upvoteReport(reportId, user(UserRole.CITIZEN)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Fixed reports cannot be upvoted");
    }

    @Test
    void upvoteReportRejectsStaffUser() {
        assertThatThrownBy(() -> reportService.upvoteReport(UUID.randomUUID(), user(UserRole.STAFF)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only citizens can upvote reports");
    }

    @Test
    void removeUpvoteRejectsOverseerUser() {
        assertThatThrownBy(() -> reportService.removeUpvote(UUID.randomUUID(), user(UserRole.OVERSEER)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only citizens can remove report upvotes");
    }

    @Test
    void getReportThrowsWhenReportDoesNotExist() {
        UUID reportId = UUID.randomUUID();
        when(reportRepository.findById(reportId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reportService.getReport(reportId, user(UserRole.OVERSEER)))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Report not found");
    }

    private User user(UserRole role) {
        User user = new User(role.name().toLowerCase() + "@example.local", role.name(), "hash", role);
        user.setId(UUID.randomUUID());
        return user;
    }

    private Report reportFor(User user) {
        return new Report(
                "Pothole",
                "Large pothole in the right lane.",
                IssueCategory.ROAD_DAMAGE,
                10.762622,
                106.660172,
                null,
                "/uploads/report-before/before.jpg",
                false,
                user
        );
    }
}
