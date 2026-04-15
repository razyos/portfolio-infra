#!/bin/bash

NAMESPACE="argocd"

# Step 1: Check if namespace exists
if kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
  echo "Namespace $NAMESPACE exists. Proceeding with deletion..."
else
  echo "Namespace $NAMESPACE does not exist. Exiting."
  exit 1
fi

# Step 2: Remove finalizers from the namespace
echo "Removing finalizers from the namespace..."
kubectl get namespace "$NAMESPACE" -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f -

# Step 3: Force delete stuck resources in the namespace
echo "Force deleting stuck resources in namespace $NAMESPACE..."
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl delete --all --grace-period=0 --force -n "$NAMESPACE"

# Step 4: Remove ArgoCD CRDs if they exist
echo "Deleting ArgoCD CRDs..."
CRDS=$(kubectl get crd | grep 'argoproj.io' | awk '{print $1}')
for crd in $CRDS; do
  kubectl delete crd "$crd"
done

# Step 5: Remove ArgoCD ClusterRoleBindings and ClusterRoles
echo "Deleting ArgoCD ClusterRoleBindings and ClusterRoles..."
CLUSTER_ROLE_BINDINGS=$(kubectl get clusterrolebinding | grep 'argocd' | awk '{print $1}')
for crb in $CLUSTER_ROLE_BINDINGS; do
  kubectl delete clusterrolebinding "$crb"
done

CLUSTER_ROLES=$(kubectl get clusterrole | grep 'argocd' | awk '{print $1}')
for cr in $CLUSTER_ROLES; do
  kubectl delete clusterrole "$cr"
done

# Step 6: Delete the namespace
echo "Deleting the namespace $NAMESPACE..."
kubectl delete namespace "$NAMESPACE"

echo "ArgoCD namespace deletion process complete."
