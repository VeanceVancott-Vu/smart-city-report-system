package com.smartcity.reports.report.persistence;

import com.smartcity.reports.report.domain.ReportUpvote;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface ReportUpvoteRepository extends JpaRepository<ReportUpvote, UUID> {

    boolean existsByReport_IdAndUser_Id(UUID reportId, UUID userId);

    long countByReport_Id(UUID reportId);

    long deleteByReport_IdAndUser_Id(UUID reportId, UUID userId);

    @Modifying
    @Query(value = """
            INSERT INTO report_upvotes (report_id, user_id)
            VALUES (:reportId, :userId)
            ON CONFLICT (report_id, user_id) DO NOTHING
            """, nativeQuery = true)
    int insertIfAbsent(
            @Param("reportId") UUID reportId,
            @Param("userId") UUID userId
    );
}