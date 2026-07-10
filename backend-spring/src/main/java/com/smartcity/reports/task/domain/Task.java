package com.smartcity.reports.task.domain;

import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.user.domain.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import org.locationtech.jts.geom.Point;

import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "tasks")
public class Task {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false, length = 120)
    private String title;

    @Column(nullable = false, columnDefinition = "text")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private IssueCategory category;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private TaskStatus status;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(name = "address_text", length = 255)
    private String addressText;

    @Column(name = "priority_score", nullable = false)
    private int priorityScore;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_staff_id")
    private User assignedStaff;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by_overseer_id")
    private User createdByOverseer;

    @Column(name = "before_photo_url", length = 2048)
    private String beforePhotoUrl;

    @Column(name = "after_photo_url", length = 2048)
    private String afterPhotoUrl;

    @Column(name = "staff_note", columnDefinition = "text")
    private String staffNote;

    @Column(name = "ai_confidence_score")
    private Double aiConfidenceScore;

    @Column(name = "ai_decision", length = 120)
    private String aiDecision;

    @Column(name = "started_at")
    private Instant startedAt;

    @Column(name = "submitted_at")
    private Instant submittedAt;

    @Column(name = "reviewed_at")
    private Instant reviewedAt;

    @Column(name = "closed_at")
    private Instant closedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(
            name = "location",
            insertable = false,
            updatable = false,
            columnDefinition = "geometry(Point,4326)"
    )
    private Point location;

    @ManyToMany
    @JoinTable(
            name = "task_reports",
            joinColumns = @JoinColumn(name = "task_id"),
            inverseJoinColumns = @JoinColumn(name = "report_id")
    )
    private Set<Report> reports = new LinkedHashSet<>();

    protected Task() {
    }

    public Task(
            String title,
            String description,
            IssueCategory category,
            double latitude,
            double longitude,
            String addressText,
            int priorityScore,
            User assignedStaff,
            User createdByOverseer,
            String beforePhotoUrl
    ) {
        this.title = title;
        this.description = description;
        this.category = category;
        this.latitude = latitude;
        this.longitude = longitude;
        this.addressText = addressText;
        this.priorityScore = Math.max(0, priorityScore);
        this.assignedStaff = assignedStaff;
        this.createdByOverseer = createdByOverseer;
        this.beforePhotoUrl = beforePhotoUrl;
        this.status = assignedStaff == null ? TaskStatus.NEW : TaskStatus.ASSIGNED;
    }

    @PrePersist
    void prePersist() {
        Instant now = Instant.now();
        if (createdAt == null) {
            createdAt = now;
        }
        if (updatedAt == null) {
            updatedAt = now;
        }
        if (status == null) {
            status = assignedStaff == null ? TaskStatus.NEW : TaskStatus.ASSIGNED;
        }
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }

    public void updateDetails(
            String title,
            String description,
            IssueCategory category,
            double latitude,
            double longitude,
            String addressText,
            int priorityScore,
            String beforePhotoUrl,
            String afterPhotoUrl,
            String staffNote
    ) {
        this.title = title;
        this.description = description;
        this.category = category;
        this.latitude = latitude;
        this.longitude = longitude;
        this.addressText = addressText;
        this.priorityScore = Math.max(0, priorityScore);
        this.beforePhotoUrl = beforePhotoUrl;
        this.afterPhotoUrl = afterPhotoUrl;
        this.staffNote = staffNote;
    }

    public void assign(User staff) {
        assignedStaff = staff;
        status = TaskStatus.ASSIGNED;
    }

    public void start(Instant now) {
        status = TaskStatus.IN_PROGRESS;
        startedAt = now;
    }

    public void complete(Instant now, String afterPhotoUrl, String staffNote) {
        status = TaskStatus.DONE;
        submittedAt = now;
        this.afterPhotoUrl = afterPhotoUrl;
        if (staffNote != null) {
            this.staffNote = staffNote;
        }
        aiConfidenceScore = null;
        aiDecision = null;
    }

    public void approve(Instant now) {
        status = TaskStatus.APPROVED;
        reviewedAt = now;
    }

    public void close(Instant now) {
        status = TaskStatus.CLOSED;
        closedAt = now;
    }

    public void cancel() {
        status = TaskStatus.CANCELLED;
    }

    public void linkReport(Report report) {
        reports.add(report);
    }

    public void unlinkReport(Report report) {
        reports.remove(report);
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public IssueCategory getCategory() {
        return category;
    }

    public TaskStatus getStatus() {
        return status;
    }

    public double getLatitude() {
        return latitude;
    }

    public double getLongitude() {
        return longitude;
    }

    public String getAddressText() {
        return addressText;
    }

    public int getPriorityScore() {
        return priorityScore;
    }

    public User getAssignedStaff() {
        return assignedStaff;
    }

    public User getCreatedByOverseer() {
        return createdByOverseer;
    }

    public String getBeforePhotoUrl() {
        return beforePhotoUrl;
    }

    public String getAfterPhotoUrl() {
        return afterPhotoUrl;
    }

    public String getStaffNote() {
        return staffNote;
    }

    public Double getAiConfidenceScore() {
        return aiConfidenceScore;
    }

    public String getAiDecision() {
        return aiDecision;
    }

    public Instant getStartedAt() {
        return startedAt;
    }

    public Instant getSubmittedAt() {
        return submittedAt;
    }

    public Instant getReviewedAt() {
        return reviewedAt;
    }

    public Instant getClosedAt() {
        return closedAt;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Point getLocation() {
        return location;
    }

    public Set<Report> getReports() {
        return reports;
    }
}
