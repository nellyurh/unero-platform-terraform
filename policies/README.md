# policies/

Guardrails enforced two ways:

- **CI scanning** — Checkov (`checkov.yaml`) + tfsec (`tfsec.yaml`) run on every PR
  (`.github/workflows/terraform-ci.yml`) and fail the build on HIGH/CRITICAL findings:
  encryption-on, no public buckets, described security groups, encrypted queues.
- **Preventive SCPs** — `scp-guardrails.json` is attached org-wide: deny unencrypted S3
  uploads, deny disabling CloudTrail, deny operating outside `af-south-1`/`eu-west-1`.

Detective (CI) catches what preventive (SCP) can't express; preventive stops what review
might miss. Both are required.
