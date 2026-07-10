package com.smartcity.reports.user.api;

import java.util.List;

public record UserListResponse(
        List<UserResponse> users
) {
}
