
import pytest

from atlas_audit.recommendations.catalog import (
    RECOMMENDATION_CATALOG,
    get_recommendation_policy,
)


def test_all_recommendations_have_valid_priorities():
    allowed_priorities = {
        "Low", "Medium", "High", "Critical"
    }

    for policy in RECOMMENDATION_CATALOG.values():
        assert policy.priority in allowed_priorities


def test_all_recommendations_have_positive_deadlines():
    for policy in RECOMMENDATION_CATALOG.values():
        assert policy.remediation_days > 0


@pytest.mark.parametrize(
    "exception_type",
    list(RECOMMENDATION_CATALOG.keys()),
)
def test_recommendation_exists(exception_type):
    policy = get_recommendation_policy(exception_type)

    assert policy.title
    assert policy.description


def test_unknown_exception_is_rejected():
    with pytest.raises(ValueError):
        get_recommendation_policy("UNKNOWN_EXCEPTION")


def test_former_employee_has_critical_recommendation():
    policy = get_recommendation_policy(
        "FORMER_EMPLOYEE_ACTIVE_ACCOUNT"
    )

    assert policy.priority == "Critical"
    assert policy.remediation_days == 1
