# AWS Infrastructure as Code (IaC)

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?style=flat&logo=terraform&logoColor=white)](https://www.terraform.io/docs)
[![AWS](https://img.shields.io/badge/AWS-SSO-FF9900?style=flat&logo=amazon-aws&logoColor=white)](https://d-9d676db98b.awsapps.com/start/#/?tab=accounts)

This repository contains Terraform code for provisioning and managing AWS infrastructure in a consistent and repeatable way.

## Project Structure

```
aws/
├── shell_scripts/        # Helper scripts for infrastructure management
│   └── create_buckets.sh # Script to create Terraform state buckets
└── terraform/            # Terraform code organized by infrastructure layer
    ├── 01_networking/    # Network infrastructure (VPC, subnets, SGs)
    │   ├── cac1/         # Canada Central region configuration 
    │   ├── net_modules/  # Shared networking modules
    │   └── use2/         # US East 2 region configuration
    ├── 02_storage/       # Storage resources (upcoming)
    └── 03_compute/       # Compute resources (upcoming)
```

## Current Implementation

### Networking Infrastructure
- Multi-AZ VPC setup with public, private app, and private DB subnet tiers
- NAT Gateway and Internet Gateway for proper routing
- Security groups for different application tiers (ALB, app, database, Redis)
- Terraform remote state configuration using S3 buckets

## Getting Started

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform v1.6+ installed
- AWS SSO access configured

### Setting Up State Buckets
```bash
cd aws/shell_scripts
chmod +x create_buckets.sh
./create_buckets.sh
```

### Deploying Network Infrastructure
```bash
cd aws/terraform/01_networking/cac1
terraform init
terraform plan
terraform apply
```

## Network Design Considerations

- **App Subnet Sizing**: `/23` CIDR blocks (512 IPs) allocated for application subnets to accommodate EKS pod IP requirements
- **Multi-AZ Design**: Resources spread across availability zones for high availability
- **Security Layers**: Strict network segregation between application and database tiers

## Contributing

1. Check the backlog for available issues and epics.
2. Follow GitHub project tasks and assign yourself accordingly.
3. Use feature branches with the following naming convention:
   ```
   git checkout -b issue-<ISSUE_NUMBER>/<SHORT_DESCRIPTION>
   ```
   Example:
   ```
   git checkout -b issue-42/setup-cloudflare-dns
   ```
4. Link commits to issues:
   - To auto-close an issue when merged:
     ```
     git commit -m "Fix #42: Setup Cloudflare DNS"
     ```
   - To reference an issue without closing it:
     ```
     git commit -m "Refs #42: Initial setup for Cloudflare DNS"
     ```
5. Open a Pull Request (PR) and reference the issue in the PR description.

## License

Proprietary - All Rights Reserved