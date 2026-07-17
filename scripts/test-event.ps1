[CmdletBinding()]
param([string]$FunctionName = "security-hub-s3-remediation")
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Payload = Join-Path $Root "tests/fixtures/security_hub_s3_finding.json"
$Output = Join-Path $env:TEMP "security-remediation-response.json"

aws lambda invoke `
    --function-name $FunctionName `
    --cli-binary-format raw-in-base64-out `
    --payload "fileb://$Payload" `
    $Output

Get-Content $Output

