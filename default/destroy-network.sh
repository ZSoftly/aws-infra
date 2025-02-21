#!/bin/bash

# Load resource IDs from file
if [[ ! -f network-resources.txt ]]; then
  echo "Error: network-resources.txt not found!"
  exit 1
fi

source network-resources.txt

echo "Starting cleanup of network resources..."

# Delete Security Groups
echo "Deleting Security Groups..."
aws ec2 delete-security-group --group-id $REDIS_SG_ID || echo "Error deleting Redis SG"
aws ec2 delete-security-group --group-id $DB_SG_ID || echo "Error deleting DB SG"
aws ec2 delete-security-group --group-id $WP_SG_ID || echo "Error deleting WP SG"
aws ec2 delete-security-group --group-id $ALB_SG_ID || echo "Error deleting ALB SG"

# Check NAT Gateway state
echo "Checking NAT Gateway state..."
NAT_STATE=$(aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID --query 'NatGateways[0].State' --output text)

if [[ "$NAT_STATE" == "deleted" ]]; then
  echo "NAT Gateway is already deleted."
elif [[ "$NAT_STATE" == "deleting" ]]; then
  echo "NAT Gateway is already in the process of deletion. Waiting for it to be deleted..."
  aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GATEWAY_ID || echo "NAT Gateway deletion failed or timed out"
else
  echo "Deleting NAT Gateway..."
  aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GATEWAY_ID || echo "Error deleting NAT Gateway"

  # Wait for NAT Gateway to be deleted
  echo "Waiting for NAT Gateway to be deleted..."
  aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GATEWAY_ID || echo "NAT Gateway deletion failed or timed out"
fi


# Release Elastic IP
echo "Releasing Elastic IP..."
aws ec2 release-address --allocation-id $EIP_ALLOCATION_ID || echo "Error releasing EIP"

# Get the public route table association IDs dynamically
PUBLIC_ASSOCIATION_IDS=$(aws ec2 describe-route-tables \
  --route-table-ids $PUBLIC_RT_ID \
  --query 'RouteTables[0].Associations[*].RouteTableAssociationId' \
  --output json)

# Get the private route table association IDs dynamically
PRIVATE_ASSOCIATION_IDS=$(aws ec2 describe-route-tables \
  --route-table-ids $PRIVATE_RT_ID \
  --query 'RouteTables[0].Associations[*].RouteTableAssociationId' \
  --output json)

# Disassociate public route table associations
if [[ -n "$PUBLIC_ASSOCIATION_IDS" ]]; then
  echo "$PUBLIC_ASSOCIATION_IDS" | jq -r '.[]' | xargs -I {} aws ec2 disassociate-route-table --association-id "{}" || echo "Error disassociating public route table"
fi

# Disassociate private route table associations
if [[ -n "$PRIVATE_ASSOCIATION_IDS" ]]; then
  echo "$PRIVATE_ASSOCIATION_IDS" | jq -r '.[]' | xargs -I {} aws ec2 disassociate-route-table --association-id "{}" || echo "Error disassociating private route table"
fi

# Delete Route Tables
echo "Deleting Route Tables..."
aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID || echo "Error deleting public route table"
aws ec2 delete-route-table --route-table-id $PRIVATE_RT_ID || echo "Error deleting private route table"

# Delete Subnets
echo "Deleting Subnets..."
aws ec2 delete-subnet --subnet-id $PRIVATE_DB_SUBNET_1_ID || echo "Error deleting private DB subnet 1"
aws ec2 delete-subnet --subnet-id $PRIVATE_DB_SUBNET_2_ID || echo "Error deleting private DB subnet 2"
aws ec2 delete-subnet --subnet-id $PRIVATE_APP_SUBNET_1_ID || echo "Error deleting private app subnet 1"
aws ec2 delete-subnet --subnet-id $PRIVATE_APP_SUBNET_2_ID || echo "Error deleting private app subnet 2"
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_1_ID || echo "Error deleting public subnet 1"
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_2_ID || echo "Error deleting public subnet 2"

# Detach and delete Internet Gateway
echo "Detaching Internet Gateway..."
aws ec2 detach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID || echo "Error detaching internet gateway"
echo "Deleting Internet Gateway..."
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID || echo "Error deleting internet gateway"

# Delete VPC
echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID || echo "Error deleting VPC"

echo "Cleanup complete!"