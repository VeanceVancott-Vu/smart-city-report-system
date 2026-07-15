package com.smartcity.reports.report.domain;

import com.smartcity.reports.issue.IssueCategory;
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
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import org.locationtech.jts.geom.Point;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "reports")
public class Report {

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
    private ReportStatus status;

    @Column(nullable = false)
    private double latitude;

    @Column(nullable = false)
    private double longitude;

    @Column(name = "address_text", length = 255)
    private String addressText;

    @Column(name = "before_photo_url", length = 2048)
    private String beforePhotoUrl;

    @Column(name = "after_photo_url", length = 2048)
    private String afterPhotoUrl;

    @Column(name = "is_anonymous", nullable = false)
    private boolean anonymous;

    @Column(name = "upvote_count", nullable = false)
    private int upvoteCount;

    @Column(name = "priority_score", nullable = false)
    private int priorityScore;

    @Column(name = "linked_task_id")
    private UUID linkedTaskId;

    @Column(
            name = "location",
            insertable = false,
            updatable = false,
            columnDefinition = "geometry(Point,4326)"
    )
    private Point location;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "created_by_user_id", nullable = false)
    private User createdBy;

    protected Report() {
    }

    public Report(
            String title,
            String description,
            IssueCategory category,
            double latitude,
            double longitude,
            String addressText,
            String beforePhotoUrl,
            boolean anonymous,
            User createdBy
    ) {
        this.title = title;
        this.description = description;
        this.category = category;
        this.status = ReportStatus.SUBMITTED;
        this.latitude = latitude;
        this.longitude = longitude;
        this.addressText = addressText;
        this.beforePhotoUrl = beforePhotoUrl;
        this.anonymous = anonymous;
        this.upvoteCount = 0;
        this.priorityScore = 0;
        this.createdBy = createdBy;
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
            status = ReportStatus.SUBMITTED;
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
            String beforePhotoUrl
    ) {
        this.title = title;
        this.description = description;
        this.category = category;
        this.latitude = latitude;
        this.longitude = longitude;
        this.addressText = addressText;
        this.beforePhotoUrl = beforePhotoUrl;
    }

    public void updateAfterPhoto(String afterPhotoUrl) {
        this.afterPhotoUrl = afterPhotoUrl;
    }

    public void cancel() {
        status = ReportStatus.CANCELLED;
    }

    public void markInProgress() {
        if (status == ReportStatus.SUBMITTED) {
            status = ReportStatus.IN_PROGRESS;
        }
    }

    public void reopen() {
        if (status == ReportStatus.IN_PROGRESS) {
            status = ReportStatus.SUBMITTED;
        }
    }

    public void fix() {
        status = ReportStatus.FIXED;
    }

    public void linkToTask(UUID taskId) {
        linkedTaskId = taskId;
        markInProgress();
    }

    public void unlinkFromTask(UUID taskId) {
        if (linkedTaskId != null && linkedTaskId.equals(taskId)) {
            linkedTaskId = null;
            reopen();
        }
    }

    public void updateUpvoteCount(int upvoteCount) {
        int safeUpvoteCount = Math.max(0, upvoteCount);
        this.upvoteCount = safeUpvoteCount;
        this.priorityScore = safeUpvoteCount;
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

    public ReportStatus getStatus() {
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

    public String getBeforePhotoUrl() {
        return beforePhotoUrl;
    }

    public String getAfterPhotoUrl() {
        return afterPhotoUrl;
    }

    public boolean isAnonymous() {
        return anonymous;
    }

    public int getUpvoteCount() {
        return upvoteCount;
    }

    public int getPriorityScore() {
        return priorityScore;
    }

    public UUID getLinkedTaskId() {
        return linkedTaskId;
    }

    public Point getLocation() {
        return location;
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

    public User getCreatedBy() {
        return createdBy;
    }
}
