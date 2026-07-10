package com.smartcity.reports.auth.api;

import com.smartcity.reports.auth.application.AuthService;

import com.smartcity.reports.common.ApiExceptionHandler;
import com.smartcity.reports.config.SecurityConfig;
import com.smartcity.reports.security.JwtService;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.persistence.UserRepository;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(AuthController.class)
@Import({SecurityConfig.class, ApiExceptionHandler.class, JwtService.class})
@TestPropertySource(properties = {
        "jwt.secret=test-secret-with-at-least-32-characters",
        "jwt.expiration-minutes=120",
        "app.cors.allowed-origins=http://127.0.0.1:5200,http://localhost:5200"
})
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AuthService authService;

    @MockBean
    private UserRepository userRepository;

    @Test
    void registerIsPublicAndReturnsAuthResponse() throws Exception {
        UUID userId = UUID.randomUUID();
        when(authService.register(any(RegisterRequest.class))).thenReturn(AuthResponse.bearer(
                "signed.jwt.token",
                new CurrentUserResponse(userId, "Demo Citizen", "citizen@example.local", UserRole.CITIZEN)
        ));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "fullName": "Demo Citizen",
                                  "email": "citizen@example.local",
                                  "password": "correct-password"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").value("signed.jwt.token"))
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.user.id").value(userId.toString()))
                .andExpect(jsonPath("$.user.role").value("CITIZEN"));
    }

    @Test
    void loginIsPublicAndReturnsAuthResponse() throws Exception {
        UUID userId = UUID.randomUUID();
        when(authService.login(any(LoginRequest.class))).thenReturn(AuthResponse.bearer(
                "signed.jwt.token",
                new CurrentUserResponse(userId, "Demo Staff", "staff@example.local", UserRole.STAFF)
        ));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "staff@example.local",
                                  "password": "correct-password"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("signed.jwt.token"))
                .andExpect(jsonPath("$.user.role").value("STAFF"));
    }

    @Test
    void loginAllowsFlutterWebCorsPreflight() throws Exception {
        mockMvc.perform(options("/api/auth/login")
                        .header(HttpHeaders.ORIGIN, "http://127.0.0.1:5200")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://127.0.0.1:5200"))
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS, containsString("POST")))
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS, containsString("content-type")));
    }

    @Test
    void registerAllowsFlutterWebCorsPreflight() throws Exception {
        mockMvc.perform(options("/api/auth/register")
                        .header(HttpHeaders.ORIGIN, "http://localhost:5200")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_HEADERS, "content-type"))
                .andExpect(status().isOk())
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:5200"))
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS, containsString("POST")))
                .andExpect(header().string(HttpHeaders.ACCESS_CONTROL_ALLOW_HEADERS, containsString("content-type")));
    }

    @Test
    void meRequiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Authentication required"));
    }

    @Test
    void meReturnsCurrentUserWhenAuthenticated() throws Exception {
        UUID userId = UUID.randomUUID();
        User user = new User(
                "overseer@example.local",
                "Demo Overseer",
                "$2a$10$abcdefghijklmnopqrstuu",
                UserRole.OVERSEER
        );
        user.setId(userId);

        when(authService.toCurrentUserResponse(user)).thenReturn(new CurrentUserResponse(
                userId,
                "Demo Overseer",
                "overseer@example.local",
                UserRole.OVERSEER
        ));

        UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                user,
                null,
                List.of(new SimpleGrantedAuthority("ROLE_OVERSEER"))
        );

        mockMvc.perform(get("/api/auth/me").with(authentication(authentication)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(userId.toString()))
                .andExpect(jsonPath("$.role").value("OVERSEER"));
    }
}
