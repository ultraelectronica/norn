# Norn infrastructure

Terraform-managed AWS. Terraform is **not** installed in this environment, so
nothing here has been `init`/`validate`/`plan`-checked yet — run those on a
machine with AWS credentials before relying on it. Only the safe foundation
files exist: `versions.tf`, `providers.tf`, `variables.tf`.

## Planned files (add per phase)

| File | Resources | Phase |
|---|---|---|
| `vpc.tf` | VPC, public/private subnets, NAT, IGW, route tables | 0 |
| `s3.tf` | asset/backup bucket, Terraform state bucket, block public access | 0 |
| `kms.tf` | BYOK-key encryption key + key policy | 3 |
| `cognito.tf` | user pool federated to OAuth provider, user-pool client, domain | 1 |
| `alb.tf` | ALB, Cognito OIDC listener, target group, TLS cert (ACM), WAF web ACL | 1 |
| `ecs.tf` | cluster, task definition (Fargate), service behind ALB, ECR repo | 0 |
| `rds.tf` | Postgres subnet group, security group, parameter group, instance | 0 |
| `elasticache.tf` | Redis subnet group, security group, replication group | 5 |
| `apigw.tf` | HTTP API routing async/admin endpoints to Lambda | 5 |
| `lambda.tf` | usage metering, model-list sync (container/image), EventBridge schedules | 5 |
| `secrets.tf` | Secrets Manager entries (DB creds, OAuth secret, JWT signing key) | 1 |
| `cloudwatch.tf` | log groups, metric alarms, X-Ray | 6 |

## Workflow

```bash
terraform init -backend-config="bucket=<state-bucket>" \
               -backend-config="key=norn/${ENV}/terraform.tfstate" \
               -backend-config="region=${AWS_REGION}"
terraform validate
terraform plan -var="environment=${ENV}"
terraform apply -var="environment=${ENV}"
```

Keep one state per environment (`dev`, `staging`, `prod`) under distinct keys.
