# Norn infrastructure

Terraform-managed AWS. Phase 0 layout is live and `terraform validate`-checked
(needs AWS credentials for `plan`/`apply`).

```
infra/
├── versions.tf      # provider pins + s3 backend (partial config)
├── providers.tf     # aws provider, default tags
├── variables.tf     # project/env/region + sizing knobs
├── main.tf          # module wiring
├── outputs.tf       # ALB DNS, ECR URL, CI role, DB endpoints
└── modules/
    ├── network/     # VPC 10.0.0.0/16, IGW, 2× public + 2× private subnets (no NAT in dev)
    ├── data/        # RDS Postgres 16 (db.t4g.micro) + ElastiCache Redis 7 + Secrets Manager creds
    ├── compute/     # ECS Fargate, ECR repo, ALB :80 → TG /healthz, task def + service
    └── ci/          # GitHub OIDC role (terraform plan + ECR push)
```

## First-run bootstrap

Remote state lives in S3 + a DynamoDB lock table, which Terraform cannot
create for itself. `scripts/bootstrap-state.sh` does it once (idempotent):

```bash
./scripts/bootstrap-state.sh          # PROJECT=norn ENVIRONMENT=dev REGION=us-east-1
terraform -chdir=infra init \
  -backend-config="bucket=<from-script-output>" \
  -backend-config="dynamodb_table=norn-tflock-dev" \
  -backend-config="key=norn/dev/terraform.tfstate" \
  -backend-config="region=us-east-1"
TF_VAR_github_repository=<owner>/norn terraform -chdir=infra plan
terraform -chdir=infra apply
```

## Fargate stub bring-up

`desired_count` defaults to **0** because the ECR repo is empty on first
apply. After CI pushes the first image (or a manual
`docker build && docker push` to the `ecr_repository_url` output):

```bash
terraform -chdir=infra apply -var="desired_count=1"
curl http://<alb_dns_name>/healthz   # → 200
```

## Coming per phase

| Module / change | Phase |
|---|---|
| Cognito user pool, ACM cert, ALB OIDC + HTTPS listener, WAF | 1 |
| RDS/Redis wired into task def env (Secrets Manager) | 2 |
| KMS `norn/byok` key + task-role policy | 3 |
| API Gateway, Lambdas (usage-meter, model-sync) | 5 |
| CloudWatch dashboards/alarms, X-Ray, prod workspace | 6 |

## Notes

- Dev networking is deliberately NAT-free: ALB + Fargate tasks carry public
  IPs; RDS/Redis sit in private subnets with SGs allowing ingress from the
  service SG only. Swap to private tasks + NAT before prod.
- `db_master` password is random + stored in Secrets Manager;
  `ignore_changes = [password]` — rotate via AWS, not Terraform.
- CI role attaches `ReadOnlyAccess` (plan reads) + scoped ECR/state write.
  Tighten in Phase 6.
- Engine versions are pinned (`postgres 16.4`, `redis 7.1`) with
  `auto_minor_version_upgrade = false` to keep plans drift-free; bump
  deliberately.
