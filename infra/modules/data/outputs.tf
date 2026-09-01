output "db_address" {
  description = "RDS hostname."
  value       = aws_db_instance.this.address
}

output "db_port" {
  value = aws_db_instance.this.port
}

output "db_secret_arn" {
  description = "Secrets Manager ARN holding {username, password}."
  value       = aws_secretsmanager_secret.db_master.arn
}

output "redis_address" {
  value = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "redis_port" {
  value = aws_elasticache_cluster.this.port
}
