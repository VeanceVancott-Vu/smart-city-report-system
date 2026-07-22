package com.smartcity.reports.task.persistence;

import com.smartcity.reports.task.domain.Task;
import com.smartcity.reports.task.domain.TaskStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface TaskRepository extends JpaRepository<Task, UUID> {


    List<Task> findByAssignedStaff_IdOrderByCreatedAtDesc(UUID assignedStaffId);

    @Query("""
            SELECT task.status AS status, COUNT(task) AS count
            FROM Task task
            WHERE task.assignedStaff.id = :staffId
            GROUP BY task.status
            """)
    List<TaskStatusCount> countByAssignedStaffGroupedByStatus(@Param("staffId") UUID staffId);

    @Query("""
            SELECT CASE WHEN COUNT(task) > 0 THEN true ELSE false END
            FROM Task task
            JOIN task.reports report
            WHERE task.assignedStaff.id = :staffId
              AND report.createdBy.id = :citizenId
            """)
    boolean existsAssignmentForCitizenReport(
            @Param("staffId") UUID staffId,
            @Param("citizenId") UUID citizenId
    );

    interface TaskStatusCount {
        TaskStatus getStatus();

        long getCount();
    }
}
