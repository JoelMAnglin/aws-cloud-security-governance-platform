# Troubleshooting Runbook

## Terraform initialization is incomplete

**Symptom:** `terraform validate` says a required provider is unavailable.

Run initialization to completion. Provider installation can exceed short terminal timeouts.

```powershell
docker run --rm -v "${PWD}:/workspace" -w /workspace/terraform `
  hashicorp/terraform:1.10.5 init -backend=false
```

Commit `.terraform.lock.hcl`; do not commit `.terraform/`.

## SCP access is unexpectedly denied

Remember that SCPs do not grant access. Effective permission requires an allow from the identity path
and must remain within every applicable boundary/SCP. An explicit deny wins. Inspect the account's OU
ancestry, attached policies, permission boundary, session policy, and resource policy. Move only a
sandbox account during initial testing; never experiment at the organization root.

## Identity Center resources are not created

All three values are required: instance ARN, identity store ID, and existing security group ID. The
module intentionally creates no permission set when any is null. Verify delegated-administrator
permissions and that the group belongs to the configured Identity Store.

## HCL format or parse failures

Terraform single-line block syntax supports one argument only. Expand variables, principals,
conditions, and nested blocks onto multiple lines, then run `terraform fmt -recursive` before
validation.

## Security Hub findings do not reach EventBridge

Confirm Security Hub CSPM is enabled in the same region, inspect the rule event pattern, check the
EventBridge `MatchedEvents` metric, and inspect failed invocations/dead-letter configuration in an
enterprise extension. Security Hub sends new and updated findings as events.

## GuardDuty coverage is incomplete

Confirm the detector and individual `aws_guardduty_detector_feature` resources. Organization-level
coverage requires delegated administration and auto-enable configuration beyond this single-account
root module. Coverage status can take time to update.

## Lambda logs a plan but does not change S3

This is the default. Set `enable_automatic_remediation = true` only after sandbox validation and owner
approval. Confirm the deployed environment variable is `DRY_RUN=false`, then check IAM, CloudWatch
Logs, Lambda errors/throttles, and the finding resource type.

## Lambda is invoked but skips a finding

The handler processes only resources whose ASFF type is `AwsS3Bucket`. Inspect `detail.findings`,
`Resources[].Type`, bucket name details, and EventBridge input transformation. Replay the sanitized
fixture locally before changing production logic.

## Encrypted SNS delivery fails

Validate that the customer-managed KMS key permits SNS to generate data keys and decrypt under the
correct account condition. Then confirm the topic resource policy permits only the intended
EventBridge rule. Inspect EventBridge failed-invocation metrics.

## CI dependency audit fails

Upgrade the affected direct dependency and rerun tests. Audit in a clean virtual environment; a
developer's global Python installation may include unrelated editable projects and vulnerable tools.
The workflow upgrades pip before installing this project's constrained dependencies.

## Full reset

```powershell
Remove-Item -Recurse -Force .\terraform\.terraform
Remove-Item -Force .\terraform\.terraform.lock.hcl
docker run --rm -v "${PWD}:/workspace" -w /workspace/terraform `
  hashicorp/terraform:1.10.5 init -backend=false
```

Review the regenerated lock file before committing it.

