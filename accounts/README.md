# accounts/

AWS Organization with security, shared-services, and workloads OUs. One account per
environment (dev, staging, production, load-test) so boundaries are account-hard, not
tag-soft. A Service Control Policy denies mutating ClickOps in production outside the
Terraform role (break-glass excepted). Applied from the management account.
