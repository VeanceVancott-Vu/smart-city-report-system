package com.smartcity.reports.user;

import com.smartcity.reports.common.DuplicateResourceException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public UserListResponse getUsers(UserRole role, User currentUser) {
        requireOverseer(currentUser);
        if (role != UserRole.STAFF) {
            throw new IllegalArgumentException("Only STAFF user listing is supported");
        }

        return new UserListResponse(userRepository.findByRoleAndActiveTrueOrderByFullNameAsc(UserRole.STAFF)
                .stream()
                .map(UserResponse::from)
                .toList());
    }

    @Transactional(readOnly = true)
    public UserResponse getCurrentUser(User currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
        return UserResponse.from(currentUser);
    }

    @Transactional
    public UserResponse createUser(CreateUserRequest request, User currentUser) {
        requireOverseer(currentUser);
        if (request.role() != UserRole.STAFF && request.role() != UserRole.OVERSEER) {
            throw new IllegalArgumentException("Only STAFF or OVERSEER users can be created here");
        }

        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new DuplicateResourceException("Email is already registered");
        }

        User user = new User(
                email,
                request.fullName().trim(),
                passwordEncoder.encode(request.password()),
                request.role()
        );

        try {
            return UserResponse.from(userRepository.save(user));
        } catch (DataIntegrityViolationException exception) {
            throw new DuplicateResourceException("Email is already registered");
        }
    }

    private void requireOverseer(User currentUser) {
        if (currentUser == null) {
            throw new AccessDeniedException("Authentication required");
        }
        if (currentUser.getRole() != UserRole.OVERSEER) {
            throw new AccessDeniedException("Only overseers can manage users");
        }
    }

    private String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
