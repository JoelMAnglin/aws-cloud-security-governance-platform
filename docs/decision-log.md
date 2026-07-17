# Architecture Decision Log

## ADR-001: Terraform modules over console instructions

**Decision:** express controls as versioned Terraform modules.

**Reason:** peer review, repeatability, policy scanning, change plans, and rollback history are core
requirements for enterprise security engineering.

## ADR-002: Guardrails are opt-in

**Decision:** create SCP documents but require `attach_guardrails = true` before attaching them.

**Reason:** AWS recommends testing SCP effects in a sandbox OU before wider rollout. An incorrect SCP
can interrupt every member-account workload under the target.

## ADR-003: Remediation defaults to dry-run

**Decision:** Lambda logs proposed S3 changes until `enable_automatic_remediation = true`.

**Reason:** public access might be intentional. Automation should begin with observation, ownership
validation, and exception handling before enforcement.

## ADR-004: CI receives no AWS credentials

**Decision:** pull-request validation runs entirely offline.

**Reason:** untrusted contribution content must not inherit cloud mutation privileges. Deployment is a
separate, approved workflow outside this reference repository.

