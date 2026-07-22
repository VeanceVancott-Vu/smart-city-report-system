package com.smartcity.reports.user.api;

import com.smartcity.reports.user.application.UserService;
import com.smartcity.reports.user.domain.User;
import com.smartcity.reports.user.domain.UserRole;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public UserListResponse getUsers(
            @RequestParam UserRole role,
            @AuthenticationPrincipal User currentUser
    ) {
        return userService.getUsers(role, currentUser);
    }

    @GetMapping("/staff-summary")
    public StaffListResponse getStaffSummary(
            @AuthenticationPrincipal User currentUser
    ) {
        return userService.getStaffSummary(currentUser);
    }

    @GetMapping("/me")
    public UserResponse me(@AuthenticationPrincipal User currentUser) {
        return userService.getCurrentUser(currentUser);
    }

    @GetMapping("/me/profile")
    public UserProfileResponse myProfile(@AuthenticationPrincipal User currentUser) {
        return userService.getCurrentUserProfile(currentUser);
    }

    @GetMapping("/staff/{staffId}/profile")
    public StaffPublicProfileResponse staffProfile(
            @PathVariable UUID staffId,
            @AuthenticationPrincipal User currentUser
    ) {
        return userService.getStaffPublicProfile(staffId, currentUser);
    }

    @GetMapping("/staff/{staffId}/details")
    public StaffDetailProfileResponse staffDetails(
            @PathVariable UUID staffId,
            @AuthenticationPrincipal User currentUser
    ) {
        return userService.getStaffDetailProfile(staffId, currentUser);
    }

    @PostMapping
    public ResponseEntity<UserResponse> createUser(
            @Valid @RequestBody CreateUserRequest request,
            @AuthenticationPrincipal User currentUser
    ) {
        UserResponse response = userService.createUser(request, currentUser);
        return ResponseEntity.created(URI.create("/api/users/" + response.id())).body(response);
    }
}
