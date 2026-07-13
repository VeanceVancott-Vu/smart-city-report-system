package com.smartcity.reports.task.persistence;

import com.smartcity.reports.task.domain.Task;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TaskRepository extends JpaRepository<Task, UUID> {

    boolean existsByBeforePhotoUrl(String beforePhotoUrl);

    boolean existsByBeforePhotoUrlAndIdNot(String beforePhotoUrl, UUID id);

    boolean existsByAfterPhotoUrl(String afterPhotoUrl);

    boolean existsByAfterPhotoUrlAndIdNot(String afterPhotoUrl, UUID id);

    List<Task> findByAssignedStaff_IdOrderByCreatedAtDesc(UUID assignedStaffId);
}