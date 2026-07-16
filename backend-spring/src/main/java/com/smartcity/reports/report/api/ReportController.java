package com.smartcity.reports.report.api;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.application.ReportService;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.user.domain.User;
import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import org.springframework.http.MediaType;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.net.URI;
import java.util.List;
import java.util.UUID;

@Validated
@RestController
@RequestMapping("/api/reports")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping
    public ResponseEntity<ReportResponse> createReport(
            @Valid @RequestBody CreateReportRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        ReportResponse response = reportService.createReport(request, currentUser);
        return ResponseEntity.created(URI.create("/api/reports/" + response.id())).body(response);
    }

    @GetMapping
    public ReportListResponse getReports(
            @AuthenticationPrincipal User currentUser,
            @RequestParam(defaultValue = "false") boolean mine,
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(required = false) IssueCategory category
    ) {
        return reportService.getReports(currentUser, mine, status, category);
    }

    @GetMapping("/map")
    public List<ReportMapPinResponse> getReportsForMap(
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") double minLat,
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") double minLng,
            @RequestParam @DecimalMin("-90.0") @DecimalMax("90.0") double maxLat,
            @RequestParam @DecimalMin("-180.0") @DecimalMax("180.0") double maxLng,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.getReportsForMap(minLat, minLng, maxLat, maxLng, currentUser);
    }

    @PostMapping("/{id}/upvote")
    public ReportUpvoteResponse upvoteReport(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.upvoteReport(id, currentUser);
    }

    @DeleteMapping("/{id}/upvote")
    public ReportUpvoteResponse removeUpvote(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.removeUpvote(id, currentUser);
    }

    @GetMapping("/{id}")
    public ReportResponse getReport(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.getReport(id, currentUser);
    }

    @PutMapping("/{id}")
    public ReportResponse updateReport(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateReportRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.updateReport(id, request, currentUser);
    }

    @PatchMapping("/{id}/after-photo")
    public ReportResponse updateAfterPhoto(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateReportAfterPhotoRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.updateAfterPhoto(id, request, currentUser);
    }

    @PostMapping(value = "/{id}/after-photo/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ReportResponse uploadAfterPhoto(
            @PathVariable UUID id,
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.uploadAfterPhoto(id, file, currentUser);
    }
    @PatchMapping("/{id}/cancel")
    public ReportResponse cancelReport(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.cancelReport(id, currentUser);
    }

    @PatchMapping("/{id}/fix")
    public ReportResponse fixReport(
            @PathVariable UUID id,
            @AuthenticationPrincipal User currentUser
    ) {
        return reportService.fixReport(id, currentUser);
    }
}
