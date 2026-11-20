
import pytest

from atlas_audit.risk import (
    calculate_risk_score,
    classify_risk,
    assess_risk,
    RiskAssessment,
)


# ============================================================
# 1. RISK SCORE TESTS
# ============================================================

@pytest.mark.parametrize(
    "impact, likelihood, expected",
    [
        (1, 1, 1),
        (2, 3, 6),
        (3, 3, 9),
        (4, 4, 16),
        (5, 4, 20),
        (5, 5, 25),
    ],
)
def test_calculate_risk_score(impact, likelihood, expected):
    assert calculate_risk_score(impact, likelihood) == expected


# ============================================================
# 2. RISK CLASSIFICATION TESTS
# ============================================================

@pytest.mark.parametrize(
    "score, expected",
    [
        (1, "Low"),
        (4, "Low"),
        (5, "Medium"),
        (9, "Medium"),
        (10, "High"),
        (16, "High"),
        (17, "Critical"),
        (25, "Critical"),
    ],
)
def test_classify_risk(score, expected):
    assert classify_risk(score) == expected


# ============================================================
# 3. INPUT VALIDATION TESTS
# ============================================================

@pytest.mark.parametrize(
    "impact, likelihood",
    [
        (0, 3),
        (6, 3),
        (3, 0),
        (3, 6),
    ],
)
def test_invalid_risk_dimensions(impact, likelihood):
    with pytest.raises(ValueError):
        calculate_risk_score(impact, likelihood)


@pytest.mark.parametrize(
    "impact, likelihood",
    [
        (2.5, 3),
        (3, 2.5),
        ("4", 3),
        (3, "4"),
        (True, 3),
    ],
)
def test_non_integer_risk_dimensions(impact, likelihood):
    with pytest.raises(TypeError):
        calculate_risk_score(impact, likelihood)


@pytest.mark.parametrize("score", [0, 26, -1])
def test_invalid_risk_score(score):
    with pytest.raises(ValueError):
        classify_risk(score)


def test_non_integer_risk_score():
    with pytest.raises(TypeError):
        classify_risk(10.5)


# ============================================================
# 4. COMPLETE ASSESSMENT TESTS
# ============================================================

def test_complete_risk_assessment():

    result = assess_risk(
        impact=5,
        likelihood=4,
    )

    assert isinstance(result, RiskAssessment)
    assert result.impact == 5
    assert result.likelihood == 4
    assert result.risk_score == 20
    assert result.risk_level == "Critical"


def test_medium_risk_assessment():

    result = assess_risk(
        impact=3,
        likelihood=2,
    )

    assert result.risk_score == 6
    assert result.risk_level == "Medium"


def test_risk_assessment_is_immutable():

    result = assess_risk(
        impact=5,
        likelihood=5,
    )

    with pytest.raises(AttributeError):
        result.risk_score = 10
