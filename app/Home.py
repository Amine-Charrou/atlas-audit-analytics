from __future__ import annotations

import pandas as pd
import streamlit as st

st.set_page_config(page_title="Atlas Audit Analytics", page_icon="🔎", layout="wide")

# Démonstration uniquement : données entièrement fictives.
DEMO_USERS = [
    {"user_id": "U101", "department": "Finance", "role": "Admin", "authorized": False, "status": "Active"},
    {"user_id": "U102", "department": "IT", "role": "Admin", "authorized": True, "status": "Active"},
    {"user_id": "U103", "department": "Operations", "role": "Viewer", "authorized": True, "status": "Active"},
    {"user_id": "U104", "department": "Finance", "role": "Editor", "authorized": True, "status": "Active"},
    {"user_id": "U105", "department": "Human Resources", "role": "Viewer", "authorized": True, "status": "Inactive"},
    {"user_id": "U106", "department": "Finance", "role": "Admin", "authorized": None, "status": "Active"},
]

st.title("Atlas Audit Analytics")
st.caption("Plateforme pédagogique d'IT Audit & Data Analytics · Jeu de démonstration fictif")

users = pd.DataFrame(DEMO_USERS)
findings = users[
    users["role"].eq("Admin")
    & users["status"].eq("Active")
    & users["authorized"].ne(True)
]

col1, col2, col3 = st.columns(3)
col1.metric("Comptes analysés", len(users))
col2.metric("Comptes actifs", int(users["status"].eq("Active").sum()))
col3.metric("Exceptions à investiguer", len(findings))

st.subheader("AC-01 · Administrateurs actifs sans autorisation confirmée")
st.write(
    "Le contrôle signale les comptes actifs de rôle Admin dont l'autorisation est "
    "False ou inconnue (NULL). Une exception est un signal à investiguer, pas une "
    "preuve de fraude."
)
st.dataframe(findings, use_container_width=True, hide_index=True)

with st.expander("Critères et limites"):
    st.markdown(
        "- Critères : rôle `Admin`, statut `Active`, autorisation différente de `True`.\n"
        "- Une valeur manquante doit être rapprochée des preuves d'approbation.\n"
        "- Vérifier les responsabilités, l'approbation et la qualité des données avant toute conclusion."
    )

st.caption("Étape de démarrage : les données sont en mémoire. PostgreSQL sera connecté dans un jalon ultérieur.")