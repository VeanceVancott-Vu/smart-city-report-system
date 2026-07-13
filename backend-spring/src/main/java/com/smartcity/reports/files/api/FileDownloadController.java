package com.smartcity.reports.files.api;

import com.smartcity.reports.files.application.FileDownload;
import com.smartcity.reports.files.application.FileStorageService;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.TimeUnit;

@RestController
public class FileDownloadController {

    private final FileStorageService fileStorageService;

    public FileDownloadController(FileStorageService fileStorageService) {
        this.fileStorageService = fileStorageService;
    }

    @GetMapping("/uploads/{directory}/{filename:.+}")
    public ResponseEntity<Resource> download(
            @PathVariable String directory,
            @PathVariable String filename
    ) {
        FileDownload download = fileStorageService.load("/uploads/" + directory + "/" + filename);
        return ResponseEntity.ok()
                .contentType(download.contentType())
                .contentLength(download.contentLength())
                .cacheControl(CacheControl.maxAge(1, TimeUnit.HOURS).cachePrivate())
                .body(download.resource());
    }
}
