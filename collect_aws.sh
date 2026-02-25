#!/bin/bash
# collect_aws.sh – Mengumpulkan data keamanan AWS (perlu AWS CLI terkonfigurasi)

PROFILE="${1:-default}"
OUTPUT_DIR="./aws_data_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "[1/8] Mengumpulkan IAM information..."
aws iam list-users --profile "$PROFILE" > "$OUTPUT_DIR/iam_users.json"
aws iam list-roles --profile "$PROFILE" > "$OUTPUT_DIR/iam_roles.json"
aws iam list-policies --scope Local --profile "$PROFILE" > "$OUTPUT_DIR/iam_policies.json"
aws iam get-account-summary --profile "$PROFILE" > "$OUTPUT_DIR/iam_summary.json"

echo "[2/8] Mengumpulkan S3 buckets..."
aws s3api list-buckets --profile "$PROFILE" | jq -r '.Buckets[].Name' | while read bucket; do
    aws s3api get-bucket-acl --bucket "$bucket" --profile "$PROFILE" > "$OUTPUT_DIR/s3_acl_$bucket.json" 2>/dev/null
    aws s3api get-bucket-policy --bucket "$bucket" --profile "$PROFILE" > "$OUTPUT_DIR/s3_policy_$bucket.json" 2>/dev/null
    aws s3api get-bucket-public-access-block --bucket "$bucket" --profile "$PROFILE" > "$OUTPUT_DIR/s3_public_access_$bucket.json" 2>/dev/null
done

echo "[3/8] Mengumpulkan Security Groups..."
aws ec2 describe-security-groups --profile "$PROFILE" > "$OUTPUT_DIR/security_groups.json"
aws ec2 describe-security-group-rules --profile "$PROFILE" > "$OUTPUT_DIR/security_group_rules.json"

echo "[4/8] Mengumpulkan EC2 instances..."
aws ec2 describe-instances --profile "$PROFILE" > "$OUTPUT_DIR/ec2_instances.json"
aws ec2 describe-images --owners self --profile "$PROFILE" > "$OUTPUT_DIR/amis.json" 2>/dev/null

echo "[5/8] Mengumpulkan VPC information..."
aws ec2 describe-vpcs --profile "$PROFILE" > "$OUTPUT_DIR/vpcs.json"
aws ec2 describe-subnets --profile "$PROFILE" > "$OUTPUT_DIR/subnets.json"
aws ec2 describe-network-acls --profile "$PROFILE" > "$OUTPUT_DIR/network_acls.json"

echo "[6/8] Mengumpulkan CloudTrail trails..."
aws cloudtrail describe-trails --profile "$PROFILE" > "$OUTPUT_DIR/cloudtrail.json"
aws cloudtrail get-trail-status --name all --profile "$PROFILE" > "$OUTPUT_DIR/cloudtrail_status.json" 2>/dev/null

echo "[7/8] Mengumpulkan Config rules..."
aws configservice describe-config-rules --profile "$PROFILE" > "$OUTPUT_DIR/config_rules.json" 2>/dev/null

echo "[8/8] Mengumpulkan summary resource..."
aws resourcegroupstaggingapi get-resources --profile "$PROFILE" > "$OUTPUT_DIR/all_resources.json" 2>/dev/null

tar -czf "aws_data_$(date +%Y%m%d_%H%M%S).tar.gz" "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
echo "✅ Data AWS terkumpul"
