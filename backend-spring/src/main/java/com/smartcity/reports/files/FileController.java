package com.smartcity.reports.files;

import com.smartcity.reports.user.User;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/files")
public class FileController {

    private final FileStorageService fileStorageService;

    public FileController(FileStorageService fileStorageService) {
        this.fileStorageService = fileStorageService;
    }

    @PostMapping(value = "/report-before", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public FileUploadResponse uploadReportBefore(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal User currentUser
    ) {
        return fileStorageService.uploadReportBefore(file, currentUser);
    }

    @PostMapping(value = "/task-after", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public FileUploadResponse uploadTaskAfter(
            @RequestParam("file") MultipartFile file,
            @AuthenticationPrincipal User currentUser
    ) {
        return fileStorageService.uploadTaskAfter(file, currentUser);
    }
}
