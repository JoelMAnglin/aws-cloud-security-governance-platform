# Tier 3 Runbook: High-Severity Public S3 Exposure

## Trigger

Security Hub imports a HIGH or CRITICAL finding for an `AwsS3Bucket`. EventBridge sends it to the
remediation function and the notification path.

## Severity and escalation

- **SEV-1:** confirmed public access to regulated, credential, customer, or production-sensitive data.
- **SEV-2:** public control exists but data sensitivity/exposure is not yet confirmed.
- Notify the incident commander, bucket owner, privacy/legal contact when applicable, and the cloud
  platform lead. Preserve a single incident timeline.

## Triage

1. Validate finding ID, account, region, bucket, first/last observed time, and workflow status.
2. Determine whether exposure is ACL-, bucket-policy-, access-point-, or account-block-related.
3. Inspect CloudTrail data and management events; do not modify evidence during collection.
4. Classify data sensitivity, intended public use, affected principals, and evidence of access.
5. Confirm whether dry-run automation proposed the correct bucket and control.

## Containment

1. Obtain incident commander approval unless active exfiltration requires emergency action.
2. Enable all four bucket public-access-block settings.
3. Remove unauthorized bucket/access-point policy statements and ACL grants.
4. Revoke exposed credentials or sessions, and apply a scoped deny when necessary.
5. Preserve the previous configuration, CloudTrail evidence, finding JSON, and change identity.

## Eradication and recovery

1. Identify the creation path: console, IaC, deployment role, compromised identity, or exception drift.
2. Fix the source template or pipeline; do not rely only on a console correction.
3. Validate required applications with the owner.
4. Confirm Security Hub reevaluation and update the finding with evidence—not just status.
5. Remove temporary containment only after the corrected design is approved.

## Post-incident

- Document timeline, impact, detection gap, root cause, and contributing factors.
- Add a regression test or policy gate for the creation path.
- Review similar buckets, accounts, and roles for systemic exposure.
- Track corrective actions with owner and due date; review effectiveness after completion.

## Useful commands

```bash
aws s3api get-public-access-block --bucket BUCKET
aws s3api get-bucket-policy-status --bucket BUCKET
aws s3api get-bucket-policy --bucket BUCKET
aws s3api get-bucket-acl --bucket BUCKET
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=BUCKET
```

