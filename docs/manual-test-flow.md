# Backend Manual Test Flow

This verifies the current core CRUD workflow with real HTTP requests, JWT auth, Flyway tables, and PostgreSQL data.

It intentionally does not test AI, offline sync, OAuth, rate limiting, or stress behavior.

## What This Script Does

The commands below:

1. Log in as a citizen.
2. Upload a before photo.
3. Create a report with the uploaded before photo URL.
4. View the citizen's own reports.
5. Upvote the report and verify `priorityScore`.
6. View open report map pins.
7. Verify the citizen cannot access task APIs.
8. Log in as an overseer.
9. View all reports.
10. List active staff users as overseer.
11. Create a task from the report and assign staff.
12. Log in as staff.
13. View assigned tasks.
14. Start the task.
15. Upload an after photo and complete the task.
16. Verify staff cannot close the task.
17. Use the overseer token again.
18. Close the task.
19. Verify the related report status becomes `FIXED`.
20. Verify the fixed report is no longer returned as an open map pin.

The flow uses the overseer-only staff listing endpoint to capture `assignedStaffId`.

## 1. Start Local Services

Run this from the repository root:

```powershell
docker compose up -d postgres
```

This starts the local PostgreSQL/PostGIS container used by the Spring Boot backend. Make sure `.env` exists first; copy `.env.example` to `.env` for local defaults.

In a second terminal, run:

```powershell
mvn -f backend-spring/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
```

This starts the Spring Boot backend with the `local` profile. Flyway runs automatically on startup, so the database schema is migrated before the app accepts requests.

## 2. Prepare PowerShell Variables

Run these commands in a new PowerShell terminal:

```powershell
$BASE = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://localhost:8080" }
$WORK = Join-Path $env:TEMP "smart-city-manual-flow"
New-Item -ItemType Directory -Force $WORK | Out-Null
```

This stores the base API URL and creates a temporary folder for JSON request bodies. Set `API_BASE_URL` first if your backend is not running on the local default. Using files avoids PowerShell quoting problems with `curl.exe`.

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
$BEFORE_IMAGE = Join-Path $WORK "manual-before.png"
[IO.File]::WriteAllBytes(
  $BEFORE_IMAGE,
  [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=")
)

$BEFORE_UPLOAD = curl.exe -s -X POST "$BASE/api/files/report-before" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" `
  -F "file=@$BEFORE_IMAGE;type=image/png" | ConvertFrom-Json

$BEFORE_PHOTO_URL = $BEFORE_UPLOAD.fileUrl

$CREATE_REPORT_BODY = @'
{
  "title": "Manual flow pothole",
  "description": "Large pothole blocking the right lane.",
  "category": "ROAD_DAMAGE",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "addressText": "District 1 test street",
  "beforePhotoUrl": "__BEFORE_PHOTO_URL__",
  "anonymous": false
}
'@

$CREATE_REPORT_BODY.Replace("__BEFORE_PHOTO_URL__", $BEFORE_PHOTO_URL) |
  Set-Content -NoNewline "$WORK\create-report.json"

$REPORT = curl.exe -s -X POST "$BASE/api/reports" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" `
  --data-binary "@$WORK\create-report.json" | ConvertFrom-Json

$REPORT_ID = $REPORT.id
$REPORT | Select-Object id,title,status,category,upvoteCount,priorityScore
```

This uploads a before photo, then creates a new report as the citizen using the returned `/uploads/report-before/...` URL. New reports should start as `SUBMITTED` with `upvoteCount = 0` and `priorityScore = 0`.

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

## 11. List Active Staff Users For Assignment

```powershell
$STAFF_USERS = curl.exe -s "$BASE/api/users?role=STAFF" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$STAFF_USERS.users | Select-Object id,fullName,email,role

$STAFF = $STAFF_USERS.users | Where-Object { $_.email -eq "staff@test.com" } | Select-Object -First 1
$STAFF_ID = $STAFF.id

if (-not $STAFF_ID) {
  throw "Expected staff@test.com in active staff listing"
}
```

Expected result:

```text
staff@test.com is listed with role STAFF.
No passwordHash field is returned.
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
  "beforePhotoUrl": "$BEFORE_PHOTO_URL",
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

## 13. Login As Staff

```powershell
@'
{ "email": "staff@test.com", "password": "Password123" }
'@ | Set-Content -NoNewline "$WORK\login-staff.json"

$STAFF_LOGIN = curl.exe -s -X POST "$BASE/api/auth/login" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\login-staff.json" | ConvertFrom-Json

$STAFF_TOKEN = $STAFF_LOGIN.token
$STAFF_LOGIN.user
```

This logs in with the seeded development staff user.

Expected user role:

```text
STAFF
```

## 14. View Assigned Tasks As Staff

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

## 15. Start Task As Staff

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

## 16. Complete Task As Staff

```powershell
$AFTER_IMAGE = Join-Path $WORK "manual-after.png"
[IO.File]::WriteAllBytes(
  $AFTER_IMAGE,
  [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=")
)

$AFTER_UPLOAD = curl.exe -s -X POST "$BASE/api/files/task-after" `
  -H "Authorization: Bearer $STAFF_TOKEN" `
  -F "file=@$AFTER_IMAGE;type=image/png" | ConvertFrom-Json

$AFTER_PHOTO_URL = $AFTER_UPLOAD.fileUrl

$COMPLETE_TASK_BODY = @'
{
  "afterPhotoUrl": "__AFTER_PHOTO_URL__",
  "staffNote": "Manual flow repair completed."
}
'@

$COMPLETE_TASK_BODY.Replace("__AFTER_PHOTO_URL__", $AFTER_PHOTO_URL) |
  Set-Content -NoNewline "$WORK\complete-task.json"

$DONE_TASK = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/complete" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $STAFF_TOKEN" `
  --data-binary "@$WORK\complete-task.json" | ConvertFrom-Json

$DONE_TASK | Select-Object id,status,submittedAt,afterPhotoUrl,staffNote
```

This uploads an after photo, moves the task to `DONE`, sets `submittedAt`, and stores staff completion notes.

Expected task status:

```text
DONE
```

## 17. Verify Staff Cannot Close Task

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

## 18. Close Task As Overseer

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

## 19. Verify Related Report Becomes Fixed

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

## 20. Verify Fixed Report Leaves Open Map Pins

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
