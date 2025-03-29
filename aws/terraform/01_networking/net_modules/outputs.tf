# VPC
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.vpc.id
}

# Subnets
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets"
  value       = [for subnet in aws_subnet.private_app : subnet.id]
}

output "private_db_subnet_ids" {
  description = "IDs of private database subnets"
  value       = [for subnet in aws_subnet.private_db : subnet.id]
}

# Security Groups
output "alb_sg_id" {
  description = "ID of ALB security group"
  value       = aws_security_group.alb.id
}

output "application_sg_id" {
  description = "ID of application security group"
  value       = aws_security_group.application.id
}

output "database_sg_id" {
  description = "ID of database security group"
  value       = aws_security_group.database.id
}

output "redis_sg_id" {
  description = "ID of Redis security group"
  value       = aws_security_group.redis.id
}

# Routing
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.nat.id
}

output "nat_eip" {
  description = "Elastic IP address for the NAT Gateway"
  value       = aws_eip.nat.public_ip
}