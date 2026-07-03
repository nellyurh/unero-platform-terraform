# Bootstrap: brand-new AWS account -> CI-managed platform

Order matters: credentials -> backend -> OIDC -> secrets -> CI takes over. Human credentials
are used exactly twice (backend + OIDC first-apply); everything after is OIDC.

## 0. Prerequisites
- AWS account (note the 12-digit ID), an IAM identity you control with AdministratorAccess
  (root only to create that identity, then stop using root; enable MFA on both).
- Locally: terraform >= 1.7, AWS CLI v2, gh CLI, this repo cloned.

## 1. AWS CLI
```bash
aws configure --profile unero          # access key, secret, region af-south-1, output json
export AWS_PROFILE=unero
aws sts get-caller-identity            # verify: correct account, your admin identity
```
Required permissions for bootstrap: AdministratorAccess (it creates IAM roles, KMS, S3,
DynamoDB). After bootstrap, humans need far less; CI does the applying.

## 2. Backend (state bucket + lock + KMS) — via baseline/
`baseline/` already defines the state bucket (versioned, KMS-encrypted, public-access-blocked,
DR-replicated to eu-west-1), the lock table, and the root CMKs. Chicken-and-egg: its own
backend points at the bucket it creates, so the first apply is local-state, then migrated:
```bash
cd baseline
terraform init -backend=false
terraform plan     # KMS keys, state bucket + replica, lock table, CloudTrail
terraform apply
terraform init     # backend now exists -> answer "yes" to migrate local state into S3
```
Known issue: the org CloudTrail in baseline/ may fail without a bucket policy (tracked for
the next delta). If it does, target the backend first:
`terraform apply -target=aws_s3_bucket.state -target=aws_s3_bucket_versioning.state \
 -target=aws_s3_bucket_server_side_encryption_configuration.state \
 -target=aws_s3_bucket_public_access_block.state -target=aws_dynamodb_table.locks \
 -target=module.kms_data -target=module.kms_secrets -target=module.kms_logs`

## 3. OIDC provider + roles — via oidc/
```bash
cd ../oidc
cp terraform.tfvars.example terraform.tfvars   # defaults are fine
terraform init      # backend exists now; if you ran oidc before the backend, use -backend=false then re-init to migrate
terraform plan      # 1 OIDC provider, 1 plan role, 3 apply roles (+ policies)
terraform apply
terraform output account_id   # -> value for the GitHub secret
```
If the account already has the GitHub OIDC provider: set `create_oidc_provider = false` and
`oidc_provider_arn` in terraform.tfvars.

## 4. GitHub configuration
```bash
gh secret set AWS_ACCOUNT_ID --repo nellyurh/unero-platform-terraform --body "<12-digit id>"
```
Then in repo Settings -> Environments: create `dev`, `staging`, `production`; add required
reviewers to staging and production.

## 5. Hand over to CI
Open/rerun a PR: `plan` assumes `unero-terraform-plan` and goes green. Merge to main:
`terraform-apply` runs dev automatically, waits for approval on staging/production.

From here, human AWS credentials are for break-glass only.
