package com.smartcity.reports.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartcity.reports.common.DuplicateResourceException;
import com.smartcity.reports.security.JwtService;
import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRepository;
import com.smartcity.reports.user.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final JwtService jwtService = new JwtService(
            new ObjectMapper(),
            "test-secret-with-at-least-32-characters",
            120
    );

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, passwordEncoder, jwtService);
    }

    @Test
    void registerHashesPasswordAndReturnsToken() {
        RegisterRequest request = new RegisterRequest(
                "Demo Citizen",
                "DEMO.CITIZEN@example.local",
                "correct-password",
                UserRole.CITIZEN
        );

        when(userRepository.existsByEmailIgnoreCase("demo.citizen@example.local")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            user.setId(UUID.randomUUID());
            return user;
        });

        AuthResponse response = authService.register(request);

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository).save(userCaptor.capture());
        User savedUser = userCaptor.getValue();

        assertThat(savedUser.getEmail()).isEqualTo("demo.citizen@example.local");
        assertThat(savedUser.getPasswordHash()).isNotEqualTo("correct-password");
        assertThat(passwordEncoder.matches("correct-password", savedUser.getPasswordHash())).isTrue();
        assertThat(response.token()).isNotBlank();
        assertThat(response.user().role()).isEqualTo(UserRole.CITIZEN);
    }

    @Test
    void registerRejectsDuplicateEmail() {
        RegisterRequest request = new RegisterRequest(
                "Demo Staff",
                "staff@example.local",
                "correct-password",
                UserRole.STAFF
        );

        when(userRepository.existsByEmailIgnoreCase("staff@example.local")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(DuplicateResourceException.class)
                .hasMessage("Email is already registered");
    }

    @Test
    void loginRejectsInvalidPassword() {
        User user = new User(
                "overseer@example.local",
                "Demo Overseer",
                passwordEncoder.encode("correct-password"),
                UserRole.OVERSEER
        );
        user.setId(UUID.randomUUID());

        when(userRepository.findByEmailIgnoreCase("overseer@example.local")).thenReturn(Optional.of(user));

        assertThatThrownBy(() -> authService.login(new LoginRequest("overseer@example.local", "wrong-password")))
                .isInstanceOf(BadCredentialsException.class)
                .hasMessage("Invalid email or password");
    }
}
