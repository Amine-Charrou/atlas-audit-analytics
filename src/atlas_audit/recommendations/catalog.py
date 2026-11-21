
"""Business recommendation catalog for IAM audit findings."""

from dataclasses import dataclass


@dataclass(frozen=True)
class RecommendationPolicy:
    title: str
    description: str
    priority: str
    remediation_days: int


RECOMMENDATION_CATALOG = {
    "NOT_AUTHORIZED": RecommendationPolicy(
        title="Revoke unauthorized privileged access",
        description=(
            "Revoke the privileged role assignment immediately. "
            "Review access logs to identify potentially unauthorized "
            "activities and document the remediation."
        ),
        priority="Critical",
        remediation_days=1,
    ),

    "UNKNOWN_AUTHORIZATION": RecommendationPolicy(
        title="Validate privileged access authorization",
        description=(
            "Obtain documented approval from the appropriate business "
            "owner. If authorization cannot be established, revoke "
            "the privileged access."
        ),
        priority="High",
        remediation_days=7,
    ),

    "FORMER_EMPLOYEE_ACTIVE_ACCOUNT": RecommendationPolicy(
        title="Disable former employee account",
        description=(
            "Disable the account immediately, revoke active sessions "
            "and associated access, and review authentication logs "
            "since the employee termination date."
        ),
        priority="Critical",
        remediation_days=1,
    ),

    "DEACTIVATION_SLA_BREACH": RecommendationPolicy(
        title="Improve account deactivation SLA compliance",
        description=(
            "Investigate the delayed deactivation, identify process "
            "bottlenecks, and strengthen HR-to-IT termination "
            "notifications and monitoring."
        ),
        priority="High",
        remediation_days=7,
    ),

    "DEACTIVATION_OVERDUE": RecommendationPolicy(
        title="Immediately disable overdue employee account",
        description=(
            "Disable the account immediately, revoke active sessions, "
            "investigate possible access after termination, and "
            "document the incident."
        ),
        priority="Critical",
        remediation_days=1,
    ),

    "DEACTIVATED_BEFORE_TERMINATION": RecommendationPolicy(
        title="Review premature account deactivation",
        description=(
            "Confirm whether early deactivation was authorized and "
            "whether it disrupted legitimate business activities. "
            "Improve coordination between HR and IT."
        ),
        priority="Low",
        remediation_days=60,
    ),

    "MISSING_APPROVAL_EVIDENCE": RecommendationPolicy(
        title="Complete role assignment approval evidence",
        description=(
            "Obtain independent approval evidence, including the "
            "approver identity, approval date and reference. "
            "Review the legitimacy of the assigned role."
        ),
        priority="High",
        remediation_days=7,
    ),

    "SELF_APPROVED_ASSIGNMENT": RecommendationPolicy(
        title="Enforce independent role approval",
        description=(
            "Introduce an independent approval requirement so that "
            "the person assigning a role cannot approve the same "
            "assignment."
        ),
        priority="Critical",
        remediation_days=1,
    ),

    "SOD_CONFLICT_DETECTED": RecommendationPolicy(
        title="Resolve segregation of duties conflict",
        description=(
            "Review the conflicting permissions, remove one of the "
            "incompatible permissions, and document any formally "
            "approved compensating controls."
        ),
        priority="Critical",
        remediation_days=1,
    ),
}


def get_recommendation_policy(
    exception_type: str,
) -> RecommendationPolicy:
    """Retrieve the recommendation policy for an exception."""

    policy = RECOMMENDATION_CATALOG.get(exception_type)

    if policy is None:
        raise ValueError(
            f"No recommendation policy configured for: {exception_type}"
        )

    return policy
