package com.smartcity.reports.report.application;

import com.smartcity.reports.report.api.ReportMapPinResponse;
import com.smartcity.reports.report.api.ReportResponse;
import com.smartcity.reports.report.api.ReportUpvoteResponse;
import com.smartcity.reports.user.api.UserSummaryResponse;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.user.domain.User;
import org.springframework.stereotype.Component;

@Component
public class ReportMapper {

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
