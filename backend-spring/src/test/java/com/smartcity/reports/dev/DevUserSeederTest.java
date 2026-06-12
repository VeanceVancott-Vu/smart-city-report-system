package com.smartcity.reports.dev;

import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRepository;
import com.smartcity.reports.user.UserRole;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.context.annotation.Profile;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DevUserSeederTest {

    @Mock
    private UserRepository userRepository;

    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    @Test
    void seederOnlyRunsForLocalAndDevProfiles() {
        Profile profile = DevUserSeeder.class.getAnnotation(Profile.class);

        assertThat(profile).isNotNull();
        assertThat(profile.value()).containsExactlyInAnyOrder("local", "dev");
    }

    @Test
    void seedUsersCreatesMissingUsersWithHashedPasswords() {
        DevUserSeeder seeder = new DevUserSeeder(userRepository, passwordEncoder);

        when(userRepository.existsByEmailIgnoreCase("citizen@test.com")).thenReturn(false);
        when(userRepository.existsByEmailIgnoreCase("staff@test.com")).thenReturn(false);
        when(userRepository.existsByEmailIgnoreCase("overseer@test.com")).thenReturn(false);

        seeder.seedUsers();

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository, org.mockito.Mockito.times(3)).save(userCaptor.capture());

        List<User> users = userCaptor.getAllValues();
        assertThat(users).extracting(User::getEmail)
                .containsExactly("citizen@test.com", "staff@test.com", "overseer@test.com");
        assertThat(users).extracting(User::getRole)
                .containsExactly(UserRole.CITIZEN, UserRole.STAFF, UserRole.OVERSEER);
        assertThat(users).allSatisfy(user -> {
            assertThat(user.getPasswordHash()).isNotEqualTo("Password123");
            assertThat(passwordEncoder.matches("Password123", user.getPasswordHash())).isTrue();
        });
    }

    @Test
    void seedUsersDoesNotCreateUsersThatAlreadyExist() {
        DevUserSeeder seeder = new DevUserSeeder(userRepository, passwordEncoder);

        when(userRepository.existsByEmailIgnoreCase("citizen@test.com")).thenReturn(true);
        when(userRepository.existsByEmailIgnoreCase("staff@test.com")).thenReturn(true);
        when(userRepository.existsByEmailIgnoreCase("overseer@test.com")).thenReturn(true);

        seeder.seedUsers();

        verify(userRepository, never()).save(org.mockito.ArgumentMatchers.any(User.class));
    }
}
