from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_returns_ok() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "service": "ai-service-fastapi",
    }


def test_verify_before_after_returns_mock_decision() -> None:
    response = client.post(
        "/ai/verify-before-after",
        json={
            "beforeImageUrl": "https://example.test/before.jpg",
            "afterImageUrl": "https://example.test/after.jpg",
        },
    )

    body = response.json()
    assert response.status_code == 200
    assert body["decision"] == "verified"
    assert body["confidenceScore"] == 0.87
    assert "explanation" in body


def test_verify_before_after_flags_identical_urls() -> None:
    image_url = "https://example.test/same.jpg"

    response = client.post(
        "/ai/verify-before-after",
        json={
            "beforeImageUrl": image_url,
            "afterImageUrl": image_url,
        },
    )

    body = response.json()
    assert response.status_code == 200
    assert body["decision"] == "needs_review"
    assert body["confidenceScore"] == 0.34


def test_hotspots_returns_geojson_feature_collection() -> None:
    response = client.post(
        "/ai/hotspots",
        json={
            "reports": [
                {
                    "reportId": "R-1",
                    "category": "road",
                    "status": "resolved",
                    "latitude": 10.7769,
                    "longitude": 106.7009,
                    "severity": 4,
                },
                {
                    "reportId": "R-2",
                    "category": "lighting",
                    "status": "open",
                    "latitude": 10.823,
                    "longitude": 106.6296,
                    "severity": 2,
                },
            ]
        },
    )

    body = response.json()
    assert response.status_code == 200
    assert body["type"] == "FeatureCollection"
    assert len(body["features"]) == 2
    assert body["features"][0]["type"] == "Feature"
    assert body["features"][0]["geometry"]["type"] == "Point"
    assert body["features"][0]["properties"]["source"] == "mock"
