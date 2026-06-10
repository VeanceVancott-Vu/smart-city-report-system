from collections import Counter

from app.models import (
    GeoJSONFeature,
    GeoJSONFeatureCollection,
    GeoJSONPointGeometry,
    HotspotRequest,
    VerifyBeforeAfterRequest,
    VerifyBeforeAfterResponse,
)


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
