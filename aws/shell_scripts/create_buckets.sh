#!/bin/bash

# Project-specific variables
org_name="zsoftly"
project_prefix="poc"
environment="sandbox"

# Define regions and short names
declare -A regions
regions["ca-central-1"]="cac1"
regions["us-east-2"]="use2"

# Function to create a statefile-safe bucket
create_bucket() {
    region=$1
    region_short=${regions[$region]}
    bucket_name="${org_name}-${project_prefix}-${environment}-terraform-${region_short}"

    echo "Creating bucket: $bucket_name in $region"

    # Create bucket (handling us-east-1 differently)
    if [ "$region" == "us-east-1" ]; then
        aws s3api create-bucket --bucket "$bucket_name" --region "$region"
    else
        aws s3api create-bucket --bucket "$bucket_name" --region "$region" \
            --create-bucket-configuration LocationConstraint="$region"
    fi

    # Configure bucket properties
    aws s3api put-bucket-encryption --bucket "$bucket_name" \
        --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    
    aws s3api put-bucket-versioning --bucket "$bucket_name" \
        --versioning-configuration Status=Enabled
    
    # Fixed lifecycle configuration - added Prefix and Filter elements
    aws s3api put-bucket-lifecycle-configuration --bucket "$bucket_name" \
        --lifecycle-configuration '{
            "Rules": [{
                "ID": "ExpireOldVersions",
                "Status": "Enabled",
                "Filter": {
                    "Prefix": ""
                },
                "NoncurrentVersionExpiration": {
                    "NoncurrentDays": 90
                }
            }]
        }'

    echo "Bucket $bucket_name is ready"
}

# Function to delete buckets
delete_buckets() {
    for region in "${!regions[@]}"; do
        region_short=${regions[$region]}
        bucket_name="${org_name}-${project_prefix}-${environment}-terraform-${region_short}"
        
        echo "Emptying and deleting bucket: $bucket_name in $region"
        aws s3 rm s3://$bucket_name --recursive
        aws s3api delete-bucket --bucket $bucket_name --region $region
    done
}

# Uncomment one of these functions to either create or delete buckets
create_buckets() {
    for region in "${!regions[@]}"; do
        create_bucket "$region"
    done
}

# Create all buckets (uncomment to use)
create_buckets

# Delete all buckets (uncomment to use)
# delete_buckets

# How to run this script:
# 1. Make it executable: chmod +x create_buckets.sh
# 2. Run it: ./create_buckets.sh
#
# Edit the script to uncomment either the create_buckets or delete_buckets line
# depending on what operation you want to perform.