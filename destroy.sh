#!/bin/bash
WORKSPACE="$1"

if [ -z "$WORKSPACE" ]; then
  echo "No workspace specified. Usage: ./manage_workspace.sh <workspace-name>"
  exit 1
fi

terraform workspace select "$WORKSPACE"

echo "Searching for ELBs associated with the VPC..."
VPC_ID=$(terraform output -raw vpc_id)

if [ -n "$VPC_ID" ]; then
  echo "Checking for ELBs in the VPC..."
  ELB_NAMES=$(aws elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text)
  
  for ELB_NAME in $ELB_NAMES; do
    echo "Deleting ELB: $ELB_NAME"
    aws elb delete-load-balancer --load-balancer-name "$ELB_NAME"
  done
else
  echo "No VPC ID found."
fi

terraform destroy -var-file="$WORKSPACE.tfvars" --auto-approve
