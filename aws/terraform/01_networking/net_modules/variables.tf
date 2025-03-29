variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.vpc_cidr))
    error_message = "The CIDR block for the VPC must be a valid IPv4 CIDR."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && length(var.public_subnet_cidrs) <= 3
    error_message = "You must provide 2 or 3 CIDR blocks for public subnets."
  }
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  validation {
    condition     = length(var.private_app_subnet_cidrs) >= 2 && length(var.private_app_subnet_cidrs) <= 3
    error_message = "You must provide 2 or 3 CIDR blocks for private application subnets."
  }
}

variable "private_db_subnet_cidrs" {
  description = "CIDR blocks for private database subnets"
  type        = list(string)
  validation {
    condition     = length(var.private_db_subnet_cidrs) >= 2 && length(var.private_db_subnet_cidrs) <= 3
    error_message = "You must provide 2 or 3 CIDR blocks for private database subnets."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "You must provide at least 2 availability zones."
  }
}

variable "project_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access application instances (e.g., for SSH or other protocols)"
  type        = list(string)
  default     = ["24.200.207.18/32"] # Default value
}

variable "create_db_endpoint" {
  description = "Whether to create Aurora VPC Endpoint"
  type        = bool
  default     = false
}

variable "aurora_service_name" {
  description = "Service name for Aurora VPC Endpoint"
  type        = string
  default     = ""
}

variable "remote_application_cidrs" {
  description = "CIDR blocks of remote application subnets"
  type        = list(string)
  default     = []
}

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "region_short" {
  description = "Short code for AWS region (e.g., cac1 for ca-central-1)"
  type        = string
}