package com.smartcity.reports.report.persistence;

import com.smartcity.reports.report.domain.Report;
import com.smartcity.reports.report.domain.ReportStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ReportRepository extends JpaRepository<Report, UUID>, JpaSpecificationExecutor<Report> {

    boolean existsByBeforePhotoUrl(String beforePhotoUrl);

    boolean existsByBeforePhotoUrlAndIdNot(String beforePhotoUrl, UUID id);

    boolean existsByAfterPhotoUrl(String afterPhotoUrl);

    boolean existsByAfterPhotoUrlAndIdNot(String afterPhotoUrl, UUID id);

    Optional<Report> findFirstByTitleAndCreatedBy_EmailIgnoreCase(String title, String creatorEmail);

    @Query("""
            SELECT report.status AS status, COUNT(report) AS count
            FROM Report report
            WHERE report.createdBy.id = :creatorId
            GROUP BY report.status
            """)
    List<ReportStatusCount> countByCreatorGroupedByStatus(@Param("creatorId") UUID creatorId);

    @Query(value = """
            SELECT *
            FROM reports
            WHERE status = 'SUBMITTED'
              AND ST_Intersects(
                location,
                ST_MakeEnvelope(:minLng, :minLat, :maxLng, :maxLat, 4326)
            )
            ORDER BY priority_score DESC, upvote_count DESC, created_at DESC
            """, nativeQuery = true)
    List<Report> findSubmittedWithinBounds(
            @Param("minLat") double minLat,
            @Param("minLng") double minLng,
            @Param("maxLat") double maxLat,
            @Param("maxLng") double maxLng
    );

    @Query(value = """
            SELECT *
            FROM reports
            WHERE ST_Intersects(
                location,
                ST_MakeEnvelope(:minLng, :minLat, :maxLng, :maxLat, 4326)
            )
            ORDER BY priority_score DESC, upvote_count DESC, created_at DESC
            """, nativeQuery = true)
    List<Report> findWithinBounds(
            @Param("minLat") double minLat,
            @Param("minLng") double minLng,
            @Param("maxLat") double maxLat,
            @Param("maxLng") double maxLng
    );

    interface ReportStatusCount {
        ReportStatus getStatus();

        long getCount();
    }
}
