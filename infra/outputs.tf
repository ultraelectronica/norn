output "alb_dns_name" {
  description = "Public ALB hostname — curl http://<alb_dns_name>/healthz"
  value       = module.compute.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.compute.cluster_name
}

output "ecr_repository_url" {
  description = "Push the backend image here, then set desired_count = 1."
  value       = module.compute.ecr_repository_url
}

output "rds_address" {
  value = module.data.db_address
}

output "redis_address" {
  value = module.data.redis_address
}

output "ci_role_arn" {
  description = "GitHub secret AWS_ROLE_ARN (empty when github_repository unset)."
  value       = length(module.ci) > 0 ? module.ci[0].role_arn : ""
}
