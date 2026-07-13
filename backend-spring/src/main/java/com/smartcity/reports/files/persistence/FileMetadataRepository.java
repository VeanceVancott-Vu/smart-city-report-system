package com.smartcity.reports.files.persistence;

import com.smartcity.reports.files.domain.FileMetadata;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface FileMetadataRepository extends JpaRepository<FileMetadata, UUID> {

    Optional<FileMetadata> findByStorageKey(String storageKey);

    long deleteByStorageKey(String storageKey);
}
