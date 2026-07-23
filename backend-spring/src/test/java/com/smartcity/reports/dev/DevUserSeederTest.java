package com.smartcity.reports.dev;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.persistence.UserRepository;
import com.smartcity.reports.user.domain.UserRole;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
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
    void seederOnlyRunsForLocalAndDevProfilesBeforeDemoData() {
        Profile profile = DevUserSeeder.class.getAnnotation(Profile.class);
        Order order = DevUserSeeder.class.getAnnotation(Order.class);

        assertThat(profile).isNotNull();
        assertThat(profile.value()).containsExactlyInAnyOrder("local", "dev");
        assertThat(order).isNotNull();
        assertThat(order.value()).isEqualTo(1);
    }

    @Test
    void seedUsersCreatesMissingUsersWithHashedPasswords() {
        DevUserSeeder seeder = new DevUserSeeder(userRepository, passwordEncoder);

        when(userRepository.existsByEmailIgnoreCase(org.mockito.ArgumentMatchers.anyString()))
                .thenReturn(false);

        seeder.seedUsers();

        ArgumentCaptor<User> userCaptor = ArgumentCaptor.forClass(User.class);
        verify(userRepository, org.mockito.Mockito.times(9)).save(userCaptor.capture());

        List<User> users = userCaptor.getAllValues();
        assertThat(users).extracting(User::getEmail)
                .containsExactly(
                        "citizen@test.com",
                        "linh.nguyen@test.com",
                        "minh.tran@test.com",
                        "an.le@test.com",
                        "staff@test.com",
                        "mai.nguyen.staff@test.com",
                        "quang.tran.staff@test.com",
                        "thuy.le.staff@test.com",
                        "overseer@test.com"
                );
        assertThat(users).filteredOn(user -> user.getRole() == UserRole.CITIZEN).hasSize(4);
        assertThat(users).filteredOn(user -> user.getRole() == UserRole.STAFF).hasSize(4);
        assertThat(users).filteredOn(user -> user.getRole() == UserRole.OVERSEER).hasSize(1);
        assertThat(users).allSatisfy(user -> {
            assertThat(user.getPasswordHash()).isNotEqualTo("Password123");
            assertThat(passwordEncoder.matches("Password123", user.getPasswordHash())).isTrue();
        });
    }

    @Test
    void seedUsersDoesNotCreateUsersThatAlreadyExist() {
        DevUserSeeder seeder = new DevUserSeeder(userRepository, passwordEncoder);

        when(userRepository.existsByEmailIgnoreCase(org.mockito.ArgumentMatchers.anyString()))
                .thenReturn(true);

        seeder.seedUsers();

        verify(userRepository, never()).save(org.mockito.ArgumentMatchers.any(User.class));
    }
}
