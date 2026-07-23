package com.smartcity.reports.priority.application;

import com.smartcity.reports.report.domain.Report;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface PriorityScoringClient {

    Map<UUID, Integer> calculatePriorities(List<Report> reports);
}
