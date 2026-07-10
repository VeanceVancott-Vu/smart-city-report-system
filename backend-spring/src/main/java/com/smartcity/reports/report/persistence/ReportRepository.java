package com.smartcity.reports.report.persistence;

import com.smartcity.reports.report.domain.Report;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ReportRepository extends JpaRepository<Report, UUID>, JpaSpecificationExecutor<Report> {

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
}