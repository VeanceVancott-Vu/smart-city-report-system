package com.smartcity.reports.report;

import com.smartcity.reports.common.ResourceNotFoundException;
import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRole;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;

@Service
public class ReportService {

    private final ReportRepository reportRepository;
    private final ReportUpvoteRepository reportUpvoteRepository;
    private final ReportMapper reportMapper;

    public ReportService(
            ReportRepository reportRepository,
            ReportUpvoteRepository reportUpvoteRepository,
            ReportMapper reportMapper
    ) {
        this.reportRepository = reportRepository;
        this.reportUpvoteRepository = reportUpvoteRepository;
        this.reportMapper = reportMapper;
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
        return reportMapper.toResponse(report);
    }

    @Transactional
    public ReportResponse cancelReport(UUID id, User currentUser) {
        requireAuthenticated(currentUser);
        Report report = getReportEntity(id);
        ensureCanCancel(report, currentUser);
        reportRepository.delete(report);
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
        return reportRepository.findSubmittedWithinBounds(minLat, minLng, maxLat, maxLng)
                .stream()
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
        if (report.getStatus() == ReportStatus.CANCELLED) {
            throw new IllegalArgumentException("Cancelled reports cannot be upvoted");
        }
        if (report.getStatus() == ReportStatus.FIXED) {
            throw new IllegalArgumentException("Fixed reports cannot be upvoted");
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
                || isOwner(report, currentUser);
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

    private void ensureCanCancel(Report report, User currentUser) {
        if (currentUser.getRole() == UserRole.OVERSEER) {
            return;
        }
        if (currentUser.getRole() == UserRole.CITIZEN
                && isOwner(report, currentUser)
                && report.getStatus() != ReportStatus.FIXED) {
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
