module "calculation" {
  source            = "./modules/calculation"
  instance_type     = var.instance_type
  number_of_subnets = var.number_of_subnets
  vpc_cidr          = var.vpc_cidr
}

module "network" {
  source       = "./modules/network"
  env          = var.env
  vpc_cidr     = var.vpc_cidr
  base_tags    = var.base_tags
  subnet_cidrs = module.calculation.subnet_cidrs
  final_azs    = module.calculation.final_azs
  cluster_name = var.cluster_name
  depends_on   = [module.calculation]
}

module "eks" {
  source                  = "./modules/eks"
  cluster_name            = var.cluster_name
  kubernetes_version      = var.kubernetes_version
  subnet_ids              = module.network.public_subnet_ids
  vpc_id                  = module.network.vpc_id
  instance_type           = var.instance_type
  desired_size            = var.desired_size
  max_size                = var.max_size
  min_size                = var.min_size
  node_group_name         = var.node_group_name
  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  eks_cluster_sg_id       = module.network.eks_cluster_sg_id
  base_tags               = var.base_tags
  env                     = var.env
}

module "eks_addons" {
  source                    = "./modules/eks-addons"
  cluster_name              = module.eks.cluster_id
  env                       = var.env
  enable_vpc_cni_addon      = var.enable_vpc_cni_addon
  enable_coredns_addon      = var.enable_coredns_addon
  enable_kube_proxy_addon   = var.enable_kube_proxy_addon
  vpc_cni_addon_version     = var.vpc_cni_addon_version
  coredns_addon_version     = var.coredns_addon_version
  kube_proxy_addon_version  = var.kube_proxy_addon_version
  base_tags                 = var.base_tags
  oidc_provider             = module.eks.oidc_provider
  enable_ebs_csi_driver_addon    = var.enable_ebs_csi_driver_addon
  ebs_csi_driver_addon_version   = var.ebs_csi_driver_addon_version
}

data "aws_secretsmanager_secret" "gitlab_ssh_key" {
  name = var.gitlab_ssh_key_secret_name
}

data "aws_secretsmanager_secret_version" "gitlab_ssh_key" {
  secret_id = data.aws_secretsmanager_secret.gitlab_ssh_key.id
}
module "argocd" {
  source        = "./modules/argocd"
  argocd_namespace = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version
  argocd_values = var.argocd_values
  gitlab_repo_url = var.gitlab_repo_url
  gitlab_ssh_key = data.aws_secretsmanager_secret_version.gitlab_ssh_key.secret_string
  gitlab_repo_revision = var.gitlab_repo_revision
  infra_apps_path = var.infra_apps_path
  depends_on = [module.eks, module.eks_addons]
}


