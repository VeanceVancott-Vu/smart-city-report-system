package com.smartcity.reports.report;

final class ReportPhotoUrls {

    static final String REPORT_BEFORE_URL_PATTERN =
            "^/uploads/report-before/[A-Za-z0-9][A-Za-z0-9._-]*\\.(?i:jpg|jpeg|png|webp)$";
    static final String REPORT_BEFORE_URL_MESSAGE =
            "Before photo must be uploaded with /api/files/report-before";

    private ReportPhotoUrls() {
    }
}
