
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


## AC-02 — Former Employees with Active Accounts

**Domain:** Identity & Access Management (IAM)

**Risk:**
Former employees may retain access to organizational information systems after leaving the company.

**Control Objective:**
Identify former employees whose user accounts remain active.

**Scope:**
- Employees with a recorded termination timestamp
- Associated user accounts

**Detection Criteria:**
- termination_at IS NOT NULL
- User status = Active

**Expected Output:**
- Employee identification
- Department
- Username
- Termination timestamp
- Account status
- Deactivation timestamp
- Time elapsed since termination

**Exception Type:**
- FORMER_EMPLOYEE_ACTIVE_ACCOUNT

**Test Results:**
4 functional test scenarios passed.

**Audit Interpretation:**
An active account associated with a former employee is an exception requiring investigation. It should be assessed against the organization's access revocation policy.

**Status:** Implemented and tested.

