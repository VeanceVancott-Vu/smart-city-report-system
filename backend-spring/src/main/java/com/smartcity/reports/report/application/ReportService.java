package com.smartcity.reports.report.application;

import com.smartcity.reports.common.ResourceNotFoundException;
import com.smartcity.reports.files.api.FileUploadResponse;
import com.smartcity.reports.files.application.FileReferenceCleanupService;
import com.smartcity.reports.files.application.FileStorageService;
import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.api.CreateReportRequest;
import com.smartcity.reports.report.api.ReportListResponse;
import com.smartcity.reports.report.api.ReportMapPinResponse;
import com.smartcity.reports.report.api.ReportResponse;
import com.smartcity.reports.report.api.ReportUpvoteResponse;
import com.smartcity.reports.report.api.UpdateReportAfterPhotoRequest;
import com.smartcity.reports.report.api.UpdateReportRequest;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.report.persistence.ReportUpvoteRepository;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Service
public class ReportService {

    private final ReportRepository reportRepository;
    private final ReportUpvoteRepository reportUpvoteRepository;
    private final ReportMapper reportMapper;
    private final FileReferenceCleanupService fileReferenceCleanupService;
    private final TaskRepository taskRepository;
    private final FileStorageService fileStorageService;

    public ReportService(
            ReportRepository reportRepository,
            ReportUpvoteRepository reportUpvoteRepository,
            ReportMapper reportMapper,
            FileReferenceCleanupService fileReferenceCleanupService
    ) {
        this(
                reportRepository,
                reportUpvoteRepository,
                reportMapper,
                fileReferenceCleanupService,
                null,
                null
        );
    }

    @Autowired
    public ReportService(
            ReportRepository reportRepository,
            ReportUpvoteRepository reportUpvoteRepository,
            ReportMapper reportMapper,
            FileReferenceCleanupService fileReferenceCleanupService,
            TaskRepository taskRepository,
            FileStorageService fileStorageService
    ) {
        this.reportRepository = reportRepository;
        this.reportUpvoteRepository = reportUpvoteRepository;
        this.reportMapper = reportMapper;
        this.fileReferenceCleanupService = fileReferenceCleanupService;
        this.taskRepository = taskRepository;
        this.fileStorageService = fileStorageService;
    }

    @Transactional
    public ReportResponse createReport(CreateReportRequest request, User currentUser) {
        requireAuthenticated(currentUser);
        if (currentUser.getRole() != UserRole.CITIZEN) {
            throw new AccessDeniedException("Only citizens can create reports");
        }

        Report report = new Report(
                request.title(),
                request.description(),
                request.category(),
                request.latitude(),
                request.longitude(),
                request.addressText(),
                request.beforePhotoUrl(),
                request.isAnonymous(),
                currentUser
        );

        return reportMapper.toResponse(reportRepository.save(report));
    }

    @Transactional(readOnly = true)
    public ReportListResponse getReports(
            User currentUser,
            boolean mine,
            ReportStatus status,
            IssueCategory category
    ) {
        requireAuthenticated(currentUser);
        Specification<Report> filters = buildFilters(currentUser, mine, status, category);
        List<ReportResponse> reports = reportRepository
                .findAll(filters, Sort.by(Sort.Direction.DESC, "createdAt"))
                .stream()
                .map(reportMapper::toResponse)
                .toList();
        return new ReportListResponse(reports);
    }

    @Transactional(readOnly = true)
    public ReportResponse getReport(UUID id, User currentUser) {
        requireAuthenticated(currentUser);
        Report report = getReportEntity(id);
        ensureCanView(report, currentUser);
        return reportMapper.toResponse(report);
    }

    @Transactional
    public ReportResponse updateReport(UUID id, UpdateReportRequest request, User currentUser) {
        requireAuthenticated(currentUser);
        Report report = getReportEntity(id);
        ensureCanEdit(report, currentUser);
        String previousBeforePhotoUrl = report.getBeforePhotoUrl();
        ensureBeforePhotoCanBeReplaced(report, request.beforePhotoUrl());

        report.updateDetails(
                request.title(),
                request.description(),
                request.category(),
                request.latitude(),
                request.longitude(),
                request.addressText(),
                request.beforePhotoUrl()
        );
        if (!Objects.equals(previousBeforePhotoUrl, request.beforePhotoUrl())) {
            reportRepository.flush();
            fileReferenceCleanupService.deleteIfUnused(previousBeforePhotoUrl, report.getId(), null);
        }
        return reportMapper.toResponse(report);
    }

    @Transactional
    public ReportResponse updateAfterPhoto(
            UUID id,
            UpdateReportAfterPhotoRequest request,
            User currentUser
    ) {
        requireAuthenticated(currentUser);
        requireStaff(currentUser);

        Report report = getReportEntity(id);
        ensureStaffOwnsLinkedTask(report, currentUser);
        String previousAfterPhotoUrl = report.getAfterPhotoUrl();
        report.updateAfterPhoto(request.afterPhotoUrl().trim());
        if (!Objects.equals(previousAfterPhotoUrl, report.getAfterPhotoUrl())) {
            reportRepository.flush();
            fileReferenceCleanupService.deleteIfUnused(previousAfterPhotoUrl, report.getId(), null);
        }
        return reportMapper.toResponse(report);
    }
    @Transactional
    public ReportResponse uploadAfterPhoto(
            UUID id,
            MultipartFile file,
            User currentUser
    ) {
        requireAuthenticated(currentUser);
        requireStaff(currentUser);

        Report report = getReportEntity(id);
        ensureStaffOwnsLinkedTask(report, currentUser);
        if (fileStorageService == null) {
            throw new IllegalStateException("File storage is not configured");
        }

        FileUploadResponse uploaded = fileStorageService.uploadReportAfter(file, currentUser);
        try {
            return updateAfterPhoto(
                    id,
                    new UpdateReportAfterPhotoRequest(uploaded.fileUrl()),
                    currentUser
            );
        } catch (RuntimeException exception) {
            try {
                fileStorageService.delete(uploaded.fileUrl());
            } catch (RuntimeException cleanupException) {
                exception.addSuppressed(cleanupException);
            }
            throw exception;
        }
    }


    @Transactional
    public ReportResponse cancelReport(UUID id, User currentUser) {
        requireAuthenticated(currentUser);
        Report report = getReportEntity(id);
        ensureCanCancel(report, currentUser);
        String beforePhotoUrl = report.getBeforePhotoUrl();
        String afterPhotoUrl = report.getAfterPhotoUrl();
        reportRepository.delete(report);
        reportRepository.flush();
        fileReferenceCleanupService.deleteIfUnused(beforePhotoUrl, report.getId(), null);
        fileReferenceCleanupService.deleteIfUnused(afterPhotoUrl, report.getId(), null);
        return reportMapper.toResponse(report);
    }

    @Transactional
    public ReportResponse fixReport(UUID id, User currentUser) {
        requireAuthenticated(currentUser);
        if (currentUser.getRole() != UserRole.OVERSEER) {
            throw new AccessDeniedException("Only overseers can fix reports");
        }

        Report report = getReportEntity(id);
        report.fix();
        return reportMapper.toResponse(report);
    }

    @Transactional
    public ReportUpvoteResponse upvoteReport(UUID id, User currentUser) {
        requireAuthenticated(currentUser);
        requireCitizen(currentUser, "Only citizens can upvote reports");
        Report report = getReportEntity(id);
        ensureCanReceiveUpvote(report);
        if (isOwner(report, currentUser)) {
            throw new IllegalArgumentException("Creators cannot upvote their own reports");
        }

        reportUpvoteRepository.insertIfAbsent(id, currentUser.getId());
        return syncUpvoteSummary(report, true);
    }

    @Transactional
    public ReportUpvoteResponse removeUpvote(UUID id, User currentUser) {
        requireAuthenticated(currentUser);
        requireCitizen(currentUser, "Only citizens can remove report upvotes");
        Report report = getReportEntity(id);
        reportUpvoteRepository.deleteByReport_IdAndUser_Id(id, currentUser.getId());
        return syncUpvoteSummary(report, false);
    }

    @Transactional(readOnly = true)
    public List<ReportMapPinResponse> getReportsForMap(
            double minLat,
            double minLng,
            double maxLat,
            double maxLng,
            User currentUser
    ) {
        requireAuthenticated(currentUser);
        validateBounds(minLat, minLng, maxLat, maxLng);
        List<Report> reports;
        if (currentUser.getRole() == UserRole.CITIZEN) {
            reports = reportRepository.findSubmittedWithinBounds(minLat, minLng, maxLat, maxLng);
        } else {
            reports = reportRepository.findWithinBounds(minLat, minLng, maxLat, maxLng);
        }
        return reports.stream()
                .map(reportMapper::toMapPinResponse)
                .toList();
    }

    private Specification<Report> buildFilters(
            User currentUser,
            boolean mine,
            ReportStatus status,
            IssueCategory category
    ) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (mine || currentUser.getRole() == UserRole.CITIZEN) {
                predicates.add(criteriaBuilder.equal(root.get("createdBy").get("id"), currentUser.getId()));
            }
            if (status != null) {
                predicates.add(criteriaBuilder.equal(root.get("status"), status));
            }
            if (category != null) {
                predicates.add(criteriaBuilder.equal(root.get("category"), category));
            }

            return criteriaBuilder.and(predicates.toArray(Predicate[]::new));
        };
    }

    private Report getReportEntity(UUID id) {
        return reportRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Report not found: " + id));
    }

    private ReportUpvoteResponse syncUpvoteSummary(Report report, boolean hasUpvoted) {
        int upvoteCount = Math.toIntExact(reportUpvoteRepository.countByReport_Id(report.getId()));
        report.updateUpvoteCount(upvoteCount);
        return reportMapper.toUpvoteResponse(report, hasUpvoted);
    }

    private void ensureCanReceiveUpvote(Report report) {
        if (report.getStatus() != ReportStatus.SUBMITTED) {
            throw new IllegalArgumentException("Only submitted reports can be upvoted");
        }
    }

    private void ensureCanView(Report report, User currentUser) {
        if (!canView(report, currentUser)) {
            throw new AccessDeniedException("Report is not visible to this user");
        }
    }

    private boolean canView(Report report, User currentUser) {
        return currentUser.getRole() == UserRole.OVERSEER
                || currentUser.getRole() == UserRole.STAFF
                || isOwner(report, currentUser)
                || (currentUser.getRole() == UserRole.CITIZEN
                        && report.getStatus() == ReportStatus.SUBMITTED);
    }

    private void ensureCanEdit(Report report, User currentUser) {
        if (currentUser.getRole() == UserRole.OVERSEER) {
            return;
        }
        if (currentUser.getRole() == UserRole.CITIZEN
                && isOwner(report, currentUser)
                && report.getStatus() == ReportStatus.SUBMITTED) {
            return;
        }
        throw new AccessDeniedException("Report cannot be edited by this user");
    }

    private void ensureBeforePhotoCanBeReplaced(Report report, String requestedBeforePhotoUrl) {
        if (Objects.equals(report.getBeforePhotoUrl(), requestedBeforePhotoUrl)) {
            return;
        }
        if (report.getStatus() != ReportStatus.SUBMITTED) {
            throw new IllegalArgumentException("Before photo can only be replaced while report is SUBMITTED");
        }
    }

    private void ensureStaffOwnsLinkedTask(Report report, User currentUser) {
        UUID linkedTaskId = report.getLinkedTaskId();
        if (linkedTaskId == null || taskRepository == null) {
            throw new AccessDeniedException("Only staff assigned to the linked task can upload report after photos");
        }

        Task task = taskRepository.findById(linkedTaskId)
                .orElseThrow(() -> new ResourceNotFoundException("Linked task not found: " + linkedTaskId));
        if (task.getAssignedStaff() == null
                || !task.getAssignedStaff().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Only staff assigned to the linked task can upload report after photos");
        }
    }

    private void ensureCanCancel(Report report, User currentUser) {
        if (currentUser.getRole() == UserRole.OVERSEER) {
            return;
        }
        if (currentUser.getRole() == UserRole.CITIZEN
                && isOwner(report, currentUser)
                && report.getStatus() == ReportStatus.SUBMITTED) {
            return;
        }
        throw new AccessDeniedException("Report cannot be cancelled by this user");
    }

    private boolean isOwner(Report report, User currentUser) {
        return report.getCreatedBy().getId().equals(currentUser.getId());
    }

    private void requireAuthenticated(User currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
    }

    private void requireStaff(User currentUser) {
        if (currentUser.getRole() != UserRole.STAFF) {
            throw new AccessDeniedException("Only staff can upload report after photos");
        }
    }

    private void requireCitizen(User currentUser, String message) {
        if (currentUser.getRole() != UserRole.CITIZEN) {
            throw new AccessDeniedException(message);
        }
    }

    private void validateBounds(double minLat, double minLng, double maxLat, double maxLng) {
        if (minLat > maxLat) {
            throw new IllegalArgumentException("minLat must be less than or equal to maxLat");
        }
        if (minLng > maxLng) {
            throw new IllegalArgumentException("minLng must be less than or equal to maxLng");
        }
    }
}
