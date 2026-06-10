package com.smartcity.reports.dev;

import com.smartcity.reports.user.User;
import com.smartcity.reports.user.UserRepository;
import com.smartcity.reports.user.UserRole;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
@Profile({"local", "dev"})
public class DevUserSeeder implements ApplicationRunner {

    private static final String DEFAULT_PASSWORD = "Password123";

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DevUserSeeder(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        seedUsers();
    }

    void seedUsers() {
        for (SeedUser seedUser : seedUsersToCreate()) {
            if (userRepository.existsByEmailIgnoreCase(seedUser.email())) {
                continue;
            }

            User user = new User(
                    seedUser.email(),
                    seedUser.fullName(),
                    passwordEncoder.encode(DEFAULT_PASSWORD),
                    seedUser.role()
            );
            userRepository.save(user);
        }
    }

    private List<SeedUser> seedUsersToCreate() {
        return List.of(
                new SeedUser("citizen@test.com", "Test Citizen", UserRole.CITIZEN),
                new SeedUser("staff@test.com", "Test Staff", UserRole.STAFF),
                new SeedUser("overseer@test.com", "Test Overseer", UserRole.OVERSEER)
        );
    }

    private record SeedUser(String email, String fullName, UserRole role) {
    }
}
