
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
from typing import Any

import psycopg
from psycopg.rows import dict_row


# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[3]

CONTROL_FILES = {
    "AC-01": "sql/controls/001_unconfirmed_active_admins.sql",
    "AC-02": "sql/controls/002_former_employees_active_accounts.sql",
    "AC-03": "sql/controls/003_deactivation_sla.sql",
    "AC-04": "sql/controls/004_unapproved_role_assignments.sql",
    "AC-05": "sql/controls/005_segregation_of_duties.sql",
}

CONTROL_TITLES = {
    "AC-01": "Accès privilégié sans autorisation confirmée",
    "AC-02": "Compte actif d'un ancien employé",
    "AC-03": "Non-respect du délai de désactivation",
    "AC-04": "Attribution de rôle sans approbation valide",
    "AC-05": "Conflit de séparation des tâches",
}

# Fields that uniquely identify the same business exception.
IDENTITY_FIELDS = {
    "AC-01": ("user_id", "role_name", "exception_type"),
    "AC-02": ("user_id", "exception_type"),
    "AC-03": ("username", "exception_type"),
    "AC-04": ("username", "role_name", "exception_type"),
    "AC-05": (
        "user_id",
        "conflict_name",
        "permission_1",
        "permission_2",
    ),
}


# ------------------------------------------------------------
# NORMALIZATION
# ------------------------------------------------------------

def normalize_control_row(
    control_code: str,
    original_row: dict[str, Any],
) -> dict[str, Any] | None:
    """
    Convert a SQL control result into a normalized finding.

    AC-03 returns both compliant and non-compliant employees.
    Only actual exceptions are converted into findings.
    """

    row = dict(original_row)

    if control_code == "AC-03":
        compliance_status = row.get("compliance_status")

        exception_mapping = {
            "NON_COMPLIANT": "DEACTIVATION_SLA_BREACH",
            "PENDING_OVERDUE": "DEACTIVATION_OVERDUE",
            "DEACTIVATED_BEFORE_TERMINATION":
                "DEACTIVATED_BEFORE_TERMINATION",
        }

        exception_type = exception_mapping.get(compliance_status)

        if exception_type is None:
            return None

        row["exception_type"] = exception_type

    if not row.get("exception_type"):
        raise ValueError(
            f"{control_code}: missing exception_type in SQL result"
        )

    return row


def generate_source_key(
    control_code: str,
    row: dict[str, Any],
) -> str:
    """
    Generate a stable identifier for a business exception.

    Non-identity fields such as timestamps and descriptions are
    deliberately excluded so that repeated detections match.
    """

    identity_fields = IDENTITY_FIELDS[control_code]

    identity = {
        field: row.get(field)
        for field in identity_fields
    }

    canonical_identity = json.dumps(
        {
            "control_code": control_code,
            "identity": identity,
        },
        sort_keys=True,
        default=str,
    )

    return hashlib.sha256(
        canonical_identity.encode("utf-8")
    ).hexdigest()


def build_finding_description(
    control_code: str,
    row: dict[str, Any],
) -> str:
    """Build a traceable JSON description of the exception."""

    payload = {
        "control_code": control_code,
        "exception_type": row["exception_type"],
        "evidence": row,
    }

    return json.dumps(
        payload,
        ensure_ascii=False,
        indent=2,
        default=str,
    )


# ------------------------------------------------------------
# DATABASE HELPERS
# ------------------------------------------------------------

def get_affected_user_id(
    conn: psycopg.Connection,
    row: dict[str, Any],
    cache: dict[str, int | None],
) -> int | None:
    """
    Resolve the affected user.

    Some controls return user_id directly; others return username.
    """

    if row.get("user_id") is not None:
        return int(row["user_id"])

    username = row.get("username")

    if not username:
        return None

    if username not in cache:
        result = conn.execute(
            """
            SELECT user_id
            FROM users
            WHERE username = %s
            """,
            (username,),
        ).fetchone()

        cache[username] = (
            result["user_id"] if result else None
        )

    return cache[username]


def upsert_finding(
    conn: psycopg.Connection,
    run_id: int,
    control_code: str,
    row: dict[str, Any],
    user_cache: dict[str, int | None],
) -> None:
    """
    Insert a new finding or update an existing active finding.

    Resolved findings are not reopened automatically. If the same
    exception reappears after resolution, a new finding is created.
    """

    source_key = generate_source_key(control_code, row)

    title = (
        f"{control_code} - "
        f"{CONTROL_TITLES[control_code]}"
    )

    description = build_finding_description(
        control_code,
        row,
    )

    affected_user_id = get_affected_user_id(
        conn,
        row,
        user_cache,
    )

    conn.execute(
        """
        INSERT INTO audit_findings (
            control_code,
            exception_type,
            title,
            description,
            affected_user_id,
            source_key,
            detected_at,
            last_seen_at,
            detection_count,
            last_seen_run_id
        )
        VALUES (
            %s, %s, %s, %s, %s, %s,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP,
            1,
            %s
        )

        ON CONFLICT (control_code, source_key)
        WHERE status <> 'Resolved'

        DO UPDATE SET
            title = EXCLUDED.title,
            description = EXCLUDED.description,
            affected_user_id = COALESCE(
                EXCLUDED.affected_user_id,
                audit_findings.affected_user_id
            ),
            last_seen_at = CURRENT_TIMESTAMP,
            detection_count = audit_findings.detection_count + 1,
            last_seen_run_id = EXCLUDED.last_seen_run_id
        """,
        (
            control_code,
            row["exception_type"],
            title,
            description,
            affected_user_id,
            source_key,
            run_id,
        ),
    )


# ------------------------------------------------------------
# CONTROL EXECUTION
# ------------------------------------------------------------

def execute_control(
    conn: psycopg.Connection,
    run_id: int,
    control_code: str,
    sql_relative_path: str,
    user_cache: dict[str, int | None],
) -> dict[str, Any]:
    """
    Execute one control in a savepoint.

    A failed control does not prevent the remaining controls
    from executing.
    """

    execution = conn.execute(
        """
        INSERT INTO control_executions (
            run_id,
            control_code,
            status
        )
        VALUES (%s, %s, 'Running')
        RETURNING execution_id
        """,
        (run_id, control_code),
    ).fetchone()

    execution_id = execution["execution_id"]

    try:
        sql_path = PROJECT_ROOT / sql_relative_path

        if not sql_path.is_file():
            raise FileNotFoundError(
                f"SQL control file not found: {sql_path}"
            )

        sql_query = sql_path.read_text(encoding="utf-8")

        # A nested transaction creates a savepoint.
        # If the SQL or a finding insertion fails, all work
        # inside this control is rolled back.
        with conn.transaction():
            raw_rows = conn.execute(sql_query).fetchall()

            finding_count = 0

            for raw_row in raw_rows:
                normalized = normalize_control_row(
                    control_code,
                    raw_row,
                )

                if normalized is None:
                    continue

                upsert_finding(
                    conn=conn,
                    run_id=run_id,
                    control_code=control_code,
                    row=normalized,
                    user_cache=user_cache,
                )

                finding_count += 1

        conn.execute(
            """
            UPDATE control_executions
            SET
                status = 'Completed',
                findings_count = %s,
                completed_at = CURRENT_TIMESTAMP
            WHERE execution_id = %s
            """,
            (finding_count, execution_id),
        )

        return {
            "control_code": control_code,
            "status": "Completed",
            "findings_count": finding_count,
        }

    except Exception as exc:
        error_message = str(exc)[:4000]

        conn.execute(
            """
            UPDATE control_executions
            SET
                status = 'Failed',
                error_message = %s,
                completed_at = CURRENT_TIMESTAMP
            WHERE execution_id = %s
            """,
            (error_message, execution_id),
        )

        return {
            "control_code": control_code,
            "status": "Failed",
            "findings_count": 0,
            "error": error_message,
        }


# ------------------------------------------------------------
# AUDIT RUNNER
# ------------------------------------------------------------

def run_audit() -> dict[str, Any]:
    """
    Run all five SQL controls and centralize their findings.
    """

    database_url = os.getenv("ATLAS_DATABASE_URL")

    if not database_url:
        raise RuntimeError(
            "ATLAS_DATABASE_URL environment variable is not set."
        )

    results = []

    with psycopg.connect(
        database_url,
        row_factory=dict_row,
    ) as conn:

        with conn.transaction():

            run = conn.execute(
                """
                INSERT INTO audit_runs (
                    status,
                    triggered_by
                )
                VALUES ('Running', 'python_integration_engine')
                RETURNING run_id
                """
            ).fetchone()

            run_id = run["run_id"]

            user_cache: dict[str, int | None] = {}

            for control_code, sql_path in CONTROL_FILES.items():

                result = execute_control(
                    conn=conn,
                    run_id=run_id,
                    control_code=control_code,
                    sql_relative_path=sql_path,
                    user_cache=user_cache,
                )

                results.append(result)

            failed_controls = sum(
                1
                for result in results
                if result["status"] == "Failed"
            )

            run_status = (
                "Completed"
                if failed_controls == 0
                else "Completed_With_Errors"
            )

            conn.execute(
                """
                UPDATE audit_runs
                SET
                    status = %s,
                    completed_at = CURRENT_TIMESTAMP
                WHERE run_id = %s
                """,
                (run_status, run_id),
            )

    return {
        "run_id": run_id,
        "status": run_status,
        "controls": results,
        "total_findings": sum(
            result["findings_count"]
            for result in results
        ),
        "failed_controls": failed_controls,
    }


# ------------------------------------------------------------
# CLI ENTRY POINT
# ------------------------------------------------------------

if __name__ == "__main__":
    report = run_audit()

    print("\n========== ATLAS AUDIT REPORT ==========")
    print(f"Run ID: {report['run_id']}")
    print(f"Status: {report['status']}")
    print(f"Total findings: {report['total_findings']}")
    print(f"Failed controls: {report['failed_controls']}")

    for control in report["controls"]:
        print(
            f"{control['control_code']} | "
            f"{control['status']} | "
            f"{control['findings_count']} findings"
        )

        if control.get("error"):
            print(f"  Error: {control['error']}")

    print("========================================\n")
