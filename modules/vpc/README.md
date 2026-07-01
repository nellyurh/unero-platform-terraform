# module: vpc

Three-tier, multi-AZ VPC. Public (ALB/NAT), private-app (ECS Fargate tasks, no public IP),
private-data (Aurora + Redis, no route to the internet gateway). Flow logs to CloudWatch
(Volume 10). `single_nat_gateway = false` in production for AZ-independent egress.
