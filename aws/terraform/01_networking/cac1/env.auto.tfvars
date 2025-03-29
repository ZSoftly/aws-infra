# Updated env.auto.tfvars file
vpc_cidr                 = "10.0.0.0/16"
public_subnet_cidrs      = ["10.0.0.0/24", "10.0.1.0/24"]
private_app_subnet_cidrs = ["10.0.2.0/23", "10.0.4.0/23"] # Changed to /23
private_db_subnet_cidrs  = ["10.0.6.0/24", "10.0.7.0/24"] # Moved to avoid overlap
availability_zones       = ["ca-central-1a", "ca-central-1b"]
project_prefix           = "poc"
environment              = "sandbox"
region_short             = "cac1"

default_tags = {
  Environment = "poc"
  Project     = "GTM"
  Managed     = "terraform"
}