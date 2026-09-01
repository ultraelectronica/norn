variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

# Compute service SG — RDS/Redis accept traffic only from it.
variable "allowed_sg_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "redis_node_type" {
  type = string
}
