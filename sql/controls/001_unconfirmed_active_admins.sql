-- AC-01: Active admin accounts without confirmed authorization.
-- FALSE and NULL are both flagged for investigation.
SELECT
    user_id,
    department,
    role,
    authorized,
    status
FROM users
WHERE role = 'Admin'
  AND status = 'Active'
  AND authorized IS NOT TRUE
ORDER BY user_id;