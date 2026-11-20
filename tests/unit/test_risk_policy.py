
import pytest

from atlas_audit.risk.policy import (
    calculate_likelihood,
    assess_finding_policy,
)


@pytest.mark.parametrize(
    "detection_count, expected",
    [
        (1, 2),
        (2, 3),
        (3, 3),
        (4, 4),
        (5, 4),
        (6, 5),
        (10, 5),
    ],
)
def test_likelihood_persistence_mapping(detection_count, expected):
    score, _ = calculate_likelihood(detection_count)
    assert score == expected


def test_unauthorized_privileged_access_impact():
    impact, likelihood, rationale = assess_finding_policy(
        "NOT_AUTHORIZED",
        2,
    )

    assert impact == 5
    assert likelihood == 3
    assert "auditor review" in rationale


def test_unknown_exception_type_is_rejected():
    with pytest.raises(ValueError):
        assess_finding_policy("UNKNOWN_EXCEPTION", 1)


def test_zero_detection_count_is_rejected():
    with pytest.raises(ValueError):
        calculate_likelihood(0)


def test_boolean_detection_count_is_rejected():
    with pytest.raises(TypeError):
        calculate_likelihood(True)
