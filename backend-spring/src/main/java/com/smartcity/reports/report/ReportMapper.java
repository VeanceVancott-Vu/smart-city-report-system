package com.smartcity.reports.report;

import com.smartcity.reports.user.User;
import org.springframework.stereotype.Component;

@Component
class ReportMapper {

    ReportResponse toResponse(Report report) {
        User creator = report.getCreatedBy();
        return new ReportResponse(
                report.getId(),
                report.getTitle(),
                report.getDescription(),
                report.getCategory(),
                report.getStatus(),
                report.getLatitude(),
                report.getLongitude(),
                report.getAddressText(),
                report.getBeforePhotoUrl(),
                report.isAnonymous(),
                report.getUpvoteCount(),
                report.getPriorityScore(),
                report.getCreatedAt(),
                report.getUpdatedAt(),
                new UserSummaryResponse(creator.getId(), creator.getDisplayName(), creator.getRole())
        );
    }

    ReportMapPinResponse toMapPinResponse(Report report) {
        return new ReportMapPinResponse(
                report.getId(),
                report.getTitle(),
                report.getCategory(),
                report.getStatus(),
                report.getLatitude(),
                report.getLongitude(),
                report.getUpvoteCount(),
                report.getPriorityScore(),
                report.getCreatedBy().getId()
        );
    }

    ReportUpvoteResponse toUpvoteResponse(Report report, boolean hasUpvoted) {
        return new ReportUpvoteResponse(
                report.getId(),
                report.getUpvoteCount(),
                report.getPriorityScore(),
                hasUpvoted
        );
    }
}
