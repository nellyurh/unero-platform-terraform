# GitHub Actions <-> AWS OIDC — single-account model (ADR-017)

One AWS account. No long-lived keys: GitHub presents a signed OIDC token; STS returns
short-lived credentials only when the token's `aud` and `sub` (repo + ref/environment) match
a role's trust policy.

## Roles (created once by `oidc/`)
| Role | Assumable from | Permissions |
|------|----------------|-------------|
| `unero-terraform-plan` | any PR, `main` | ReadOnlyAccess + state backend RW; `secretsmanager:GetSecretValue` denied |
| `unero-dev-terraform` | `main` | apply policy |
| `unero-staging-terraform` | GitHub Environment `staging` | apply policy |
| `unero-production-terraform` | GitHub Environment `production` | apply policy |

## Why plan/apply are separate roles
Any PR can trigger `plan`, including a hostile one. The role a PR can assume therefore must
be unable to mutate infrastructure or read secrets. That's the plan role. Apply roles are
assumable only from `main` (dev) or a reviewer-approved Environment (staging/production).

## Why per-env apply roles in a single account
The permissions are identical; the **trust** differs. `unero-production-terraform` can only be
assumed by a job attached to the protected `production` GitHub Environment — the human
approval and the IAM trust are the same boundary. It is also the multi-account seam: to split
accounts later, recreate the same-named role in the new account and repoint that env's
backend; CI does not change.

## Trust model
```
PR            -> unero-terraform-plan              terraform plan   (read-only)
push to main  -> unero-dev-terraform               terraform apply  dev
push to main  -> Environment approval (staging)    -> unero-staging-terraform      apply
push to main  -> Environment approval (production) -> unero-production-terraform   apply
```

## Required GitHub configuration
- Secret `AWS_ACCOUNT_ID` — the single 12-digit account ID (output by `oidc/` apply).
- GitHub Environments `dev`, `staging`, `production`; required reviewers on staging+production.

Bootstrap of a brand-new account: see `docs/BOOTSTRAP.md`.
