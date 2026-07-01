# module: ecs-cluster

Shared Fargate cluster (ADR-010) with Container Insights and ECS Exec logging. Lower envs
default to FARGATE_SPOT for cost; production pins FARGATE. Exposes the shared app-tier
security group that Aurora and Redis grant ingress to.
