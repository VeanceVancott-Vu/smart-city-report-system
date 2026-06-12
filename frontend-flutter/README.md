# Smart City Report Frontend

Flutter web and mobile client for the Smart City Report System.

## Structure

```text
lib/src/app.dart                         App shell and route table
lib/src/core/routing/                    Named route constants
lib/src/core/services/                   Shared API service base
lib/src/features/auth/                   Login placeholder
lib/src/features/reports/                Citizen report list and create flow
lib/src/features/map/                    Overseer map placeholder
lib/src/features/tasks/                  Staff task list placeholder
```

Real backend calls go through the Spring Boot API, not PostgreSQL.

## Run

For local web with the Spring Boot backend on `127.0.0.1:8080`:

```bash
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5200 --dart-define-from-file=config/local_web.json
```

Open `http://127.0.0.1:5200` after the web server starts. The fixed port
matches the backend CORS allowlist.

For Android emulator:

```bash
flutter run -d android --dart-define-from-file=config/android_emulator.json
```

You can also override the API URL directly:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5200 --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

## Test

```bash
flutter analyze
flutter test
```
