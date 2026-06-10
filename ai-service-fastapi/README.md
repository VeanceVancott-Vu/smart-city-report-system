# Smart City AI Service

FastAPI service for AI-only features in the smart city report system. This service does not connect directly to PostgreSQL or the Spring Boot database. The Spring Boot backend should call these endpoints over HTTP.

## Endpoints

- `GET /health`
- `POST /ai/verify-before-after`
- `POST /ai/hotspots`

## Local Setup

Create and activate a virtual environment:

```bash
python -m venv .venv
.venv\Scripts\activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the service:

```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Open the API docs at:

```text
http://127.0.0.1:8000/docs
```

## Example Requests

Verify before and after photos:

```bash
curl -X POST http://127.0.0.1:8000/ai/verify-before-after ^
  -H "Content-Type: application/json" ^
  -d "{\"beforeImageUrl\":\"https://example.test/before.jpg\",\"afterImageUrl\":\"https://example.test/after.jpg\"}"
```

Generate mock hotspots:

```bash
curl -X POST http://127.0.0.1:8000/ai/hotspots ^
  -H "Content-Type: application/json" ^
  -d "{\"reports\":[{\"reportId\":\"R-1\",\"category\":\"road\",\"status\":\"open\",\"latitude\":10.7769,\"longitude\":106.7009,\"severity\":4}]}"
```

## Tests

Run tests from this directory:

```bash
pytest
```
