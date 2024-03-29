# Sample Terraform for Domino installed in an EKS cluster

## Prerequisites

- **kubectl** (>= v1.20)
- **aws-iam-authenticator**
- **terraform** (>= 1.1.4)

## Creating an EKS cluster

Sample code is provided in `example/main.tf`. To create an EKS cluster copy that file to a directory of your choosing and then:

* Ensure you have valid [AWS credentials in your environment or credentials file](https://www.terraform.io/docs/providers/aws/index.html#authentication)
* Ensure the variables in the `eks_cluster` module are correctly filled in. `name` is an arbitrary cluster name, but is used in combination with `root_domain` to create the Route53 records pointing to your deployment.
  * The AWS sub-account must have a hosted zone for the `root_domain` you have chosen.
* `terraform apply`

### Known Issues

1. It's possible that the EKS cluster URL DNS does not propagate entirely before the AWS authentication configmap is applied. In that case you may seen an error similar to:
    ```
    Error: Post https://XXXXX.yl4.us-west-2.eks.amazonaws.com/api/v1/namespaces/kube-system/configmaps: dial tcp 44.228.144.238:443: i/o timeout
    ```
    It is safe to re-apply the terraform when the DNS has correctly propagated. An upstream fix is potentially being tracked in [terraform-provider-kubernetes#96](https://github.com/terraform-providers/terraform-provider-kubernetes/issues/96).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allowed\_access\_cidr\_blocks | CIDR blocks allowed HTTP(s) access to the cluster's domain name. Defaults to only allowing access through the Aviatrix VPN. | `list` | <pre>[<br>  "52.206.158.130/32",<br>  "52.25.178.121/32",<br>  "52.56.39.158/32",<br>  "13.126.91.85/32"<br>]</pre> | no |
| amis | AMI mappings for regular eks and eks\_gpu nodes | <pre>map(object({<br>    name   = string<br>    owners = list(string)<br>  }))</pre> | <pre>{<br>  "eks": {<br>    "name": "amazon-eks-node-%s-v*",<br>    "owners": [<br>      "602401143452"<br>    ]<br>  },<br>  "eks_gpu": {<br>    "name": "amazon-eks-gpu-node-%s-v*",<br>    "owners": [<br>      "602401143452"<br>    ]<br>  }<br>}</pre> | no |
| autoscaling\_groups | Configuration settings for the default autoscaling groups | <pre>map(object({<br>    instance_type    = string,<br>    min_size         = number,<br>    max_size         = number,<br>    desired_capacity = number<br>  }))</pre> | <pre>{<br>  "compute": {<br>    "desired_capacity": 0,<br>    "instance_type": "m5.2xlarge",<br>    "max_size": 10,<br>    "min_size": 0<br>  },<br>  "gpu": {<br>    "desired_capacity": 0,<br>    "instance_type": "p3.2xlarge",<br>    "max_size": 1,<br>    "min_size": 0<br>  },<br>  "platform": {<br>    "desired_capacity": 1,<br>    "instance_type": "m5.2xlarge",<br>    "max_size": 1,<br>    "min_size": 0<br>  }<br>}</pre> | no |
| kubeconfig\_output\_path | Path to output a kubeconfig for the EKS cluster. Defaults to an eks-kubeconfig file in the current working directory. | `string` | `""` | no |
| kubernetes\_version | Desired Kubernetes version | `string` | `"1.21"` | no |
| name | Name of your EKS deployment | `any` | n/a | yes |
| private\_subnet\_count | Total number of private subnets in your cluster | `number` | `3` | no |
| public\_subnet\_count | Total number of public subnets in your cluster | `number` | `3` | no |
| root\_domain | Root domain where cluster DNS records will be created | `any` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| ap\_id | EFS access point ID |
| autoscaling\_group\_names | List of compute autoscaling group names that can be added to the Domino installer config |
| efs\_id | EFS filesystem ID |
| filesystem\_id | Installer filesystem ID (EFS & AP) |
| kubeconfig | kubeconfig file contents |
| s3\_buckets | S3 bucket names for use with domino |
