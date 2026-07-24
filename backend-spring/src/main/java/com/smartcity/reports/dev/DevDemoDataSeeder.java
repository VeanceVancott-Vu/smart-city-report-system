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

    static final int ANALYTICS_REPORT_COUNT = 96;
    static final int ANALYTICS_TASK_COUNT = 64;

    static final UUID POTHOLE_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000003");
    static final UUID STREETLIGHT_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000004");
    static final UUID CURB_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000005");
    static final UUID DRAIN_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000006");
    static final UUID MANHOLE_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000007");
    static final UUID FLOODING_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000008");
    static final UUID VKU_ROAD_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000009");
    static final UUID FPT_LIGHT_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000010");
    static final UUID VKU_DRAIN_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000011");
    static final UUID FPT_TREE_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000012");

    static final UUID ROAD_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000001");
    static final UUID STREETLIGHT_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000002");
    static final UUID DRAINAGE_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000003");
    static final UUID VKU_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000004");

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
            "Resolve repair the damaged road surface in Hai Chau District";
    private static final List<AreaSeed> ANALYTICS_AREAS = List.of(
            new AreaSeed(
                    "Hai Chau District",
                    "Bach Dang Street, Hai Chau 1 Ward, Hai Chau District",
                    "Han Market riverfront",
                    16.0678,
                    108.2241
            ),
            new AreaSeed(
                    "Son Tra District",
                    "Vo Nguyen Giap Street, Phuoc My Ward, Son Tra District",
                    "My Khe Beach",
                    16.0644,
                    108.2461
            ),
            new AreaSeed(
                    "Thanh Khe District",
                    "Dien Bien Phu Street, Chinh Gian Ward, Thanh Khe District",
                    "Thanh Khe railway station",
                    16.0666,
                    108.1907
            ),
            new AreaSeed(
                    "Ngu Hanh Son District",
                    "Ngu Hanh Son Street, My An Ward, Ngu Hanh Son District",
                    "Bac My An Market",
                    16.0474,
                    108.2406
            ),
            new AreaSeed(
                    "VKU - FPT Complex",
                    "Nam Ky Khoi Nghia Street, Hoa Hai Ward, Ngu Hanh Son District",
                    "VKU Campus & FPT Complex",
                    15.9753,
                    108.2532
            ),
            new AreaSeed(
                    "FPT City Urban Area",
                    "Tran Dai Nghia Street, Hoa Hai Ward, Ngu Hanh Son District",
                    "FPT Plaza & Software Park",
                    15.9725,
                    108.2580
            ),
            new AreaSeed(
                    "Cam Le District",
                    "Cach Mang Thang Tam Street, Khue Trung Ward, Cam Le District",
                    "Hoa Cam junction",
                    16.0145,
                    108.2143
            ),
            new AreaSeed(
                    "Lien Chieu District",
                    "Nguyen Luong Bang Street, Hoa Khanh Bac Ward, Lien Chieu District",
                    "Hoa Khanh market",
                    16.0728,
                    108.1508
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
            TaskStatus.CANCELLED,
            TaskStatus.NEW,
            TaskStatus.APPROVED,
            TaskStatus.ASSIGNED,
            TaskStatus.IN_PROGRESS,
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
            1, 1, 2, 2, 3, 0, 1, 2,
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
                16.0679,
                108.2208,
                "Bach Dang bus stop near Han Market",
                "/uploads/report-before/pothole-before.jpg",
                false,
                5,
                Instant.parse("2026-06-06T08:15:00Z")
        ), citizen);
        Report curb = findOrCreateReport(new SeedReport(
                CURB_REPORT_ID,
                "Cracked curb near Bach Dang crossing",
                "The curb edge is broken and difficult for wheelchairs to pass.",
                IssueCategory.ROAD_DAMAGE,
                16.0683,
                108.2211,
                "Bach Dang pedestrian crossing near Han Market",
                "/uploads/report-before/curb-before.jpg",
                false,
                2,
                Instant.parse("2026-06-06T09:10:00Z")
        ), citizen);
        Report streetlight = findOrCreateReport(new SeedReport(
                STREETLIGHT_REPORT_ID,
                "Broken streetlight near Dragon Bridge",
                "The light has been off for two nights.",
                IssueCategory.STREET_LIGHT,
                16.0612,
                108.2276,
                "Dragon Bridge, Hai Chau District",
                "/uploads/report-before/streetlight-before.jpg",
                false,
                3,
                Instant.parse("2026-06-07T19:20:00Z")
        ), citizen);
        Report blockedDrain = findOrCreateReport(new SeedReport(
                DRAIN_REPORT_ID,
                "Blocked drain on Nguyen Van Linh Street",
                "Rainwater is pooling because leaves and trash are blocking the drain.",
                IssueCategory.DRAINAGE,
                16.0595,
                108.2098,
                "Nguyen Van Linh Street near the school gate",
                "/uploads/report-before/drain-before.jpg",
                false,
                4,
                Instant.parse("2026-06-08T07:40:00Z")
        ), citizen);
        Report looseManhole = findOrCreateReport(new SeedReport(
                MANHOLE_REPORT_ID,
                "Loose manhole cover near Nguyen Van Linh alley",
                "The cover shifts when motorcycles pass and could become dangerous.",
                IssueCategory.DRAINAGE,
                16.0591,
                108.2103,
                "Nguyen Van Linh alley entrance",
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
                16.0600,
                108.2093,
                "Nguyen Van Linh Street service lane",
                "/uploads/report-before/flooding-before.jpg",
                false,
                2,
                Instant.parse("2026-06-08T08:35:00Z")
        ), citizen);

        Task roadTask = findOrCreateTask(new SeedTask(
                ROAD_TASK_ID,
                "Repair road damage near Bach Dang",
                "Repair the pothole and damaged curb reported by citizens.",
                IssueCategory.ROAD_DAMAGE,
                16.0681,
                108.2209,
                "Bach Dang bus stop near Han Market",
                7,
                Instant.parse("2026-06-09T09:00:00Z")
        ), staff, overseer);
        linkReports(roadTask, List.of(pothole, curb));

        Task streetlightTask = findOrCreateTask(new SeedTask(
                STREETLIGHT_TASK_ID,
                "Inspect broken streetlight",
                "Check wiring and replace the failed lamp.",
                IssueCategory.STREET_LIGHT,
                16.0612,
                108.2276,
                "Dragon Bridge, Hai Chau District",
                3,
                Instant.parse("2026-06-09T10:00:00Z")
        ), staff, overseer);
        linkReports(streetlightTask, List.of(streetlight));

        Task drainageTask = findOrCreateTask(new SeedTask(
                DRAINAGE_TASK_ID,
                "Clear Nguyen Van Linh drainage cluster",
                "Clear the blocked drain, inspect the loose manhole cover, and check the flooded lane.",
                IssueCategory.DRAINAGE,
                16.0595,
                108.2098,
                "Nguyen Van Linh Street drainage cluster",
                9,
                Instant.parse("2026-06-09T11:00:00Z")
        ), staff, overseer);
        linkReports(drainageTask, List.of(blockedDrain, looseManhole, flooding));

        Report vkuRoad = findOrCreateReport(new SeedReport(
                VKU_ROAD_REPORT_ID,
                "Sunken asphalt near VKU main entrance",
                "Heavy vehicle traffic on Nam Ky Khoi Nghia has created deep ruts in front of VKU gate.",
                IssueCategory.ROAD_DAMAGE,
                15.9753,
                108.2532,
                "Nam Ky Khoi Nghia St, VKU Campus, Hoa Hai Ward",
                "/uploads/report-before/pothole-before.jpg",
                false,
                8,
                Instant.parse("2026-06-10T08:00:00Z")
        ), citizen);
        Report fptLight = findOrCreateReport(new SeedReport(
                FPT_LIGHT_REPORT_ID,
                "Dark streetlights along FPT Complex avenue",
                "Multiple streetlight lamps are dark near FPT Complex entrance and FPT Plaza.",
                IssueCategory.STREET_LIGHT,
                15.9725,
                108.2580,
                "Tran Dai Nghia St, FPT Complex, Hoa Hai Ward",
                "/uploads/report-before/streetlight-before.jpg",
                false,
                6,
                Instant.parse("2026-06-11T19:30:00Z")
        ), citizen);
        Report vkuDrain = findOrCreateReport(new SeedReport(
                VKU_DRAIN_REPORT_ID,
                "Clogged stormwater inlet near VKU dormitories",
                "Trash and leaves are blocking the storm drain inlet causing localized pooling.",
                IssueCategory.DRAINAGE,
                15.9768,
                108.2515,
                "Tran Dai Nghia St, near VKU Dormitories, Hoa Hai Ward",
                "/uploads/report-before/drain-before.jpg",
                false,
                5,
                Instant.parse("2026-06-12T07:15:00Z")
        ), citizen);
        Report fptTree = findOrCreateReport(new SeedReport(
                FPT_TREE_REPORT_ID,
                "Tree branches obstructing sign at FPT City roundabout",
                "Low tree branches cover the directional traffic sign at FPT City main roundabout.",
                IssueCategory.TREE_BLOCKAGE,
                15.9710,
                108.2595,
                "FPT City main roundabout, Hoa Hai Ward",
                "/uploads/report-before/curb-before.jpg",
                false,
                4,
                Instant.parse("2026-06-12T10:45:00Z")
        ), citizen);

        Task vkuTask = findOrCreateTask(new SeedTask(
                VKU_TASK_ID,
                "Maintain infrastructure around VKU - FPT Complex",
                "Resurface asphalt at VKU entrance, clear storm inlet, and inspect FPT streetlights.",
                IssueCategory.ROAD_DAMAGE,
                15.9753,
                108.2532,
                "Nam Ky Khoi Nghia St, VKU - FPT Complex area",
                12,
                Instant.parse("2026-06-13T09:00:00Z")
        ), staff, overseer);
        linkReports(vkuTask, List.of(vkuRoad, fptLight, vkuDrain, fptTree));

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
                    ANALYTICS_TASK_STATUSES.get(taskIndex % ANALYTICS_TASK_STATUSES.size())
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
        AreaSeed area = analyticsArea(index);
        IssueSeed issue = analyticsIssue(index);
        String title = issue.reportTitle() + " near " + area.landmark();
        String description = issue.description()
                + " Nearby residents asked the city to inspect the site.";
        double latitude = area.latitude() + coordinateOffset(index, 0.0007);
        double longitude = area.longitude() + coordinateOffset(index + 2, 0.0008);
        return reportRepository.findById(id)
                .map(report -> {
                    report.updateDetails(
                            title,
                            description,
                            issue.category(),
                            latitude,
                            longitude,
                            area.addressText(),
                            report.getBeforePhotoUrl()
                    );
                    return reportRepository.save(report);
                })
                .orElseGet(() -> {
                    Instant createdAt = analyticsReportCreatedAt(index);
                    Report report = new Report(
                            title,
                            description,
                            issue.category(),
                            latitude,
                            longitude,
                            area.addressText(),
                            null,
                            index % 11 == 0,
                            citizen
                    );
                    report.setId(id);
                    report.updateUpvoteCount(analyticsUpvotes(index, issue.category()));
                    report.updatePriorityScore(report.getUpvoteCount());
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
        IssueSeed issue = analyticsIssue(reportIndexForTask(index));
        AreaSeed area = analyticsArea(reportIndexForTask(index));
        String title = "Resolve " + issue.taskAction() + " in " + area.name();
        String description = "Inspect the site, " + issue.taskAction()
                + ", and record the completed work for overseer review.";
        return taskRepository.findById(id)
                .map(task -> {
                    task.updateDetails(
                            title,
                            description,
                            report.getCategory(),
                            report.getLatitude(),
                            report.getLongitude(),
                            report.getAddressText(),
                            task.getPriorityScore(),
                            task.getStaffNote()
                    );
                    return taskRepository.save(task);
                })
                .orElseGet(() -> {
                    TaskStatus targetStatus = ANALYTICS_TASK_STATUSES.get(index % ANALYTICS_TASK_STATUSES.size());
                    User assignedStaff = targetStatus == TaskStatus.NEW
                            ? null
                            : staff.get(STAFF_ASSIGNMENT_PATTERN[index % STAFF_ASSIGNMENT_PATTERN.length]);
                    Instant createdAt = report.getCreatedAt().plus(Duration.ofHours(2L + index % 5));
                    Task task = new Task(
                            title,
                            description,
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
                .map(report -> {
                    report.updateDetails(
                            seed.title(),
                            seed.description(),
                            seed.category(),
                            seed.latitude(),
                            seed.longitude(),
                            seed.addressText(),
                            seed.beforePhotoUrl()
                    );
                    return reportRepository.save(report);
                })
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
                    report.updatePriorityScore(seed.upvoteCount());
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
                .map(task -> {
                    task.updateDetails(
                            seed.title(),
                            seed.description(),
                            seed.category(),
                            seed.latitude(),
                            seed.longitude(),
                            seed.addressText(),
                            seed.priorityScore(),
                            task.getStaffNote()
                    );
                    return taskRepository.save(task);
                })
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
