# Backend Manual Test Flow

This verifies the current core CRUD workflow with real HTTP requests, JWT auth, Flyway tables, and PostgreSQL data.

It intentionally does not test AI, offline sync, OAuth, rate limiting, or stress behavior.

## What This Script Does

The commands below:

1. Log in as a citizen.
2. Create a report.
3. View the citizen's own reports.
4. Upvote the report and verify `priorityScore`.
5. View open report map pins.
6. Verify the citizen cannot access task APIs.
7. Log in as an overseer.
8. View all reports.
9. Create a task from the report and assign staff.
10. Log in as staff.
11. View assigned tasks.
12. Start the task.
13. Complete the task.
14. Verify staff cannot close the task.
15. Use the overseer token again.
16. Close the task.
17. Verify the related report status becomes `FIXED`.
18. Verify the fixed report is no longer returned as an open map pin.

Because the backend does not have a staff-list endpoint yet, the script logs in as staff before task creation to capture `assignedStaffId`, then reuses that staff token for the staff workflow.

## 1. Start Local Services

Run this from the repository root:

```powershell
docker compose up -d postgres
```

This starts the local PostgreSQL/PostGIS container used by the Spring Boot backend.

In a second terminal, run:

```powershell
mvn -f backend-spring/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
```

This starts the Spring Boot backend with the `local` profile. Flyway runs automatically on startup, so the database schema is migrated before the app accepts requests.

## 2. Prepare PowerShell Variables

Run these commands in a new PowerShell terminal:

```powershell
$BASE = "http://localhost:8080"
$WORK = Join-Path $env:TEMP "smart-city-manual-flow"
New-Item -ItemType Directory -Force $WORK | Out-Null
```

This stores the base API URL and creates a temporary folder for JSON request bodies. Using files avoids PowerShell quoting problems with `curl.exe`.

## 3. Login As Citizen

```powershell
@'
{ "email": "citizen@test.com", "password": "Password123" }
'@ | Set-Content -NoNewline "$WORK\login-citizen.json"

$CITIZEN_LOGIN = curl.exe -s -X POST "$BASE/api/auth/login" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\login-citizen.json" | ConvertFrom-Json

$CITIZEN_TOKEN = $CITIZEN_LOGIN.token
$CITIZEN_LOGIN.user
```

This logs in with the seeded development citizen and stores the JWT in `$CITIZEN_TOKEN`.

Expected user role:

```text
CITIZEN
```

## 4. Create Report

```powershell
@'
{
  "title": "Manual flow pothole",
  "description": "Large pothole blocking the right lane.",
  "category": "ROAD_DAMAGE",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "addressText": "District 1 test street",
  "beforePhotoUrl": "https://example.local/manual-before.jpg",
  "anonymous": false
}
'@ | Set-Content -NoNewline "$WORK\create-report.json"

$REPORT = curl.exe -s -X POST "$BASE/api/reports" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" `
  --data-binary "@$WORK\create-report.json" | ConvertFrom-Json

$REPORT_ID = $REPORT.id
$REPORT | Select-Object id,title,status,category,upvoteCount,priorityScore
```

This creates a new report as the citizen. New reports should start as `SUBMITTED` with `upvoteCount = 0` and `priorityScore = 0`.

Expected status:

```text
SUBMITTED
```

## 5. View My Reports

```powershell
$MY_REPORTS = curl.exe -s "$BASE/api/reports?mine=true" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" | ConvertFrom-Json

$MY_REPORTS.reports | Select-Object id,title,status,category
```

This verifies the citizen can see their own reports.

Expected result:

```text
The report id stored in $REPORT_ID is listed.
```

## 6. Upvote Report And Verify Priority

```powershell
$UPVOTE = curl.exe -s -X POST "$BASE/api/reports/$REPORT_ID/upvote" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" | ConvertFrom-Json

$UPVOTE | Select-Object id,upvoteCount,priorityScore,hasUpvoted

if ($UPVOTE.priorityScore -ne 1) {
  throw "Expected priorityScore to be 1 after upvote, got $($UPVOTE.priorityScore)"
}
```

This verifies upvotes increase `priorityScore`.

Expected result:

```text
upvoteCount = 1
priorityScore = 1
hasUpvoted = True
```

## 7. View Open Report Map Pins

```powershell
$MAP_PINS = curl.exe -s "$BASE/api/reports/map?minLat=10.0&minLng=106.0&maxLat=11.0&maxLng=107.0" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" | ConvertFrom-Json

$MAP_PINS | Select-Object id,title,status,upvoteCount,priorityScore

if (-not ($MAP_PINS.id -contains $REPORT_ID)) {
  throw "Expected report $REPORT_ID to appear as an open map pin"
}
```

The map endpoint returns open `SUBMITTED` report pins inside the bounding box.

## 8. Verify Citizen Cannot Access Task APIs

```powershell
$CITIZEN_TASK_DENIED = curl.exe -s "$BASE/api/tasks" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" | ConvertFrom-Json

$CITIZEN_TASK_DENIED | Select-Object status,message
```

Expected result:

```text
status  = 403
message = Citizens cannot access tasks
```

## 9. Login As Overseer

```powershell
@'
{ "email": "overseer@test.com", "password": "Password123" }
'@ | Set-Content -NoNewline "$WORK\login-overseer.json"

$OVERSEER_LOGIN = curl.exe -s -X POST "$BASE/api/auth/login" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\login-overseer.json" | ConvertFrom-Json

$OVERSEER_TOKEN = $OVERSEER_LOGIN.token
$OVERSEER_LOGIN.user
```

This logs in with the seeded development overseer and stores the JWT in `$OVERSEER_TOKEN`.

Expected user role:

```text
OVERSEER
```

## 10. View All Reports As Overseer

```powershell
$ALL_REPORTS = curl.exe -s "$BASE/api/reports" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$ALL_REPORTS.reports | Select-Object id,title,status,category
```

This verifies the overseer can see all reports, not just their own.

Expected result:

```text
The report id stored in $REPORT_ID is listed.
```

## 11. Capture Staff Id For Assignment

```powershell
@'
{ "email": "staff@test.com", "password": "Password123" }
'@ | Set-Content -NoNewline "$WORK\login-staff.json"

$STAFF_LOGIN = curl.exe -s -X POST "$BASE/api/auth/login" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\login-staff.json" | ConvertFrom-Json

$STAFF_TOKEN = $STAFF_LOGIN.token
$STAFF_ID = $STAFF_LOGIN.user.id
$STAFF_LOGIN.user
```

This logs in with the seeded development staff user. The task create endpoint needs the staff user's UUID in `assignedStaffId`.

Expected user role:

```text
STAFF
```

## 12. Create Task From Report And Assign Staff

```powershell
@"
{
  "title": "Repair manual flow pothole",
  "description": "Repair the pothole reported by the citizen manual flow.",
  "category": "ROAD_DAMAGE",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "addressText": "District 1 test street",
  "priorityScore": 0,
  "assignedStaffId": "$STAFF_ID",
  "beforePhotoUrl": "https://example.local/manual-before.jpg",
  "reportIds": ["$REPORT_ID"]
}
"@ | Set-Content -NoNewline "$WORK\create-task.json"

$TASK = curl.exe -s -X POST "$BASE/api/tasks" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" `
  --data-binary "@$WORK\create-task.json" | ConvertFrom-Json

$TASK_ID = $TASK.id
$TASK | Select-Object id,title,status,priorityScore,reportIds
$TASK.assignedStaff
```

This creates a task as the overseer, links it to the report through `task_reports`, and assigns it to staff. Creating a task with `assignedStaffId` should set the task status to `ASSIGNED`.

Expected task status:

```text
ASSIGNED
```

## 13. View Assigned Tasks As Staff

```powershell
$STAFF_TASKS = curl.exe -s "$BASE/api/tasks?assignedToMe=true" `
  -H "Authorization: Bearer $STAFF_TOKEN" | ConvertFrom-Json

$STAFF_TASKS.tasks | Select-Object id,title,status
```

This verifies staff can see assigned tasks.

Expected result:

```text
The task id stored in $TASK_ID is listed with status ASSIGNED.
```

## 14. Start Task As Staff

```powershell
$STARTED_TASK = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/start" `
  -H "Authorization: Bearer $STAFF_TOKEN" | ConvertFrom-Json

$STARTED_TASK | Select-Object id,status,startedAt
```

This moves the assigned task to `IN_PROGRESS` and sets `startedAt`.

Expected task status:

```text
IN_PROGRESS
```

## 15. Complete Task As Staff

```powershell
@'
{
  "afterPhotoUrl": "https://example.local/manual-after.jpg",
  "staffNote": "Manual flow repair completed."
}
'@ | Set-Content -NoNewline "$WORK\complete-task.json"

$DONE_TASK = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/complete" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $STAFF_TOKEN" `
  --data-binary "@$WORK\complete-task.json" | ConvertFrom-Json

$DONE_TASK | Select-Object id,status,submittedAt,afterPhotoUrl,staffNote
```

This moves the task to `DONE`, sets `submittedAt`, and stores staff completion notes.

Expected task status:

```text
DONE
```

## 16. Verify Staff Cannot Close Task

```powershell
$STAFF_CLOSE_DENIED = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/close" `
  -H "Authorization: Bearer $STAFF_TOKEN" | ConvertFrom-Json

$STAFF_CLOSE_DENIED | Select-Object status,message
```

Expected result:

```text
status  = 403
message = Only overseers can manage tasks
```

## 17. Close Task As Overseer

```powershell
$CLOSED_TASK = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/close" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$CLOSED_TASK | Select-Object id,status,closedAt,reportIds
```

This closes the task as the overseer. Closing a task should mark every linked report as `FIXED`.

Expected task status:

```text
CLOSED
```

## 18. Verify Related Report Becomes Fixed

```powershell
$REPORT_AFTER_CLOSE = curl.exe -s "$BASE/api/reports/$REPORT_ID" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$REPORT_AFTER_CLOSE | Select-Object id,title,status,category

if ($REPORT_AFTER_CLOSE.status -ne "FIXED") {
  throw "Expected report $REPORT_ID to be FIXED, but got $($REPORT_AFTER_CLOSE.status)"
}

"Manual flow passed: report $REPORT_ID is FIXED after closing task $TASK_ID"
```

This reloads the original report and fails loudly if closing the task did not update the report status.

Expected final output:

```text
Manual flow passed: report <report-id> is FIXED after closing task <task-id>
```

## 19. Verify Fixed Report Leaves Open Map Pins

```powershell
$MAP_PINS_AFTER_CLOSE = curl.exe -s "$BASE/api/reports/map?minLat=10.0&minLng=106.0&maxLat=11.0&maxLng=107.0" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" | ConvertFrom-Json

if ($MAP_PINS_AFTER_CLOSE.id -contains $REPORT_ID) {
  throw "Expected fixed report $REPORT_ID to be absent from open map pins"
}

"Manual flow passed: fixed report $REPORT_ID is absent from open map pins"
```

## Troubleshooting

If a request returns `401`, the token variable is probably empty or expired. Re-run the matching login command.

If a request returns `403`, check that the correct role token is being used. Citizens cannot manage tasks, and staff can only start or complete their own assigned tasks.

If a request returns `404` for a new endpoint, the backend process is probably older than the code. Stop Spring Boot and run the `mvn spring-boot:run` command again.

If task creation fails because the report is already linked to another task, create a fresh report and repeat from step 4.
