locals {
  name_prefix = "${var.project}-${var.environment}"
}

# --- RDS Postgres 16 ---

resource "random_password" "db_master" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db_master" {
  name                    = "${var.project}/${var.environment}/db-master"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_master" {
  secret_id = aws_secretsmanager_secret.db_master.id
  secret_string = jsonencode({
    username = "norn_app"
    password = random_password.db_master.result
  })
}

resource "aws_security_group" "rds" {
  name   = "${local.name_prefix}-rds"
  vpc_id = var.vpc_id

  ingress {
    description     = "Postgres from compute"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.allowed_sg_id]
  }

  tags = {
    Name = "${local.name_prefix}-rds"
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier                 = "${local.name_prefix}-pg"
  engine                     = "postgres"
  engine_version             = "16.4"
  instance_class             = var.db_instance_class
  allocated_storage          = 20
  storage_type               = "gp3"
  storage_encrypted          = true
  username                   = "norn_app"
  password                   = random_password.db_master.result
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 0
  auto_minor_version_upgrade = false
  skip_final_snapshot        = true
  deletion_protection        = false

  tags = {
    Name = "${local.name_prefix}-pg"
  }

  lifecycle {
    ignore_changes = [password]
  }
}

# --- ElastiCache Redis 7 (created now, wired in Phase 5) ---

resource "aws_security_group" "redis" {
  name   = "${local.name_prefix}-redis"
  vpc_id = var.vpc_id

  ingress {
    description     = "Redis from compute"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.allowed_sg_id]
  }

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-redis"
  subnet_ids = var.private_subnet_ids
}

resource "aws_elasticache_cluster" "this" {
  cluster_id         = "${local.name_prefix}-redis"
  engine             = "redis"
  engine_version     = "7.1"
  node_type          = var.redis_node_type
  num_cache_nodes    = 1
  port               = 6379
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}
