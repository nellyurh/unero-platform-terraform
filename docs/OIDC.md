# GitHub Actions <-> AWS OIDC (ADR-017)

No long-lived AWS keys. GitHub presents a signed OIDC token; AWS STS returns short-lived
credentials only if the token's `sub` (repo + ref/environment) and `aud` match the role's
trust policy.

## Roles (per workload account)
| Role | Assumable from | Permissions |
|------|----------------|-------------|
| `unero-<env>-terraform-plan` | PRs + `main` | ReadOnlyAccess + state-backend RW; `secretsmanager:GetSecretValue` denied |
| `unero-<env>-terraform` | `main` (dev/load-test) or GitHub Environment `<env>` (staging/production) | apply policy (default AdministratorAccess; scope + boundary in prod) |

## Trust model
```
PR            -> plan role  (read-only)      terraform plan
push to main  -> apply role (write)          terraform apply   [dev, load-test]
push to main  -> GitHub Environment approval -> apply role      [staging, production]
```
Production/staging binding uses the `environment:<env>` subject claim, so the apply role can
only be assumed from a job attached to that protected Environment — the approval gate and the
IAM trust are the same boundary.

## Bootstrap (once per account, with that account's credentials)
```bash
cd oidc
cp terraform.tfvars.example terraform.tfvars   # set environment + state ARNs (no account IDs in git)
terraform init -backend-config="bucket=unero-terraform-state" \
               -backend-config="region=af-south-1" \
               -backend-config="dynamodb_table=unero-terraform-locks" \
               -backend-config="key=oidc/<env>/terraform.tfstate"
terraform apply
```
Set `create_oidc_provider = false` if the account already has the GitHub OIDC provider.

## Required GitHub secrets
`DEV_ACCOUNT_ID`, `STAGING_ACCOUNT_ID`, `PRODUCTION_ACCOUNT_ID` (12-digit account IDs — not
secret, but kept out of git). Add `LOAD_TEST_ACCOUNT_ID` if load-test joins CI.

## OPEN — state-account decision (ARB, blocks true isolation)
Today every environment shares one state bucket in the baseline account, but the org is
multi-account. A `dev` plan/apply role in the dev account cannot reach a state bucket in the
baseline account without a cross-account bucket policy. Two resolutions:
- **A (central state):** keep one state bucket; add cross-account bucket/KMS policies granting
  each `unero-<env>-terraform*` role access. Simpler; weaker isolation.
- **B (state per account):** one state bucket + lock table per workload account; each env's
  backend points at its own. Full isolation; more bootstrap.
Recommend **B** for the fintech posture. Resolve before wiring apply in staging/production.
Until resolved, apply `oidc/` in the account that holds the shared state bucket to unblock
`dev` plan.
