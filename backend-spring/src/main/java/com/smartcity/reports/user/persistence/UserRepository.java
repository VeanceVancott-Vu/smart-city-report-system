package com.smartcity.reports.user.persistence;

import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {

    boolean existsByEmailIgnoreCase(String email);

    Optional<User> findByEmailIgnoreCase(String email);

    List<User> findByRoleAndActiveTrueOrderByFullNameAsc(UserRole role);

    List<User> findByRoleOrderByFullNameAsc(UserRole role);
}
