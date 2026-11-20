
"""
Risk scoring module.

Calculates the risk score from impact and likelihood.
"""


def _validate_score_input(value: int, field_name: str) -> None:
    """Validate that a risk dimension is an integer between 1 and 5."""

    if isinstance(value, bool) or not isinstance(value, int):
        raise TypeError(f"{field_name} must be an integer.")

    if not 1 <= value <= 5:
        raise ValueError(f"{field_name} must be between 1 and 5.")


def calculate_risk_score(impact: int, likelihood: int) -> int:
    """
    Calculate the risk score.

    Formula:
        Risk Score = Impact * Likelihood

    Args:
        impact: Impact score from 1 to 5.
        likelihood: Likelihood score from 1 to 5.

    Returns:
        Integer risk score between 1 and 25.
    """

    _validate_score_input(impact, "Impact")
    _validate_score_input(likelihood, "Likelihood")

    return impact * likelihood
