variable "argocd_namespace" {
  description = "Namespace to deploy ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart to install"
  type        = string
  default     = "7.7.0"
}

variable "argocd_values" {
  description = "Values to pass to the ArgoCD Helm chart"
  type        = any
  default     = {}
}

variable "github_repo_url" {
  description = "SSH URL of the GitHub charts repository"
  type        = string
}

variable "github_ssh_key" {
  description = "SSH private key for GitHub repository access (retrieved from Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "github_repo_revision" {
  description = "GitHub repository revision (branch) to track"
  type        = string
  default     = "main"
}

variable "infra_apps_path" {
  description = "Path inside the GitHub repo that contains the ArgoCD ApplicationSets"
  type        = string
  default     = "sets"
}
