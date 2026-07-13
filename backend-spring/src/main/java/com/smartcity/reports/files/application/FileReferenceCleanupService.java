package com.smartcity.reports.files.application;

import com.smartcity.reports.report.persistence.ReportRepository;
import com.smartcity.reports.task.persistence.TaskRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class FileReferenceCleanupService {

    private final FileStorageService fileStorageService;
    private final ReportRepository reportRepository;
    private final TaskRepository taskRepository;

    public FileReferenceCleanupService(
            FileStorageService fileStorageService,
            ReportRepository reportRepository,
            TaskRepository taskRepository
    ) {
        this.fileStorageService = fileStorageService;
        this.reportRepository = reportRepository;
        this.taskRepository = taskRepository;
    }

    public void deleteIfUnused(
            String fileUrl,
            UUID excludedReportId,
            UUID excludedTaskId
    ) {
        if (fileUrl == null || fileUrl.isBlank()) {
            return;
        }

        boolean usedByReport = excludedReportId == null
                ? reportRepository.existsByBeforePhotoUrl(fileUrl)
                : reportRepository.existsByBeforePhotoUrlAndIdNot(fileUrl, excludedReportId);
        boolean usedByTaskBefore = excludedTaskId == null
                ? taskRepository.existsByBeforePhotoUrl(fileUrl)
                : taskRepository.existsByBeforePhotoUrlAndIdNot(fileUrl, excludedTaskId);
        boolean usedByTaskAfter = excludedTaskId == null
                ? taskRepository.existsByAfterPhotoUrl(fileUrl)
                : taskRepository.existsByAfterPhotoUrlAndIdNot(fileUrl, excludedTaskId);

        if (!usedByReport && !usedByTaskBefore && !usedByTaskAfter) {
            fileStorageService.delete(fileUrl);
        }
    }
}
