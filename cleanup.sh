#!/bin/bash
set -e

WORKSPACE="$1"
if [ -z "$WORKSPACE" ]; then
  echo "Usage: ./cleanup.sh <workspace-name>"
  exit 1
fi

# Grace period before force-killing stuck kubectl processes
TIMEOUT_DURATION=60

# Get all namespaces
namespaces=$(kubectl get namespaces -o jsonpath="{.items[*].metadata.name}")

# Iterate over each namespace
for namespace in $namespaces; do
    echo "Attempting to delete all Kubernetes resources in the namespace: $namespace..."
    resources=$(kubectl get all -n $namespace -o name)
    if [ -z "$resources" ]; then
        echo "No resources found in the namespace: $namespace, skipping deletion."
    else
        kubectl delete all --all -n $namespace --grace-period=60 & sleep $TIMEOUT_DURATION && pkill -9 kubectl
        echo "Forcing deletion of all Kubernetes resources in the namespace: $namespace if not completed..."
        kubectl delete all --all -n $namespace --grace-period=0 --force
    fi

    echo "Attempting to delete all Persistent Volume Claims in the namespace: $namespace..."
    pvcs=$(kubectl get pvc -n $namespace -o name)
    if [ -z "$pvcs" ]; then
        echo "No Persistent Volume Claims found in the namespace: $namespace, skipping deletion."
    else
        kubectl delete pvc --all -n $namespace --grace-period=60 & sleep $TIMEOUT_DURATION && pkill -9 kubectl
        echo "Forcing deletion of all Persistent Volume Claims in the namespace: $namespace if not completed..."
        kubectl delete pvc --all -n $namespace --grace-period=0 --force
    fi
done

echo "Attempting to delete all Persistent Volumes..."
pvs=$(kubectl get pv -o name)
if [ -z "$pvs" ]; then
    echo "No Persistent Volumes found, skipping deletion."
else
    kubectl delete pv --grace-period=60 --all & sleep $TIMEOUT_DURATION && pkill -9 kubectl
    echo "Forcing deletion of all Persistent Volumes if not completed..."
    kubectl delete pv --grace-period=0 --force --all
fi

echo "Destroying the EKS cluster using Terraform..."
./destroy.sh "$WORKSPACE"

echo "Cleanup complete."
