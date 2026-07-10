package com.smartcity.reports.dev;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.persistence.TaskRepository;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.persistence.UserRepository;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
@Profile({"local", "dev"})
@Order(2)
public class DevDemoDataSeeder implements ApplicationRunner {

    static final UUID POTHOLE_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000003");
    static final UUID STREETLIGHT_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000004");
    static final UUID CURB_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000005");
    static final UUID DRAIN_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000006");
    static final UUID MANHOLE_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000007");
    static final UUID FLOODING_REPORT_ID = UUID.fromString("11111111-1111-1111-1111-000000000008");

    static final UUID ROAD_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000001");
    static final UUID STREETLIGHT_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000002");
    static final UUID DRAINAGE_TASK_ID = UUID.fromString("33333333-3333-3333-3333-000000000003");

    private final UserRepository userRepository;
    private final ReportRepository reportRepository;
    private final TaskRepository taskRepository;

    public DevDemoDataSeeder(
            UserRepository userRepository,
            ReportRepository reportRepository,
            TaskRepository taskRepository
    ) {
        this.userRepository = userRepository;
        this.reportRepository = reportRepository;
        this.taskRepository = taskRepository;
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
                "/uploads/report-before/pothole-before.jpg",
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
                "/uploads/report-before/streetlight-before.jpg",
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
                "/uploads/report-before/drain-before.jpg",
                Instant.parse("2026-06-09T11:00:00Z")
        ), staff, overseer);
        linkReports(drainageTask, List.of(blockedDrain, looseManhole, flooding));
    }

    private User requireUser(String email) {
        return userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new IllegalStateException("Seed user is missing: " + email));
    }

    private Report findOrCreateReport(SeedReport seed, User citizen) {
        return reportRepository.findById(seed.id())
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
                            overseer,
                            seed.beforePhotoUrl()
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
            String beforePhotoUrl,
            Instant createdAt
    ) {
    }
}