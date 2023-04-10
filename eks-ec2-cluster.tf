resource "aws_iam_role" "eks-cluster" {
  name = "eks-${var.eks_name}-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-service-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_eks_cluster" "cluster" {
  name     = var.eks_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks-cluster.arn

  enabled_cluster_log_types = var.enabled_cluster_log_types

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]

    security_group_ids = ["${aws_security_group.eks_cluster_sg.id}"]
    subnet_ids         = aws_subnet.private.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon-eks-cluster-policy,
    aws_iam_role_policy_attachment.amazon-eks-service-policy
  ]

  tags = merge(
    {
      Name        = format("%s-%s", var.vpc_name, "ekscluster"),
      Project     = var.project,
      Environment = var.environment
    },
    var.tags
  )

}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-ec2-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-ec2-cluster-sg"
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "egress"
}

data "tls_certificate" "example" {
  url = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "openid_connect_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.example.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

resource "aws_eks_addon" "kube-proxy" {
  addon_name        = "kube-proxy"
  addon_version     = "v1.22.6-eksbuild.1"
  cluster_name      = aws_eks_cluster.cluster.name
  resolve_conflicts = "OVERWRITE"
  depends_on        = [aws_security_group.eks_cluster_sg]
}

resource "aws_eks_addon" "coredns" {
  addon_name        = "coredns"
  addon_version     = "v1.8.7-eksbuild.1"
  cluster_name      = aws_eks_cluster.cluster.name
  resolve_conflicts = "OVERWRITE"
  depends_on        = [
    aws_security_group.eks_cluster_sg,
    aws_security_group.eks_nodes
    ]
}

resource "aws_eks_addon" "vpc-cni" {
  addon_name        = "vpc-cni"
  addon_version     = "v1.10.1-eksbuild.1"
  cluster_name      = aws_eks_cluster.cluster.name
  resolve_conflicts = "OVERWRITE"
  depends_on        = [
    aws_security_group.eks_cluster_sg,
    aws_security_group.eks_nodes
    ]
}