terraform {
  required_version = ">= 0.12.0"

  required_providers {
    aws        = ">= 2.28.1"
    http       = ">= 1.1.1"
    template   = ">= 2.1.2"
    kubernetes = "~> 1.10.0"
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this.id
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
