# AWS Security Pillar Control Mapping

This matrix translates architecture objectives into deployable controls and evidence. It is a
starting point for a formal control library, not a certification claim.

| Security Pillar practice | Technical implementation | Evidence | Owner |
|---|---|---|---|
| SEC01-BP01 Separate workloads using accounts | Organization/OU design and SCP attachment targets | OU inventory, policy attachment report | Cloud platform lead |
| SEC01-BP03 Identify and validate control objectives | This mapping, ADRs, pull-request review | Approved architecture change | Security architecture |
| SEC01-BP06 Automate deployment of standard controls | Versioned Terraform modules and CI validation | Plan, approval, apply log | Security engineering |
| SEC02-BP01 Use strong sign-in mechanisms | IAM Identity Center with enterprise IdP and MFA as deployment prerequisite | IdP policy and sign-in logs | IAM team |
| SEC02-BP02 Use temporary credentials | Two-hour Identity Center permission-set session | Permission-set configuration | IAM team |
| SEC02-BP04 Rely on a centralized identity provider | Group-assigned Identity Center access | Assignment report | IAM team |
| SEC03-BP01 Define access requirements | SecurityAdmin task policy and developer boundary | Policy review record | Control owner |
| SEC03-BP02 Grant least privilege | Intersection of SCP, boundary, and identity policies | IAM Access Analyzer and last-accessed review | IAM governance |
| SEC04-BP01 Configure service and application logging | Encrypted Lambda logs; Security Hub and GuardDuty signals | Log-group retention and detector status | Security operations |
| SEC04-BP02 Capture logs, findings, and metrics centrally | Central security-account architecture | Aggregator/member coverage report | Security operations |
| SEC04-BP04 Initiate remediation for non-compliant resources | EventBridge to dry-run-first Lambda | Invocation log and updated finding | Security automation |
| SEC10-BP01 Identify key personnel and external resources | Tier 3 escalation and RACI | On-call roster and exercise record | Incident commander |
| SEC10-BP02 Develop incident management plans | S3 exposure runbook | Tabletop results and after-action report | Security operations |
| SEC10-BP06 Pre-deploy tools | Terraform, event fixture, test script, and bounded permissions | CI run and test event | Security engineering |

## Evidence lifecycle

1. Architecture approves the objective and control pattern.
2. Engineering changes Terraform through a reviewed pull request.
3. CI produces immutable validation evidence.
4. An authorized operator reviews `terraform plan` and deploys from a protected environment.
5. Security operations verifies detector coverage, event delivery, and remediation behavior.
6. Control owners review exceptions, access data, and operational metrics on a defined cadence.

## Authoritative references

- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [AWS Organizations SCP behavior](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html)
- [IAM permissions boundaries](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)
- [IAM Identity Center delegated administration](https://docs.aws.amazon.com/singlesignon/latest/userguide/delegated-admin.html)
- [Security Hub automated response with EventBridge](https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cloudwatch-events.html)
- [GuardDuty findings with EventBridge](https://docs.aws.amazon.com/guardduty/latest/ug/guardduty_findings_eventbridge.html)

