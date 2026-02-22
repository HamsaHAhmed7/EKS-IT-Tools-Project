module "vpc" {
  source = "./modules/vpc"

  project      = var.project
  cluster_name = "${var.project}-eks-cluster"
  common_tags  = local.common_tags
}

module "route53" {
  source         = "./modules/route53"
  project        = var.project
  domain         = var.domain
  parent_zone_id = var.parent_zone_id
  common_tags    = local.common_tags

}

module "eks" {
  source = "./modules/eks"

  project     = var.project
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids
  common_tags = local.common_tags
  eks_version = var.eks_version

}

module "helm" {
  source = "./modules/helm"

  lbc_pod_identity          = module.eks.aws_lbc_pod_identity
  external_dns_pod_identity = module.eks.external_dns_pod_identity
  cluster_name              = module.eks.cluster_name
  vpc_id                    = module.vpc.vpc_id

  depends_on = [module.eks]
}

module "github_oidc" {
  source = "./modules/github-oidc"

  project     = var.project
  github_org  = var.github_org
  github_repo = var.github_repo
  common_tags = local.common_tags
}
