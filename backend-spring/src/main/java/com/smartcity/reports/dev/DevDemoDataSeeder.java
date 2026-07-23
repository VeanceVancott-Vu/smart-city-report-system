package com.smartcity.reports.dev;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.domain.TaskStatus;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.persistence.UserRepository;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Component
@Profile({"local", "dev"})
@Order(2)
public class DevDemoDataSeeder implements ApplicationRunner {

    static final int ANALYTICS_REPORT_COUNT = 48;
    static final int ANALYTICS_TASK_COUNT = 32;

    static final UUID POTHOLE_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000003");
    static final UUID STREETLIGHT_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000004");
    static final UUID CURB_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000005");
    static final UUID DRAIN_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000006");
    static final UUID MANHOLE_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000007");
    static final UUID FLOODING_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000008");

    static final UUID ROAD_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000001");
    static final UUID STREETLIGHT_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000002");
    static final UUID DRAINAGE_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000003");

    private static final List<String> ANALYTICS_CITIZEN_EMAILS = List.of(
            "citizen@test.com",
            "linh.nguyen@test.com",
            "minh.tran@test.com",
            "an.le@test.com"
    );
    private static final List<String> ANALYTICS_STAFF_EMAILS = List.of(
            "staff@test.com",
            "mai.nguyen.staff@test.com",
            "quang.tran.staff@test.com",
            "thuy.le.staff@test.com"
    );
    private static final String ANALYTICS_SEED_MARKER_TASK_TITLE =
            "Resolve flush the local drainage line in District 1";
    private static final List<AreaSeed> ANALYTICS_AREAS = List.of(
            new AreaSeed(
                    "District 1",
                    "Nguyen Hue Boulevard, Ben Nghe Ward, District 1",
                    "Nguyen Hue walking street",
                    10.7769,
                    106.7009
            ),
            new AreaSeed(
                    "District 3",
                    "Vo Thi Sau Street, Ward 7, District 3",
                    "Turtle Lake",
                    10.7876,
                    106.6917
            ),
            new AreaSeed(
                    "Binh Thanh District",
                    "Dien Bien Phu Street, Ward 25, Binh Thanh District",
                    "Hang Xanh intersection",
                    10.8030,
                    106.7147
            ),
            new AreaSeed(
                    "Thu Duc City",
                    "Vo Nguyen Giap Boulevard, Thao Dien Ward, Thu Duc City",
                    "Thao Dien station",
                    10.8025,
                    106.7335
            ),
            new AreaSeed(
                    "District 7",
                    "Nguyen Van Linh Boulevard, Tan Phong Ward, District 7",
                    "Crescent Mall junction",
                    10.7295,
                    106.7215
            ),
            new AreaSeed(
                    "Tan Binh District",
                    "Cong Hoa Street, Ward 4, Tan Binh District",
                    "Hoang Hoa Tham flyover",
                    10.8004,
                    106.6521
            )
    );
    private static final List<IssueSeed> ANALYTICS_ISSUES = List.of(
            new IssueSeed(
                    IssueCategory.ROAD_DAMAGE,
                    "Deep pothole slowing traffic",
                    "repair the damaged road surface",
                    "The road surface has broken into a deep pothole and vehicles are swerving around it."
            ),
            new IssueSeed(
                    IssueCategory.GARBAGE,
                    "Overflowing public waste bins",
                    "remove accumulated public waste",
                    "Several public bins are full and loose rubbish is spreading onto the pavement."
            ),
            new IssueSeed(
                    IssueCategory.DRAINAGE,
                    "Drain blocked after heavy rain",
                    "clear and inspect the drainage inlet",
                    "Leaves and sediment are blocking the inlet, leaving standing water after rain."
            ),
            new IssueSeed(
                    IssueCategory.STREET_LIGHT,
                    "Streetlights dark along the sidewalk",
                    "restore the street lighting circuit",
                    "Multiple lamps are not turning on at night and visibility is poor for pedestrians."
            ),
            new IssueSeed(
                    IssueCategory.ROAD_DAMAGE,
                    "Cracked road edge near crossing",
                    "repair the cracked road edge",
                    "The edge of the carriageway is cracked and is becoming unsafe near the crossing."
            ),
            new IssueSeed(
                    IssueCategory.WATER_LEAK,
                    "Clean water leaking from roadside pipe",
                    "locate and repair the leaking pipe",
                    "Clean water is continuously seeping through the road and creating a slippery patch."
            ),
            new IssueSeed(
                    IssueCategory.GARBAGE,
                    "Illegal dumping beside the alley",
                    "clear the illegal dumping site",
                    "Household waste and bulky items have been left beside the alley entrance."
            ),
            new IssueSeed(
                    IssueCategory.TRAFFIC_SIGN,
                    "Traffic sign leaning toward the road",
                    "secure the damaged traffic sign",
                    "The signpost is loose and leaning into the vehicle lane."
            ),
            new IssueSeed(
                    IssueCategory.DRAINAGE,
                    "Recurring waterlogging at intersection",
                    "flush the local drainage line",
                    "The intersection remains waterlogged for hours after otherwise moderate rainfall."
            ),
            new IssueSeed(
                    IssueCategory.TREE_BLOCKAGE,
                    "Low branches blocking the footpath",
                    "trim branches obstructing the footpath",
                    "Low branches force pedestrians to step off the footpath into traffic."
            ),
            new IssueSeed(
                    IssueCategory.ROAD_DAMAGE,
                    "Uneven asphalt around utility cover",
                    "level the asphalt around the utility cover",
                    "The asphalt has sunk around a utility cover and creates a sharp bump for motorcycles."
            ),
            new IssueSeed(
                    IssueCategory.STREET_LIGHT,
                    "Streetlamp flickering through the night",
                    "replace the failing streetlamp",
                    "A lamp repeatedly flickers and leaves the bus stop dark for long periods."
            ),
            new IssueSeed(
                    IssueCategory.OTHER,
                    "Loose pedestrian safety railing",
                    "secure the pedestrian safety railing",
                    "A section of safety railing is loose beside a busy pedestrian route."
            ),
            new IssueSeed(
                    IssueCategory.WATER_LEAK,
                    "Possible underground water-main leak",
                    "inspect the suspected water-main leak",
                    "A wet patch keeps returning during dry weather and the asphalt is starting to soften."
            )
    );
    private static final List<TaskStatus> ANALYTICS_TASK_STATUSES = List.of(
            TaskStatus.CLOSED,
            TaskStatus.ASSIGNED,
            TaskStatus.IN_PROGRESS,
            TaskStatus.DONE,
            TaskStatus.APPROVED,
            TaskStatus.NEW,
            TaskStatus.CLOSED,
            TaskStatus.DENIED,
            TaskStatus.IN_PROGRESS,
            TaskStatus.CLOSED,
            TaskStatus.ASSIGNED,
            TaskStatus.DONE,
            TaskStatus.CANCELLED,
            TaskStatus.APPROVED,
            TaskStatus.IN_PROGRESS,
            TaskStatus.CLOSED,
            TaskStatus.NEW,
            TaskStatus.ASSIGNED,
            TaskStatus.DONE,
            TaskStatus.CLOSED,
            TaskStatus.DENIED,
            TaskStatus.IN_PROGRESS,
            TaskStatus.APPROVED,
            TaskStatus.ASSIGNED,
            TaskStatus.CLOSED,
            TaskStatus.DONE,
            TaskStatus.IN_PROGRESS,
            TaskStatus.CANCELLED,
            TaskStatus.NEW,
            TaskStatus.APPROVED,
            TaskStatus.ASSIGNED,
            TaskStatus.IN_PROGRESS
    );
    private static final int[] STAFF_ASSIGNMENT_PATTERN = {
            0, 0, 0, 1, 1, 2, 2, 3,
            0, 0, 1, 1, 2, 2, 3, 0,
            0, 1, 1, 2, 2, 3, 0, 0,
            1, 1, 2, 2, 3, 0, 1, 2
    };

    private final UserRepository userRepository;
    private final ReportRepository reportRepository;
    private final TaskRepository taskRepository;
    private final Clock clock;

    public DevDemoDataSeeder(
            UserRepository userRepository,
            ReportRepository reportRepository,
            TaskRepository taskRepository,
            Clock clock
    ) {
        this.userRepository = userRepository;
        this.reportRepository = reportRepository;
        this.taskRepository = taskRepository;
        this.clock = clock;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        seedDemoData();
    }

    void seedDemoData() {
        User citizen = requireUser("citizen@test.com");
        User staff = requireUser("staff@test.com");
        User overseer = requireUser("overseer@test.com");

        Report pothole = findOrCreateReport(new SeedReport(
                POTHOLE_REPORT_ID,
                "Pothole beside the bus stop",
                "Cars swerve around it during rush hour.",
                IssueCategory.ROAD_DAMAGE,
                10.7827,
                106.6994,
                "Bus stop near Le Loi",
                "/uploads/report-before/pothole-before.jpg",
                false,
                5,
                Instant.parse("2026-06-06T08:15:00Z")
        ), citizen);
        Report curb = findOrCreateReport(new SeedReport(
                CURB_REPORT_ID,
                "Cracked curb near Le Loi crossing",
                "The curb edge is broken and difficult for wheelchairs to pass.",
                IssueCategory.ROAD_DAMAGE,
                10.7831,
                106.6991,
                "Le Loi pedestrian crossing",
                "/uploads/report-before/curb-before.jpg",
                false,
                2,
                Instant.parse("2026-06-06T09:10:00Z")
        ), citizen);
        Report streetlight = findOrCreateReport(new SeedReport(
                STREETLIGHT_REPORT_ID,
                "Broken streetlight near Nguyen Hue",
                "The light has been off for two nights.",
                IssueCategory.STREET_LIGHT,
                10.7769,
                106.7009,
                "Nguyen Hue, District 1",
                "/uploads/report-before/streetlight-before.jpg",
                false,
                3,
                Instant.parse("2026-06-07T19:20:00Z")
        ), citizen);
        Report blockedDrain = findOrCreateReport(new SeedReport(
                DRAIN_REPORT_ID,
                "Blocked drain on Pasteur Street",
                "Rainwater is pooling because leaves and trash are blocking the drain.",
                IssueCategory.DRAINAGE,
                10.7805,
                106.6956,
                "Pasteur Street near the school gate",
                "/uploads/report-before/drain-before.jpg",
                false,
                4,
                Instant.parse("2026-06-08T07:40:00Z")
        ), citizen);
        Report looseManhole = findOrCreateReport(new SeedReport(
                MANHOLE_REPORT_ID,
                "Loose manhole cover near Pasteur alley",
                "The cover shifts when motorcycles pass and could become dangerous.",
                IssueCategory.DRAINAGE,
                10.7801,
                106.6961,
                "Pasteur alley entrance",
                "/uploads/report-before/manhole-before.jpg",
                false,
                3,
                Instant.parse("2026-06-08T08:05:00Z")
        ), citizen);
        Report flooding = findOrCreateReport(new SeedReport(
                FLOODING_REPORT_ID,
                "Street flooding after short rain",
                "Water remains across the lane for hours after light rain.",
                IssueCategory.DRAINAGE,
                10.7810,
                106.6951,
                "Pasteur Street service lane",
                "/uploads/report-before/flooding-before.jpg",
                false,
                2,
                Instant.parse("2026-06-08T08:35:00Z")
        ), citizen);

        Task roadTask = findOrCreateTask(new SeedTask(
                ROAD_TASK_ID,
                "Repair road damage near Le Loi",
                "Repair the pothole and damaged curb reported by citizens.",
                IssueCategory.ROAD_DAMAGE,
                10.7829,
                106.6993,
                "Bus stop near Le Loi",
                7,
                Instant.parse("2026-06-09T09:00:00Z")
        ), staff, overseer);
        linkReports(roadTask, List.of(pothole, curb));

        Task streetlightTask = findOrCreateTask(new SeedTask(
                STREETLIGHT_TASK_ID,
                "Inspect broken streetlight",
                "Check wiring and replace the failed lamp.",
                IssueCategory.STREET_LIGHT,
                10.7769,
                106.7009,
                "Nguyen Hue, District 1",
                3,
                Instant.parse("2026-06-09T10:00:00Z")
        ), staff, overseer);
        linkReports(streetlightTask, List.of(streetlight));

        Task drainageTask = findOrCreateTask(new SeedTask(
                DRAINAGE_TASK_ID,
                "Clear Pasteur drainage cluster",
                "Clear the blocked drain, inspect the loose manhole cover, and check the flooded lane.",
                IssueCategory.DRAINAGE,
                10.7805,
                106.6956,
                "Pasteur Street drainage cluster",
                9,
                Instant.parse("2026-06-09T11:00:00Z")
        ), staff, overseer);
        linkReports(drainageTask, List.of(blockedDrain, looseManhole, flooding));

        seedAnalyticsData(
                requireUsers(ANALYTICS_CITIZEN_EMAILS),
                requireUsers(ANALYTICS_STAFF_EMAILS),
                overseer
        );
    }

    private User requireUser(String email) {
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new IllegalStateException("Seed user is missing: " + email));
    }

    private List<User> requireUsers(List<String> emails) {
        return emails.stream().map(this::requireUser).toList();
    }

    private void seedAnalyticsData(List<User> citizens, List<User> staff, User overseer) {
        if (taskRepository.existsByTitleAndCreatedByOverseer_EmailIgnoreCase(
                ANALYTICS_SEED_MARKER_TASK_TITLE,
                overseer.getEmail()
        )) {
            return;
        }

        Set<Integer> linkedReportIndexes = new HashSet<>();
        for (int taskIndex = 0; taskIndex < ANALYTICS_TASK_COUNT; taskIndex++) {
            linkedReportIndexes.add(reportIndexForTask(taskIndex));
        }

        List<Report> reports = new ArrayList<>();
        for (int reportIndex = 0; reportIndex < ANALYTICS_REPORT_COUNT; reportIndex++) {
            reports.add(findOrCreateAnalyticsReport(
                    reportIndex,
                    citizens.get(reportIndex % citizens.size()),
                    linkedReportIndexes.contains(reportIndex)
            ));
        }

        List<Task> tasks = new ArrayList<>();
        for (int taskIndex = 0; taskIndex < ANALYTICS_TASK_COUNT; taskIndex++) {
            tasks.add(findOrCreateAnalyticsTask(
                    taskIndex,
                    reports.get(reportIndexForTask(taskIndex)),
                    staff,
                    overseer
            ));
        }
        taskRepository.flush();

        for (int taskIndex = 0; taskIndex < ANALYTICS_TASK_COUNT; taskIndex++) {
            int reportIndex = reportIndexForTask(taskIndex);
            reports.set(reportIndex, finalizeAnalyticsReport(
                    tasks.get(taskIndex),
                    reports.get(reportIndex),
                    ANALYTICS_TASK_STATUSES.get(taskIndex)
            ));
        }
        reportRepository.flush();

        for (int taskIndex = 0; taskIndex < ANALYTICS_TASK_COUNT; taskIndex++) {
            Task task = tasks.get(taskIndex);
            Report report = reports.get(reportIndexForTask(taskIndex));
            boolean alreadyLinked = task.getReports().stream()
                    .anyMatch(linked -> linked.getId().equals(report.getId()));
            if (!alreadyLinked) {
                task.linkReport(report);
            }
        }
        taskRepository.flush();
    }

    private Report findOrCreateAnalyticsReport(int index, User citizen, boolean willBeLinked) {
        UUID id = analyticsReportId(index);
        return reportRepository.findById(id)
                .orElseGet(() -> {
                    AreaSeed area = analyticsArea(index);
                    IssueSeed issue = analyticsIssue(index);
                    Instant createdAt = analyticsReportCreatedAt(index);
                    Report report = new Report(
                            issue.reportTitle() + " near " + area.landmark(),
                            issue.description() + " Nearby residents asked the city to inspect the site.",
                            issue.category(),
                            area.latitude() + coordinateOffset(index, 0.0007),
                            area.longitude() + coordinateOffset(index + 2, 0.0008),
                            area.addressText(),
                            null,
                            index % 11 == 0,
                            citizen
                    );
                    report.setId(id);
                    report.updateUpvoteCount(analyticsUpvotes(index, issue.category()));
                    report.setCreatedAt(createdAt);
                    report.setUpdatedAt(createdAt);
                    if (!willBeLinked && (index % 3 == 0 || index % 11 == 0)) {
                        report.cancel();
                        report.setUpdatedAt(createdAt.plus(Duration.ofHours(18L + index % 20)));
                    }
                    return willBeLinked ? report : reportRepository.save(report);
                });
    }

    private Task findOrCreateAnalyticsTask(
            int index,
            Report report,
            List<User> staff,
            User overseer
    ) {
        UUID id = analyticsTaskId(index);
        return taskRepository.findById(id)
                .orElseGet(() -> {
                    TaskStatus targetStatus = ANALYTICS_TASK_STATUSES.get(index);
                    User assignedStaff = targetStatus == TaskStatus.NEW
                            ? null
                            : staff.get(STAFF_ASSIGNMENT_PATTERN[index]);
                    IssueSeed issue = analyticsIssue(reportIndexForTask(index));
                    AreaSeed area = analyticsArea(reportIndexForTask(index));
                    Instant createdAt = report.getCreatedAt().plus(Duration.ofHours(2L + index % 5));
                    Task task = new Task(
                            "Resolve " + issue.taskAction() + " in " + area.name(),
                            "Inspect the site, " + issue.taskAction()
                                    + ", and record the completed work for overseer review.",
                            report.getCategory(),
                            report.getLatitude(),
                            report.getLongitude(),
                            report.getAddressText(),
                            report.getPriorityScore() + index % 3,
                            assignedStaff,
                            overseer
                    );
                    task.setId(id);
                    task.setCreatedAt(createdAt);
                    applyTaskWorkflow(task, targetStatus, createdAt, index);

                    return taskRepository.save(task);
                });
    }

    private Report finalizeAnalyticsReport(Task task, Report report, TaskStatus taskStatus) {
        UUID linkedTaskId = report.getLinkedTaskId();
        if (linkedTaskId != null) {
            return report;
        }

        report.linkToTask(task.getId());
        if (taskStatus == TaskStatus.APPROVED || taskStatus == TaskStatus.CLOSED) {
            report.fix();
            report.setUpdatedAt(task.getReviewedAt());
        } else {
            report.setUpdatedAt(task.getCreatedAt());
        }
        return reportRepository.save(report);
    }

    private void applyTaskWorkflow(Task task, TaskStatus targetStatus, Instant createdAt, int index) {
        Instant startedAt = createdAt.plus(Duration.ofHours(4L + index % 4));
        Instant submittedAt = startedAt.plus(Duration.ofHours(8L + (index % 5) * 3L));
        Instant reviewedAt = submittedAt.plus(Duration.ofHours(4L + (index % 3) * 4L));
        Instant closedAt = reviewedAt.plus(Duration.ofHours(4L + (index % 4) * 2L));
        Instant updatedAt = createdAt;

        switch (targetStatus) {
            case NEW, ASSIGNED -> {
            }
            case IN_PROGRESS -> {
                task.start(startedAt);
                updatedAt = startedAt;
            }
            case DONE -> {
                task.start(startedAt);
                task.complete(submittedAt, "Work completed; site photos and notes are ready for review.");
                updatedAt = submittedAt;
            }
            case DENIED -> {
                task.start(startedAt);
                task.complete(submittedAt, "Initial repair completed and submitted for review.");
                task.deny(reviewedAt, "Follow-up is required before this work can be approved.");
                updatedAt = reviewedAt;
            }
            case APPROVED -> {
                task.start(startedAt);
                task.complete(submittedAt, "Repair completed and the area was cleaned after the work.");
                task.approve(reviewedAt);
                updatedAt = reviewedAt;
            }
            case CLOSED -> {
                task.start(startedAt);
                task.complete(submittedAt, "Repair completed and the area was reopened to the public.");
                task.approve(reviewedAt);
                task.close(closedAt);
                updatedAt = closedAt;
            }
            case CANCELLED -> {
                task.cancel();
                updatedAt = createdAt.plus(Duration.ofHours(6L + index % 8));
            }
            case PENDING_REVIEW -> throw new IllegalArgumentException(
                    "PENDING_REVIEW is not currently produced by the task workflow"
            );
        }
        task.setUpdatedAt(updatedAt);
    }

    private int reportIndexForTask(int taskIndex) {
        return taskIndex * 7 % ANALYTICS_REPORT_COUNT;
    }

    private AreaSeed analyticsArea(int reportIndex) {
        return ANALYTICS_AREAS.get((reportIndex * 5 + reportIndex / 6) % ANALYTICS_AREAS.size());
    }

    private IssueSeed analyticsIssue(int reportIndex) {
        return ANALYTICS_ISSUES.get(reportIndex % ANALYTICS_ISSUES.size());
    }

    private Instant analyticsReportCreatedAt(int index) {
        int daysAgo;
        if (index < 20) {
            daysAgo = 4 + index + index / 5;
        } else if (index < 36) {
            daysAgo = 34 + (index - 20) * 4 + index % 3;
        } else {
            daysAgo = 104 + (index - 36) * 7 + index % 4;
        }
        return clock.instant()
                .minus(Duration.ofDays(daysAgo))
                .minus(Duration.ofHours(index * 7L % 20));
    }

    private int analyticsUpvotes(int index, IssueCategory category) {
        int[] pattern = {12, 8, 6, 4, 3, 2, 1, 0, 5, 2, 7, 1};
        int categoryBoost = category == IssueCategory.ROAD_DAMAGE || category == IssueCategory.DRAINAGE
                ? 2
                : 0;
        return pattern[index % pattern.length] + categoryBoost;
    }

    private double coordinateOffset(int index, double step) {
        return (index % 5 - 2) * step;
    }

    static UUID analyticsReportId(int index) {
        return UUID.fromString("22222222-2222-2222-2222-%012d".formatted(index + 1));
    }

    static UUID analyticsTaskId(int index) {
        return UUID.fromString("44444444-4444-4444-4444-%012d".formatted(index + 1));
    }

    private Report findOrCreateReport(SeedReport seed, User citizen) {
        return reportRepository.findById(seed.id())
                .or(() -> reportRepository.findFirstByTitleAndCreatedBy_EmailIgnoreCase(
                        seed.title(),
                        citizen.getEmail()
                ))
                .orElseGet(() -> {
                    Report report = new Report(
                            seed.title(),
                            seed.description(),
                            seed.category(),
                            seed.latitude(),
                            seed.longitude(),
                            seed.addressText(),
                            seed.beforePhotoUrl(),
                            seed.anonymous(),
                            citizen
                    );
                    report.setId(seed.id());
                    report.updateUpvoteCount(seed.upvoteCount());
                    report.setCreatedAt(seed.createdAt());
                    report.setUpdatedAt(seed.createdAt());
                    return reportRepository.save(report);
                });
    }

    private Task findOrCreateTask(SeedTask seed, User staff, User overseer) {
        return taskRepository.findById(seed.id())
                .or(() -> taskRepository.findFirstByTitleAndCreatedByOverseer_EmailIgnoreCase(
                        seed.title(),
                        overseer.getEmail()
                ))
                .orElseGet(() -> {
                    Task task = new Task(
                            seed.title(),
                            seed.description(),
                            seed.category(),
                            seed.latitude(),
                            seed.longitude(),
                            seed.addressText(),
                            seed.priorityScore(),
                            staff,
                            overseer
                    );
                    task.setId(seed.id());
                    task.setCreatedAt(seed.createdAt());
                    task.setUpdatedAt(seed.createdAt());
                    return taskRepository.save(task);
                });
    }

    private void linkReports(Task task, List<Report> reports) {
        for (Report report : reports) {
            if (report.getLinkedTaskId() != null && !report.getLinkedTaskId().equals(task.getId())) {
                continue;
            }
            task.linkReport(report);
            report.linkToTask(task.getId());
        }
        taskRepository.save(task);
        reportRepository.saveAll(reports);
    }

    private record AreaSeed(
            String name,
            String addressText,
            String landmark,
            double latitude,
            double longitude
    ) {
    }

    private record IssueSeed(
            IssueCategory category,
            String reportTitle,
            String taskAction,
            String description
    ) {
    }

    private record SeedReport(
            UUID id,
            String title,
            String description,
            IssueCategory category,
            double latitude,
            double longitude,
            String addressText,
            String beforePhotoUrl,
            boolean anonymous,
            int upvoteCount,
            Instant createdAt
    ) {
    }

    private record SeedTask(
            UUID id,
            String title,
            String description,
            IssueCategory category,
            double latitude,
            double longitude,
            String addressText,
            int priorityScore,
            Instant createdAt
    ) {
    }
}
