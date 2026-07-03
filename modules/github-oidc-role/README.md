# modules/github-oidc-role

Creates (optionally) the GitHub Actions OIDC provider and one IAM role assumable only by a
specific repo + ref/environment via `sts:AssumeRoleWithWebIdentity`. No long-lived keys.

Compose it twice per account: a read-only **plan** role (assumable from PRs) and a write
**apply** role (assumable only from `main`, or a protected GitHub Environment for prod).
See `oidc/` for the per-account composition.
