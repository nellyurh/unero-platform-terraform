# module: task-iam-role

The ECS-Fargate realization of ADR-017's "IAM Roles for Service Accounts". Each service
receives a **task role** (runtime identity: its own SQS queues, EventBridge PutEvents, its
own secrets) and a **task execution role** (image pull + secret injection). Secret access
is prefix-scoped to `unero/<env>/<service>/*` — a service can never read another service's
secrets. No long-lived credentials anywhere.
