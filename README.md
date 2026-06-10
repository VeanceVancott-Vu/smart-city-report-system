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

6. Run Flutter web:

```bash
cd frontend-flutter
flutter pub get
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5200 --dart-define=API_BASE_URL=http://localhost:8080
```

Open the printed web-server URL, usually:

```text
http://127.0.0.1:5200
```

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
- The local database is published on laptop port `55432` to avoid conflicts with PostgreSQL installations already using common ports like `5432` or `5433`.
- Public registration creates `CITIZEN` accounts only. Staff and overseer accounts are seeded for local demos until user management is added.
- See `docs/manual-test-flow.md` for the full CRUD/auth demo flow.
