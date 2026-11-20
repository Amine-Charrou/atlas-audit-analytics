
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



## AC-03 — Account Deactivation SLA

**Domain:** Identity & Access Management (IAM)

**Risk:**
Former employees may retain access to organizational systems beyond the permitted deactivation period.

**Control Objective:**
Verify that user accounts are deactivated within 24 hours after employee termination.

**Scope:**
- Employees with a recorded termination timestamp
- Associated user accounts

**Detection Criteria:**
- Termination timestamp is available
- Account deactivation is evaluated against a 24-hour SLA

**Compliance Statuses:**
- COMPLIANT
- NON_COMPLIANT
- PENDING_OVERDUE
- PENDING_WITHIN_SLA
- DEACTIVATED_BEFORE_TERMINATION

**Policy Assumption:**
The 24-hour deactivation SLA is an illustrative project rule and must be validated against the organization's actual access management policy.

**Test Results:**
6 functional test scenarios.

**Audit Interpretation:**
A delayed deactivation or overdue active account represents an exception requiring investigation. Early deactivation should also be reviewed to confirm that it was appropriate.

**Status:** Implemented and tested.

---

## AC-04 — Unapproved Role Assignments

**Domain:** Identity & Access Management (IAM)

**Risk:**
Users may receive access privileges without appropriate authorization or independent approval.

**Control Objective:**
Identify active role assignments without complete approval evidence or with self-approval.

**Scope:**
- Active user-role assignments
- Assignment records
- Approval evidence

**Detection Criteria:**
- Missing approval timestamp
- Missing approver
- Missing approval reference
- Assignment approved by the same employee who assigned the role

**Exception Types:**
- MISSING_APPROVAL_EVIDENCE
- SELF_APPROVED_ASSIGNMENT

**Test Results:**
3 functional test scenarios.

**Audit Interpretation:**
An exception indicates that the organization cannot demonstrate a complete and independent approval process for the role assignment. It does not automatically prove that the access was unauthorized.

**Status:** Implemented and tested.

---

## AC-05 — Segregation of Duties (SoD)

**Domain:** Identity & Access Management (IAM)

**Risk:**
A single user may accumulate incompatible permissions, allowing them to perform multiple sensitive activities without adequate separation of responsibilities.

**Control Objective:**
Identify users holding conflicting permissions.

**Scope:**
- Active user accounts
- Active role assignments
- Role-permission mappings

**Conflict Rule:**
- CREATE_USERS
- ASSIGN_ROLES

A user holding both permissions is flagged for review.

**Exception Type:**
- SOD_CONFLICT_DETECTED

**Test Results:**
2 functional test scenarios.

**Audit Interpretation:**
A detected conflict indicates a potential segregation-of-duties weakness. The conflict must be assessed against the organization's approved SoD matrix, business responsibilities and compensating controls.

**Policy Assumption:**
The initial conflict rule is illustrative and should be expanded and validated with business stakeholders.

**Status:** Implemented and tested.
