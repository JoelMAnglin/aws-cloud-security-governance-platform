# Architecture and Trust Boundaries

## Communication objective

Give cloud security engineers a repeatable way to translate enterprise architecture into preventive,
detective, responsive, and recovery controls while keeping production changes reviewable.

## Account model

The reference design assumes AWS Organizations with all features enabled:

- **Management account:** organization governance only; avoid routine workloads and human access.
- **Security tooling account:** delegated administration, Security Hub, GuardDuty, EventBridge,
  encrypted logs, and security notifications.
- **Identity account:** IAM Identity Center delegated administration and permission-set lifecycle.
- **Workload accounts:** isolated production and non-production workloads protected by OU guardrails.
- **Log archive account:** immutable organization audit logs in a production extension of this lab.

## Control planes

### Preventive

SCPs define the maximum permissions available in member accounts. A workload permissions boundary
limits roles that developers create. Neither mechanism grants permissions. Identity policies,
boundaries, SCPs, session policies, and applicable resource policies combine during authorization.

### Identity

IAM Identity Center supplies short-duration, group-assigned access. The example SecurityAdmin
permission set combines read-oriented `SecurityAudit` access with a narrow incident-response policy.
Production programs should source group membership from the enterprise identity provider and require
strong authentication.

### Detective

Security Hub CSPM normalizes posture findings, while GuardDuty produces threat findings. EventBridge
routes service events to operations without polling. Organization-wide delegated administration and
cross-region aggregation are documented extensions because they require organization-specific IDs.

### Responsive

The Lambda example handles only S3 bucket findings, applies all four public-access-block settings,
and marks the finding resolved. It is dry-run by default, uses reserved concurrency, and receives only
matching high-severity S3 events. Production remediation should use approvals for actions with high
business impact.

### Delivery

Pull requests validate formatting and Terraform syntax, test remediation logic, audit dependencies,
scan Python, scan IaC, and search for committed secrets. CI intentionally has no AWS credentials and
cannot mutate accounts.

## Threat model

| Threat | Control | Residual consideration |
|---|---|---|
| Administrator disables monitoring | Security-service protection SCP | SCP exceptions require rigorous role governance |
| Developer creates an over-privileged role | Permissions boundary plus review | Resource policies and role sessions require separate analysis |
| Compromised external principal accesses data | Organization data-perimeter condition | Validate service-to-service exceptions before enforcement |
| Public S3 exposure | Security Hub finding plus EventBridge and Lambda | Dry-run until owner approval; public access block may affect intended websites |
| Malicious or vulnerable code enters IaC | CI scanning and tests | Tools reduce risk but do not replace architecture review |
| High-severity finding is ignored | SNS escalation and Tier 3 runbook | Integrate with the enterprise case-management or SIEM platform |

## Deployment boundaries

The root module targets one account and one region. Enterprise deployment should add provider aliases,
delegated-administrator resources, cross-region aggregation, organization auto-enable settings, log
archive controls, and a tested break-glass process.

