# ── AWS ────────────────────────────────────────────────────────────────────────
aws_region = "us-east-1"

# ── Network ────────────────────────────────────────────────────────────────────
# /20 gives 4x /22 subnets (1024 IPs each) — 2 public + 2 private
vpc_cidr          = "10.0.0.0/20"
number_of_subnets = 2

# ── General ────────────────────────────────────────────────────────────────────
env = "prod"
base_tags = {
  owner   = "your-name"
  project = "portfolio"
}

# ── EKS Cluster ────────────────────────────────────────────────────────────────
cluster_name            = "portfolio-eks"
kubernetes_version      = "1.31"
instance_type           = "t3a.medium"
endpoint_private_access = false
endpoint_public_access  = true
# Replace with your office/VPN IP before applying (e.g. "1.2.3.4/32")
public_access_cidrs = ["192.0.2.0/24"]

# ── EKS Node Group ─────────────────────────────────────────────────────────────
node_group_name = "portfolio-ng"
desired_size    = 3
min_size        = 2
max_size        = 5

# ── EKS Add-ons ────────────────────────────────────────────────────────────────
enable_vpc_cni_addon        = true
enable_coredns_addon        = true
enable_kube_proxy_addon     = true
enable_ebs_csi_driver_addon = true

vpc_cni_addon_version        = "v1.19.0-eksbuild.1"
coredns_addon_version        = "v1.11.3-eksbuild.1"
kube_proxy_addon_version     = "v1.31.2-eksbuild.3"
ebs_csi_driver_addon_version = "v1.37.0-eksbuild.1"

# ── ArgoCD ─────────────────────────────────────────────────────────────────────
argocd_namespace     = "argocd"
argocd_chart_version = "7.7.0"

# Secrets stored in AWS Secrets Manager (never commit secrets themselves)
github_ssh_key_secret_name = "portfolio/github-ssh-key"
google_oauth_secret_name   = "portfolio/google-oauth-client-secret"
github_repo_url            = "git@github.com:razyos/charts.git"
github_repo_revision       = "main"
infra_apps_path            = "sets"

# ArgoCD Helm values — ingress, SSO, and RBAC
argocd_values = {
  server = {
    ingress = {
      enabled = true
      https   = true
      hosts   = ["argocd.your-domain.com"]
      annotations = {
        "kubernetes.io/ingress.class"    = "nginx"
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      }
      tls = [{
        secretName = "argocd-server-tls"
        hosts      = ["argocd.your-domain.com"]
      }]
    }
  }
  configs = {
    params = {
      "server.insecure" = false
    }
    cm = {
      "admin.enabled" = "true"
      "url"           = "https://argocd.your-domain.com"
    }
  }
}
