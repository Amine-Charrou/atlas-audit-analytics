
## AC-01 — Active Privileged Accounts Without Confirmed Authorization

**Domain:** Identity & Access Management (IAM)

**Risk:**
Users may retain active privileged access without documented authorization.

**Control Objective:**
Identify active accounts assigned to high or critical privilege roles where authorization is not confirmed.

**Scope:**
- Active user accounts
- Active role assignments
- High and Critical privilege levels

**Detection Criteria:**
- User status = Active
- Role assignment is not revoked
- Privilege level IN (High, Critical)
- Authorization IS NOT TRUE

**Expected Output:**
- User information
- Employee information
- Department
- Assigned role
- Privilege level
- Authorization status
- Exception classification

**Exception Types:**
- NOT_AUTHORIZED
- UNKNOWN_AUTHORIZATION

**Test Results:**
6 functional test scenarios passed.

**Audit Interpretation:**
Detected exceptions require investigation and supporting documentation. They do not automatically constitute confirmed control failures or fraud.

**Status:** Implemented and tested.
