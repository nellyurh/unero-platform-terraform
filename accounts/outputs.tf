output "workload_account_ids" {
  value = { for k, a in aws_organizations_account.workload : k => a.id }
}
output "organization_id" {
  value = aws_organizations_organization.this.id
}
