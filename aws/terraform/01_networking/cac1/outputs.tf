### VPC Outputs ###
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

### Subnet Outputs ###
output "public_subnet_ids" {
  description = "IDs of public subnets for ALB deployment"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets for EC2 instances"
  value       = module.networking.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "IDs of private database subnets for RDS Aurora deployment"
  value       = module.networking.private_db_subnet_ids
}

### Security Group Outputs ###
output "alb_sg_id" {
  description = "Security Group ID for Application Load Balancer (ALB)"
  value       = module.networking.alb_sg_id
}

output "app_sg_id" {
  description = "Security Group ID for Application EC2 instances"
  value       = module.networking.application_sg_id
}

output "database_sg_id" {
  description = "Security Group ID for Database instances"
  value       = module.networking.database_sg_id
}

output "redis_sg_id" {
  description = "Security Group ID for Redis instances"
  value       = module.networking.redis_sg_id
}

### Routing Outputs ###
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.networking.public_route_table_id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = module.networking.private_route_table_id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.networking.nat_gateway_id
}

output "nat_eip" {
  description = "Elastic IP address for the NAT Gateway"
  value       = module.networking.nat_eip
}