# versions.tf
terraform {
  required_version = ">= 1.7.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.5.0, < 7.0.0"
    }
  }
}

# main.tf
provider "aws" {
  region = "ca-central-1"
}

module "networking" {
  source = "../net_modules"

  vpc_cidr                 = var.vpc_cidr
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_app_subnet_cidrs = var.private_app_subnet_cidrs
  private_db_subnet_cidrs  = var.private_db_subnet_cidrs
  availability_zones       = var.availability_zones
  project_prefix           = var.project_prefix
  environment              = var.environment
  region_short             = var.region_short
  default_tags             = var.default_tags
}