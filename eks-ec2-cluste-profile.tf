resource "aws_iam_role" "eks_nodegroup_role" {
  name = "${var.eks_name}-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ec2.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-workernode-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks-ekscni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks-ecrreadonly-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodegroup_role.name
}

resource "aws_eks_node_group" "eksec2-nodegroup" {
  cluster_name           = aws_eks_cluster.cluster.name
  node_group_name = "eks-ec2-nodegroup"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn  
  subnet_ids = "${aws_subnet.private.*.id}"

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 1
  }

  ami_type       = "AL2_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM
  capacity_type  = "ON_DEMAND"  # ON_DEMAND, SPOT
  disk_size      = 20
  instance_types = ["t2.medium"]  

  tags = merge(
    {
      Name        = format("%s-%s", var.vpc_name, "node-grup"),
      Project     = var.project,
      Environment = var.environment
    },    
    var.tags
  )  

  depends_on = [
    aws_iam_role_policy_attachment.eks-workernode-policy,
    aws_iam_role_policy_attachment.eks-ekscni-policy,
    aws_iam_role_policy_attachment.eks-ecrreadonly-policy,
  ]  

}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.eks_name}-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name                                    = "${var.eks_name}-node-sg"
    "kubernetes.io/cluster/${var.eks_name}" = "owned"
  }
}

resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "nodes_cluster_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  to_port                  = 65535
  type                     = "ingress"
}