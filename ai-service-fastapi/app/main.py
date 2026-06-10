from fastapi import FastAPI

from app.models import (
    HealthResponse,
    HotspotRequest,
    GeoJSONFeatureCollection,
    VerifyBeforeAfterRequest,
    VerifyBeforeAfterResponse,
)
from app.services import build_mock_hotspots, verify_before_after_mock

app = FastAPI(
    title="Smart City AI Service",
    description="Mock AI endpoints for report photo verification and hotspot prediction.",
    version="0.1.0",
)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="ok", service="ai-service-fastapi")


@app.post("/ai/verify-before-after", response_model=VerifyBeforeAfterResponse)
def verify_before_after(request: VerifyBeforeAfterRequest) -> VerifyBeforeAfterResponse:
    return verify_before_after_mock(request)


@app.post("/ai/hotspots", response_model=GeoJSONFeatureCollection)
def hotspots(request: HotspotRequest) -> GeoJSONFeatureCollection:
    return build_mock_hotspots(request)
