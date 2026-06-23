# Smart City Report System

Smart city citizen issue reporting system with a Flutter frontend, Spring Boot backend, PostgreSQL/PostGIS database, and a Python FastAPI AI service.

## Project Structure

```text
backend-spring/       Spring Boot backend and system of record
ai-service-fastapi/   Python FastAPI AI services
frontend-flutter/     Flutter web and mobile app
docker-compose.yml    Local PostgreSQL/PostGIS database
.env.example          Example local environment variables
```

## Local Setup

1. Install Docker Desktop.
2. Copy `.env.example` to `.env` and adjust local values if needed.
   Existing `.env` files should include `SERVER_PORT`, `JWT_SECRET`, `JWT_EXPIRATION_MINUTES`, `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `APP_FILE_UPLOAD_DIR`, `APP_FILE_MAX_UPLOAD_SIZE`, and `APP_CORS_ALLOWED_ORIGINS`.
   The backend imports `.env` through `spring.config.import`; production should provide these as real environment variables instead of committing secrets.
3. Start PostgreSQL with PostGIS from the repository root:

```bash
docker compose up -d
```

4. Check the database container:

```bash
docker compose ps
```

5. Start the Spring Boot backend:

```bash
mvn -f backend-spring/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
```

The `local` profile runs Flyway migrations and seeds demo users:

```text
citizen@test.com  / Password123
staff@test.com    / Password123
overseer@test.com / Password123
```

Demo users are created only by `DevUserSeeder`, which is active for the `local` and `dev` Spring profiles. A production run must not activate either profile.

6. Run Flutter web:

```bash
cd frontend-flutter
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5200 --dart-define-from-file=config/local_web.json
```

Open the printed web-server URL, usually:

```text
http://127.0.0.1:5200
```

For Android emulator, keep the backend running on your host machine and use:

```bash
cd frontend-flutter
flutter run -d emulator --dart-define-from-file=config/android_emulator.json
```

The Flutter config files set:

```text
config/local_web.json           API_BASE_URL=http://127.0.0.1:8080
config/android_emulator.json    API_BASE_URL=http://10.0.2.2:8080
```

Flutter service classes do not contain a fallback localhost URL. They read only `API_BASE_URL` from `--dart-define` or `--dart-define-from-file`. If you change `SERVER_PORT` or host the backend elsewhere, update the selected config JSON or pass an override.

You can also override directly:

```bash
flutter run --dart-define=API_BASE_URL=http://your-backend-host:8080
```

If Flutter web runs on a different host or port, add that browser origin to `APP_CORS_ALLOWED_ORIGINS` before starting Spring Boot. Native Android emulator traffic uses `10.0.2.2` to reach the host machine backend.

7. Connect with pgAdmin if you want to inspect the database:

```text
Host name/address: 127.0.0.1
Port: 55432
Maintenance database: smart_city
Username: smart_city_user
Password: change_me_for_local_dev
```

8. Stop local services when finished:

```bash
docker compose down
```

To remove the local database volume as well:

```bash
docker compose down -v
```

## Notes

- Flutter must call the Spring Boot backend, not PostgreSQL directly.
- Spring Boot will own auth, roles, reports, tasks, status workflow, map queries, and file metadata.
- FastAPI will be used only for AI features such as before/after photo verification and predictive hotspot generation.
- Secrets and passwords should be supplied through environment variables, not hardcoded in source files.
- JWT secret, JWT expiry, database connection, upload directory, upload max size, and CORS origins are configured through `.env` / environment variables.
- The local database is published on laptop port `55432` to avoid conflicts with PostgreSQL installations already using common ports like `5432` or `5433`.
- Public registration creates `CITIZEN` accounts only. Overseers can create `STAFF` or `OVERSEER` accounts with `POST /api/users`.
- Overseer task assignment loads active staff from `GET /api/users?role=STAFF`.
- Local file upload uses `APP_FILE_UPLOAD_DIR` and `APP_FILE_MAX_UPLOAD_SIZE`. Uploaded files are served from `/uploads/**`, while reports and tasks store only the returned URL string.
- Flutter requires `API_BASE_URL` through `--dart-define` or `--dart-define-from-file`; no API URL fallback is compiled into the app.
- See `docs/manual-test-flow.md` for the full CRUD/auth demo flow.

## Local File Uploads

Authenticated users can upload image files with multipart form data:

```text
POST /api/files/report-before  CITIZEN only
POST /api/files/task-after     STAFF only
```

The multipart field name is `file`. Allowed extensions and image signatures are `jpg`, `jpeg`, `png`, and `webp`. Files larger than `APP_FILE_MAX_UPLOAD_SIZE` are rejected. The response is:

```json
{ "fileUrl": "/uploads/report-before/filename.jpg" }
```

Use that `fileUrl` as `beforePhotoUrl` when creating/updating a report, or as `afterPhotoUrl` when completing a task. Image binary is stored on disk under `APP_FILE_UPLOAD_DIR`, not in PostgreSQL.

## Seed Data

Demo seed users are enabled only when Spring runs with the `local` or `dev` profile:

```bash
mvn -f backend-spring/pom.xml spring-boot:run "-Dspring-boot.run.profiles=local"
```

or by setting:

```env
SPRING_PROFILES_ACTIVE=local
```

To disable seed data, run without `local` or `dev`, for example:

```env
SPRING_PROFILES_ACTIVE=prod
```

Production must not use `local` or `dev`. With `prod`, `DevUserSeeder` is not loaded and demo users are not created.

citizen
vu08112005@gmail.com 
08112005

overseer
overseer@test.com
Password123

staff
staff@test.com
Password123
