package com.smartcity.reports.task.api;

final class TaskPhotoUrls {

    static final String TASK_AFTER_URL_PATTERN =
            "^/uploads/task-after/[A-Za-z0-9][A-Za-z0-9._-]*\\.(?i:jpg|jpeg|png|webp)$";
    static final String TASK_AFTER_URL_MESSAGE =
            "After photo must be uploaded with /api/files/task-after";

    private TaskPhotoUrls() {
    }
}
