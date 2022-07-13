variable "allowed_access_cidr_blocks" {
  description = "CIDR blocks allowed HTTP(s) access to the cluster's domain name. Defaults to only allowing access through the Aviatrix VPN."
  default     = ["52.206.158.130/32", "52.25.178.121/32", "52.56.39.158/32", "13.126.91.85/32"]
}

variable "autoscaling_groups" {
  description = "Configuration settings for the default autoscaling groups"
  type = map(object({
    instance_type    = string,
    min_size         = number,
    max_size         = number,
    desired_capacity = number
  }))

  default = {
    platform = {
      instance_type    = "m5.2xlarge"
      min_size         = 0
      max_size         = 3
      desired_capacity = 1
    },
    compute = {
      instance_type    = "m5.2xlarge"
      min_size         = 0
      max_size         = 10
      desired_capacity = 0
    },
    gpu = {
      instance_type    = "p3.2xlarge"
      min_size         = 0
      max_size         = 1
      desired_capacity = 0
    }
  }
}

variable "amis" {
  description = "AMI mappings for regular eks and eks_gpu nodes"

  type = map(object({
    name   = string
    owners = list(string)
  }))

  default = {
    eks = {
      name   = "amazon-eks-node-%s-v*"
      owners = ["602401143452"]
    }
    eks_gpu = {
      name   = "amazon-eks-gpu-node-%s-v*"
      owners = ["602401143452"]
    }
  }
}

variable "kubeconfig_output_path" {
  description = "Path to output a kubeconfig for the EKS cluster. Defaults to an eks-kubeconfig file in the current working directory."
  default     = ""
}

variable "kubernetes_version" {
  description = "Desired Kubernetes version"
  default     = "1.21"
}

variable "name" {
  description = "Name of your EKS deployment"
}

variable "private_subnet_count" {
  description = "Total number of private subnets in your cluster"
  default     = 3
}

variable "public_subnet_count" {
  description = "Total number of public subnets in your cluster"
  default     = 3
}

variable "root_domain" {
  description = "Root domain where cluster DNS records will be created"
}
