package com.smartcity.reports.files.application;

import com.smartcity.reports.common.ResourceNotFoundException;
import com.smartcity.reports.files.api.FileUploadResponse;
import com.smartcity.reports.files.config.FileStorageProperties;
import com.smartcity.reports.files.domain.FileMetadata;
import com.smartcity.reports.files.persistence.FileMetadataRepository;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@Service
public class FileStorageService {

    private static final String REPORT_BEFORE_DIR = "report-before";
    private static final String TASK_AFTER_DIR = "task-after";
    private static final Set<String> ALLOWED_DIRECTORIES = Set.of(REPORT_BEFORE_DIR, TASK_AFTER_DIR);

    private final Path uploadRoot;
    private final long maxUploadBytes;
    private final FileMetadataRepository fileMetadataRepository;

    public FileStorageService(
            FileStorageProperties properties,
            FileMetadataRepository fileMetadataRepository
    ) {
        this.uploadRoot = Path.of(properties.uploadDir()).toAbsolutePath().normalize();
        this.maxUploadBytes = properties.maxUploadSize().toBytes();
        this.fileMetadataRepository = fileMetadataRepository;
    }

    public FileUploadResponse uploadReportBefore(MultipartFile file, User currentUser) {
        requireRole(currentUser, UserRole.CITIZEN, "Only citizens can upload report before photos");
        return store(file, REPORT_BEFORE_DIR, currentUser);
    }

    public FileUploadResponse uploadTaskAfter(MultipartFile file, User currentUser) {
        requireRole(currentUser, UserRole.STAFF, "Only staff can upload task after photos");
        return store(file, TASK_AFTER_DIR, currentUser);
    }

    public FileDownload load(String fileUrl) {
        String storageKey = storageKeyOf(fileUrl);
        Path targetFile = resolveStoragePath(storageKey);
        if (!Files.isRegularFile(targetFile)) {
            throw new ResourceNotFoundException("File not found");
        }

        String contentType = fileMetadataRepository.findByStorageKey(storageKey)
                .map(FileMetadata::getContentType)
                .orElseGet(() -> contentTypeFor(storageKey));
        try {
            Resource resource = new FileSystemResource(targetFile);
            return new FileDownload(resource, MediaType.parseMediaType(contentType), Files.size(targetFile));
        } catch (IOException | IllegalArgumentException exception) {
            throw new FileStorageException("Unable to read stored file", exception);
        }
    }

    public void delete(String fileUrl) {
        String storageKey = storageKeyOf(fileUrl);
        Path targetFile = resolveStoragePath(storageKey);
        try {
            Files.deleteIfExists(targetFile);
            fileMetadataRepository.deleteByStorageKey(storageKey);
        } catch (IOException exception) {
            throw new FileStorageException("Unable to delete stored file", exception);
        }
    }

    private FileUploadResponse store(
            MultipartFile file,
            String directoryName,
            User currentUser
    ) {
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

        ImageFileType detectedType = detectType(file);
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
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, targetFile);
            }

            String storageKey = directoryName + "/" + filename;
            FileMetadata metadata = new FileMetadata(
                    storageKey,
                    originalFilenameOf(file.getOriginalFilename()),
                    extensionType.mediaType,
                    file.getSize(),
                    currentUser
            );
            try {
                fileMetadataRepository.save(metadata);
            } catch (RuntimeException exception) {
                Files.deleteIfExists(targetFile);
                throw exception;
            }
            return new FileUploadResponse("/uploads/" + storageKey);
        } catch (IOException exception) {
            throw new FileStorageException("Unable to store uploaded file", exception);
        }
    }

    private ImageFileType detectType(MultipartFile file) {
        try (InputStream inputStream = file.getInputStream()) {
            return ImageFileType.detect(inputStream.readNBytes(12));
        } catch (IOException exception) {
            throw new FileStorageException("Unable to read uploaded file", exception);
        }
    }

    private Path resolveStoragePath(String storageKey) {
        Path targetFile = uploadRoot.resolve(storageKey).normalize();
        if (!targetFile.startsWith(uploadRoot)) {
            throw new ResourceNotFoundException("File not found");
        }
        return targetFile;
    }

    private String storageKeyOf(String fileUrl) {
        if (fileUrl == null || !fileUrl.startsWith("/uploads/")) {
            throw new ResourceNotFoundException("File not found");
        }

        String storageKey = fileUrl.substring("/uploads/".length());
        if (storageKey.contains("\\")) {
            throw new ResourceNotFoundException("File not found");
        }

        Path relativePath = Path.of(storageKey).normalize();
        String normalizedKey = relativePath.toString().replace('\\', '/');
        if (relativePath.getNameCount() != 2
                || !ALLOWED_DIRECTORIES.contains(relativePath.getName(0).toString())
                || relativePath.getName(1).toString().isBlank()
                || !normalizedKey.equals(storageKey)) {
            throw new ResourceNotFoundException("File not found");
        }
        return storageKey;
    }

    private String contentTypeFor(String storageKey) {
        ImageFileType type = ImageFileType.fromExtension(extensionOf(storageKey));
        return type == null ? MediaType.APPLICATION_OCTET_STREAM_VALUE : type.mediaType;
    }

    private String originalFilenameOf(String filename) {
        if (filename == null || filename.isBlank()) {
            return "uploaded-image";
        }
        String normalized = filename.replace('\\', '/');
        return normalized.substring(normalized.lastIndexOf('/') + 1);
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
        JPEG(Set.of("jpg", "jpeg"), Set.of(MediaType.IMAGE_JPEG_VALUE), MediaType.IMAGE_JPEG_VALUE),
        PNG(Set.of("png"), Set.of(MediaType.IMAGE_PNG_VALUE), MediaType.IMAGE_PNG_VALUE),
        WEBP(Set.of("webp"), Set.of("image/webp"), "image/webp");

        private final Set<String> extensions;
        private final Set<String> contentTypes;
        private final String mediaType;

        ImageFileType(Set<String> extensions, Set<String> contentTypes, String mediaType) {
            this.extensions = extensions;
            this.contentTypes = contentTypes;
            this.mediaType = mediaType;
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
