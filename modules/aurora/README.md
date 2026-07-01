# module: aurora

Aurora Serverless v2 PostgreSQL (ADR-008). Storage encrypted with the data CMK; master
credentials are RDS-managed in Secrets Manager (ADR-017) — never in code or tfvars.
Reachable only from the app tier security group. Production runs writer + reader and
enables deletion protection and final snapshots. Each service owns a schema; no service
reads another's tables (data-ownership invariant).
