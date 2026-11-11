data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "hotel-tf-state-sa-2026"
    key    = "01-network/terraform.tfstate"
    region = "eu-west-1"
  }
}
data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = "hotel-tf-state-sa-2026"
    key    = "02-data/terraform.tfstate"
    region = "eu-west-1"
  }
}
resource "aws_iam_role" "eks_cluster" {
  name = "hotel-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}
resource "aws_iam_role" "eks_node" {
  name = "hotel-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}
resource "aws_iam_role_policy_attachment" "eks_ecr" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_security_group" "eks" {
  name   = "hotel-eks-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "hotel-eks-sg"
  }
}
resource "aws_eks_cluster" "main" {
  name     = "hotel-eks"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.32"
  vpc_config {
    subnet_ids             = concat(data.terraform_remote_state.network.outputs.public_subnets, data.terraform_remote_state.network.outputs.private_subnets)
    security_group_ids     = [aws_security_group.eks.id]
    endpoint_public_access = true
  }
  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
  tags = {
    Name = "hotel-eks"
  }
}
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "hotel-nodes"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = data.terraform_remote_state.network.outputs.private_subnets
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  instance_types = ["t3.micro"]
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr
  ]
  tags = {
    Name = "hotel-nodes"
  }
}
output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}
output "cloudfront_domain" {
  value = "DISABLED_FOR_FREE_TIER - Use ALB URL from kubectl get svc"
}
output "eks_cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}
output "s3_images_bucket" {
  value = "hotel-images-sa-2026"
}
