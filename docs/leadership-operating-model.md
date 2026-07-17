# Security Engineering Leadership Operating Model

## Mission

Translate architectural blueprints into controls that are usable, testable, measurable, and owned.
The lead engineer is accountable for technical direction and escalation quality; control owners remain
accountable for risk decisions.

## Team topology

| Role | Primary accountability |
|---|---|
| Security engineering lead | Architecture alignment, prioritization, design approval, Tier 3 escalation |
| Identity engineer | Permission sets, boundaries, access reviews, federation, break-glass controls |
| Cloud detection engineer | Security Hub/GuardDuty coverage, routing, tuning, attack-path analysis |
| Security automation engineer | CI gates, Lambda remediations, tests, rollback and observability |
| Platform partner | Organization structure, landing zone, networking, workload enablement |
| Risk/control owner | Policy intent, exceptions, evidence acceptance, residual-risk decisions |

## Delivery workflow

1. **Intake:** capture risk, affected workloads, threat scenario, owner, and success metric.
2. **Design:** map Security Pillar guidance to preventive, detective, responsive, and recovery controls.
3. **Threat model:** identify abuse cases, trust boundaries, failure modes, and exception paths.
4. **Implement:** use least privilege, safe defaults, tests, observable outcomes, and rollback.
5. **Review:** require security and platform approval for organization-wide changes.
6. **Progressive rollout:** sandbox OU, non-production OU, limited production cohort, then broader use.
7. **Operate:** measure coverage, false positives, mean time to acknowledge/remediate, and exceptions.
8. **Improve:** convert incidents and deployment friction into backlog items and regression tests.

## Change gates

- Two-person review for SCP, KMS policy, Identity Center, and automated containment changes.
- Recorded plan output and named approver before deployment.
- Tested recovery or rollback for every enforcing control.
- Time-bound exception with business owner, compensating control, and expiration date.
- Break-glass access is separate, monitored, short-lived, and exercised at least twice yearly.

## Suggested metrics

- Percentage of accounts covered by Security Hub and GuardDuty
- Percentage of human access delivered through federation and MFA
- Privileged permission sets unused for 30/60/90 days
- High-severity finding mean time to acknowledge and contain
- Automated remediation success, failure, rollback, and false-positive rates
- Control exception count, age, and overdue percentage
- CI security gate pass rate and time to developer feedback

