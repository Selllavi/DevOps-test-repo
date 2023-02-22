output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private subnets"
  value       = module.vpc.private_subnets
}

output "worker_group_mgmt_one" {
  description = "worker_group_mgmt_one id"
  value       = aws_security_group.worker_group_mgmt_one.id
}