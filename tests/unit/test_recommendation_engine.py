
import pytest

from atlas_audit.recommendations.engine import (
    get_remediation_policy,
)


@pytest.mark.parametrize(
    "risk_level, expected_priority, expected_days",
    [
        ("Critical", "Critical", 1),
        ("High", "High", 7),
        ("Medium", "Medium", 30),
        ("Low", "Low", 60),
    ],
)
def test_remediation_policy(
    risk_level,
    expected_priority,
    expected_days,
):
    policy = get_remediation_policy(risk_level)

    assert policy["priority"] == expected_priority
    assert policy["days"] == expected_days


def test_unknown_risk_level_is_rejected():
    with pytest.raises(ValueError):
        get_remediation_policy("Unknown")


def test_remediation_policy_has_positive_deadlines():
    for risk_level in ("Critical", "High", "Medium", "Low"):
        policy = get_remediation_policy(risk_level)

        assert policy["days"] > 0
