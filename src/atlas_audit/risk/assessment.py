
"""
Risk assessment module.

Combines risk scoring and classification.
"""

from dataclasses import dataclass

from atlas_audit.risk.scoring import calculate_risk_score
from atlas_audit.risk.classification import classify_risk


@dataclass(frozen=True)
class RiskAssessment:
    """Represents a complete risk assessment."""

    impact: int
    likelihood: int
    risk_score: int
    risk_level: str


def assess_risk(impact: int, likelihood: int) -> RiskAssessment:
    """
    Assess a risk using impact and likelihood.

    Returns:
        RiskAssessment containing the dimensions,
        calculated score and classification.
    """

    risk_score = calculate_risk_score(
        impact=impact,
        likelihood=likelihood,
    )

    risk_level = classify_risk(risk_score)

    return RiskAssessment(
        impact=impact,
        likelihood=likelihood,
        risk_score=risk_score,
        risk_level=risk_level,
    )
