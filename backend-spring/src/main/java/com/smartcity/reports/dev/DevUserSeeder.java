package com.smartcity.reports.dev;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.persistence.UserRepository;
import com.smartcity.reports.user.domain.UserRole;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
@Profile({"local", "dev"})
@Order(1)
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
                new SeedUser("citizen@test.com", "Nguyen Minh Anh", UserRole.CITIZEN),
                new SeedUser("linh.nguyen@test.com", "Nguyen Hoang Linh", UserRole.CITIZEN),
                new SeedUser("minh.tran@test.com", "Tran Quang Minh", UserRole.CITIZEN),
                new SeedUser("an.le@test.com", "Le Bao An", UserRole.CITIZEN),
                new SeedUser("staff@test.com", "Pham Gia Bao", UserRole.STAFF),
                new SeedUser("mai.nguyen.staff@test.com", "Nguyen Ngoc Mai", UserRole.STAFF),
                new SeedUser("quang.tran.staff@test.com", "Tran Minh Quang", UserRole.STAFF),
                new SeedUser("thuy.le.staff@test.com", "Le Thanh Thuy", UserRole.STAFF),
                new SeedUser("overseer@test.com", "Test Overseer", UserRole.OVERSEER)
        );
    }

    private record SeedUser(String email, String fullName, UserRole role) {
    }
}
