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

The first version uses mock API service classes only. Real backend calls should go through the Spring Boot API, not PostgreSQL.

## Run

```bash
flutter pub get
flutter run -d chrome
```

For Android:

```bash
flutter run -d android
```

## Test

```bash
flutter analyze
flutter test
```
