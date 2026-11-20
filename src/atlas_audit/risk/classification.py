
"""
Risk classification module.

Maps risk scores to risk levels.
"""


RISK_THRESHOLDS = {
    "Low": (1, 4),
    "Medium": (5, 9),
    "High": (10, 16),
    "Critical": (17, 25),
}


def classify_risk(risk_score: int) -> str:
    """
    Classify a risk score.

    Risk matrix:
        1-4   : Low
        5-9   : Medium
        10-16 : High
        17-25 : Critical
    """

    if isinstance(risk_score, bool) or not isinstance(risk_score, int):
        raise TypeError("Risk score must be an integer.")

    if not 1 <= risk_score <= 25:
        raise ValueError("Risk score must be between 1 and 25.")

    for risk_level, (minimum, maximum) in RISK_THRESHOLDS.items():
        if minimum <= risk_score <= maximum:
            return risk_level

    raise ValueError("Unable to classify risk score.")
