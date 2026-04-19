terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

# Install ArgoCD Helm Chart
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    yamlencode(var.argocd_values)
  ]
  depends_on = [kubernetes_namespace.argocd]
  # depends_on = [kubernetes_namespace.argocd,helm_release.cert_manager_crds]
}

# GitHub Repo Secret
resource "kubernetes_secret" "github_repo" {
  metadata {
    name      = "github-repo"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.github_repo_url
    sshPrivateKey = var.github_ssh_key
  }

  type       = "Opaque"
  depends_on = [kubernetes_namespace.argocd]
}

# Apply the "App of Apps" ArgoCD Application
resource "kubectl_manifest" "argocd_app_of_apps" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: ${var.argocd_namespace}
spec:
  project: default
  source:
    repoURL: ${var.github_repo_url}
    targetRevision: ${var.github_repo_revision}
    path: ${var.infra_apps_path}

  destination:
    server: https://kubernetes.default.svc
    namespace: ${var.argocd_namespace}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML

  depends_on = [helm_release.argocd, kubernetes_secret.github_repo]
}
