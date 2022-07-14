terraform {
  required_version = ">= 1.1.4"

  required_providers {
    aws        = ">= 4.22.0"
    http       = ">= 2.2.0"
    #template   = ">= 2.2.0"
    kubernetes = "~> 2.12.1"
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this.id
}

provider "kubernetes" {
  host                   = aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.this.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
