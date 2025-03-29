# AWS Network Infrastructure Scripts

## Overview
This repository contains scripts for creating and managing AWS network infrastructure in a repeatable and maintainable way. The scripts create a complete VPC setup with public and private subnets, NAT Gateway, and security groups suitable for a multi-tier application deployment.

## Directory Structure
```
.
├── default/                  # Default configuration
│   ├── create-network.sh    # Network creation script
│   ├── destroy-network.sh   # Network cleanup script
│   └── network-resources.txt # Resource tracking file
└── func/                    # Function-based modular version
    ├── create-network.sh    # Modular creation script
    ├── destroy-network.sh   # Modular cleanup script
    └── network-resources.txt # Resource tracking file
```

## Prerequisites
- AWS CLI installed and configured
- Appropriate AWS permissions to create/delete:
  - VPCs
  - Subnets
  - Internet Gateways
  - NAT Gateways
  - Route Tables
  - Security Groups
  - Elastic IPs

## Network Architecture
The scripts create the following resources:
- VPC with DNS support enabled
- 2 Public subnets across different AZs
- 2 Private Application subnets
- 2 Private Database subnets
- NAT Gateway for private subnet internet access
- Internet Gateway for public subnet internet access
- Route tables for both public and private subnets
- Security Groups:
  - ALB Security Group (ports 80/443)
  - WordPress Security Group (ports 80/443/22)
  - Database Security Group (port 3306)
  - Redis Security Group (port 6379)

## Usage

### Default Version
```bash
# Create network infrastructure
cd default
./create-network.sh

# Delete network infrastructure
./destroy-network.sh
```

### Function-based Version
```bash
# Create network infrastructure
cd func
./create-network.sh

# Delete network infrastructure
./destroy-network.sh
```

## Configuration
Both versions use the following default CIDR blocks:
- VPC: 10.0.0.0/16
- Public Subnets: 10.0.1.0/24, 10.0.2.0/24
- Private App Subnets: 10.0.3.0/24, 10.0.4.0/24
- Private DB Subnets: 10.0.5.0/24, 10.0.6.0/24

To modify these values, edit the variables at the top of the creation scripts.

## Security Considerations
- The default SSH CIDR is set to 0.0.0.0/0. Modify ALLOWED_SSH_CIDR in the scripts for production use.
- Security group rules are configured for a typical web application stack.
- NAT Gateway is placed in the first public subnet for high availability.

## Resource Tracking
- All created resource IDs are saved to `network-resources.txt`
- The destroy script uses this file to clean up resources
- The file is cleared after successful cleanup

## Error Handling
- Both scripts include comprehensive error checking
- Resources are checked before creation/deletion
- Dependencies are properly managed
- Detailed logging is provided

## Differences Between Versions
- Default: Single script with linear execution
- Func: Modular approach with separate functions for each resource type
- Func version includes additional error handling and logging
- Func version supports better resource existence checking

## Best Practices
1. Always review the CIDR blocks before running in production
2. Modify the SSH CIDR range to your specific requirements
3. Test the destroy script in a non-production environment first
4. Keep the resource tracking file for cleanup purposes
5. Monitor the AWS console during first-time execution

## Known Limitations
- Region is hardcoded to us-east-1
- Does not support custom VPC endpoints
- No support for VPC flow logs
- No built-in backup/restore functionality

## Contributing
1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Create a pull request

## License
MIT