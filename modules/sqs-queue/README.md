# module: sqs-queue

Work queue + mandatory DLQ, KMS-encrypted, with a DLQ-not-empty alarm. Consumers are
idempotent and use bounded retry with backoff (ADR-011, AI_RULES Events). `maxReceiveCount`
exhausted -> message moves to DLQ -> alarm -> runbook.
