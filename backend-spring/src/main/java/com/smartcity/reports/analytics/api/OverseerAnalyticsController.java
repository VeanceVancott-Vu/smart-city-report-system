package com.smartcity.reports.analytics.api;

import com.smartcity.reports.analytics.application.OverseerAnalyticsService;
import com.smartcity.reports.issue.IssueCategory;
import com.smartcity.reports.user.domain.User;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.UUID;

@RestController
@RequestMapping("/api/analytics")
public class OverseerAnalyticsController {

    private final OverseerAnalyticsService analyticsService;

    public OverseerAnalyticsController(OverseerAnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/overseer")
    public OverseerAnalyticsResponse overseerAnalytics(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false) IssueCategory category,
            @RequestParam(required = false) UUID staffId,
            @RequestParam(required = false) String area,
            @AuthenticationPrincipal User currentUser
    ) {
        return analyticsService.getAnalytics(from, to, category, staffId, area, currentUser);
    }
}
