"""Read-only PostgreSQL queries used by the Atlas dashboard."""

from __future__ import annotations

import pandas as pd
import psycopg
from psycopg.rows import dict_row


def load_dashboard_data(
    database_url: str | None,
) -> tuple[dict[str, object], str | None]:
    """Load available dashboard datasets without modifying the database."""
    if not database_url:
        return {}, (
            "ATLAS_DATABASE_URL n’est pas configurée. Définissez-la dans "
            "l’environnement ou dans .streamlit/secrets.toml."
        )

    try:
        with psycopg.connect(
            database_url,
            row_factory=dict_row,
            connect_timeout=5,
            options="-c default_transaction_read_only=on",
        ) as conn:
            with conn.transaction():
                tables = {
                    row["table_name"]
                    for row in conn.execute(
                        """
                        SELECT table_name
                        FROM information_schema.tables
                        WHERE table_schema = current_schema()
                        """
                    ).fetchall()
                }
                columns = {
                    row["column_name"]
                    for row in conn.execute(
                        """
                        SELECT column_name
                        FROM information_schema.columns
                        WHERE table_schema = current_schema()
                          AND table_name = 'audit_findings'
                        """
                    ).fetchall()
                } if "audit_findings" in tables else set()
                datasets: dict[str, object] = {}
                warnings: list[str] = []

                if "audit_findings" in tables:
                    if "risk_assessments" in tables:
                        risk_columns = """
                            ra.impact_score, ra.likelihood_score, ra.risk_score,
                            ra.risk_level, ra.assessed_at
                        """
                        risk_join = """
                            LEFT JOIN LATERAL (
                                SELECT impact_score, likelihood_score, risk_score,
                                       risk_level, assessed_at
                                FROM risk_assessments
                                WHERE finding_id = f.finding_id
                                ORDER BY assessed_at DESC, assessment_id DESC
                                LIMIT 1
                            ) ra ON TRUE
                        """
                    else:
                        risk_columns = """
                            NULL::integer AS impact_score,
                            NULL::integer AS likelihood_score,
                            NULL::integer AS risk_score,
                            NULL::varchar AS risk_level,
                            NULL::timestamptz AS assessed_at
                        """
                        risk_join = ""
                        warnings.append(
                            "risk_assessments n’est pas installée : les constats "
                            "s’affichent sans évaluation de risque."
                        )

                    source_key_column = (
                        "f.source_key" if "source_key" in columns
                        else "NULL::varchar AS source_key"
                    )
                    last_seen_column = (
                        "f.last_seen_at" if "last_seen_at" in columns
                        else "f.detected_at AS last_seen_at"
                    )
                    detection_count_column = (
                        "f.detection_count" if "detection_count" in columns
                        else "1::integer AS detection_count"
                    )
                    if not {"source_key", "last_seen_at", "detection_count"}.issubset(columns):
                        warnings.append(
                            "Le schéma d’intégration des constats est incomplet ; "
                            "certaines colonnes historiques utilisent une valeur de repli."
                        )

                    datasets["findings"] = pd.DataFrame(
                        conn.execute(
                            f"""
                            SELECT f.finding_id, f.control_code, f.exception_type,
                                   f.title, f.description, f.affected_user_id,
                                   f.status, f.detected_at, f.resolved_at,
                                   {source_key_column}, {last_seen_column},
                                   {detection_count_column},
                                   {risk_columns},
                                   u.username, e.employee_number,
                                   d.department_name AS department
                            FROM audit_findings f
                            {risk_join}
                            LEFT JOIN users u ON u.user_id = f.affected_user_id
                            LEFT JOIN employees e ON e.employee_id = u.employee_id
                            LEFT JOIN departments d ON d.department_id = e.department_id
                            ORDER BY f.detected_at DESC, f.finding_id DESC
                            """
                        ).fetchall()
                    )
                else:
                    warnings.append(
                        "audit_findings n’est pas installée : aucun finding ne sera affiché."
                    )

                if "audit_recommendations" in tables:
                    if "audit_findings" in tables:
                        finding_columns = "f.control_code, f.exception_type, f.status AS finding_status"
                        finding_join = "LEFT JOIN audit_findings f ON f.finding_id = r.finding_id"
                    else:
                        finding_columns = """
                            NULL::varchar AS control_code,
                            NULL::varchar AS exception_type,
                            NULL::varchar AS finding_status
                        """
                        finding_join = ""
                    datasets["recommendations"] = pd.DataFrame(
                        conn.execute(
                            f"""
                            SELECT r.recommendation_id, r.finding_id, r.title,
                                   r.description, r.priority, r.status,
                                   r.assigned_to, r.due_date, r.completed_at,
                                   r.created_at, {finding_columns}
                            FROM audit_recommendations r
                            {finding_join}
                            ORDER BY r.due_date NULLS LAST, r.created_at DESC
                            """
                        ).fetchall()
                    )
                else:
                    warnings.append("audit_recommendations n’est pas installée.")

                if "audit_runs" in tables:
                    datasets["runs"] = pd.DataFrame(
                        conn.execute(
                            """
                            SELECT run_id, started_at, completed_at, status, triggered_by
                            FROM audit_runs
                            ORDER BY started_at DESC, run_id DESC
                            """
                        ).fetchall()
                    )
                else:
                    warnings.append("audit_runs n’est pas installée.")

                if "control_executions" in tables:
                    datasets["executions"] = pd.DataFrame(
                        conn.execute(
                            """
                            SELECT execution_id, run_id, control_code, status,
                                   findings_count, error_message, started_at, completed_at
                            FROM control_executions
                            ORDER BY started_at DESC, execution_id DESC
                            """
                        ).fetchall()
                    )
                else:
                    warnings.append("control_executions n’est pas installée.")

                datasets["_schema_warnings"] = warnings

        return datasets, None
    except psycopg.Error as exc:
        return {}, (
            "Connexion ou lecture PostgreSQL impossible "
            f"({exc.__class__.__name__}). Vérifiez l’URL et les migrations SQL."
        )
    except Exception as exc:
        return {}, f"Impossible de charger le tableau de bord ({exc.__class__.__name__})."
