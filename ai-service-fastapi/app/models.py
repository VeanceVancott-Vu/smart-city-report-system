from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class CamelModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class HealthResponse(CamelModel):
    status: str
    service: str


class VerifyBeforeAfterRequest(CamelModel):
    before_image_url: str = Field(..., alias="beforeImageUrl", min_length=1)
    after_image_url: str = Field(..., alias="afterImageUrl", min_length=1)


class VerifyBeforeAfterResponse(CamelModel):
    confidence_score: float = Field(..., alias="confidenceScore", ge=0.0, le=1.0)
    decision: Literal["verified", "needs_review", "rejected"]
    explanation: str


class ReportHistoryItem(CamelModel):
    report_id: str | None = Field(default=None, alias="reportId")
    category: str | None = None
    status: str | None = None
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    created_at: datetime | None = Field(default=None, alias="createdAt")
    severity: int | None = Field(default=None, ge=1, le=5)


class HotspotRequest(CamelModel):
    reports: list[ReportHistoryItem] = Field(default_factory=list)


class GeoJSONPointGeometry(CamelModel):
    type: Literal["Point"] = "Point"
    coordinates: tuple[float, float]


class GeoJSONFeature(CamelModel):
    type: Literal["Feature"] = "Feature"
    geometry: GeoJSONPointGeometry
    properties: dict[str, Any]


class GeoJSONFeatureCollection(CamelModel):
    type: Literal["FeatureCollection"] = "FeatureCollection"
    features: list[GeoJSONFeature]
