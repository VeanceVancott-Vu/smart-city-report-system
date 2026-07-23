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


def test_priorities_combines_upvotes_crowd_and_urgency() -> None:
    response = client.post(
        "/ai/priorities",
        json={
            "reports": [
                {
                    "reportId": "urgent-market-leak",
                    "title": "Dangerous water leak",
                    "description": "Vỡ ống gây ngập sâu, cần sửa khẩn cấp.",
                    "category": "WATER_LEAK",
                    "status": "SUBMITTED",
                    "latitude": 10.7769,
                    "longitude": 106.7009,
                    "addressText": "Chợ Bến Thành",
                    "upvoteCount": 7,
                },
                {
                    "reportId": "nearby-light",
                    "title": "Street light is out",
                    "description": "One lamp is not working.",
                    "category": "STREET_LIGHT",
                    "status": "SUBMITTED",
                    "latitude": 10.7770,
                    "longitude": 106.7010,
                    "addressText": "Side street",
                    "upvoteCount": 0,
                },
            ]
        },
    )

    body = response.json()
    urgent = body["results"][0]
    nearby = body["results"][1]

    assert response.status_code == 200
    assert body["modelVersion"] == "priority-lite-v1"
    assert urgent["priorityScore"] > nearby["priorityScore"]
    assert urgent["priorityLevel"] == "critical"
    assert urgent["components"]["upvoteScore"] == 45
    assert urgent["components"]["crowdScore"] > 0
    assert urgent["components"]["urgencyScore"] > 15
    assert len(urgent["reasons"]) == 3


def test_priorities_gives_more_upvotes_a_higher_score() -> None:
    common = {
        "title": "Street light is out",
        "description": "A lamp is not working.",
        "category": "STREET_LIGHT",
        "status": "SUBMITTED",
        "latitude": 10.8,
        "longitude": 106.7,
    }
    response = client.post(
        "/ai/priorities",
        json={
            "reports": [
                {"reportId": "no-votes", "upvoteCount": 0, **common},
                {
                    "reportId": "many-votes",
                    "upvoteCount": 5,
                    **{**common, "latitude": 11.0},
                },
            ]
        },
    )

    results = response.json()["results"]

    assert response.status_code == 200
    assert results[1]["priorityScore"] > results[0]["priorityScore"]


def test_priorities_zeroes_closed_reports() -> None:
    response = client.post(
        "/ai/priorities",
        json={
            "reports": [
                {
                    "reportId": "fixed-report",
                    "title": "Fixed sinkhole",
                    "description": "This urgent sinkhole was repaired.",
                    "category": "ROAD_DAMAGE",
                    "status": "FIXED",
                    "latitude": 10.8,
                    "longitude": 106.7,
                    "addressText": "Busy market",
                    "upvoteCount": 50,
                }
            ]
        },
    )

    result = response.json()["results"][0]

    assert response.status_code == 200
    assert result["priorityScore"] == 0
    assert result["components"] == {
        "upvoteScore": 0,
        "crowdScore": 0,
        "urgencyScore": 0,
    }


def test_priorities_rejects_negative_upvotes() -> None:
    response = client.post(
        "/ai/priorities",
        json={
            "reports": [
                {
                    "reportId": "invalid",
                    "title": "Invalid report",
                    "category": "OTHER",
                    "status": "SUBMITTED",
                    "latitude": 10.8,
                    "longitude": 106.7,
                    "upvoteCount": -1,
                }
            ]
        },
    )

    assert response.status_code == 422
