# Project Rules for Codex

Project: Smart City Management Platform.

Current build goal:
- Build the core CRUD system first.

Architecture:
- Flutter is the frontend for web and mobile.
- Spring Boot is the main backend and system of record.
- PostgreSQL + PostGIS is the main database.
- Python FastAPI is reserved for AI services later.
- Do not implement AI now.
- Flutter must never connect directly to PostgreSQL.
- Spring Boot handles authentication, roles, reports, tasks, status workflows, map queries, file metadata, and clean API contracts.
- FastAPI will later handle AI features, but it should not be expanded during the CRUD-first phase.

Current scope:
- Implement real email/password login in the Spring Boot backend now.
- Use JWT authentication.
- Use DTOs, services, repositories, and controllers.
- Keep frontend and backend JSON contracts clean and consistent.
- Use local file storage for demo photos unless asked otherwise.

Out of scope for now:
- Do not implement AI features yet.
- Do not implement offline sync yet.
- Do not implement OAuth yet.
- Do not implement rate limiting yet.
- Do not run or design stress testing yet.
- Do not build a complex duplicate detection system yet.

Roles:
- CITIZEN
- STAFF
- OVERSEER

Report status:
- SUBMITTED
- FIXED
- CANCELLED

Task status:
- NEW
- ASSIGNED
- IN_PROGRESS
- DONE
- PENDING_REVIEW
- APPROVED
- CLOSED
- CANCELLED

Priority and duplicates:
- Reports use upvotes to increase priority.
- Store report priority as `priorityScore`.
- Calculate `priorityScore` from upvotes for now.
- Leave room for AI priority later, but do not implement AI priority yet.
- Handle duplicates mainly through map pins and "I see this too" upvotes.
- Do not build complex duplicate detection yet.

Development rules:
- Do not build everything in one huge change.
- Always make small, testable changes.
- Add or update tests when possible.
- Do not hardcode secrets, database passwords, API keys, or JWT secrets.
- Use environment variables for configuration.
- Use Docker Compose for local PostgreSQL/PostGIS.

Before editing:
- Explain the plan briefly.
- List files you will change.
- Then implement.

After editing:
- Tell me what changed.
- Explain all changed files after each step.
- Include how to run and test after each step.
