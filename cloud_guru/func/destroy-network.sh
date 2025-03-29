#!/bin/bash

set -e  # Exit on error
set -u  # Exit on undefined variables

# Load resource IDs from file
RESOURCE_FILE="network-resources.txt"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
handle_error() {
    log "Error: $1"
    return 1
}

# Function to check if a resource exists
resource_exists() {
    local resource_type=$1
    local resource_id=$2
    
    case $resource_type in
        "sg")
            aws ec2 describe-security-groups --group-ids $resource_id >/dev/null 2>&1
            ;;
        "nat")
            aws ec2 describe-nat-gateways --nat-gateway-ids $resource_id --query 'NatGateways[?State!=`deleted`]' --output text >/dev/null 2>&1
            ;;
        "eip")
            aws ec2 describe-addresses --allocation-ids $resource_id >/dev/null 2>&1
            ;;
        "rtb")
            aws ec2 describe-route-tables --route-table-ids $resource_id >/dev/null 2>&1
            ;;
        "subnet")
            aws ec2 describe-subnets --subnet-ids $resource_id >/dev/null 2>&1
            ;;
        "igw")
            aws ec2 describe-internet-gateways --internet-gateway-ids $resource_id >/dev/null 2>&1
            ;;
        "vpc")
            aws ec2 describe-vpcs --vpc-ids $resource_id >/dev/null 2>&1
            ;;
    esac
    return $?
}

# Function to delete security groups
delete_security_groups() {
    log "Deleting Security Groups..."
    
    local sgs=("$REDIS_SG_ID:Redis" "$DB_SG_ID:Database" "$WP_SG_ID:WordPress" "$ALB_SG_ID:ALB")
    
    for sg_pair in "${sgs[@]}"; do
        IFS=':' read -r sg_id sg_name <<< "$sg_pair"
        if resource_exists "sg" "$sg_id"; then
            log "Deleting $sg_name Security Group: $sg_id"
            aws ec2 delete-security-group --group-id "$sg_id" || handle_error "Failed to delete $sg_name Security Group"
        else
            log "$sg_name Security Group $sg_id does not exist, skipping"
        fi
    done
}

# Function to delete NAT Gateway and EIP
delete_nat_gateway() {
    log "Cleaning up NAT Gateway resources..."
    
    if resource_exists "nat" "$NAT_GATEWAY_ID"; then
        log "Deleting NAT Gateway: $NAT_GATEWAY_ID"
        aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GATEWAY_ID"
        
        log "Waiting for NAT Gateway to be deleted..."
        aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$NAT_GATEWAY_ID"
    else
        log "NAT Gateway $NAT_GATEWAY_ID does not exist, skipping"
    fi
    
    if resource_exists "eip" "$EIP_ALLOCATION_ID"; then
        log "Releasing Elastic IP: $EIP_ALLOCATION_ID"
        aws ec2 release-address --allocation-id "$EIP_ALLOCATION_ID" || handle_error "Failed to release EIP"
    else
        log "EIP $EIP_ALLOCATION_ID does not exist, skipping"
    fi
}

# Function to delete route tables and their associations
delete_route_tables() {
    log "Cleaning up route tables..."
    
    local route_tables=("$PUBLIC_RT_ID:Public" "$PRIVATE_RT_ID:Private")
    
    for rt_pair in "${route_tables[@]}"; do
        IFS=':' read -r rt_id rt_name <<< "$rt_pair"
        
        if resource_exists "rtb" "$rt_id"; then
            # Get association IDs
            local assoc_ids=$(aws ec2 describe-route-tables \
                --route-table-ids "$rt_id" \
                --query 'RouteTables[0].Associations[*].RouteTableAssociationId' \
                --output text)
            
            # Disassociate route tables
            if [[ -n "$assoc_ids" ]]; then
                log "Disassociating $rt_name route table associations"
                for assoc_id in $assoc_ids; do
                    aws ec2 disassociate-route-table --association-id "$assoc_id" || \
                        handle_error "Failed to disassociate route table: $assoc_id"
                done
            fi
            
            # Delete route table
            log "Deleting $rt_name route table: $rt_id"
            aws ec2 delete-route-table --route-table-id "$rt_id" || \
                handle_error "Failed to delete $rt_name route table"
        else
            log "$rt_name route table $rt_id does not exist, skipping"
        fi
    done
}

# Function to delete subnets
delete_subnets() {
    log "Deleting subnets..."
    
    local subnets=(
        "$PRIVATE_DB_SUBNET_1_ID:Private DB 1"
        "$PRIVATE_DB_SUBNET_2_ID:Private DB 2"
        "$PRIVATE_APP_SUBNET_1_ID:Private App 1"
        "$PRIVATE_APP_SUBNET_2_ID:Private App 2"
        "$PUBLIC_SUBNET_1_ID:Public 1"
        "$PUBLIC_SUBNET_2_ID:Public 2"
    )
    
    for subnet_pair in "${subnets[@]}"; do
        IFS=':' read -r subnet_id subnet_name <<< "$subnet_pair"
        
        if resource_exists "subnet" "$subnet_id"; then
            log "Deleting $subnet_name subnet: $subnet_id"
            aws ec2 delete-subnet --subnet-id "$subnet_id" || \
                handle_error "Failed to delete $subnet_name subnet"
        else
            log "$subnet_name subnet $subnet_id does not exist, skipping"
        fi
    done
}

# Function to delete Internet Gateway
delete_internet_gateway() {
    log "Cleaning up Internet Gateway..."
    
    if resource_exists "igw" "$IGW_ID"; then
        log "Detaching Internet Gateway from VPC"
        aws ec2 detach-internet-gateway \
            --vpc-id "$VPC_ID" \
            --internet-gateway-id "$IGW_ID" || \
            handle_error "Failed to detach Internet Gateway"
            
        log "Deleting Internet Gateway: $IGW_ID"
        aws ec2 delete-internet-gateway \
            --internet-gateway-id "$IGW_ID" || \
            handle_error "Failed to delete Internet Gateway"
    else
        log "Internet Gateway $IGW_ID does not exist, skipping"
    fi
}

# Function to delete VPC
delete_vpc() {
    log "Deleting VPC..."
    
    if resource_exists "vpc" "$VPC_ID"; then
        aws ec2 delete-vpc --vpc-id "$VPC_ID" || \
            handle_error "Failed to delete VPC"
        log "VPC deleted successfully"
    else
        log "VPC $VPC_ID does not exist, skipping"
    fi
}

# Main execution
main() {
    # Check if resource file exists
    if [[ ! -f $RESOURCE_FILE ]]; then
        handle_error "$RESOURCE_FILE not found!"
        exit 1
    fi
    
    # Load resource IDs
    source $RESOURCE_FILE
    
    log "Starting cleanup of network resources..."
    
    # Delete resources in dependency order
    delete_security_groups
    delete_nat_gateway
    delete_route_tables
    delete_subnets
    delete_internet_gateway
    delete_vpc
    
    # Clear the resource file
    log "Clearing resource file..."
    : > $RESOURCE_FILE  # This empties the file while preserving its permissions
    # Alternative: rm $RESOURCE_FILE  # This would remove the file completely
    
    log "Cleanup completed successfully!"
}

# Execute main function
main