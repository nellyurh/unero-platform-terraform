# baseline/

Org-wide roots created once, referenced everywhere: the data/secrets/logs CMKs (multi-region
for DR), the S3+DynamoDB remote-state store, and the organization CloudTrail with log-file
validation. Applied first, from the management account, before any environment.

Bootstrap note: the state bucket + lock table are created here but the S3 backend needs them
to exist first — on a clean org, apply once with a local backend, then migrate state to S3.
