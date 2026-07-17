# Build Troubleshooting Journal

Only issues observed during the real local build and validation are recorded here.

| Date | Symptom | Root cause | Resolution | Verification |
|---|---|---|---|---|
| 2026-07-17 | Editable Python install failed with “multiple top-level packages” | Setuptools auto-discovery treated `lambda` and `terraform` as packages | Added an explicit setuptools build system and empty `py-modules` list | `pip install -e ".[dev]"` completed |
| 2026-07-17 | Ruff reported two over-length lines and format drift | Initial Lambda logging and finding-update calls exceeded the configured 100-character limit | Reformatted Lambda and tests and split structured arguments | `ruff check` and `ruff format --check` passed |
| 2026-07-17 | Pytest rejected coverage arguments during the first run | The failed editable install meant `pytest-cov` had not been installed | Fixed package discovery and reinstalled development dependencies | Four tests passed with 93% coverage |
| 2026-07-17 | Dependency audit reported vulnerable pip and pytest versions | The existing workstation environment used pip 25.0.1 and pytest 8.4.2 | Upgraded pip and constrained pytest to 9.0.3 or newer | Clean-environment dependency install and tests passed |
| 2026-07-17 | Terraform format could not parse several blocks | Multiple arguments and nested blocks were compressed into invalid single-line HCL | Expanded variables, principals, conditions, retry policy, and GuardDuty blocks | `terraform fmt` completed and syntax advanced to validation |
| 2026-07-17 | Terraform validate could not find providers after a short run | Provider download had not completed before the terminal call yielded | Allowed `terraform init` to finish and committed the generated lock file | Terraform initialized with AWS 6.55.0 and Archive 2.8.0 |
| 2026-07-17 | Terraform warned that GuardDuty `datasources` was deprecated | AWS provider v6 moves features to dedicated detector-feature resources | Replaced the deprecated block with `aws_guardduty_detector_feature` resources | Terraform validated with no warnings |
| 2026-07-17 | Trivy raised HIGH AWS-0136 for the findings topic | SNS used the AWS-managed `alias/aws/sns` key | Added a rotating customer-managed KMS key with a scoped SNS service statement | Trivy reported zero HIGH/CRITICAL misconfigurations |

