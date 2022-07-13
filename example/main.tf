provider "aws" {
  region = "us-west-2"
}

module "eks_cluster" {
  source = "git::https://github.com/ddl-acoleman/sample-tf-aws"

  name        = "ddl-frbny"
  root_domain = "ddl-frbny.cs.domino.tech"
}

output "autoscaling_groups" {
  value = module.eks_cluster.autoscaling_group_names
}

output "efs_id" {
  value = module.eks_cluster.efs_id
}

output "s3_buckets" {
  value = module.eks_cluster.s3_buckets
}
