package com.smartcity.reports.files.application;

import com.smartcity.reports.report.persistence.ReportRepository;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class FileReferenceCleanupService {

    private final FileStorageService fileStorageService;
    private final ReportRepository reportRepository;

    public FileReferenceCleanupService(
            FileStorageService fileStorageService,
            ReportRepository reportRepository
    ) {
        this.fileStorageService = fileStorageService;
        this.reportRepository = reportRepository;
    }

    public void deleteIfUnused(
            String fileUrl,
            UUID excludedReportId
    ) {
        if (fileUrl == null || fileUrl.isBlank()) {
            return;
        }

        boolean usedByReportBefore = excludedReportId == null
                ? reportRepository.existsByBeforePhotoUrl(fileUrl)
                : reportRepository.existsByBeforePhotoUrlAndIdNot(fileUrl, excludedReportId);
        boolean usedByReportAfter = excludedReportId == null
                ? reportRepository.existsByAfterPhotoUrl(fileUrl)
                : reportRepository.existsByAfterPhotoUrlAndIdNot(fileUrl, excludedReportId);

        if (!usedByReportBefore && !usedByReportAfter) {
            fileStorageService.delete(fileUrl);
        }
    }
}
