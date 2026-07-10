package com.smartcity.reports.user.api;

import java.util.List;

public record StaffListResponse(
        List<StaffSummaryResponse> staff
) {}
