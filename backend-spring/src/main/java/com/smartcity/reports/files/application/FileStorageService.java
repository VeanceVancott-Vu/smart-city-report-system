package com.smartcity.reports.files.application;

import com.smartcity.reports.files.api.FileUploadResponse;
import com.smartcity.reports.files.config.FileStorageProperties;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.Arrays;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@Service
public class FileStorageService {

    private static final String REPORT_BEFORE_DIR = "report-before";
    private static final String TASK_AFTER_DIR = "task-after";

    private final Path uploadRoot;
    private final long maxUploadBytes;

    public FileStorageService(FileStorageProperties properties) {
        this.uploadRoot = Path.of(properties.uploadDir()).toAbsolutePath().normalize();
        this.maxUploadBytes = properties.maxUploadSize().toBytes();
    }

    public FileUploadResponse uploadReportBefore(MultipartFile file, User currentUser) {
        requireRole(currentUser, UserRole.CITIZEN, "Only citizens can upload report before photos");
        return store(file, REPORT_BEFORE_DIR);
    }

    public FileUploadResponse uploadTaskAfter(MultipartFile file, User currentUser) {
        requireRole(currentUser, UserRole.STAFF, "Only staff can upload task after photos");
        return store(file, TASK_AFTER_DIR);
    }

    private FileUploadResponse store(MultipartFile file, String directoryName) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("File is required");
        }
        if (file.getSize() > maxUploadBytes) {
            throw new IllegalArgumentException("File exceeds maximum upload size");
        }

        String extension = extensionOf(file.getOriginalFilename());
        ImageFileType extensionType = ImageFileType.fromExtension(extension);
        if (extensionType == null) {
            throw new IllegalArgumentException("Only jpg, jpeg, png, and webp image files are allowed");
        }
        if (!extensionType.allowsContentType(file.getContentType())) {
            throw new IllegalArgumentException("Only jpg, jpeg, png, and webp image files are allowed");
        }

        byte[] content = readBytes(file);
        ImageFileType detectedType = ImageFileType.detect(content);
        if (detectedType == null || detectedType != extensionType) {
            throw new IllegalArgumentException("Only jpg, jpeg, png, and webp image files are allowed");
        }

        Path targetDir = uploadRoot.resolve(directoryName).normalize();
        if (!targetDir.startsWith(uploadRoot)) {
            throw new IllegalArgumentException("Invalid upload directory");
        }

        String filename = UUID.randomUUID() + "." + extensionType.extensionForStoredFile(extension);
        Path targetFile = targetDir.resolve(filename).normalize();
        if (!targetFile.startsWith(targetDir)) {
            throw new IllegalArgumentException("Invalid upload filename");
        }

        try {
            Files.createDirectories(targetDir);
            Files.write(targetFile, content, StandardOpenOption.CREATE_NEW);
            return new FileUploadResponse("/uploads/" + directoryName + "/" + filename);
        } catch (IOException exception) {
            throw new FileStorageException("Unable to store uploaded file", exception);
        }
    }

    private byte[] readBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException exception) {
            throw new FileStorageException("Unable to read uploaded file", exception);
        }
    }

    private void requireRole(User currentUser, UserRole role, String message) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
        if (currentUser.getRole() != role) {
            throw new AccessDeniedException(message);
        }
    }

    private String extensionOf(String filename) {
        if (filename == null || filename.isBlank()) {
            return "";
        }
        int extensionStart = filename.lastIndexOf('.');
        if (extensionStart < 0 || extensionStart == filename.length() - 1) {
            return "";
        }
        return filename.substring(extensionStart + 1).toLowerCase(Locale.ROOT);
    }

    private enum ImageFileType {
        JPEG(Set.of("jpg", "jpeg"), Set.of(MediaType.IMAGE_JPEG_VALUE)),
        PNG(Set.of("png"), Set.of(MediaType.IMAGE_PNG_VALUE)),
        WEBP(Set.of("webp"), Set.of("image/webp"));

        private final Set<String> extensions;
        private final Set<String> contentTypes;

        ImageFileType(Set<String> extensions, Set<String> contentTypes) {
            this.extensions = extensions;
            this.contentTypes = contentTypes;
        }

        static ImageFileType fromExtension(String extension) {
            return Arrays.stream(values())
                    .filter(type -> type.extensions.contains(extension))
                    .findFirst()
                    .orElse(null);
        }

        static ImageFileType detect(byte[] bytes) {
            if (bytes.length >= 3
                    && (bytes[0] & 0xFF) == 0xFF
                    && (bytes[1] & 0xFF) == 0xD8
                    && (bytes[2] & 0xFF) == 0xFF) {
                return JPEG;
            }
            if (bytes.length >= 8
                    && (bytes[0] & 0xFF) == 0x89
                    && bytes[1] == 0x50
                    && bytes[2] == 0x4E
                    && bytes[3] == 0x47
                    && bytes[4] == 0x0D
                    && bytes[5] == 0x0A
                    && bytes[6] == 0x1A
                    && bytes[7] == 0x0A) {
                return PNG;
            }
            if (bytes.length >= 12
                    && bytes[0] == 0x52
                    && bytes[1] == 0x49
                    && bytes[2] == 0x46
                    && bytes[3] == 0x46
                    && bytes[8] == 0x57
                    && bytes[9] == 0x45
                    && bytes[10] == 0x42
                    && bytes[11] == 0x50) {
                return WEBP;
            }
            return null;
        }

        boolean allowsContentType(String contentType) {
            return contentType != null && contentTypes.contains(contentType.toLowerCase(Locale.ROOT));
        }

        String extensionForStoredFile(String originalExtension) {
            if (this == JPEG && "jpeg".equals(originalExtension)) {
                return "jpeg";
            }
            return switch (this) {
                case JPEG -> "jpg";
                case PNG -> "png";
                case WEBP -> "webp";
            };
        }
    }
}
