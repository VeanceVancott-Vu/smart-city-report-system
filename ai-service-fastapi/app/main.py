from fastapi import FastAPI

from app.models import (
    HealthResponse,
    HotspotRequest,
    GeoJSONFeatureCollection,
    PriorityBatchRequest,
    PriorityBatchResponse,
    VerifyBeforeAfterRequest,
    VerifyBeforeAfterResponse,
)
from app.services import (
    build_mock_hotspots,
    calculate_priority_scores,
    verify_before_after_mock,
)

app = FastAPI(
    title="Smart City AI Service",
    description="Lightweight AI endpoints for smart-city report analysis.",
    version="0.2.0",
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


@app.post("/ai/priorities", response_model=PriorityBatchResponse)
def priorities(request: PriorityBatchRequest) -> PriorityBatchResponse:
    return calculate_priority_scores(request)
