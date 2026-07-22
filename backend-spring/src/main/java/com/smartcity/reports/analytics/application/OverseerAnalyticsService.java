package com.smartcity.reports.analytics.application;

import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.AnalyticsFiltersResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.AnalyticsMapPointResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.AttentionItemResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.CategoryBreakdownResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.ReportOverviewResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.StaffWorkloadResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.TaskOverviewResponse;
import com.smartcity.reports.analytics.api.OverseerAnalyticsResponse.TrendPointResponse;
import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.report.domain.ReportStatus;
import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.domain.TaskStatus;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import com.smartcity.reports.user.persistence.UserRepository;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;

@Service
public class OverseerAnalyticsService {

    private static final Set<TaskStatus> ACTIVE_STATUSES = EnumSet.of(
            TaskStatus.ASSIGNED,
            TaskStatus.IN_PROGRESS,
            TaskStatus.DENIED
    );
    private static final Set<TaskStatus> REVIEW_STATUSES = EnumSet.of(
            TaskStatus.DONE,
            TaskStatus.PENDING_REVIEW
    );
    private static final Set<TaskStatus> COMPLETED_STATUSES = EnumSet.of(
            TaskStatus.DONE,
            TaskStatus.PENDING_REVIEW,
            TaskStatus.APPROVED,
            TaskStatus.CLOSED
    );
    private static final int ATTENTION_LIMIT = 30;

    private final ReportRepository reportRepository;
    private final TaskRepository taskRepository;
    private final UserRepository userRepository;
    private final Clock clock;

    public OverseerAnalyticsService(
            ReportRepository reportRepository,
            TaskRepository taskRepository,
            UserRepository userRepository,
            Clock clock
    ) {
        this.reportRepository = reportRepository;
        this.taskRepository = taskRepository;
        this.userRepository = userRepository;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public OverseerAnalyticsResponse getAnalytics(
            Instant from,
            Instant to,
            IssueCategory category,
            UUID staffId,
            String area,
            User currentUser
    ) {
        requireOverseer(currentUser);
        Instant effectiveTo = to == null ? clock.instant() : to;
        if (from != null && from.isAfter(effectiveTo)) {
            throw new IllegalArgumentException("Analytics start date must not be after end date");
        }

        String normalizedArea = normalizeArea(area);
        List<Task> allTasks = taskRepository.findAll();
        Set<UUID> staffTaskIds = new HashSet<>();
        Set<UUID> staffReportIds = new HashSet<>();
        if (staffId != null) {
            allTasks.stream()
                    .filter(task -> isAssignedTo(task, staffId))
                    .forEach(task -> {
                        staffTaskIds.add(task.getId());
                        task.getReports().forEach(report -> staffReportIds.add(report.getId()));
                    });
        }

        List<Task> tasks = allTasks.stream()
                .filter(task -> within(task.getCreatedAt(), from, effectiveTo))
                .filter(task -> category == null || task.getCategory() == category)
                .filter(task -> matchesArea(task.getAddressText(), normalizedArea))
                .filter(task -> staffId == null || isAssignedTo(task, staffId))
                .toList();

        List<Report> reports = reportRepository.findAll().stream()
                .filter(report -> within(report.getCreatedAt(), from, effectiveTo))
                .filter(report -> category == null || report.getCategory() == category)
                .filter(report -> matchesArea(report.getAddressText(), normalizedArea))
                .filter(report -> staffId == null
                        || staffTaskIds.contains(report.getLinkedTaskId())
                        || staffReportIds.contains(report.getId()))
                .toList();

        List<User> staffUsers = userRepository.findByRoleOrderByFullNameAsc(UserRole.STAFF).stream()
                .filter(user -> staffId == null || user.getId().equals(staffId))
                .toList();

        Map<ReportStatus, Long> reportCounts = enumCounts(ReportStatus.class);
        long totalUpvotes = 0;
        long priorityTotal = 0;
        for (Report report : reports) {
            reportCounts.compute(report.getStatus(), (status, count) -> count + 1);
            totalUpvotes += report.getUpvoteCount();
            priorityTotal += report.getPriorityScore();
        }

        Map<TaskStatus, Long> taskCounts = enumCounts(TaskStatus.class);
        for (Task task : tasks) {
            taskCounts.compute(task.getStatus(), (status, count) -> count + 1);
        }

        long completedTasks = tasks.stream().filter(task -> isCompleted(task.getStatus())).count();
        ReportOverviewResponse reportOverview = new ReportOverviewResponse(
                reports.size(),
                immutable(reportCounts),
                totalUpvotes,
                average(priorityTotal, reports.size()),
                percentage(reportCounts.get(ReportStatus.FIXED), reports.size()),
                percentage(reportCounts.get(ReportStatus.CANCELLED), reports.size())
        );
        TaskOverviewResponse taskOverview = new TaskOverviewResponse(
                tasks.size(),
                immutable(taskCounts),
                tasks.stream().filter(task -> task.getAssignedStaff() == null).count(),
                tasks.stream().filter(task -> ACTIVE_STATUSES.contains(task.getStatus())).count(),
                tasks.stream().filter(task -> REVIEW_STATUSES.contains(task.getStatus())).count(),
                completedTasks,
                percentage(completedTasks, tasks.size()),
                averageHours(tasks, Task::getStartedAt, Task::getSubmittedAt),
                averageHours(tasks, Task::getSubmittedAt, Task::getReviewedAt),
                averageHours(tasks, Task::getCreatedAt, Task::getClosedAt)
        );

        return new OverseerAnalyticsResponse(
                clock.instant(),
                new AnalyticsFiltersResponse(from, effectiveTo, category, staffId, normalizedArea),
                reportOverview,
                taskOverview,
                trends(reports, tasks, from, effectiveTo),
                categoryBreakdown(reports, tasks),
                staffWorkloads(staffUsers, tasks),
                attentionItems(reports, tasks, staffUsers),
                mapPoints(reports)
        );
    }

    private List<TrendPointResponse> trends(
            List<Report> reports,
            List<Task> tasks,
            Instant requestedFrom,
            Instant to
    ) {
        Instant firstDataPoint = earliestCreatedAt(reports, tasks);
        Instant effectiveFrom = requestedFrom != null
                ? requestedFrom
                : firstDataPoint != null ? firstDataPoint : to.minus(Duration.ofDays(29));
        TrendGranularity granularity = TrendGranularity.forRange(effectiveFrom, to);
        LocalDate firstBucket = granularity.bucket(date(effectiveFrom));
        LocalDate lastBucket = granularity.bucket(date(to));
        Map<LocalDate, long[]> values = new LinkedHashMap<>();
        for (LocalDate cursor = firstBucket;
             !cursor.isAfter(lastBucket);
             cursor = granularity.next(cursor)) {
            values.put(cursor, new long[4]);
        }

        for (Report report : reports) {
            increment(values, granularity.bucket(date(report.getCreatedAt())), 0);
            if (report.getStatus() == ReportStatus.FIXED) {
                increment(values, granularity.bucket(date(report.getUpdatedAt())), 1);
            }
        }
        for (Task task : tasks) {
            increment(values, granularity.bucket(date(task.getCreatedAt())), 2);
            if (task.getClosedAt() != null) {
                increment(values, granularity.bucket(date(task.getClosedAt())), 3);
            }
        }

        return values.entrySet().stream()
                .map(entry -> new TrendPointResponse(
                        entry.getKey(),
                        entry.getValue()[0],
                        entry.getValue()[1],
                        entry.getValue()[2],
                        entry.getValue()[3]
                ))
                .toList();
    }

    private List<CategoryBreakdownResponse> categoryBreakdown(
            List<Report> reports,
            List<Task> tasks
    ) {
        List<CategoryBreakdownResponse> result = new ArrayList<>();
        for (IssueCategory category : IssueCategory.values()) {
            long categoryReports = reports.stream().filter(report -> report.getCategory() == category).count();
            long fixedReports = reports.stream()
                    .filter(report -> report.getCategory() == category)
                    .filter(report -> report.getStatus() == ReportStatus.FIXED)
                    .count();
            long categoryTasks = tasks.stream().filter(task -> task.getCategory() == category).count();
            long closedTasks = tasks.stream()
                    .filter(task -> task.getCategory() == category)
                    .filter(task -> task.getStatus() == TaskStatus.CLOSED)
                    .count();
            result.add(new CategoryBreakdownResponse(
                    category,
                    categoryReports,
                    fixedReports,
                    categoryTasks,
                    closedTasks
            ));
        }
        return List.copyOf(result);
    }

    private List<StaffWorkloadResponse> staffWorkloads(List<User> staffUsers, List<Task> tasks) {
        Map<UUID, List<Task>> tasksByStaff = new HashMap<>();
        for (Task task : tasks) {
            if (task.getAssignedStaff() != null) {
                tasksByStaff.computeIfAbsent(task.getAssignedStaff().getId(), ignored -> new ArrayList<>())
                        .add(task);
            }
        }

        return staffUsers.stream()
                .map(staff -> {
                    List<Task> assigned = tasksByStaff.getOrDefault(staff.getId(), List.of());
                    long active = assigned.stream()
                            .filter(task -> ACTIVE_STATUSES.contains(task.getStatus()))
                            .count();
                    long pendingReview = assigned.stream()
                            .filter(task -> REVIEW_STATUSES.contains(task.getStatus()))
                            .count();
                    long completed = assigned.stream().filter(task -> isCompleted(task.getStatus())).count();
                    long denied = assigned.stream()
                            .filter(task -> task.getStatus() == TaskStatus.DENIED)
                            .count();
                    return new StaffWorkloadResponse(
                            staff.getId(),
                            staff.getFullName(),
                            staff.getEmail(),
                            staff.isActive(),
                            assigned.size(),
                            active,
                            pendingReview,
                            completed,
                            denied,
                            percentage(completed, assigned.size()),
                            averageHours(assigned, Task::getStartedAt, Task::getSubmittedAt)
                    );
                })
                .sorted(Comparator.comparingLong(StaffWorkloadResponse::activeTasks).reversed()
                        .thenComparing(StaffWorkloadResponse::fullName))
                .toList();
    }

    private List<AttentionItemResponse> attentionItems(
            List<Report> reports,
            List<Task> tasks,
            List<User> staffUsers
    ) {
        List<AttentionItemResponse> items = new ArrayList<>();
        for (Report report : reports) {
            if (report.getStatus() == ReportStatus.SUBMITTED && report.getLinkedTaskId() == null) {
                String reason = report.getPriorityScore() > 0
                        ? "HIGH_PRIORITY_UNASSIGNED_REPORT"
                        : "UNASSIGNED_REPORT";
                items.add(new AttentionItemResponse(
                        "REPORT",
                        report.getId(),
                        report.getTitle(),
                        report.getStatus().name(),
                        reason,
                        report.getPriorityScore(),
                        null,
                        null,
                        report.getAddressText(),
                        report.getUpdatedAt()
                ));
            }
        }

        Map<UUID, User> staffById = new HashMap<>();
        staffUsers.forEach(staff -> staffById.put(staff.getId(), staff));
        Instant staleBefore = clock.instant().minus(Duration.ofDays(7));
        for (Task task : tasks) {
            String reason = taskAttentionReason(task, staffById, staleBefore);
            if (reason == null) {
                continue;
            }
            User assigned = task.getAssignedStaff();
            items.add(new AttentionItemResponse(
                    "TASK",
                    task.getId(),
                    task.getTitle(),
                    task.getStatus().name(),
                    reason,
                    task.getPriorityScore(),
                    assigned == null ? null : assigned.getId(),
                    assigned == null ? null : assigned.getFullName(),
                    task.getAddressText(),
                    task.getUpdatedAt()
            ));
        }

        return items.stream()
                .sorted(Comparator.comparingInt(AttentionItemResponse::priorityScore).reversed()
                        .thenComparing(
                                AttentionItemResponse::updatedAt,
                                Comparator.nullsLast(Comparator.naturalOrder())
                        ))
                .limit(ATTENTION_LIMIT)
                .toList();
    }

    private String taskAttentionReason(Task task, Map<UUID, User> staffById, Instant staleBefore) {
        if (task.getAssignedStaff() == null && task.getStatus() == TaskStatus.NEW) {
            return "UNASSIGNED_TASK";
        }
        if (REVIEW_STATUSES.contains(task.getStatus())) {
            return "PENDING_REVIEW";
        }
        if (task.getStatus() == TaskStatus.DENIED) {
            return "DENIED_REWORK";
        }
        if (task.getAssignedStaff() != null
                && ACTIVE_STATUSES.contains(task.getStatus())
                && !staffById.getOrDefault(task.getAssignedStaff().getId(), task.getAssignedStaff()).isActive()) {
            return "INACTIVE_STAFF_ASSIGNMENT";
        }
        if (ACTIVE_STATUSES.contains(task.getStatus())
                && task.getUpdatedAt() != null
                && task.getUpdatedAt().isBefore(staleBefore)) {
            return "STALE_ACTIVE_TASK";
        }
        return null;
    }

    private List<AnalyticsMapPointResponse> mapPoints(List<Report> reports) {
        return reports.stream()
                .sorted(Comparator.comparingInt(Report::getPriorityScore).reversed()
                        .thenComparing(Report::getCreatedAt, Comparator.reverseOrder()))
                .map(report -> new AnalyticsMapPointResponse(
                        report.getId(),
                        report.getTitle(),
                        report.getCategory(),
                        report.getStatus(),
                        report.getLatitude(),
                        report.getLongitude(),
                        report.getAddressText(),
                        report.getPriorityScore(),
                        report.getUpvoteCount()
                ))
                .toList();
    }

    private Instant earliestCreatedAt(List<Report> reports, List<Task> tasks) {
        Instant earliestReport = reports.stream()
                .map(Report::getCreatedAt)
                .filter(java.util.Objects::nonNull)
                .min(Comparator.naturalOrder())
                .orElse(null);
        Instant earliestTask = tasks.stream()
                .map(Task::getCreatedAt)
                .filter(java.util.Objects::nonNull)
                .min(Comparator.naturalOrder())
                .orElse(null);
        if (earliestReport == null) {
            return earliestTask;
        }
        if (earliestTask == null) {
            return earliestReport;
        }
        return earliestReport.isBefore(earliestTask) ? earliestReport : earliestTask;
    }

    private <E extends Enum<E>> Map<E, Long> enumCounts(Class<E> enumType) {
        EnumMap<E, Long> counts = new EnumMap<>(enumType);
        for (E value : enumType.getEnumConstants()) {
            counts.put(value, 0L);
        }
        return counts;
    }

    private <E extends Enum<E>> Map<E, Long> immutable(Map<E, Long> source) {
        return Collections.unmodifiableMap(new EnumMap<>(source));
    }

    private double averageHours(
            List<Task> tasks,
            Function<Task, Instant> start,
            Function<Task, Instant> end
    ) {
        double totalHours = 0;
        long count = 0;
        for (Task task : tasks) {
            Instant startValue = start.apply(task);
            Instant endValue = end.apply(task);
            if (startValue == null || endValue == null || endValue.isBefore(startValue)) {
                continue;
            }
            totalHours += Duration.between(startValue, endValue).toMinutes() / 60.0;
            count++;
        }
        return count == 0 ? 0 : round(totalHours / count);
    }

    private boolean within(Instant value, Instant from, Instant to) {
        if (value == null) {
            return false;
        }
        return (from == null || !value.isBefore(from)) && !value.isAfter(to);
    }

    private boolean matchesArea(String address, String normalizedArea) {
        return normalizedArea == null
                || address != null && address.toLowerCase(Locale.ROOT).contains(normalizedArea);
    }

    private boolean isAssignedTo(Task task, UUID staffId) {
        return task.getAssignedStaff() != null && task.getAssignedStaff().getId().equals(staffId);
    }

    private boolean isCompleted(TaskStatus status) {
        return COMPLETED_STATUSES.contains(status);
    }

    private String normalizeArea(String area) {
        if (area == null || area.isBlank()) {
            return null;
        }
        return area.trim().toLowerCase(Locale.ROOT);
    }

    private double average(long total, long count) {
        return count == 0 ? 0 : round((double) total / count);
    }

    private double percentage(long part, long total) {
        return total == 0 ? 0 : round((double) part * 100 / total);
    }

    private double round(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private LocalDate date(Instant value) {
        return value.atZone(ZoneOffset.UTC).toLocalDate();
    }

    private void increment(Map<LocalDate, long[]> values, LocalDate bucket, int index) {
        long[] counts = values.get(bucket);
        if (counts != null) {
            counts[index]++;
        }
    }

    private void requireOverseer(User currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
        if (currentUser.getRole() != UserRole.OVERSEER) {
            throw new AccessDeniedException("Only overseers can view system analytics");
        }
    }

    private enum TrendGranularity {
        DAY {
            @Override
            LocalDate bucket(LocalDate date) {
                return date;
            }

            @Override
            LocalDate next(LocalDate date) {
                return date.plusDays(1);
            }
        },
        WEEK {
            @Override
            LocalDate bucket(LocalDate date) {
                return date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
            }

            @Override
            LocalDate next(LocalDate date) {
                return date.plusWeeks(1);
            }
        },
        MONTH {
            @Override
            LocalDate bucket(LocalDate date) {
                return date.withDayOfMonth(1);
            }

            @Override
            LocalDate next(LocalDate date) {
                return date.plusMonths(1);
            }
        };

        abstract LocalDate bucket(LocalDate date);

        abstract LocalDate next(LocalDate date);

        static TrendGranularity forRange(Instant from, Instant to) {
            long days = Math.max(0, Duration.between(from, to).toDays());
            if (days <= 31) {
                return DAY;
            }
            if (days <= 180) {
                return WEEK;
            }
            return MONTH;
        }
    }
}
