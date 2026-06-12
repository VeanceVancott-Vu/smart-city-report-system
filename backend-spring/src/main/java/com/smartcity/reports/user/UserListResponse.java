package com.smartcity.reports.user;

import java.util.List;

public record UserListResponse(
        List<UserResponse> users
) {
}
