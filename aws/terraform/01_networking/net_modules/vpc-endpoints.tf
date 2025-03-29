# VPC Endpoint
resource "aws_vpc_endpoint" "aurora" {
  for_each = var.create_db_endpoint ? { "aurora" = true } : {}

  vpc_id              = aws_vpc.vpc.id
  service_name        = var.aurora_service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_app : subnet.id]
  security_group_ids  = [aws_security_group.aurora_endpoint["aurora"].id]
  private_dns_enabled = true

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-aur-vpce-${var.region_short}"
  })
}

# Security group for VPC endpoint
resource "aws_security_group" "aurora_endpoint" {
  for_each = var.create_db_endpoint ? { "aurora" = true } : {}

  name        = "${var.project_prefix}-${var.environment}-aur-vpce-sg-${var.region_short}"
  vpc_id      = aws_vpc.vpc.id
  description = "Security group for Aurora VPC Endpoint"

  # Default egress rule - all outbound traffic allowed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_prefix}-${var.environment}-aur-vpce-sg-${var.region_short}"
  })
}