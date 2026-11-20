
"""Risk assessment automation for Atlas Audit Analytics."""

from __future__ import annotations

import os
from typing import Any

import psycopg
from psycopg.rows import dict_row

from atlas_audit.risk.assessment import assess_risk
from atlas_audit.risk.policy import assess_finding_policy


def evaluate_open_findings(
    conn: psycopg.Connection,
) -> dict[str, Any]:
    """Evaluate open findings and persist new or changed assessments."""

    findings = conn.execute(
        """
        SELECT
            f.finding_id,
            f.control_code,
            f.exception_type,
            f.detection_count
        FROM audit_findings f
        WHERE f.status <> 'Resolved'
        ORDER BY f.finding_id
        """
    ).fetchall()

    evaluated = 0
    inserted = 0
    unchanged = 0
    errors = []

    for finding in findings:
        finding_id = finding["finding_id"]

        try:
            impact, likelihood, rationale = assess_finding_policy(
                exception_type=finding["exception_type"],
                detection_count=finding["detection_count"],
            )

            result = assess_risk(
                impact=impact,
                likelihood=likelihood,
            )

            latest = conn.execute(
                """
                SELECT
                    impact_score,
                    likelihood_score,
                    risk_score,
                    risk_level
                FROM risk_assessments
                WHERE finding_id = %s
                ORDER BY assessed_at DESC, assessment_id DESC
                LIMIT 1
                """,
                (finding_id,),
            ).fetchone()

            evaluated += 1

            if (
                latest is not None
                and latest["impact_score"] == result.impact
                and latest["likelihood_score"] == result.likelihood
            ):
                unchanged += 1
                continue

            conn.execute(
                """
                INSERT INTO risk_assessments (
                    finding_id,
                    impact_score,
                    likelihood_score,
                    assessment_rationale,
                    assessed_by
                )
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    finding_id,
                    result.impact,
                    result.likelihood,
                    rationale,
                    "atlas_risk_engine_v1",
                ),
            )

            inserted += 1

        except (TypeError, ValueError) as exc:
            errors.append({
                "finding_id": finding_id,
                "error": str(exc),
            })

    return {
        "findings_evaluated": evaluated,
        "assessments_inserted": inserted,
        "assessments_unchanged": unchanged,
        "errors": errors,
    }


def run_risk_assessment() -> dict[str, Any]:
    """Run the risk assessment process against PostgreSQL."""

    database_url = os.getenv("ATLAS_DATABASE_URL")

    if not database_url:
        raise RuntimeError(
            "ATLAS_DATABASE_URL environment variable is not set."
        )

    with psycopg.connect(
        database_url,
        row_factory=dict_row,
    ) as conn:
        with conn.transaction():
            report = evaluate_open_findings(conn)

    return report


if __name__ == "__main__":
    report = run_risk_assessment()

    print("\n========== ATLAS RISK ASSESSMENT ==========")
    print(f"Findings evaluated: {report['findings_evaluated']}")
    print(f"Assessments inserted: {report['assessments_inserted']}")
    print(f"Assessments unchanged: {report['assessments_unchanged']}")
    print(f"Errors: {len(report['errors'])}")

    for error in report["errors"]:
        print(
            f"Finding {error['finding_id']}: "
            f"{error['error']}"
        )

    print("===========================================\n")
