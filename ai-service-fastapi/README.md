# Smart City AI Service

FastAPI service for AI-only features in the smart city report system. This service does not connect directly to PostgreSQL or the Spring Boot database. The Spring Boot backend calls these endpoints over HTTP.

## Endpoints

- `GET /health`
- `POST /ai/priorities`
- `POST /ai/verify-before-after`
- `POST /ai/hotspots`

## Priority model

`POST /ai/priorities` uses the CPU-only `priority-lite-v1` model. It has no
downloaded weights, GPU requirement, or paid API dependency. A batch is scored
from three explainable components:

- upvotes: 0-45 points with logarithmic scaling;
- crowded location: 0-25 points from nearby report density and crowded-place
  language in the report/address;
- urgency: 0-30 points from the issue category and urgent hazard language.

The endpoint returns a 0-100 score, a priority level, component scores, and
short reasons. Fixed and cancelled reports return zero. Spring Boot remains the
system of record and decides when to persist returned scores.

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

Calculate priorities by posting a batch to `POST /ai/priorities`:

```json
{
  "reports": [
    {
      "reportId": "R-1",
      "title": "Flooded road",
      "description": "Urgent flooding near the school",
      "category": "DRAINAGE",
      "status": "SUBMITTED",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "addressText": "City school",
      "upvoteCount": 4
    }
  ]
}
```

## Tests

Run tests from this directory:

```bash
pytest
```
