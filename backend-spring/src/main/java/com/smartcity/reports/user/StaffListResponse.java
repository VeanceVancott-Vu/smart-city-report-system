package com.smartcity.reports.user;

import java.util.List;

public record StaffListResponse(
        List<StaffSummaryResponse> staff
) {}
