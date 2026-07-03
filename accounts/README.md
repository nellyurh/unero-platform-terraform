# accounts/ — NOT APPLIED (single-account model)

ARB decision (2026-07-03): Unero runs in a **single AWS account**. Environment separation is
per-env Terraform state keys, per-env resources (VPC/cluster/DB per environment), per-env
apply roles, and GitHub Environment approvals for staging/production.

This directory (AWS Organization, OUs, per-env workload accounts, SCP attachment) is retained
as the evolution path if/when Unero splits into multiple accounts, but it is **not part of the
active substrate and must not be applied**. The org-wide SCP guardrails it would attach live
on in spirit through CI scanning (`policies/`).
