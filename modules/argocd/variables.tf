variable "argocd_namespace" {
  description = "Namespace to deploy ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Version of the ArgoCD Helm chart to install"
  type        = string
  default     = "5.13.8"
}

variable "argocd_values" {
  description = "Values to pass to the ArgoCD Helm chart"
  type        = any
  default     = {}
}

variable "gitlab_repo_url" {
  description = "URL of the GitLab repository"
  type        = string
}

variable "gitlab_ssh_key" {
  description = "SSH private key for GitLab repository access"
  type        = string
  sensitive   = true
}

variable "gitlab_repo_revision" {
  description = "GitLab repository revision to use"
  type        = string
  default     = "main"
}

variable "infra_apps_path" {
  description = "Path in the GitLab repo for infra-apps"
  type        = string
  default     = "infra-apps"
}


variable "gitlab_ssh_key_secret_name" {
  description = "Name of the GitLab SSH key secret"
  type        = string
  default     = "gitlab-repo"
}