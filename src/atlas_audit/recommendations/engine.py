
"""Recommendation generation and persistence engine."""

from __future__ import annotations

import os
from typing import Any

import psycopg
from psycopg.rows import dict_row

from atlas_audit.recommendations.catalog import (
    get_recommendation_policy,
)


# Risk level -> recommendation priority and target remediation days.
REMEDIATION_POLICY = {
    "Critical": {
        "priority": "Critical",
        "days": 1,
    },
    "High": {
        "priority": "High",
        "days": 7,
    },
    "Medium": {
        "priority": "Medium",
        "days": 30,
    },
    "Low": {
        "priority": "Low",
        "days": 60,
    },
}


def get_remediation_policy(risk_level: str) -> dict[str, Any]:
    """Return the remediation priority and target deadline."""

    policy = REMEDIATION_POLICY.get(risk_level)

    if policy is None:
        raise ValueError(
            f"Unsupported risk level: {risk_level}"
        )

    return policy


def fetch_findings_to_process(
    conn: psycopg.Connection,
) -> list[dict[str, Any]]:
    """
    Retrieve unresolved findings with their latest risk assessment.

    Findings without a risk assessment are returned too, so they
    can be explicitly reported as skipped.
    """

    return conn.execute(
        """
        SELECT
            f.finding_id,
            f.control_code,
            f.exception_type,
            f.status AS finding_status,
            ra.risk_level,
            ra.risk_score,
            ra.impact_score,
            ra.likelihood_score
        FROM audit_findings f
        LEFT JOIN LATERAL (
            SELECT
                risk_level,
                risk_score,
                impact_score,
                likelihood_score
            FROM risk_assessments
            WHERE finding_id = f.finding_id
            ORDER BY assessed_at DESC, assessment_id DESC
            LIMIT 1
        ) ra ON TRUE
        WHERE f.status <> 'Resolved'
        ORDER BY f.finding_id
        """
    ).fetchall()


def upsert_recommendation(
    conn: psycopg.Connection,
    finding: dict[str, Any],
) -> None:
    """
    Create or update the active recommendation for a finding.

    Existing manual assignments and due dates are preserved.
    Implemented and Rejected recommendations are kept as history.
    """

    exception_type = finding["exception_type"]
    risk_level = finding["risk_level"]

    catalog_policy = get_recommendation_policy(exception_type)
    remediation_policy = get_remediation_policy(risk_level)

    priority = remediation_policy["priority"]
    remediation_days = remediation_policy["days"]

    conn.execute(
        """
        INSERT INTO audit_recommendations (
            finding_id,
            title,
            description,
            priority,
            status,
            due_date
        )
        VALUES (
            %s,
            %s,
            %s,
            %s,
            'Open',
            CURRENT_DATE + %s
        )

        ON CONFLICT (finding_id)
        WHERE status IN ('Open', 'In Progress')

        DO UPDATE SET
            title = EXCLUDED.title,
            description = EXCLUDED.description,
            priority = EXCLUDED.priority,
            due_date = COALESCE(
                audit_recommendations.due_date,
                EXCLUDED.due_date
            )
        """,
        (
            finding["finding_id"],
            catalog_policy.title,
            catalog_policy.description,
            priority,
            remediation_days,
        ),
    )


def generate_recommendations(
    conn: psycopg.Connection,
) -> dict[str, Any]:
    """Generate recommendations for all eligible audit findings."""

    findings = fetch_findings_to_process(conn)

    processed = 0
    skipped_without_assessment = 0
    errors = []

    for finding in findings:
        finding_id = finding["finding_id"]

        if finding["risk_level"] is None:
            skipped_without_assessment += 1
            continue

        try:
            # A savepoint isolates an individual finding.
            with conn.transaction():
                upsert_recommendation(conn, finding)

            processed += 1

        except (ValueError, TypeError) as exc:
            errors.append({
                "finding_id": finding_id,
                "error": str(exc),
            })

    return {
        "findings_retrieved": len(findings),
        "recommendations_processed": processed,
        "skipped_without_assessment": skipped_without_assessment,
        "errors": errors,
    }


def run_recommendation_engine() -> dict[str, Any]:
    """Run the recommendation engine against PostgreSQL."""

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
            report = generate_recommendations(conn)

    return report


if __name__ == "__main__":
    report = run_recommendation_engine()

    print("\n======= ATLAS RECOMMENDATION REPORT =======")
    print(f"Findings retrieved: {report['findings_retrieved']}")
    print(
        "Recommendations processed: "
        f"{report['recommendations_processed']}"
    )
    print(
        "Skipped without assessment: "
        f"{report['skipped_without_assessment']}"
    )
    print(f"Errors: {len(report['errors'])}")

    for error in report["errors"]:
        print(
            f"Finding {error['finding_id']}: "
            f"{error['error']}"
        )

    print("===========================================\n")
