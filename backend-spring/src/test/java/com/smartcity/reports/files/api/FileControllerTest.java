package com.smartcity.reports.files.api;

import com.smartcity.reports.common.ApiExceptionHandler;
import com.smartcity.reports.files.application.FileDownload;
import com.smartcity.reports.files.application.FileStorageService;
import com.smartcity.reports.security.JwtAuthenticationFilter;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.nullable;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest({FileController.class, FileDownloadController.class})
@AutoConfigureMockMvc(addFilters = false)
@Import(ApiExceptionHandler.class)
class FileControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private FileStorageService fileStorageService;

    @MockBean
    private JwtAuthenticationFilter jwtAuthenticationFilter;

    @Test
    void uploadReportBeforeReturnsFileUrl() throws Exception {
        User citizen = user(UserRole.CITIZEN);
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "before.jpg",
                "image/jpeg",
                new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF}
        );
        when(fileStorageService.uploadReportBefore(any(), nullable(User.class)))
                .thenReturn(new FileUploadResponse("/uploads/report-before/before.jpg"));

        mockMvc.perform(multipart("/api/files/report-before")
                        .file(file)
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fileUrl").value("/uploads/report-before/before.jpg"));
    }

    @Test
    void uploadTaskAfterReturnsFileUrl() throws Exception {
        User staff = user(UserRole.STAFF);
        MockMultipartFile file = new MockMultipartFile(
                "file",
                "after.png",
                "image/png",
                new byte[] {(byte) 0x89, 0x50, 0x4E, 0x47}
        );
        when(fileStorageService.uploadTaskAfter(any(), nullable(User.class)))
                .thenReturn(new FileUploadResponse("/uploads/task-after/after.png"));

        mockMvc.perform(multipart("/api/files/task-after")
                        .file(file)
                        .with(authentication(authenticationToken(staff))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fileUrl").value("/uploads/task-after/after.png"));
    }

    @Test
    void downloadReturnsStoredImage() throws Exception {
        byte[] contentBytes = new byte[] {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF};
        when(fileStorageService.load("/uploads/report-before/before.jpg"))
                .thenReturn(new FileDownload(
                        new ByteArrayResource(contentBytes),
                        MediaType.IMAGE_JPEG,
                        contentBytes.length
                ));

        mockMvc.perform(get("/uploads/report-before/before.jpg"))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_JPEG))
                .andExpect(content().bytes(contentBytes));
    }

    @Test
    void uploadRequiresFilePart() throws Exception {
        User citizen = user(UserRole.CITIZEN);

        mockMvc.perform(multipart("/api/files/report-before")
                        .with(authentication(authenticationToken(citizen))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Multipart file field 'file' is required"));
    }

    private User user(UserRole role) {
        return new User(role.name().toLowerCase() + "@example.local", role.name(), "hash", role);
    }

    private UsernamePasswordAuthenticationToken authenticationToken(User user) {
        return new UsernamePasswordAuthenticationToken(
                user,
                null,
                List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
        );
    }
}