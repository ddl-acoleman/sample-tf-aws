data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "autoscaling_role_policy" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]

    resources = concat(
      aws_autoscaling_group.compute[*].arn,
      aws_autoscaling_group.gpu[*].arn
    )
  }
}

data "aws_iam_policy_document" "ec2_snapshot_policy" {
  statement {
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "nodes" {
  name               = "${var.name}-nodes"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_policy" "autoscaling_policy" {
  name   = "${var.name}-autoscaling"
  policy = data.aws_iam_policy_document.autoscaling_role_policy.json
}

resource "aws_iam_policy" "ec2_snapshot_policy" {
  name   = "${var.name}-ec2-snapshot"
  policy = data.aws_iam_policy_document.ec2_snapshot_policy.json
}

resource "aws_iam_role_policy_attachment" "nodes_autoscaling_policy" {
  policy_arn = aws_iam_policy.autoscaling_policy.arn
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_ec2_snapshot_policy" {
  policy_arn = aws_iam_policy.ec2_snapshot_policy.arn
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonElasticFileSystemReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemReadOnlyAccess"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_s3_bucket_access" {
  policy_arn = aws_iam_policy.s3_bucket_access.arn
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_instance_profile" "nodes" {
  name = "${var.name}-nodes"
  role = aws_iam_role.nodes.name
}

resource "aws_security_group" "nodes" {
  name        = "${var.name}-nodes"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-nodes"
  }
}

resource "aws_security_group_rule" "nodes_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_ingress_alb" {
  description              = "Allow worker nodes to receive communication from the ALB"
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nodes.id
  source_security_group_id = aws_security_group.alb.id
  to_port                  = 80
  type                     = "ingress"
}

data "aws_ami" "eks_node" {
  filter {
    name   = "name"
    values = [format(var.amis.eks.name, aws_eks_cluster.this.version)]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

data "aws_ami" "gpu_node" {
  filter {
    name   = "name"
    values = [format(var.amis.eks_gpu.name, aws_eks_cluster.this.version)]
  }

  most_recent = true
  owners      = var.amis.eks_gpu.owners # Amazon EKS AMI Account ID
}

# data "template_file" "platform" {
#   template = file("${path.module}/templates/user_data.sh.tpl")
#   vars = {
#     apiserver_endpoint   = aws_eks_cluster.this.endpoint
#     cluster_ca           = aws_eks_cluster.this.certificate_authority.0.data
#     name                 = var.name
#     kubelet_extra_args   = "--node-labels=dominodatalab.com/node-pool=platform"
#     enable_docker_bridge = true
#   }
# }
# 
# data "template_file" "compute" {
#   template = file("${path.module}/templates/user_data.sh.tpl")
#   vars = {
#     apiserver_endpoint   = aws_eks_cluster.this.endpoint
#     cluster_ca           = aws_eks_cluster.this.certificate_authority.0.data
#     name                 = var.name
#     kubelet_extra_args   = "--node-labels=dominodatalab.com/node-pool=default,domino/build-node=true"
#     enable_docker_bridge = true
#   }
# }
# 
# data "template_file" "gpu" {
#   template = file("${path.module}/templates/user_data.sh.tpl")
#   vars = {
#     apiserver_endpoint   = aws_eks_cluster.this.endpoint
#     cluster_ca           = aws_eks_cluster.this.certificate_authority.0.data
#     name                 = var.name
#     kubelet_extra_args   = "--node-labels=dominodatalab.com/node-pool=default-gpu,nvidia.com/gpu=true --register-with-taints=nvidia.com/gpu=true:NoExecute"
#     enable_docker_bridge = false
#   }
# }

resource "aws_launch_configuration" "platform" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.nodes.name
  image_id                    = data.aws_ami.eks_node.id
  instance_type               = var.autoscaling_groups.platform.instance_type
  name_prefix                 = "${var.name}-platform-"
  security_groups             = [aws_security_group.nodes.id]
  #user_data_base64            = base64encode(data.template_file.platform.rendered)
  user_data_base64 = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl",
    { apiserver_endpoint   = aws_eks_cluster.this.endpoint,
      cluster_ca           = aws_eks_cluster.this.certificate_authority.0.data,
      name                 = var.name,
      kubelet_extra_args   = "--node-labels=dominodatalab.com/node-pool=platform",
      enable_docker_bridge = true
  }))
  root_block_device {
    volume_size           = 200
    delete_on_termination = true
    encrypted             = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "platform" {
  count                = var.private_subnet_count
  desired_capacity     = var.autoscaling_groups.platform.desired_capacity
  launch_configuration = aws_launch_configuration.platform.id
  max_size             = var.autoscaling_groups.platform.max_size
  min_size             = var.autoscaling_groups.platform.min_size
  name                 = "${var.name}-platform-${aws_subnet.private[count.index].availability_zone_id}"
  vpc_zone_identifier  = [aws_subnet.private[count.index].id]
  target_group_arns    = [aws_lb_target_group.this.arn]

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-platform-${aws_subnet.private[count.index].availability_zone_id}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/dominodatalab.com/node-pool"
    propagate_at_launch = true
    value               = "platform"
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/dominodatalab.com/domino-node"
    propagate_at_launch = true
    value               = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.name}"
    value               = "shared"
    propagate_at_launch = true
  }
}


resource "aws_launch_configuration" "compute" {
  iam_instance_profile = aws_iam_instance_profile.nodes.name
  image_id             = data.aws_ami.eks_node.id
  instance_type        = var.autoscaling_groups.compute.instance_type
  name_prefix          = "${var.name}-compute-"
  security_groups      = [aws_security_group.nodes.id]
  #user_data_base64     = base64encode(data.template_file.compute.rendered)
  user_data_base64 = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl",
    { apiserver_endpoint   = aws_eks_cluster.this.endpoint,
      cluster_ca           = aws_eks_cluster.this.certificate_authority.0.data,
      name                 = var.name,
      kubelet_extra_args   = "--node-labels=dominodatalab.com/node-pool=default,domino/build-node=true"
      enable_docker_bridge = true
  }))

  root_block_device {
    volume_size           = 200
    delete_on_termination = true
    encrypted             = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "compute" {
  count                = var.private_subnet_count
  vpc_zone_identifier  = [aws_subnet.private[count.index].id]
  desired_capacity     = var.autoscaling_groups.compute.desired_capacity
  launch_configuration = aws_launch_configuration.compute.id
  max_size             = var.autoscaling_groups.compute.max_size
  min_size             = var.autoscaling_groups.compute.min_size
  name                 = "${var.name}-compute-${aws_subnet.private[count.index].availability_zone_id}"

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-compute-${aws_subnet.private[count.index].availability_zone_id}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/dominodatalab.com/node-pool"
    propagate_at_launch = true
    value               = "default"
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/domino/build-node"
    propagate_at_launch = true
    value               = "true"
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    propagate_at_launch = true
    value               = "true"
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.name}"
    propagate_at_launch = true
    value               = "true"
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/dominodatalab.com/domino-node"
    propagate_at_launch = true
    value               = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.name}"
    value               = "shared"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "gpu" {
  iam_instance_profile = aws_iam_instance_profile.nodes.name
  image_id             = data.aws_ami.gpu_node.id
  instance_type        = var.autoscaling_groups.gpu.instance_type
  name_prefix          = "${var.name}-gpu-"
  security_groups      = [aws_security_group.nodes.id]
  #user_data_base64     = base64encode(data.template_file.gpu.rendered)
  user_data_base64 = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl",
    { apiserver_endpoint   = aws_eks_cluster.this.endpoint,
      cluster_ca           = aws_eks_cluster.this.certificate_authority.0.data,
      name                 = var.name,
      kubelet_extra_args   = "--node-labels=dominodatalab.com/node-pool=default-gpu,nvidia.com/gpu=true --register-with-taints=nvidia.com/gpu=true:NoExecute"
      enable_docker_bridge = false
  }))

  root_block_device {
    volume_size           = 200
    delete_on_termination = true
    encrypted             = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "gpu" {
  count                = var.private_subnet_count
  vpc_zone_identifier  = [aws_subnet.private[count.index].id]
  desired_capacity     = var.autoscaling_groups.gpu.desired_capacity
  launch_configuration = aws_launch_configuration.gpu.id
  max_size             = var.autoscaling_groups.gpu.max_size
  min_size             = var.autoscaling_groups.gpu.min_size
  name                 = "${var.name}-gpu-${aws_subnet.private[count.index].availability_zone_id}"

  lifecycle {
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-gpu-${aws_subnet.private[count.index].availability_zone_id}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/dominodatalab.com/node-pool"
    propagate_at_launch = true
    value               = "default-gpu"
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/node-template/label/dominodatalab.com/domino-node"
    propagate_at_launch = true
    value               = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.name}"
    value               = "shared"
    propagate_at_launch = true
  }
}
