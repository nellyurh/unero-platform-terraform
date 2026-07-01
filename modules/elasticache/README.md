# module: elasticache

Redis (ADR-009) for cache, rate-limit counters, and idempotency keys. TLS in transit and
at-rest encryption always on; AUTH token sourced from Secrets Manager (never a literal in
tfvars). Production enables replicas, Multi-AZ, and automatic failover.
