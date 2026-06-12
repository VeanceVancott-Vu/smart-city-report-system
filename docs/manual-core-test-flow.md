# Manual Core Test Flow

This manual test verifies the core CRUD/auth flow with real HTTP requests, JWT auth, role checks, file uploads, reports, tasks, and upvotes.

It intentionally does not test AI, offline sync, OAuth, rate limiting, or stress behavior.

## Preconditions

Start PostgreSQL and the Spring Boot backend from the repository root:

```powershell
docker compose up -d postgres
mvn -f backend-spring/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
```

The `local` profile seeds:

```text
citizen@test.com / Password123
staff@test.com / Password123
overseer@test.com / Password123
```

This flow creates its own public citizen and staff user, so it can be repeated without reusing old test accounts.

## Prepare Variables

```powershell
$BASE = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { "http://localhost:8080" }
$RUN_ID = Get-Date -Format "yyyyMMddHHmmss"
$WORK = Join-Path $env:TEMP "smart-city-core-flow-$RUN_ID"
New-Item -ItemType Directory -Force $WORK | Out-Null

$CITIZEN_EMAIL = "citizen.manual.$RUN_ID@test.com"
$STAFF_EMAIL = "staff.manual.$RUN_ID@test.com"
$PASSWORD = "Password123"
```

## 1. Public Register Creates Citizen Only

This intentionally sends a `role` field. Public registration must ignore it and create a `CITIZEN`.

```powershell
@"
{
  "fullName": "Manual Citizen $RUN_ID",
  "email": "$CITIZEN_EMAIL",
  "password": "$PASSWORD",
  "role": "OVERSEER"
}
"@ | Set-Content -NoNewline "$WORK\register-citizen.json"

$REGISTER = curl.exe -s -X POST "$BASE/api/auth/register" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\register-citizen.json" | ConvertFrom-Json

$REGISTER.user | Select-Object id,fullName,email,role

if ($REGISTER.user.role -ne "CITIZEN") {
  throw "Expected public registration to create CITIZEN, got $($REGISTER.user.role)"
}
```

## 2. Login As Citizen

```powershell
@"
{
  "email": "$CITIZEN_EMAIL",
  "password": "$PASSWORD"
}
"@ | Set-Content -NoNewline "$WORK\login-citizen.json"

$CITIZEN_LOGIN = curl.exe -s -X POST "$BASE/api/auth/login" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\login-citizen.json" | ConvertFrom-Json

$CITIZEN_TOKEN = $CITIZEN_LOGIN.token
$CITIZEN_LOGIN.user | Select-Object id,email,role

if ($CITIZEN_LOGIN.user.role -ne "CITIZEN") {
  throw "Expected citizen login role CITIZEN, got $($CITIZEN_LOGIN.user.role)"
}
```

## 3. Citizen Uploads Before Photo

```powershell
$BEFORE_IMAGE = Join-Path $WORK "before.png"
[IO.File]::WriteAllBytes(
  $BEFORE_IMAGE,
  [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=")
)

$BEFORE_UPLOAD = curl.exe -s -X POST "$BASE/api/files/report-before" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" `
  -F "file=@$BEFORE_IMAGE;type=image/png" | ConvertFrom-Json

$BEFORE_PHOTO_URL = $BEFORE_UPLOAD.fileUrl
$BEFORE_UPLOAD

if (-not $BEFORE_PHOTO_URL.StartsWith("/uploads/report-before/")) {
  throw "Expected report-before upload URL, got $BEFORE_PHOTO_URL"
}
```

## 4. Citizen Creates Report

```powershell
$CREATE_REPORT_BODY = @'
{
  "title": "Manual core pothole",
  "description": "Large pothole blocking the right lane.",
  "category": "ROAD_DAMAGE",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "addressText": "District 1 core test street",
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

if ($REPORT.status -ne "SUBMITTED") {
  throw "Expected new report status SUBMITTED, got $($REPORT.status)"
}
```

## 5. Citizen Sees Report In My Reports

```powershell
$MY_REPORTS = curl.exe -s "$BASE/api/reports?mine=true" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" | ConvertFrom-Json

$MY_REPORTS.reports | Select-Object id,title,status

if (-not ($MY_REPORTS.reports.id -contains $REPORT_ID)) {
  throw "Expected report $REPORT_ID in My Reports"
}
```

## 6. Citizen Cannot Mark Report Fixed

```powershell
$CITIZEN_FIX_STATUS = curl.exe -s -o "$WORK\citizen-fix-denied.json" -w "%{http_code}" `
  -X PATCH "$BASE/api/reports/$REPORT_ID/fix" `
  -H "Authorization: Bearer $CITIZEN_TOKEN"

$CITIZEN_FIX_DENIED = Get-Content "$WORK\citizen-fix-denied.json" | ConvertFrom-Json
$CITIZEN_FIX_DENIED | Select-Object status,message

if ($CITIZEN_FIX_STATUS -ne "403") {
  throw "Expected citizen fix attempt to return 403, got $CITIZEN_FIX_STATUS"
}

$REPORT_AFTER_DENIED_FIX = curl.exe -s "$BASE/api/reports/$REPORT_ID" `
  -H "Authorization: Bearer $CITIZEN_TOKEN" | ConvertFrom-Json

if ($REPORT_AFTER_DENIED_FIX.status -ne "SUBMITTED") {
  throw "Expected report to remain SUBMITTED after denied fix, got $($REPORT_AFTER_DENIED_FIX.status)"
}
```

## 7. Login As Overseer

```powershell
@'
{ "email": "overseer@test.com", "password": "Password123" }
'@ | Set-Content -NoNewline "$WORK\login-overseer.json"

$OVERSEER_LOGIN = curl.exe -s -X POST "$BASE/api/auth/login" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\login-overseer.json" | ConvertFrom-Json

$OVERSEER_TOKEN = $OVERSEER_LOGIN.token
$OVERSEER_LOGIN.user | Select-Object id,email,role

if ($OVERSEER_LOGIN.user.role -ne "OVERSEER") {
  throw "Expected overseer login role OVERSEER, got $($OVERSEER_LOGIN.user.role)"
}
```

## 8. Overseer Creates Staff User

```powershell
@"
{
  "fullName": "Manual Staff $RUN_ID",
  "email": "$STAFF_EMAIL",
  "password": "$PASSWORD",
  "role": "STAFF"
}
"@ | Set-Content -NoNewline "$WORK\create-staff.json"

$CREATED_STAFF = curl.exe -s -X POST "$BASE/api/users" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" `
  --data-binary "@$WORK\create-staff.json" | ConvertFrom-Json

$CREATED_STAFF | Select-Object id,fullName,email,role

if ($CREATED_STAFF.role -ne "STAFF") {
  throw "Expected created user role STAFF, got $($CREATED_STAFF.role)"
}
```

## 9. Overseer Lists Staff Users

```powershell
$STAFF_USERS = curl.exe -s "$BASE/api/users?role=STAFF" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$STAFF_USERS.users | Select-Object id,fullName,email,role

$STAFF = $STAFF_USERS.users | Where-Object { $_.email -eq $STAFF_EMAIL } | Select-Object -First 1
$STAFF_ID = $STAFF.id

if (-not $STAFF_ID) {
  throw "Expected $STAFF_EMAIL in active staff listing"
}
if ($STAFF.PSObject.Properties.Name -contains "passwordHash") {
  throw "Staff listing must not return passwordHash"
}
```

## 10. Overseer Sees All Reports

```powershell
$ALL_REPORTS = curl.exe -s "$BASE/api/reports" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$ALL_REPORTS.reports | Select-Object id,title,status

if (-not ($ALL_REPORTS.reports.id -contains $REPORT_ID)) {
  throw "Expected overseer to see report $REPORT_ID"
}
```

## 11. Overseer Creates Task From Report And Assigns Staff

```powershell
@"
{
  "title": "Repair manual core pothole",
  "description": "Repair the pothole reported in the manual core flow.",
  "category": "ROAD_DAMAGE",
  "latitude": 10.762622,
  "longitude": 106.660172,
  "addressText": "District 1 core test street",
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
$TASK | Select-Object id,title,status,reportIds
$TASK.assignedStaff

if ($TASK.status -ne "ASSIGNED") {
  throw "Expected created task status ASSIGNED, got $($TASK.status)"
}
```

## 12. Login As Staff

```powershell
@"
{
  "email": "$STAFF_EMAIL",
  "password": "$PASSWORD"
}
"@ | Set-Content -NoNewline "$WORK\login-staff.json"

$STAFF_LOGIN = curl.exe -s -X POST "$BASE/api/auth/login" `
  -H "Content-Type: application/json" `
  --data-binary "@$WORK\login-staff.json" | ConvertFrom-Json

$STAFF_TOKEN = $STAFF_LOGIN.token
$STAFF_LOGIN.user | Select-Object id,email,role

if ($STAFF_LOGIN.user.role -ne "STAFF") {
  throw "Expected staff login role STAFF, got $($STAFF_LOGIN.user.role)"
}
```

## 13. Staff Sees Assigned Task

```powershell
$STAFF_TASKS = curl.exe -s "$BASE/api/tasks?assignedToMe=true" `
  -H "Authorization: Bearer $STAFF_TOKEN" | ConvertFrom-Json

$STAFF_TASKS.tasks | Select-Object id,title,status

if (-not ($STAFF_TASKS.tasks.id -contains $TASK_ID)) {
  throw "Expected staff to see assigned task $TASK_ID"
}
```

## 14. Staff Starts Task

```powershell
$STARTED_TASK = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/start" `
  -H "Authorization: Bearer $STAFF_TOKEN" | ConvertFrom-Json

$STARTED_TASK | Select-Object id,status,startedAt

if ($STARTED_TASK.status -ne "IN_PROGRESS") {
  throw "Expected task status IN_PROGRESS, got $($STARTED_TASK.status)"
}
```

## 15. Staff Uploads After Photo

```powershell
$AFTER_IMAGE = Join-Path $WORK "after.png"
[IO.File]::WriteAllBytes(
  $AFTER_IMAGE,
  [Convert]::FromBase64String("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=")
)

$AFTER_UPLOAD = curl.exe -s -X POST "$BASE/api/files/task-after" `
  -H "Authorization: Bearer $STAFF_TOKEN" `
  -F "file=@$AFTER_IMAGE;type=image/png" | ConvertFrom-Json

$AFTER_PHOTO_URL = $AFTER_UPLOAD.fileUrl
$AFTER_UPLOAD

if (-not $AFTER_PHOTO_URL.StartsWith("/uploads/task-after/")) {
  throw "Expected task-after upload URL, got $AFTER_PHOTO_URL"
}
```

## 16. Staff Completes Task

```powershell
$COMPLETE_TASK_BODY = @'
{
  "afterPhotoUrl": "__AFTER_PHOTO_URL__",
  "staffNote": "Manual core flow repair completed."
}
'@

$COMPLETE_TASK_BODY.Replace("__AFTER_PHOTO_URL__", $AFTER_PHOTO_URL) |
  Set-Content -NoNewline "$WORK\complete-task.json"

$DONE_TASK = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/complete" `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $STAFF_TOKEN" `
  --data-binary "@$WORK\complete-task.json" | ConvertFrom-Json

$DONE_TASK | Select-Object id,status,submittedAt,afterPhotoUrl,staffNote,aiConfidenceScore,aiDecision

if ($DONE_TASK.status -ne "DONE") {
  throw "Expected task status DONE, got $($DONE_TASK.status)"
}
if (-not $DONE_TASK.submittedAt) {
  throw "Expected submittedAt to be set"
}
if ($DONE_TASK.aiConfidenceScore -ne $null -or $DONE_TASK.aiDecision -ne $null) {
  throw "Expected AI fields to remain null"
}
```

## 17. Staff Cannot Close Task

```powershell
$STAFF_CLOSE_STATUS = curl.exe -s -o "$WORK\staff-close-denied.json" -w "%{http_code}" `
  -X PATCH "$BASE/api/tasks/$TASK_ID/close" `
  -H "Authorization: Bearer $STAFF_TOKEN"

$STAFF_CLOSE_DENIED = Get-Content "$WORK\staff-close-denied.json" | ConvertFrom-Json
$STAFF_CLOSE_DENIED | Select-Object status,message

if ($STAFF_CLOSE_STATUS -ne "403") {
  throw "Expected staff close attempt to return 403, got $STAFF_CLOSE_STATUS"
}
```

## 18. Overseer Closes Task

```powershell
$CLOSED_TASK = curl.exe -s -X PATCH "$BASE/api/tasks/$TASK_ID/close" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$CLOSED_TASK | Select-Object id,status,closedAt,reportIds

if ($CLOSED_TASK.status -ne "CLOSED") {
  throw "Expected task status CLOSED, got $($CLOSED_TASK.status)"
}
```

## 19. Related Report Becomes Fixed

```powershell
$FIXED_REPORT = curl.exe -s "$BASE/api/reports/$REPORT_ID" `
  -H "Authorization: Bearer $OVERSEER_TOKEN" | ConvertFrom-Json

$FIXED_REPORT | Select-Object id,title,status

if ($FIXED_REPORT.status -ne "FIXED") {
  throw "Expected related report status FIXED, got $($FIXED_REPORT.status)"
}
```

## 20. Fixed Report Cannot Be Upvoted

```powershell
$FIXED_UPVOTE_STATUS = curl.exe -s -o "$WORK\fixed-upvote-denied.json" -w "%{http_code}" `
  -X POST "$BASE/api/reports/$REPORT_ID/upvote" `
  -H "Authorization: Bearer $CITIZEN_TOKEN"

$FIXED_UPVOTE_DENIED = Get-Content "$WORK\fixed-upvote-denied.json" | ConvertFrom-Json
$FIXED_UPVOTE_DENIED | Select-Object status,message

if ($FIXED_UPVOTE_STATUS -ne "400") {
  throw "Expected fixed report upvote attempt to return 400, got $FIXED_UPVOTE_STATUS"
}
if ($FIXED_UPVOTE_DENIED.message -ne "Fixed reports cannot be upvoted") {
  throw "Expected fixed upvote error message, got '$($FIXED_UPVOTE_DENIED.message)'"
}

"Manual core flow passed for report $REPORT_ID and task $TASK_ID"
```

## Troubleshooting

If registration fails with duplicate email, rerun step 1 to get a new `$RUN_ID`.

If login as overseer fails, make sure Spring Boot is running with the `local` profile so `overseer@test.com / Password123` is seeded.

If a request returns `401`, the matching token variable is empty or expired. Rerun that role's login step.

If a request returns `403`, check that the expected role token is being used. Citizens cannot fix reports, staff cannot close tasks, and overseer-only user creation requires the overseer token.

If file upload fails, check `APP_FILE_UPLOAD_DIR`, `APP_FILE_MAX_UPLOAD_SIZE`, and that the request uses multipart field name `file`.
