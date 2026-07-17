import importlib.util
import json
from pathlib import Path
from unittest.mock import MagicMock, patch

MODULE_PATH = Path(__file__).parents[1] / "lambda" / "remediate_public_s3.py"
SPEC = importlib.util.spec_from_file_location("remediate_public_s3", MODULE_PATH)
remediation = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(remediation)
FIXTURE = Path(__file__).parent / "fixtures" / "security_hub_s3_finding.json"


def load_event():
    return json.loads(FIXTURE.read_text(encoding="utf-8"))


def test_dry_run_is_default_and_makes_no_aws_calls(monkeypatch):
    monkeypatch.delenv("DRY_RUN", raising=False)
    with patch.object(remediation.boto3, "client") as client:
        result = remediation.lambda_handler(load_event(), None)
    assert result["dry_run"] is True
    assert result["processed"] == 1
    assert result["results"][0] == {"bucket": "portfolio-public-bucket", "status": "planned"}
    client.assert_not_called()


def test_live_mode_blocks_bucket_and_resolves_finding(monkeypatch):
    monkeypatch.setenv("DRY_RUN", "false")
    s3, securityhub = MagicMock(), MagicMock()

    def client(name):
        return {"s3": s3, "securityhub": securityhub}[name]

    with patch.object(remediation.boto3, "client", side_effect=client):
        result = remediation.lambda_handler(load_event(), None)

    assert result["results"][0]["status"] == "remediated"
    s3.put_public_access_block.assert_called_once_with(
        Bucket="portfolio-public-bucket",
        PublicAccessBlockConfiguration=remediation.BLOCK_CONFIGURATION,
    )
    securityhub.batch_update_findings.assert_called_once()


def test_non_s3_resources_are_ignored(monkeypatch):
    monkeypatch.setenv("DRY_RUN", "true")
    event = load_event()
    event["detail"]["findings"][0]["Resources"][0]["Type"] = "AwsEc2Instance"
    result = remediation.lambda_handler(event, None)
    assert result["processed"] == 0


def test_malformed_findings_rejected():
    event = {"detail": {"findings": {}}}
    try:
        remediation.lambda_handler(event, None)
    except ValueError as error:
        assert "must be a list" in str(error)
    else:
        raise AssertionError("Expected malformed event to fail")
