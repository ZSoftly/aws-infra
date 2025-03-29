#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variables

# Set project prefix
PROJECT_PREFIX="ssm-demo"

# Set CIDR blocks and availability zones
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR_1="10.0.1.0/24"
PUBLIC_SUBNET_CIDR_2="10.0.2.0/24"
PRIVATE_APP_SUBNET_CIDR_1="10.0.3.0/24"
PRIVATE_APP_SUBNET_CIDR_2="10.0.4.0/24"
PRIVATE_DB_SUBNET_CIDR_1="10.0.5.0/24"
PRIVATE_DB_SUBNET_CIDR_2="10.0.6.0/24"
AZ_1="us-east-1a"
AZ_2="us-east-1b"
ALLOWED_SSH_CIDR="0.0.0.0/0"  # Change this to your specific IP range for security

# Global variables to store resource IDs
VPC_ID=""
IGW_ID=""
PUBLIC_SUBNET_1_ID=""
PUBLIC_SUBNET_2_ID=""
PRIVATE_APP_SUBNET_1_ID=""
PRIVATE_APP_SUBNET_2_ID=""
PRIVATE_DB_SUBNET_1_ID=""
PRIVATE_DB_SUBNET_2_ID=""
PUBLIC_RT_ID=""
PRIVATE_RT_ID=""
NAT_GATEWAY_ID=""
EIP_ALLOCATION_ID=""
ALB_SG_ID=""
WP_SG_ID=""
DB_SG_ID=""
REDIS_SG_ID=""

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
handle_error() {
    log "Error occurred in function: ${FUNCNAME[1]}"
    log "Error message: $1"
    exit 1
}

# Check if AWS CLI is installed and configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        handle_error "AWS CLI is not installed"
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        handle_error "AWS CLI is not configured properly"
    fi
}

# VPC Functions
setup_vpc() {
    log "Setting up VPC..."
    
    # Check if VPC with same name exists
    local existing_vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Name,Values=${PROJECT_PREFIX}-vpc" \
        --query 'Vpcs[0].VpcId' \
        --output text)
    
    if [[ $existing_vpc_id != "None" && -n $existing_vpc_id ]]; then
        log "VPC already exists: $existing_vpc_id"
        VPC_ID=$existing_vpc_id
    else
        VPC_ID=$(aws ec2 create-vpc \
            --cidr-block $VPC_CIDR \
            --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-vpc}]" \
            --query 'Vpc.VpcId' \
            --output text)
        
        # Enable DNS support and hostnames
        aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support
        aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
        
        log "Created new VPC: $VPC_ID"
    fi
}

setup_internet_gateway() {
    log "Setting up Internet Gateway..."
    
    # Check if IGW already exists and is attached to our VPC
    local existing_igw_id=$(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query 'InternetGateways[0].InternetGatewayId' \
        --output text)
    
    if [[ $existing_igw_id != "None" && -n $existing_igw_id ]]; then
        log "Internet Gateway already exists: $existing_igw_id"
        IGW_ID=$existing_igw_id
    else
        IGW_ID=$(aws ec2 create-internet-gateway \
            --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-igw}]" \
            --query 'InternetGateway.InternetGatewayId' \
            --output text)
            
        aws ec2 attach-internet-gateway \
            --vpc-id $VPC_ID \
            --internet-gateway-id $IGW_ID
            
        log "Created and attached new Internet Gateway: $IGW_ID"
    fi
}

create_subnet() {
    local cidr=$1
    local az=$2
    local name=$3
    local is_public=$4
    
    # Redirect log messages to stderr so they don't interfere with command output
    log "Checking for existing subnet: $name" >&2
    
    local existing_subnet_id=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$name" \
        --query 'Subnets[0].SubnetId' \
        --output text 2>/dev/null || echo "None")
    
    if [[ $existing_subnet_id != "None" && -n $existing_subnet_id ]]; then
        log "Subnet already exists: $existing_subnet_id" >&2
        echo "$existing_subnet_id"
    else
        log "Creating new subnet: $name" >&2
        local subnet_id=$(aws ec2 create-subnet \
            --vpc-id $VPC_ID \
            --cidr-block $cidr \
            --availability-zone $az \
            --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$name}]" \
            --query 'Subnet.SubnetId' \
            --output text)
            
        if [[ $is_public == "true" ]]; then
            log "Enabling auto-assign public IP for subnet: $subnet_id" >&2
            aws ec2 modify-subnet-attribute \
                --subnet-id $subnet_id \
                --map-public-ip-on-launch
        fi
        
        log "Created new subnet: $subnet_id" >&2
        echo "$subnet_id"
    fi
}
setup_subnets() {
    log "Setting up subnets..."
    
    PUBLIC_SUBNET_1_ID=$(create_subnet "$PUBLIC_SUBNET_CIDR_1" "$AZ_1" "${PROJECT_PREFIX}-public-subnet-1" "true")
    PUBLIC_SUBNET_2_ID=$(create_subnet "$PUBLIC_SUBNET_CIDR_2" "$AZ_2" "${PROJECT_PREFIX}-public-subnet-2" "true")
    PRIVATE_APP_SUBNET_1_ID=$(create_subnet "$PRIVATE_APP_SUBNET_CIDR_1" "$AZ_1" "${PROJECT_PREFIX}-private-app-subnet-1" "false")
    PRIVATE_APP_SUBNET_2_ID=$(create_subnet "$PRIVATE_APP_SUBNET_CIDR_2" "$AZ_2" "${PROJECT_PREFIX}-private-app-subnet-2" "false")
    PRIVATE_DB_SUBNET_1_ID=$(create_subnet "$PRIVATE_DB_SUBNET_CIDR_1" "$AZ_1" "${PROJECT_PREFIX}-private-db-subnet-1" "false")
    PRIVATE_DB_SUBNET_2_ID=$(create_subnet "$PRIVATE_DB_SUBNET_CIDR_2" "$AZ_2" "${PROJECT_PREFIX}-private-db-subnet-2" "false")
}

setup_route_tables() {
    log "Setting up route tables..."
    
    # Public route table
    local existing_public_rt=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=${PROJECT_PREFIX}-public-rt" \
        --query 'RouteTables[0].RouteTableId' \
        --output text 2>/dev/null || echo "None")
    
    if [[ $existing_public_rt != "None" && -n $existing_public_rt ]]; then
        PUBLIC_RT_ID=$existing_public_rt
        log "Using existing public route table: $PUBLIC_RT_ID"
    else
        PUBLIC_RT_ID=$(aws ec2 create-route-table \
            --vpc-id $VPC_ID \
            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-public-rt}]" \
            --query 'RouteTable.RouteTableId' \
            --output text)
            
        aws ec2 create-route \
            --route-table-id $PUBLIC_RT_ID \
            --destination-cidr-block 0.0.0.0/0 \
            --gateway-id $IGW_ID >/dev/null
            
        log "Created new public route table: $PUBLIC_RT_ID"
    fi
    
    # Associate public subnets
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_1_ID --route-table-id $PUBLIC_RT_ID >/dev/null
    aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_2_ID --route-table-id $PUBLIC_RT_ID >/dev/null
    
    # Private route table
    local existing_private_rt=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=${PROJECT_PREFIX}-private-rt" \
        --query 'RouteTables[0].RouteTableId' \
        --output text 2>/dev/null || echo "None")
    
    if [[ $existing_private_rt != "None" && -n $existing_private_rt ]]; then
        PRIVATE_RT_ID=$existing_private_rt
        log "Using existing private route table: $PRIVATE_RT_ID"
    else
        PRIVATE_RT_ID=$(aws ec2 create-route-table \
            --vpc-id $VPC_ID \
            --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-private-rt}]" \
            --query 'RouteTable.RouteTableId' \
            --output text)
            
        aws ec2 create-route \
            --route-table-id $PRIVATE_RT_ID \
            --destination-cidr-block 0.0.0.0/0 \
            --nat-gateway-id $NAT_GATEWAY_ID >/dev/null
            
        log "Created new private route table: $PRIVATE_RT_ID"
    fi
    
    # Associate private subnets
    aws ec2 associate-route-table --subnet-id $PRIVATE_APP_SUBNET_1_ID --route-table-id $PRIVATE_RT_ID >/dev/null
    aws ec2 associate-route-table --subnet-id $PRIVATE_APP_SUBNET_2_ID --route-table-id $PRIVATE_RT_ID >/dev/null
    aws ec2 associate-route-table --subnet-id $PRIVATE_DB_SUBNET_1_ID --route-table-id $PRIVATE_RT_ID >/dev/null
    aws ec2 associate-route-table --subnet-id $PRIVATE_DB_SUBNET_2_ID --route-table-id $PRIVATE_RT_ID >/dev/null
}

setup_nat_gateway() {
    log "Setting up NAT Gateway..."
    
    # First check for existing EIP tagged for our NAT
    local existing_eip=$(aws ec2 describe-addresses \
        --filters "Name=tag:Name,Values=${PROJECT_PREFIX}-nat-eip" \
        --query 'Addresses[0].AllocationId' \
        --output text 2>/dev/null || echo "None")

    # More comprehensive check for existing NAT Gateway
    local existing_nat=$(aws ec2 describe-nat-gateways \
        --filter "Name=vpc-id,Values=${VPC_ID}" \
        "Name=subnet-id,Values=${PUBLIC_SUBNET_1_ID}" \
        "Name=state,Values=available,pending" \
        "Name=tag:Name,Values=${PROJECT_PREFIX}-nat" \
        --query 'NatGateways[0].NatGatewayId' \
        --output text 2>/dev/null || echo "None")
    
    if [[ $existing_nat != "None" && -n $existing_nat ]]; then
        NAT_GATEWAY_ID=$existing_nat
        log "Using existing NAT Gateway: $NAT_GATEWAY_ID"
        
        # Get associated EIP if we didn't find it by tag
        if [[ $existing_eip == "None" ]]; then
            EIP_ALLOCATION_ID=$(aws ec2 describe-nat-gateways \
                --nat-gateway-ids $NAT_GATEWAY_ID \
                --query 'NatGateways[0].NatGatewayAddresses[0].AllocationId' \
                --output text)
        else
            EIP_ALLOCATION_ID=$existing_eip
        fi
        log "Using existing EIP: $EIP_ALLOCATION_ID"
    else
        if [[ $existing_eip != "None" && -n $existing_eip ]]; then
            EIP_ALLOCATION_ID=$existing_eip
            log "Using existing EIP: $EIP_ALLOCATION_ID"
        else
            # Create new EIP
            EIP_ALLOCATION_ID=$(aws ec2 allocate-address \
                --domain vpc \
                --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-nat-eip}]" \
                --query 'AllocationId' \
                --output text)
            log "Created new EIP: $EIP_ALLOCATION_ID"
        fi
            
        # Create NAT Gateway
        NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
            --subnet-id $PUBLIC_SUBNET_1_ID \
            --allocation-id $EIP_ALLOCATION_ID \
            --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-nat}]" \
            --query 'NatGateway.NatGatewayId' \
            --output text)
        log "Created new NAT Gateway: $NAT_GATEWAY_ID"
            
        # Wait for NAT Gateway to be available
        log "Waiting for NAT Gateway to become available..."
        aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GATEWAY_ID
        log "NAT Gateway is now available"
    fi
}

create_security_group() {
    local name=$1
    local description=$2
    
    # Redirect log messages to stderr
    log "Checking for existing security group: $name" >&2
    
    local existing_sg=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=${PROJECT_PREFIX}-${name}" \
        --query 'SecurityGroups[0].GroupId' \
        --output text 2>/dev/null || echo "None")
    
    if [[ $existing_sg != "None" && -n $existing_sg ]]; then
        log "Security group already exists: $existing_sg" >&2
        echo "$existing_sg"
    else
        log "Creating new security group: $name" >&2
        local sg_id=$(aws ec2 create-security-group \
            --group-name "${PROJECT_PREFIX}-${name}" \
            --description "$description" \
            --vpc-id $VPC_ID \
            --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-${name}}]" \
            --query 'GroupId' \
            --output text)
        log "Created new security group: $sg_id" >&2
        echo "$sg_id"
    fi
}

authorize_security_group_ingress() {
    local group_id=$1
    local protocol=$2
    local port=$3
    local source=$4  # Can be CIDR or security group ID
    local is_sg=${5:-false}  # Default to false for CIDR rules
    
    log "Checking existing rules for security group: $group_id" >&2
    
    # Get full security group description
    local sg_rules=$(aws ec2 describe-security-groups \
        --group-ids $group_id \
        --query 'SecurityGroups[0].IpPermissions[]' \
        --output json)
    
    # Function to check if rule exists
    rule_exists() {
        local from_port=$1
        local to_port=$2
        local proto=$3
        local src=$4
        local is_group=$5

        if [[ "$is_group" == "true" ]]; then
            echo "$sg_rules" | jq -e --arg port "$port" --arg proto "$proto" --arg src "$src" \
                'any(.FromPort == ($port|tonumber) and .ToPort == ($port|tonumber) and .IpProtocol == $proto and .UserIdGroupPairs[].GroupId == $src)' >/dev/null
        else
            echo "$sg_rules" | jq -e --arg port "$port" --arg proto "$proto" --arg src "$src" \
                'any(.FromPort == ($port|tonumber) and .ToPort == ($port|tonumber) and .IpProtocol == $proto and .IpRanges[].CidrIp == $src)' >/dev/null
        fi
        return $?
    }

    if rule_exists "$port" "$port" "$protocol" "$source" "$is_sg"; then
        log "Rule already exists" >&2
    else
        log "Adding new security group rule" >&2
        if [[ "$is_sg" == "true" ]]; then
            aws ec2 authorize-security-group-ingress \
                --group-id $group_id \
                --protocol $protocol \
                --port $port \
                --source-group-id $source >/dev/null 2>&1 || true
        else
            aws ec2 authorize-security-group-ingress \
                --group-id $group_id \
                --protocol $protocol \
                --port $port \
                --cidr $source >/dev/null 2>&1 || true
        fi
    fi
}

setup_security_groups() {
    log "Setting up security groups..."
    
    # ALB Security Group
    ALB_SG_ID=$(create_security_group "alb-sg" "Security group for ALB")
    authorize_security_group_ingress "$ALB_SG_ID" "tcp" "80" "0.0.0.0/0"
    authorize_security_group_ingress "$ALB_SG_ID" "tcp" "443" "0.0.0.0/0"
    
    # WordPress Security Group
    WP_SG_ID=$(create_security_group "wordpress-sg" "Security group for WordPress instances")
    authorize_security_group_ingress "$WP_SG_ID" "tcp" "80" "$ALB_SG_ID" "true"
    authorize_security_group_ingress "$WP_SG_ID" "tcp" "443" "$ALB_SG_ID" "true"
    authorize_security_group_ingress "$WP_SG_ID" "tcp" "22" "$ALLOWED_SSH_CIDR"
    
    # Database Security Group
    DB_SG_ID=$(create_security_group "db-sg" "Security group for database instances")
    authorize_security_group_ingress "$DB_SG_ID" "tcp" "3306" "$WP_SG_ID" "true"
    
    # Redis Security Group
    REDIS_SG_ID=$(create_security_group "redis-sg" "Security group for Redis instances")
    authorize_security_group_ingress "$REDIS_SG_ID" "tcp" "6379" "$WP_SG_ID" "true"
}

# Function to save resource IDs for cleanup
save_resource_ids() {
    log "Saving resource IDs to network-resources.txt..."
    cat << EOF > network-resources.txt
VPC_ID=$VPC_ID
IGW_ID=$IGW_ID
PUBLIC_SUBNET_1_ID=$PUBLIC_SUBNET_1_ID
PUBLIC_SUBNET_2_ID=$PUBLIC_SUBNET_2_ID
PRIVATE_APP_SUBNET_1_ID=$PRIVATE_APP_SUBNET_1_ID
PRIVATE_APP_SUBNET_2_ID=$PRIVATE_APP_SUBNET_2_ID
PRIVATE_DB_SUBNET_1_ID=$PRIVATE_DB_SUBNET_1_ID
PRIVATE_DB_SUBNET_2_ID=$PRIVATE_DB_SUBNET_2_ID
PUBLIC_RT_ID=$PUBLIC_RT_ID
PRIVATE_RT_ID=$PRIVATE_RT_ID
NAT_GATEWAY_ID=$NAT_GATEWAY_ID
EIP_ALLOCATION_ID=$EIP_ALLOCATION_ID
ALB_SG_ID=$ALB_SG_ID
WP_SG_ID=$WP_SG_ID
DB_SG_ID=$DB_SG_ID
REDIS_SG_ID=$REDIS_SG_ID
EOF
}

# Function to validate CIDR blocks
validate_cidrs() {
    local cidr_regex='^([0-9]{1,3}\.){3}[0-9]{1,3}/(1[6-9]|2[0-9]|3[0-2])$'
    
    if ! [[ $VPC_CIDR =~ $cidr_regex ]]; then
        handle_error "Invalid VPC CIDR block format: $VPC_CIDR"
    fi
    
    # Validate all subnet CIDRs
    for cidr in "$PUBLIC_SUBNET_CIDR_1" "$PUBLIC_SUBNET_CIDR_2" \
                "$PRIVATE_APP_SUBNET_CIDR_1" "$PRIVATE_APP_SUBNET_CIDR_2" \
                "$PRIVATE_DB_SUBNET_CIDR_1" "$PRIVATE_DB_SUBNET_CIDR_2"; do
        if ! [[ $cidr =~ $cidr_regex ]]; then
            handle_error "Invalid subnet CIDR block format: $cidr"
        fi
    done
}

# Main execution function
main() {
    log "Starting network infrastructure setup..."
    
    # Validate inputs
    validate_cidrs
    
    # Check AWS CLI installation and configuration
    check_aws_cli
    
    # Create VPC and enable DNS
    setup_vpc
    
    # Create and attach Internet Gateway
    setup_internet_gateway
    
    # Create all subnets
    setup_subnets
    
    # Create NAT Gateway (needs public subnet)
    setup_nat_gateway
    
    # Setup route tables
    setup_route_tables
    
    # Setup security groups
    setup_security_groups
    
    # Save resource IDs
    save_resource_ids
    
    log "Network infrastructure setup completed successfully!"
}

# Trap errors
trap 'handle_error "An error occurred on line $LINENO. Exit code: $?"' ERR

# Execute main function
main