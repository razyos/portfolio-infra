#!/bin/bash

terraform init -backend-config=backend-config.hcl
WORKSPACE="$1"

if [ -z "$WORKSPACE" ]; then
  echo "No workspace specified. Usage: ./manage_workspace.sh <workspace-name>"
  exit 1
fi

# Check if the workspace exists
EXISTING_WORKSPACES=$(terraform workspace list)

if ! echo "$EXISTING_WORKSPACES" | grep -q "$WORKSPACE"; then
   terraform workspace new "$WORKSPACE"
fi
terraform workspace select "$WORKSPACE"

terraform plan -var-file="$WORKSPACE.tfvars"
terraform apply -var-file="$WORKSPACE.tfvars"

