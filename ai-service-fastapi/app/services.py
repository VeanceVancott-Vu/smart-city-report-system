from collections import Counter
from math import asin, cos, log2, radians, sin, sqrt
import unicodedata

from app.models import (
    GeoJSONFeature,
    GeoJSONFeatureCollection,
    GeoJSONPointGeometry,
    HotspotRequest,
    PriorityBatchRequest,
    PriorityBatchResponse,
    PriorityReportItem,
    PriorityScoreComponents,
    PriorityScoreResult,
    VerifyBeforeAfterRequest,
    VerifyBeforeAfterResponse,
)

PRIORITY_MODEL_VERSION = "priority-lite-v1"
_EARTH_RADIUS_METERS = 6_371_000
_NEARBY_REPORT_RADIUS_METERS = 300
_CLOSED_STATUSES = {"FIXED", "CANCELLED", "CLOSED"}

_CATEGORY_URGENCY = {
    "ROAD_DAMAGE": 14,
    "STREET_LIGHT": 8,
    "GARBAGE": 7,
    "WATER_LEAK": 15,
    "DRAINAGE": 13,
    "TRAFFIC_SIGN": 12,
    "TREE_BLOCKAGE": 14,
    "OTHER": 6,
}

_CROWD_TERMS = {
    "airport",
    "ben xe",
    "benh vien",
    "bus station",
    "cho",
    "cong vien",
    "hospital",
    "intersection",
    "market",
    "nha ga",
    "park",
    "school",
    "shopping mall",
    "station",
    "truong hoc",
    "university",
}

_HIGH_URGENCY_TERMS = {
    "bridge collapse",
    "chay",
    "chemical spill",
    "dien giat",
    "electrocution",
    "explosion",
    "fire",
    "gas leak",
    "hoa hoan",
    "ngap sau",
    "sap",
    "sinkhole",
    "song dien",
    "vo ong",
}

_MEDIUM_URGENCY_TERMS = {
    "blocked road",
    "can fix gap",
    "danger",
    "dangerous",
    "downed tree",
    "emergency",
    "flood",
    "gap",
    "immediately",
    "khan cap",
    "lo sau",
    "mat an toan",
    "nguy hiem",
    "urgent",
}


def verify_before_after_mock(
    request: VerifyBeforeAfterRequest,
) -> VerifyBeforeAfterResponse:
    """Return a deterministic mock decision until real image comparison is added."""
    same_reference = request.before_image_url == request.after_image_url

    if same_reference:
        return VerifyBeforeAfterResponse(
            confidence_score=0.34,
            decision="needs_review",
            explanation=(
                "Mock check found identical before and after image references, "
                "so staff review is recommended."
            ),
        )

    return VerifyBeforeAfterResponse(
        confidence_score=0.87,
        decision="verified",
        explanation=(
            "Mock check assumes the after image shows sufficient change compared "
            "with the before image. No image bytes were downloaded or analyzed."
        ),
    )


def build_mock_hotspots(request: HotspotRequest) -> GeoJSONFeatureCollection:
    """Return mock GeoJSON hotspots without reading from the Spring database."""
    category_counts = Counter(
        report.category for report in request.reports if report.category
    )
    total_reports = len(request.reports)

    features = [
        GeoJSONFeature(
            geometry=GeoJSONPointGeometry(coordinates=(106.70098, 10.77689)),
            properties={
                "clusterId": "mock-district-1",
                "riskLevel": "high",
                "reportCount": max(total_reports, 12),
                "topCategories": _top_categories(category_counts, ["road", "lighting"]),
                "source": "mock",
            },
        ),
        GeoJSONFeature(
            geometry=GeoJSONPointGeometry(coordinates=(106.62966, 10.82302)),
            properties={
                "clusterId": "mock-district-2",
                "riskLevel": "medium",
                "reportCount": max(total_reports // 2, 6),
                "topCategories": _top_categories(category_counts, ["drainage", "waste"]),
                "source": "mock",
            },
        ),
    ]

    return GeoJSONFeatureCollection(features=features)


def _top_categories(category_counts: Counter[str], fallback: list[str]) -> list[str]:
    top_categories = [category for category, _ in category_counts.most_common(2)]
    return top_categories or fallback


def calculate_priority_scores(
    request: PriorityBatchRequest,
) -> PriorityBatchResponse:
    """Score reports with a small deterministic model that needs no ML weights."""
    results = [
        _score_priority(report, request.reports)
        for report in request.reports
    ]
    return PriorityBatchResponse(
        model_version=PRIORITY_MODEL_VERSION,
        results=results,
    )


def _score_priority(
    report: PriorityReportItem,
    all_reports: list[PriorityReportItem],
) -> PriorityScoreResult:
    if report.status.upper() in _CLOSED_STATUSES:
        return PriorityScoreResult(
            report_id=report.report_id,
            priority_score=0,
            priority_level="low",
            components=PriorityScoreComponents(
                upvote_score=0,
                crowd_score=0,
                urgency_score=0,
            ),
            reasons=["Report is already closed or cancelled."],
        )

    upvote_score = min(45, round(15 * log2(report.upvote_count + 1)))
    nearby_count = _nearby_report_count(report, all_reports)
    text = _normalise_text(
        " ".join(
            part
            for part in (report.title, report.description, report.address_text)
            if part
        )
    )
    crowded_place = _contains_any(text, _CROWD_TERMS)
    density_score = min(15, round(5 * log2(nearby_count + 1)))
    crowd_score = min(25, density_score + (10 if crowded_place else 0))

    urgency_score = _CATEGORY_URGENCY.get(report.category.upper(), 6)
    if _contains_any(text, _HIGH_URGENCY_TERMS):
        urgency_score = min(30, urgency_score + 16)
    elif _contains_any(text, _MEDIUM_URGENCY_TERMS):
        urgency_score = min(30, urgency_score + 9)

    priority_score = min(100, upvote_score + crowd_score + urgency_score)
    reasons = [
        f"{report.upvote_count} upvote(s) contributed {upvote_score} points.",
        (
            f"{nearby_count} nearby report(s)"
            + (" and a crowded-place signal" if crowded_place else "")
            + f" contributed {crowd_score} points."
        ),
        (
            f"Category and urgency language contributed "
            f"{urgency_score} points."
        ),
    ]

    return PriorityScoreResult(
        report_id=report.report_id,
        priority_score=priority_score,
        priority_level=_priority_level(priority_score),
        components=PriorityScoreComponents(
            upvote_score=upvote_score,
            crowd_score=crowd_score,
            urgency_score=urgency_score,
        ),
        reasons=reasons,
    )


def _nearby_report_count(
    report: PriorityReportItem,
    all_reports: list[PriorityReportItem],
) -> int:
    return sum(
        1
        for other in all_reports
        if other.report_id != report.report_id
        and other.status.upper() not in _CLOSED_STATUSES
        and _distance_meters(report, other) <= _NEARBY_REPORT_RADIUS_METERS
    )


def _distance_meters(
    first: PriorityReportItem,
    second: PriorityReportItem,
) -> float:
    first_latitude = radians(first.latitude)
    second_latitude = radians(second.latitude)
    latitude_delta = second_latitude - first_latitude
    longitude_delta = radians(second.longitude - first.longitude)
    haversine = (
        sin(latitude_delta / 2) ** 2
        + cos(first_latitude)
        * cos(second_latitude)
        * sin(longitude_delta / 2) ** 2
    )
    return 2 * _EARTH_RADIUS_METERS * asin(sqrt(haversine))


def _normalise_text(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    ascii_characters = (
        character
        for character in decomposed
        if not unicodedata.combining(character)
    )
    words_only = (
        character if character.isalnum() else " "
        for character in ascii_characters
    )
    return " ".join("".join(words_only).split())


def _contains_any(text: str, terms: set[str]) -> bool:
    padded_text = f" {text} "
    return any(f" {term} " in padded_text for term in terms)


def _priority_level(score: int) -> str:
    if score >= 75:
        return "critical"
    if score >= 50:
        return "high"
    if score >= 25:
        return "medium"
    return "low"
