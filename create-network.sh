#!/bin/bash

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
AZ_1="us-east-1a"  # Change these according to your region
AZ_2="us-east-1b"
ALLOWED_SSH_CIDR="0.0.0.0/0"  # Change this to your specific IP range for security

# Create VPC
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-vpc}]" \
  --query 'Vpc.VpcId' \
  --output text)
echo "VPC created: $VPC_ID"

# Step 2: Enable DNS Support and Hostnames
aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-support

aws ec2 modify-vpc-attribute \
  --vpc-id $VPC_ID \
  --enable-dns-hostnames


# Create Internet Gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-igw}]" \
  --query 'InternetGateway.InternetGatewayId' \
  --output text)
echo "Internet Gateway created: $IGW_ID"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID

# Create Public Subnets
echo "Creating Public Subnets..."
PUBLIC_SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_CIDR_1 \
  --availability-zone $AZ_1 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-public-subnet-1}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Public Subnet 1 created: $PUBLIC_SUBNET_1_ID"

PUBLIC_SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUBLIC_SUBNET_CIDR_2 \
  --availability-zone $AZ_2 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-public-subnet-2}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Public Subnet 2 created: $PUBLIC_SUBNET_2_ID"

# Enable auto-assign public IP for public subnets
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_1_ID \
  --map-public-ip-on-launch
aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_2_ID \
  --map-public-ip-on-launch

# Create Private Application Subnets
echo "Creating Private Application Subnets..."
PRIVATE_APP_SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_APP_SUBNET_CIDR_1 \
  --availability-zone $AZ_1 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-private-app-subnet-1}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Private App Subnet 1 created: $PRIVATE_APP_SUBNET_1_ID"

PRIVATE_APP_SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_APP_SUBNET_CIDR_2 \
  --availability-zone $AZ_2 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-private-app-subnet-2}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Private App Subnet 2 created: $PRIVATE_APP_SUBNET_2_ID"

# Create Private Database Subnets
echo "Creating Private Database Subnets..."
PRIVATE_DB_SUBNET_1_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_DB_SUBNET_CIDR_1 \
  --availability-zone $AZ_1 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-private-db-subnet-1}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Private DB Subnet 1 created: $PRIVATE_DB_SUBNET_1_ID"

PRIVATE_DB_SUBNET_2_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIVATE_DB_SUBNET_CIDR_2 \
  --availability-zone $AZ_2 \
  --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-private-db-subnet-2}]" \
  --query 'Subnet.SubnetId' \
  --output text)
echo "Private DB Subnet 2 created: $PRIVATE_DB_SUBNET_2_ID"

# Create public route table
echo "Creating Public Route Table..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-public-rt}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)
echo "Public Route Table created: $PUBLIC_RT_ID"

# Create route to Internet Gateway
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID

# Associate public subnets with public route table
aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_1_ID \
  --route-table-id $PUBLIC_RT_ID
aws ec2 associate-route-table \
  --subnet-id $PUBLIC_SUBNET_2_ID \
  --route-table-id $PUBLIC_RT_ID

# Create NAT Gateway
echo "Creating NAT Gateway..."
EIP_ALLOCATION_ID=$(aws ec2 allocate-address \
  --domain vpc \
  --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-nat-eip}]" \
  --query 'AllocationId' \
  --output text)
echo "Elastic IP allocated: $EIP_ALLOCATION_ID"

NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUBLIC_SUBNET_1_ID \
  --allocation-id $EIP_ALLOCATION_ID \
  --tag-specifications "ResourceType=natgateway,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-nat}]" \
  --query 'NatGateway.NatGatewayId' \
  --output text)
echo "NAT Gateway created: $NAT_GATEWAY_ID"

# Wait for NAT Gateway to be available
echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GATEWAY_ID

# Create private route table
echo "Creating Private Route Table..."
PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-private-rt}]" \
  --query 'RouteTable.RouteTableId' \
  --output text)
echo "Private Route Table created: $PRIVATE_RT_ID"

# Create route to NAT Gateway
aws ec2 create-route \
  --route-table-id $PRIVATE_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id $NAT_GATEWAY_ID

# Associate private subnets with private route table
aws ec2 associate-route-table \
  --subnet-id $PRIVATE_APP_SUBNET_1_ID \
  --route-table-id $PRIVATE_RT_ID
aws ec2 associate-route-table \
  --subnet-id $PRIVATE_APP_SUBNET_2_ID \
  --route-table-id $PRIVATE_RT_ID
aws ec2 associate-route-table \
  --subnet-id $PRIVATE_DB_SUBNET_1_ID \
  --route-table-id $PRIVATE_RT_ID
aws ec2 associate-route-table \
  --subnet-id $PRIVATE_DB_SUBNET_2_ID \
  --route-table-id $PRIVATE_RT_ID

# Create Security Groups
echo "Creating Security Groups..."
# ALB Security Group
ALB_SG_ID=$(aws ec2 create-security-group \
  --group-name "${PROJECT_PREFIX}-alb-sg" \
  --description "Security group for ALB" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-alb-sg}]" \
  --query 'GroupId' \
  --output text)
echo "ALB Security Group created: $ALB_SG_ID"

# Add rules to ALB Security Group
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress \
  --group-id $ALB_SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# WordPress Security Group
WP_SG_ID=$(aws ec2 create-security-group \
  --group-name "${PROJECT_PREFIX}-wordpress-sg" \
  --description "Security group for WordPress instances" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-wordpress-sg}]" \
  --query 'GroupId' \
  --output text)
echo "WordPress Security Group created: $WP_SG_ID"

# Add rules to WordPress Security Group
aws ec2 authorize-security-group-ingress \
  --group-id $WP_SG_ID \
  --protocol tcp \
  --port 80 \
  --source-group $ALB_SG_ID
aws ec2 authorize-security-group-ingress \
  --group-id $WP_SG_ID \
  --protocol tcp \
  --port 443 \
  --source-group $ALB_SG_ID
aws ec2 authorize-security-group-ingress \
  --group-id $WP_SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr $ALLOWED_SSH_CIDR

# Database Security Group
DB_SG_ID=$(aws ec2 create-security-group \
  --group-name "${PROJECT_PREFIX}-db-sg" \
  --description "Security group for database instances" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-db-sg}]" \
  --query 'GroupId' \
  --output text)
echo "Database Security Group created: $DB_SG_ID"

# Add rule to Database Security Group
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 3306 
  --source-group $WP_SG_ID

# Redis Security Group
REDIS_SG_ID=$(aws ec2 create-security-group \
  --group-name "${PROJECT_PREFIX}-redis-sg" \
  --description "Security group for Redis instances" \
  --vpc-id $VPC_ID \
  --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT_PREFIX}-redis-sg}]" \
  --query 'GroupId' \
  --output text)
echo "Redis Security Group created: $REDIS_SG_ID"

# Add rule to Redis Security Group
aws ec2 authorize-security-group-ingress \
  --group-id $REDIS_SG_ID \
  --protocol tcp \
  --port 6379 \
  --source-group $WP_SG_ID

echo "Network setup complete\!"

# Save resource IDs to a file for cleanup
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