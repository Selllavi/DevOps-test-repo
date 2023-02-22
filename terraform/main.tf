provider "aws" {
  region = var.region
}

locals {
  cluster_name = "cluster-eks-${random_string.suffix.result}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "az0000-terraform-state"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "ecr" {
  source           = "./modules/ecr"
  ecr_repositories = var.ecr_repositories
}

module "rbac" {
  source = "./modules/eks/rbac"
}

module "dns" {
  source               = "./modules/eks/dns"
  worker_iam_role_name = module.eks.worker_iam_role_name
  cluster_id           = local.cluster_name
  helm_release         = {
    "external-dns" : "6.1.8"
  }
  eks_extra_config = {
    domain              = var.domain
    acm_certificate_arn = "arn:aws:acm:eu-west-1:723915311050:certificate/47a97105-4a64-41a9-83d7-fa4b6fedb47a"
  }
}

module "nginx" {
  source               = "./modules/eks/nginx"
  worker_iam_role_name = module.eks.worker_iam_role_name
  cluster_id           = local.cluster_name
  helm_release         = {
    "ingress-nginx" : "4.0.18"
  }
  eks_extra_config = {
    domain              = var.domain
    acm_certificate_arn = "arn:aws:acm:eu-west-1:723915311050:certificate/47a97105-4a64-41a9-83d7-fa4b6fedb47a"
  }
}

module "networking" {
  source       = "./modules/eks/networking"
  cluster_name = local.cluster_name
}

module "codepipeline" {
  source                = "./modules/codepipeline"
  repo_name             = var.repo_name
  branch                = var.branch
  repo_owner            = var.repo_owner
  github_oauth_token    = var.github_oauth_token
  aws_account_id        = var.aws_account_id
  app_bucket_name       = var.app_bucket_name
  github_webhooks_token = var.github_webhooks_token
  region                = var.region
  image_repo_name       = var.image_repo_name
  image_tag             = var.image_tag
  helm_repo_name        = var.helm_repo_name
  helm_tag              = var.helm_tag
  privileged_mode       = var.privileged_mode
  chart_release_name    = var.chart_release_name
  force_destroy         = var.force_destroy
  eks_cluster           = module.eks.cluster_id
  helm_namespace        = var.helm_namespace
  helm_namespace_create = var.helm_namespace_create
}

module "kubernetes_dashboard" {
  depends_on = ["module.rbac"]
  source     = "cookielab/dashboard/kubernetes"
  version    = "0.11.0"

  kubernetes_namespace_create = false
  kubernetes_dashboard_csrf   = "XLHOg5Wq7ZnI3zVBODzdgy14+XNrvBxLTkxWE0FTWuAtIXmwmGQ0XeQltU52KmS3eLQP9SMfQSreB6BJ7pYJNjkig3IvnJjn7MuKIrjEs3DF3xwkLF8phY/GRHmOUlCC6l5IHNWNxZQsM+b5B4wnQXlD0uREVfTuF72Tkgc98vBCK/IgWeFJB5RcpiIUVktus/T2a2HSd4KW6JGCEG4pXu8rxgZA4ZRTw0HOpGjnHag/6KK4+vGjmlvqAfoDRDBpQCO9Ijg+Yb5t2TeMrUsPbGFKxAbmmKbPgrOJNZf2rB0xbiiPo24vakC9adfCWFzL2VlK+zpKkJejGARoUsKLIQ=="
}

module "metric-server" {
  source       = "./modules/eks/metric-server"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
      command     = "aws"
    }
  }
}

module "eks" {
  source                   = "terraform-aws-modules/eks/aws"
  version                  = "17.24.0"
  cluster_name             = local.cluster_name
  cluster_version          = "1.21"
  subnets                  = module.networking.private_subnets
  wait_for_cluster_timeout = 600

  vpc_id    = module.networking.vpc_id
  map_roles = var.map_roles
  map_users = var.map_users

  workers_group_defaults = {
    root_volume_type = "gp2"
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t3.small"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [module.networking.worker_group_mgmt_one]
      asg_desired_capacity          = 2
      asg_min_size                  = 2
    },
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}