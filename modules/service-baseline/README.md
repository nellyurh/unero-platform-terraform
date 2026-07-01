# module: service-baseline

The audited shape every service starts from. A service's own `infra/terraform/` calls this
to get its task/execution roles, work queues (+DLQs), log group, standard alarms, and a
golden-signals dashboard — then defines its ECS service + task definition on top, wiring in
these outputs. One place to change the baseline; every service inherits it.
