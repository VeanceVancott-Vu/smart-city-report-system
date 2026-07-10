package com.smartcity.reports.files.application;

import com.smartcity.reports.files.api.FileUploadResponse;
import com.smartcity.reports.files.config.FileStorageProperties;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.util.unit.DataSize;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class FileStorageServiceTest {

    @TempDir
    private Path uploadDir;

    @Test
    void citizenCanUploadReportBeforePhoto() {
        FileStorageService service = service(DataSize.ofMegabytes(1));
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "before.jpg",
                "image/jpeg",
                jpegBytes()
        );

        FileUploadResponse response = service.uploadReportBefore(file, user(UserRole.CITIZEN));

        assertThat(response.fileUrl()).startsWith("/uploads/report-before/");
        assertThat(Files.exists(uploadDir.resolve(response.fileUrl().replace("/uploads/", "")))).isTrue();
    }

    @Test
    void staffCanUploadTaskAfterPhoto() {
        FileStorageService service = service(DataSize.ofMegabytes(1));
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "after.webp",
                "image/webp",
                webpBytes()
        );

        FileUploadResponse response = service.uploadTaskAfter(file, user(UserRole.STAFF));

        assertThat(response.fileUrl()).startsWith("/uploads/task-after/");
        assertThat(response.fileUrl()).endsWith(".webp");
    }

    @Test
    void staffCannotUploadReportBeforePhoto() {
        FileStorageService service = service(DataSize.ofMegabytes(1));
        MockMultipartFile file = new MockMultipartFile("file", "before.jpg", "image/jpeg", jpegBytes());

        assertThatThrownBy(() -> service.uploadReportBefore(file, user(UserRole.STAFF)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only citizens can upload report before photos");
    }

    @Test
    void citizenCannotUploadTaskAfterPhoto() {
        FileStorageService service = service(DataSize.ofMegabytes(1));
        MockMultipartFile file = new MockMultipartFile("file", "after.png", "image/png", pngBytes());

        assertThatThrownBy(() -> service.uploadTaskAfter(file, user(UserRole.CITIZEN)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessage("Only staff can upload task after photos");
    }

    @Test
    void rejectsNonImageExtension() {
        FileStorageService service = service(DataSize.ofMegabytes(1));
        MockMultipartFile file = new MockMultipartFile("file", "notes.txt", "text/plain", "hello".getBytes());

        assertThatThrownBy(() -> service.uploadReportBefore(file, user(UserRole.CITIZEN)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only jpg, jpeg, png, and webp image files are allowed");
    }

    @Test
    void rejectsContentThatDoesNotMatchImageExtension() {
        FileStorageService service = service(DataSize.ofMegabytes(1));
        MockMultipartFile file = new MockMultipartFile("file", "fake.jpg", "image/jpeg", "not-an-image".getBytes());

        assertThatThrownBy(() -> service.uploadReportBefore(file, user(UserRole.CITIZEN)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Only jpg, jpeg, png, and webp image files are allowed");
    }

    @Test
    void rejectsFilesAboveConfiguredSize() {
        FileStorageService service = service(DataSize.ofBytes(3));
        MockMultipartFile file = new MockMultipartFile("file", "before.jpg", "image/jpeg", jpegBytes());

        assertThatThrownBy(() -> service.uploadReportBefore(file, user(UserRole.CITIZEN)))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("File exceeds maximum upload size");
    }

    private FileStorageService service(DataSize maxUploadSize) {
        return new FileStorageService(new FileStorageProperties(uploadDir.toString(), maxUploadSize));
    }

    private User user(UserRole role) {
        return new User(role.name().toLowerCase() + "@example.local", role.name(), "hash", role);
    }

    private byte[] jpegBytes() {
        return new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0x00};
    }

    private byte[] pngBytes() {
        return new byte[] {
                (byte) 0x89, 0x50, 0x4E, 0x47,
                0x0D, 0x0A, 0x1A, 0x0A
        };
    }

    private byte[] webpBytes() {
        return new byte[] {
                0x52, 0x49, 0x46, 0x46,
                0x00, 0x00, 0x00, 0x00,
                0x57, 0x45, 0x42, 0x50
        };
    }
}
