[CmdletBinding()]
param([switch]$SkipContainerScans)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Push-Location $Root
try {
    python -m pip install -e ".[dev]"
    python -m ruff check .
    python -m ruff format --check .
    python -m pytest
    python -m bandit -q -r lambda
    python -m pip_audit

    if (-not $SkipContainerScans) {
        docker run --rm -v "${Root}:/workspace" -w /workspace/terraform hashicorp/terraform:1.10.5 fmt -check -recursive
        docker run --rm -v "${Root}:/workspace" -w /workspace/terraform hashicorp/terraform:1.10.5 init -backend=false
        docker run --rm -v "${Root}:/workspace" -w /workspace/terraform hashicorp/terraform:1.10.5 validate
        docker run --rm -v "${Root}:/workspace" aquasec/trivy:0.69.3 fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 /workspace
    }
} finally {
    Pop-Location
}

