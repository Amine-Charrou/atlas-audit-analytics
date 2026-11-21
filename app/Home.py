from __future__ import annotations

import os
from typing import Any

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import psycopg
import streamlit as st
from psycopg.rows import dict_row

st.set_page_config(page_title="Atlas Audit Analytics", page_icon="◈", layout="wide")

NAVY = "#17365D"
BLUE = "#2878B5"
PALETTE = {"Low": "#2E8B57", "Medium": "#D99B20", "High": "#E47728", "Critical": "#C64245"}
PLOT = dict(paper_bgcolor="rgba(0,0,0,0)", plot_bgcolor="rgba(0,0,0,0)", font_color="#334155", margin=dict(l=12, r=12, t=38, b=12))

st.markdown("""
<style>
.stApp { background: #f5f7fa; color: #172b4d; }
[data-testid="stSidebar"] { background: #ffffff; border-right: 1px solid #e4eaf1; }
.block-container { padding-top: 1.7rem; max-width: 1500px; }
[data-testid="stMetric"] { background: #fff; border: 1px solid #e4eaf1; border-radius: 12px; padding: 16px 18px; box-shadow: 0 2px 8px rgba(23,54,93,.04); }
[data-testid="stMetricLabel"] { color: #64748b; }
.hero { padding: 20px 24px; border-radius: 14px; background: linear-gradient(110deg,#fff,#eef5fb); border:1px solid #e1eaf3; margin-bottom: 18px; }
.hero h1 { color:#17365d; margin:0; font-size:1.8rem; }
.hero p { color:#64748b; margin:.35rem 0 0; }
</style>
""", unsafe_allow_html=True)

PAGES = ["Executive Overview", "Risk Analytics", "Findings Explorer", "Recommendations Tracker", "Audit Execution History"]


def database_url() -> str | None:
    value = os.getenv("ATLAS_DATABASE_URL")
    if value:
        return value
    try:
        return st.secrets.get("ATLAS_DATABASE_URL")
    except Exception:
        return None


def load_data() -> tuple[dict[str, pd.DataFrame], str | None]:
    """Read the dashboard's supported tables using a read-only PostgreSQL session."""
    url = database_url()
    if not url:
        return {}, "ATLAS_DATABASE_URL n’est pas configurée. Définissez-la dans l’environnement ou dans .streamlit/secrets.toml."
    try:
        with psycopg.connect(url, row_factory=dict_row, connect_timeout=5, options="-c default_transaction_read_only=on") as conn:
            with conn.transaction():
                tables = {r["table_name"] for r in conn.execute("""
                    SELECT table_name FROM information_schema.tables
                    WHERE table_schema = current_schema()
                """).fetchall()}
                out: dict[str, pd.DataFrame] = {}
                if "audit_findings" in tables:
                    out["findings"] = pd.DataFrame(conn.execute("""
                        SELECT f.finding_id, f.control_code, f.exception_type, f.title,
                               f.description, f.affected_user_id, f.status, f.detected_at,
                               f.resolved_at, f.source_key, f.last_seen_at, f.detection_count,
                               ra.impact_score, ra.likelihood_score, ra.risk_score, ra.risk_level,
                               ra.assessed_at,
                               u.username, e.employee_number,
                               d.department_name AS department
                        FROM audit_findings f
                        LEFT JOIN LATERAL (
                            SELECT impact_score, likelihood_score, risk_score, risk_level, assessed_at
                            FROM risk_assessments WHERE finding_id=f.finding_id
                            ORDER BY assessed_at DESC, assessment_id DESC LIMIT 1
                        ) ra ON TRUE
                        LEFT JOIN users u ON u.user_id=f.affected_user_id
                        LEFT JOIN employees e ON e.employee_id=u.employee_id
                        LEFT JOIN departments d ON d.department_id=e.department_id
                        ORDER BY f.detected_at DESC, f.finding_id DESC
                    """).fetchall())
                if "audit_recommendations" in tables:
                    out["recommendations"] = pd.DataFrame(conn.execute("""
                        SELECT r.recommendation_id, r.finding_id, r.title, r.description,
                               r.priority, r.status, r.assigned_to, r.due_date,
                               r.completed_at, r.created_at,
                               f.control_code, f.exception_type, f.status AS finding_status
                        FROM audit_recommendations r
                        LEFT JOIN audit_findings f ON f.finding_id=r.finding_id
                        ORDER BY r.due_date NULLS LAST, r.created_at DESC
                    """).fetchall())
                if "audit_runs" in tables:
                    out["runs"] = pd.DataFrame(conn.execute("""
                        SELECT run_id, started_at, completed_at, status, triggered_by
                        FROM audit_runs ORDER BY started_at DESC, run_id DESC
                    """).fetchall())
                if "control_executions" in tables:
                    out["executions"] = pd.DataFrame(conn.execute("""
                        SELECT ce.execution_id, ce.run_id, ce.control_code, ce.status,
                               ce.findings_count, ce.error_message, ce.started_at, ce.completed_at
                        FROM control_executions ce ORDER BY ce.started_at DESC, ce.execution_id DESC
                    """).fetchall())
        return out, None
    except psycopg.Error as exc:
        return {}, f"Connexion ou lecture PostgreSQL impossible : {exc.__class__.__name__}: {exc}"
    except Exception as exc:
        return {}, f"Impossible de charger le tableau de bord : {exc.__class__.__name__}: {exc}"


def empty(label: str) -> None:
    st.info(label)


def setup_plot(fig: go.Figure) -> go.Figure:
    fig.update_layout(**PLOT)
    return fig


def safe_df(data: pd.DataFrame | None) -> pd.DataFrame:
    return data if data is not None else pd.DataFrame()


def header(title: str, subtitle: str) -> None:
    st.markdown(f'<div class="hero"><h1>{title}</h1><p>{subtitle}</p></div>', unsafe_allow_html=True)


data, db_error = load_data()
with st.sidebar:
    st.markdown("## ◈ Atlas Audit Analytics")
    st.caption("Audit interne · Accès & risques")
    page = st.radio("Navigation", PAGES, label_visibility="collapsed")
    st.divider()
    if db_error:
        st.error("Base indisponible")
    else:
        st.success("PostgreSQL connecté · lecture seule")
    if st.button("Actualiser", use_container_width=True):
        st.rerun()
    st.caption("Les données affichées proviennent de la base configurée.")

findings = safe_df(data.get("findings"))
recs = safe_df(data.get("recommendations"))
runs = safe_df(data.get("runs"))
executions = safe_df(data.get("executions"))

if db_error:
    header("Atlas Audit Analytics", "Vue de pilotage des constats et des risques d’audit")
    st.error(db_error)
    st.markdown("Configurez `ATLAS_DATABASE_URL`, puis relancez l’application. Aucune donnée de démonstration n’est générée.")

elif page == "Executive Overview":
    header("Executive Overview", "Synthèse des constats, risques et actions de remédiation")
    if findings.empty and recs.empty:
        empty("Aucun finding ni recommandation n’est disponible dans la base. Les indicateurs apparaîtront après l’exécution des contrôles et l’évaluation des risques.")
    open_findings = findings[findings.status.ne("Resolved")] if not findings.empty else findings
    critical = int(findings.risk_level.eq("Critical").sum()) if "risk_level" in findings else 0
    open_recs = recs[recs.status.isin(["Open", "In Progress"])] if not recs.empty else recs
    c1,c2,c3,c4 = st.columns(4)
    c1.metric("Constats", len(findings))
    c2.metric("Constats ouverts", len(open_findings))
    c3.metric("Risques critiques", critical)
    c4.metric("Recommandations ouvertes", len(open_recs))
    left,right=st.columns([1.15,1])
    with left:
        st.subheader("Constats par niveau de risque")
        if not findings.empty and findings.risk_level.notna().any():
            counts=findings.risk_level.value_counts().reindex(PALETTE, fill_value=0).rename_axis("Niveau").reset_index(name="Constats")
            fig=px.bar(counts,x="Niveau",y="Constats",color="Niveau",color_discrete_map=PALETTE)
            st.plotly_chart(setup_plot(fig),use_container_width=True)
        else: empty("Aucune évaluation de risque disponible.")
    with right:
        st.subheader("Constats par contrôle")
        if not findings.empty:
            counts=findings.control_code.value_counts().sort_index().rename_axis("Contrôle").reset_index(name="Constats")
            fig=px.bar(counts,x="Contrôle",y="Constats",color_discrete_sequence=[BLUE])
            st.plotly_chart(setup_plot(fig),use_container_width=True)
        else: empty("Aucun constat enregistré.")
    st.subheader("Constats récents")
    if not findings.empty:
        cols=[c for c in ["finding_id","control_code","title","risk_level","status","detected_at"] if c in findings]
        st.dataframe(findings[cols].head(8),use_container_width=True,hide_index=True)

elif page == "Risk Analytics":
    header("Risk Analytics", "Répartition et cartographie Impact × Likelihood")
    if findings.empty or not {"impact_score","likelihood_score"}.issubset(findings.columns) or findings[["impact_score","likelihood_score"]].dropna().empty:
        empty("Aucune évaluation de risque n’est enregistrée. Les évaluations sont lues depuis la dernière analyse de chaque constat.")
    else:
        rated=findings.dropna(subset=["impact_score","likelihood_score"]).copy()
        a,b,c=st.columns(3); a.metric("Évaluations visibles",len(rated)); b.metric("Impact moyen",f"{rated.impact_score.mean():.1f} / 5"); c.metric("Likelihood moyen",f"{rated.likelihood_score.mean():.1f} / 5")
        left,right=st.columns([1.05,1])
        with left:
            st.subheader("Matrice Impact × Likelihood")
            matrix=rated.groupby(["likelihood_score","impact_score"]).size().reset_index(name="Constats")
            fig=px.density_heatmap(matrix,x="impact_score",y="likelihood_score",z="Constats",histfunc="sum",nbinsx=5,nbinsy=5,color_continuous_scale=[[0,"#eef3f8"],[.5,"#f2be58"],[1,"#c64245"]],text_auto=True)
            fig.update_xaxes(title="Impact",dtick=1,range=[.5,5.5]); fig.update_yaxes(title="Likelihood",dtick=1,range=[.5,5.5])
            st.plotly_chart(setup_plot(fig),use_container_width=True)
        with right:
            st.subheader("Niveaux de risque")
            counts=rated.risk_level.value_counts().reindex(PALETTE,fill_value=0).rename_axis("Niveau").reset_index(name="Constats")
            fig=px.pie(counts,values="Constats",names="Niveau",hole=.62,color="Niveau",color_discrete_map=PALETTE)
            st.plotly_chart(setup_plot(fig),use_container_width=True)
        st.subheader("Constats évalués")
        st.dataframe(rated[[c for c in ["finding_id","control_code","title","impact_score","likelihood_score","risk_score","risk_level","assessed_at"] if c in rated]],use_container_width=True,hide_index=True)

elif page == "Findings Explorer":
    header("Findings Explorer", "Recherche, filtres et éléments de preuve des constats")
    if findings.empty: empty("Aucun finding n’est présent dans la base.")
    else:
        f1,f2,f3=st.columns(3)
        codes=sorted(findings.control_code.dropna().unique())
        selected_codes=f1.multiselect("Contrôle",codes,default=codes)
        statuses=sorted(findings.status.dropna().unique())
        selected_status=f2.multiselect("Statut",statuses,default=statuses)
        levels=sorted(findings.risk_level.dropna().unique()) if "risk_level" in findings else []
        selected_levels=f3.multiselect("Risque",levels,default=levels)
        query=st.text_input("Rechercher dans titre, type ou identifiant",placeholder="Ex. AC-01, privilège…")
        view=findings[findings.control_code.isin(selected_codes)&findings.status.isin(selected_status)]
        if levels and selected_levels: view=view[view.risk_level.isin(selected_levels)]
        elif levels: view=view.iloc[0:0]
        if query:
            mask=view[["title","exception_type","control_code","finding_id"]].astype(str).agg(" ".join,axis=1).str.contains(query,case=False,na=False)
            view=view[mask]
        st.caption(f"{len(view)} constat(s)")
        show=[c for c in ["finding_id","control_code","title","exception_type","risk_level","status","username","department","detected_at","last_seen_at","detection_count"] if c in view]
        st.dataframe(view[show],use_container_width=True,hide_index=True)
        if not view.empty:
            selected=st.selectbox("Détail du constat",view.finding_id.tolist(),format_func=lambda x:f"#{x} · {view.loc[view.finding_id.eq(x),'title'].iloc[0]}")
            row=view.loc[view.finding_id.eq(selected)].iloc[0]
            st.markdown("#### Détails et description")
            st.write(row.get("description") or "Aucune description enregistrée.")

elif page == "Recommendations Tracker":
    header("Recommendations Tracker", "Suivi des responsables, priorités, échéances et statuts")
    if recs.empty: empty("Aucune recommandation n’est disponible dans la base.")
    else:
        open_recs=recs[recs.status.isin(["Open","In Progress"])]
        overdue=open_recs[pd.to_datetime(open_recs.due_date,errors="coerce").dt.date < pd.Timestamp.now().date()] if "due_date" in open_recs else open_recs.iloc[0:0]
        a,b,c=st.columns(3); a.metric("Total",len(recs)); b.metric("À traiter",len(open_recs)); c.metric("En retard",len(overdue))
        x,y=st.columns(2)
        with x:
            st.subheader("Par priorité")
            counts=recs.priority.value_counts().reindex(PALETTE,fill_value=0).rename_axis("Priorité").reset_index(name="Recommandations")
            fig=px.bar(counts,x="Priorité",y="Recommandations",color="Priorité",color_discrete_map=PALETTE)
            st.plotly_chart(setup_plot(fig),use_container_width=True)
        with y:
            st.subheader("Par statut")
            counts=recs.status.value_counts().rename_axis("Statut").reset_index(name="Recommandations")
            fig=px.pie(counts,values="Recommandations",names="Statut",hole=.55)
            st.plotly_chart(setup_plot(fig),use_container_width=True)
        status_filter=st.multiselect("Filtrer par statut",sorted(recs.status.dropna().unique()),default=sorted(recs.status.dropna().unique()))
        view=recs[recs.status.isin(status_filter)]
        cols=[c for c in ["recommendation_id","finding_id","control_code","title","priority","status","assigned_to","due_date","created_at"] if c in view]
        st.dataframe(view[cols],use_container_width=True,hide_index=True)

else:
    header("Audit Execution History", "Historique des traitements et exécutions des contrôles AC-01 à AC-05")
    if runs.empty and executions.empty: empty("Aucun historique d’exécution n’est disponible. Les tables audit_runs et control_executions sont vides ou absentes.")
    if not runs.empty:
        st.subheader("Exécutions globales")
        st.dataframe(runs,use_container_width=True,hide_index=True)
        if "status" in runs:
            counts=runs.status.value_counts().rename_axis("Statut").reset_index(name="Exécutions")
            fig=px.pie(counts,values="Exécutions",names="Statut",hole=.6)
            st.plotly_chart(setup_plot(fig),use_container_width=True)
    if not executions.empty:
        st.subheader("Détail par contrôle")
        st.dataframe(executions,use_container_width=True,hide_index=True)
        counts=executions.groupby("control_code",as_index=False).agg(Executions=("execution_id","count"),Findings=("findings_count","sum"))
        fig=px.bar(counts,x="control_code",y="Findings",color_discrete_sequence=[BLUE],hover_data=["Executions"])
        fig.update_xaxes(title="Contrôle"); fig.update_yaxes(title="Constats détectés")
        st.plotly_chart(setup_plot(fig),use_container_width=True)

st.divider()
st.caption("Atlas Audit Analytics · Données issues de PostgreSQL · Les exceptions sont des signaux à investiguer, pas des conclusions de fraude.")
