#!/bin/bash
set -e

# Get environment from command line argument, default to 'prod'
ENV=${1:-prod}

# Environment variables
AWS_DEFAULT_REGION='us-east-1'
EKS_CLUSTER_NAME='razyosefkubernetesEKS'
ARGOCD_NAMESPACE='argocd'
ARGOCD_VALUES_PATH='values/argocd-values.yaml'
GITOPS_REPO_URL='git@gitlab.com:jenkins3883827/charts.git'

infra_setup() {
    ./run.sh $ENV
}

# Function to retrieve secrets from AWS Secrets Manager
get_secret() {
    local secret_name="$1"
    local secret_value
    secret_value=$(aws secretsmanager get-secret-value --secret-id "$secret_name" --query SecretString --output text)
    if [ $? -ne 0 ]; then
        echo "Error: Failed to retrieve secret $secret_name" >&2
        exit 1
    fi
    echo "$secret_value"
}

# Function to authenticate with EKS
authenticate_eks() {
    aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_DEFAULT_REGION}
    kubectl get nodes
}

# Function to extract ArgoCD host
extract_argocd_host() {
    cluster_hostname=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} --query "cluster.endpoint" --output text | sed 's/https:\/\///')
    ARGOCD_HOST="argocd.${cluster_hostname}"
    echo "ArgoCD Host: ${ARGOCD_HOST}"
}

# Function to prepare ArgoCD values
prepare_argocd_values() {
    # Retrieve secrets
    ARGOCD_ADMIN_PASSWORD=$(get_secret "argocd-admin-password")
    GITOPS_SSH_KEY=$(get_secret "gitops-ssh-key")

    # Ensure the admin password is treated as a string
    ARGOCD_ADMIN_PASSWORD_QUOTED="'${ARGOCD_ADMIN_PASSWORD}'"

    # Format SSH key (remove any existing "sshPrivateKey: |" line)
    GITOPS_SSH_KEY_FORMATTED=$(echo "$GITOPS_SSH_KEY" | sed '/^sshPrivateKey: |/d' | sed 's/^/        /')

    # Convert hostname to lowercase
    ARGOCD_HOST_LOWER=$(echo "$ARGOCD_HOST" | tr '[:upper:]' '[:lower:]')

    # Use awk to replace placeholders and format YAML
    awk -v admin_pwd="$ARGOCD_ADMIN_PASSWORD_QUOTED" \
        -v repo_url="$GITOPS_REPO_URL" \
        -v argocd_host="$ARGOCD_HOST_LOWER" \
        -v ssh_key="$GITOPS_SSH_KEY_FORMATTED" '
    BEGIN { in_ssh_key = 0 }
    /\$ARGOCD_ADMIN_PASSWORD/ { 
        print "  secret:"
        print "    argocdServerAdminPassword: " admin_pwd
        next
    }
    /\$GITOPS_REPO_URL/ { 
        print "  repositories:"
        print "    - url: " repo_url
        print "      sshPrivateKey: |"
        print ssh_key
        in_ssh_key = 1
        next
    }
    /\$ARGOCD_HOST/ { gsub(/\$ARGOCD_HOST/, argocd_host) }
    in_ssh_key && /^[^ ]/ { in_ssh_key = 0 }  # End of SSH key block
    !in_ssh_key { print }
    ' "${ARGOCD_VALUES_PATH}" > "${ARGOCD_VALUES_PATH}.tmp" && mv "${ARGOCD_VALUES_PATH}.tmp" "${ARGOCD_VALUES_PATH}"

    # Print the content for debugging (remove in production)
    echo "Modified argocd-values.yaml content:"
    cat "${ARGOCD_VALUES_PATH}"
}


# Function to install cert-manager
install_cert_manager() {
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm upgrade --install cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --version v1.8.0 \
      --set installCRDs=true

    kubectl apply -f cert-manager/cluster-issuer.yaml
}

# Function to install ArgoCD
install_argocd() {
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade --install argocd argo/argo-cd \
      --namespace ${ARGOCD_NAMESPACE} \
      --create-namespace \
      -f ${ARGOCD_VALUES_PATH} \
      --version 3.35.4

    kubectl -n ${ARGOCD_NAMESPACE} wait --for=condition=available deployment/argocd-server --timeout=300s
}

# Main execution
main() {
    infra_setup
    authenticate_eks
    extract_argocd_host
    prepare_argocd_values
    install_cert_manager
    install_argocd
}

# Run the main function
main

# Cleanup
shred -u ${ARGOCD_VALUES_PATH}  # Securely delete the values file
