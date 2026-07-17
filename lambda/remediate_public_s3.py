"""Bounded remediation for high-severity Security Hub S3 findings."""

from __future__ import annotations

import json
import logging
import os
from typing import Any

import boto3

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)
BLOCK_CONFIGURATION = {
    "BlockPublicAcls": True,
    "IgnorePublicAcls": True,
    "BlockPublicPolicy": True,
    "RestrictPublicBuckets": True,
}


def _dry_run() -> bool:
    return os.getenv("DRY_RUN", "true").lower() != "false"


def _bucket_name(resource: dict[str, Any]) -> str | None:
    if resource.get("Type") != "AwsS3Bucket":
        return None
    details = resource.get("Details", {}).get("AwsS3Bucket", {})
    if details.get("Name"):
        return details["Name"]
    resource_id = resource.get("Id", "")
    prefix = "arn:aws:s3:::"
    return resource_id[len(prefix) :] if resource_id.startswith(prefix) else None


def _findings(event: dict[str, Any]) -> list[dict[str, Any]]:
    findings = event.get("detail", {}).get("findings", [])
    if not isinstance(findings, list):
        raise ValueError("Event detail.findings must be a list")
    return findings


def lambda_handler(event: dict[str, Any], _context: Any) -> dict[str, Any]:
    """Block public access for each S3 bucket and update processed findings."""
    dry_run = _dry_run()
    results: list[dict[str, Any]] = []
    s3 = boto3.client("s3") if not dry_run else None
    securityhub = boto3.client("securityhub") if not dry_run else None

    for finding in _findings(event):
        finding_id = finding.get("Id")
        product_arn = finding.get("ProductArn")
        for resource in finding.get("Resources", []):
            bucket = _bucket_name(resource)
            if not bucket:
                continue
            LOGGER.info(
                json.dumps({"action": "block-public-access", "bucket": bucket, "dry_run": dry_run})
            )
            if not dry_run:
                s3.put_public_access_block(
                    Bucket=bucket,
                    PublicAccessBlockConfiguration=BLOCK_CONFIGURATION,
                )
                if finding_id and product_arn:
                    securityhub.batch_update_findings(
                        FindingIdentifiers=[{"Id": finding_id, "ProductArn": product_arn}],
                        Workflow={"Status": "RESOLVED"},
                        Note={
                            "Text": "Public access blocked by automated remediation.",
                            "UpdatedBy": "security-hub-s3-remediation",
                        },
                    )
            results.append({"bucket": bucket, "status": "planned" if dry_run else "remediated"})

    return {"dry_run": dry_run, "processed": len(results), "results": results}
