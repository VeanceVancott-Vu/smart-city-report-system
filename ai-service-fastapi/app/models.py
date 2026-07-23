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


class PriorityReportItem(CamelModel):
    report_id: str = Field(..., alias="reportId", min_length=1)
    title: str = Field(..., min_length=1)
    description: str = Field(default="")
    category: str = Field(..., min_length=1)
    status: str = Field(..., min_length=1)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    address_text: str | None = Field(default=None, alias="addressText")
    upvote_count: int = Field(default=0, alias="upvoteCount", ge=0)
    created_at: datetime | None = Field(default=None, alias="createdAt")


class PriorityBatchRequest(CamelModel):
    reports: list[PriorityReportItem] = Field(default_factory=list, max_length=500)


class PriorityScoreComponents(CamelModel):
    upvote_score: int = Field(..., alias="upvoteScore", ge=0, le=45)
    crowd_score: int = Field(..., alias="crowdScore", ge=0, le=25)
    urgency_score: int = Field(..., alias="urgencyScore", ge=0, le=30)


class PriorityScoreResult(CamelModel):
    report_id: str = Field(..., alias="reportId")
    priority_score: int = Field(..., alias="priorityScore", ge=0, le=100)
    priority_level: Literal["low", "medium", "high", "critical"] = Field(
        ...,
        alias="priorityLevel",
    )
    components: PriorityScoreComponents
    reasons: list[str]


class PriorityBatchResponse(CamelModel):
    model_version: str = Field(..., alias="modelVersion")
    results: list[PriorityScoreResult]
