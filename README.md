# unero-platform-terraform

Cross-account, cross-service AWS substrate for the Unero platform. **Nothing deploys until this is applied** — it sits at the top of the Phase 1 build order (`DEPENDENCY_MAP.md`, Engineering Foundation Proposal §1.3, §4).

Governs: AWS Organization + accounts, network (VPC), compute cluster (ECS Fargate), data (Aurora Serverless v2), cache (ElastiCache Redis), messaging (SQS + EventBridge), encryption (KMS), and the per-service baseline module that every service's own `infra/terraform/` composes.

- **Primary region:** `af-south-1` · **DR region:** `eu-west-1` (ADR-010, ADR-018)
- **Compute:** ECS Fargate (ADR-010) · **DB:** Aurora Serverless v2 PostgreSQL (ADR-008)
- **Cache/idempotency:** ElastiCache Redis (ADR-009) · **Messaging:** SQS + EventBridge (ADR-003, ADR-011)
- **Secrets:** AWS Secrets Manager, fetched at boot via task IAM roles (ADR-017)

## Layout

```
modules/        reusable building blocks (vpc, ecs-cluster, aurora, elasticache,
                eventbridge-bus, sqs-queue, kms-key, task-iam-role, service-baseline)
accounts/       AWS Organization: management, security, shared-services, workloads OUs
baseline/       org-wide roots: KMS CMKs, IAM baseline, EventBridge bus, WAF, log archive
environments/   dev · staging · production (+eu-west-1 DR) · load-test
policies/       Checkov + tfsec config and deny rules (encryption-on, no-public-buckets)
```

## Change control (RELEASE_PROCESS.md §4.6)

Plan on PR, apply on merge, lowest environment first. Tier-1 resources (KMS, IAM, DB)
require >= 2 approvals. ClickOps is blocked at the IAM level in production. Every PR is
scanned by Checkov + tfsec (`policies/`).

## Usage

```bash
make init   ENV=dev
make plan   ENV=dev
make apply  ENV=dev          # applied via CI on merge; local apply for dev only
```

State is remote (S3 + DynamoDB lock), one state key per environment — see `environments/<env>/backend.tf`.

## A note on ADR-017 "IRSA"

ADR-017 references "IAM Roles for Service Accounts (IRSA)". IRSA is the EKS mechanism; this
platform runs on **ECS Fargate** (ADR-010), whose equivalent is **ECS task roles + task
execution roles**. `modules/task-iam-role` implements that equivalent. This is an
implementation faithfulness note, not an architecture change; a one-line ADR-017 clarification
is worth authoring when convenient (does not block substrate apply).
