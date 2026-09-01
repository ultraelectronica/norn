data "aws_caller_identity" "current" {}

locals {
  # Must match scripts/bootstrap-state.sh naming.
  state_bucket = "${var.project}-tfstate-${data.aws_caller_identity.current.account_id}-${var.environment}"
  state_table  = "${var.project}-tflock-${var.environment}"
}

module "network" {
  source = "./modules/network"

  project     = var.project
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  azs         = var.azs
}

module "compute" {
  source = "./modules/compute"

  project           = var.project
  environment       = var.environment
  region            = var.region
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  container_image   = var.container_image
  desired_count     = var.desired_count
  cpu               = var.task_cpu
  memory            = var.task_memory
}

module "data" {
  source = "./modules/data"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  allowed_sg_id      = module.compute.service_security_group_id
  db_instance_class  = var.db_instance_class
  redis_node_type    = var.redis_node_type
}

module "ci" {
  count = var.github_repository != "" ? 1 : 0

  source = "./modules/ci"

  project            = var.project
  environment        = var.environment
  github_repository  = var.github_repository
  state_bucket       = local.state_bucket
  state_table        = local.state_table
  ecr_repository_arn = module.compute.ecr_repository_arn
}
