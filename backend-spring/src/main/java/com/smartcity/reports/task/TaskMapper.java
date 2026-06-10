package com.smartcity.reports.task;

import com.smartcity.reports.report.Report;
import com.smartcity.reports.report.UserSummaryResponse;
import com.smartcity.reports.user.User;
import org.springframework.stereotype.Component;

@Component
class TaskMapper {

    TaskResponse toResponse(Task task) {
        return new TaskResponse(
                task.getId(),
                task.getTitle(),
                task.getDescription(),
                task.getCategory(),
                task.getStatus(),
                task.getLatitude(),
                task.getLongitude(),
                task.getAddressText(),
                task.getPriorityScore(),
                toUserSummary(task.getAssignedStaff()),
                toUserSummary(task.getCreatedByOverseer()),
                task.getBeforePhotoUrl(),
                task.getAfterPhotoUrl(),
                task.getStaffNote(),
                task.getAiConfidenceScore(),
                task.getAiDecision(),
                task.getStartedAt(),
                task.getSubmittedAt(),
                task.getReviewedAt(),
                task.getClosedAt(),
                task.getCreatedAt(),
                task.getUpdatedAt(),
                task.getReports().stream()
                        .map(Report::getId)
                        .toList()
        );
    }

    private UserSummaryResponse toUserSummary(User user) {
        if (user == null) {
            return null;
        }
        return new UserSummaryResponse(user.getId(), user.getDisplayName(), user.getRole());
    }
}
