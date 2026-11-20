
"""Initial, configurable risk policy for Atlas Audit Analytics."""

from dataclasses import dataclass


@dataclass(frozen=True)
class ImpactPolicy:
    score: int
    rationale: str


IMPACT_POLICY = {
    "NOT_AUTHORIZED": ImpactPolicy(
        5,
        "A privileged access assignment is explicitly marked as unauthorized.",
    ),
    "UNKNOWN_AUTHORIZATION": ImpactPolicy(
        4,
        "Authorization evidence for a privileged access assignment is unknown.",
    ),
    "FORMER_EMPLOYEE_ACTIVE_ACCOUNT": ImpactPolicy(
        5,
        "An account remains active after the employee's termination.",
    ),
    "DEACTIVATION_SLA_BREACH": ImpactPolicy(
        4,
        "The account was deactivated after the 24-hour deactivation deadline.",
    ),
    "DEACTIVATION_OVERDUE": ImpactPolicy(
        5,
        "The former employee's account remains active beyond the 24-hour deadline.",
    ),
    "DEACTIVATED_BEFORE_TERMINATION": ImpactPolicy(
        2,
        "The account was deactivated before the recorded termination date; "
        "verify whether this caused an operational access interruption.",
    ),
    "MISSING_APPROVAL_EVIDENCE": ImpactPolicy(
        4,
        "The role assignment lacks complete approval evidence.",
    ),
    "SELF_APPROVED_ASSIGNMENT": ImpactPolicy(
        5,
        "The same employee assigned and approved the role, weakening "
        "independent authorization.",
    ),
    "SOD_CONFLICT_DETECTED": ImpactPolicy(
        5,
        "The user holds permissions that violate the configured "
        "segregation-of-duties rule.",
    ),
}


def calculate_likelihood(detection_count: int) -> tuple[int, str]:
    """
    Use recurrence as an initial persistence indicator.

    This is not a statistical probability. It must be calibrated
    against dated audit history before being interpreted as one.
    """

    if isinstance(detection_count, bool) or not isinstance(detection_count, int):
        raise TypeError("Detection count must be an integer.")

    if detection_count < 1:
        raise ValueError("Detection count must be at least 1.")

    if detection_count == 1:
        return 2, "Observed once: isolated detection."

    if detection_count <= 3:
        return 3, "Observed 2–3 times: recurring detection."

    if detection_count <= 5:
        return 4, "Observed 4–5 times: significant persistence."

    return 5, "Observed 6 or more times: high persistence."


def assess_finding_policy(
    exception_type: str,
    detection_count: int,
) -> tuple[int, int, str]:
    """Return impact, likelihood and an auditable rationale."""

    policy = IMPACT_POLICY.get(exception_type)

    if policy is None:
        raise ValueError(
            f"No impact policy configured for exception type: {exception_type}"
        )

    likelihood_score, likelihood_rationale = calculate_likelihood(
        detection_count
    )

    rationale = (
        f"Policy version: 1.0. "
        f"Impact {policy.score}/5: {policy.rationale} "
        f"Likelihood {likelihood_score}/5: {likelihood_rationale} "
        f"Detection count: {detection_count}. "
        f"Likelihood is a persistence proxy, not a statistical probability. "
        f"Scores require auditor review."
    )

    return policy.score, likelihood_score, rationale
