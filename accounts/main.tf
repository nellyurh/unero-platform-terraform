# AWS Organization + OUs. Workloads are isolated per environment account so that a
# blast radius (or a compromised credential) in dev cannot touch production — the
# partner-bank / regulator posture rewards hard account boundaries (ADR-001, ADR-010).
resource "aws_organizations_organization" "this" {
  feature_set = "ALL"
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "guardduty.amazonaws.com",
  ]
  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "security"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "shared_services" {
  name      = "shared-services"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "workloads"
  parent_id = aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "workload" {
  for_each  = toset(["dev", "staging", "production", "load-test"])
  name      = "unero-${each.value}"
  email     = replace(var.account_email_pattern, "{env}", each.value)
  parent_id = aws_organizations_organizational_unit.workloads.id
  lifecycle {
    ignore_changes = [role_name] # account baseline set once at creation
  }
}

# Deny ClickOps in production: no console-based mutating actions outside break-glass.
resource "aws_organizations_policy" "deny_prod_clickops" {
  name    = "deny-production-clickops"
  type    = "SERVICE_CONTROL_POLICY"
  content = file("${path.module}/scp-deny-clickops.json")
}

resource "aws_organizations_policy_attachment" "deny_prod_clickops" {
  policy_id = aws_organizations_policy.deny_prod_clickops.id
  target_id = aws_organizations_account.workload["production"].id
}
